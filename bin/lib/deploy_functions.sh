#!/bin/bash

check_for_dependencies() {
    STEP="[check_for_dependencies] checking if aws in PATH"
    aws help > /dev/null
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if figlet in PATH"
    figlet test > /dev/null
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if jq in PATH"
    echo '{}' | jq '[]' > /dev/null
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if git in PATH"
    git --help > /dev/null
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if curl in PATH"
    curl --help > /dev/null
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if terraform in PATH"
    TERRAFORM_VERSION=$(terraform version | grep -o 'Terraform v[0-9]*\.[0-9]*\.[0-9]*')
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if $TERRAFORM_VERSION matches ${EXPECTED_TERRAFORM_VERSION}"
    [ "$EXPECTED_TERRAFORM_VERSION" == "$TERRAFORM_VERSION" ]
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if packer in PATH"
    PACKER_VERSION=$(packer version | grep -o 'Packer v[0-9]*\.[0-9]*\.[0-9]*')
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if $PACKER_VERSION matches ${EXPECTED_PACKER_VERSION}"
    [ "$EXPECTED_PACKER_VERSION" == "$PACKER_VERSION" ]
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if python in PATH"
    PYTHON_VERSION=$(python --version)
    RC=$?; error_check

    STEP="[check_for_dependencies] checking if $PYTHON_VERSION matches ${EXPECTED_PYTHON_VERSION}"
    [ "$EXPECTED_PYTHON_VERSION" == "$PYTHON_VERSION" ]
    RC=$?; error_check
}

check_if_should_deploy() {
    STEP="[check_if_should_deploy] curl ${LIVE_ENV_URL}"
    LIVE_GIT_COMMIT_HASH=$(curl ${LIVE_ENV_URL})
    RC=$?; error_check

    if [[ "$GIT_COMMIT_HASH" == "$LIVE_GIT_COMMIT_HASH" ]]; then
        # up to date
        SHOULD_DEPLOY="false"
    fi
}

function find_ami() {
    STEP="[find_ami] Finding AMI by apphash ${SPECIFIED_HASH}"; format_logs
    # the aws command outputs CreationDate and ImageId
    # we sort by date and choose the most recent AMI using sort | tail | awk
    AMI_ID=$(aws ec2 describe-images \
             --filters Name=tag:apphash,Values="${SPECIFIED_HASH}" \
             --output text --query 'Images[].[CreationDate, ImageId]' \
             | sort -k1 | tail -n1 | awk '{print $2; exit ($2 == "" ? 1: 0)}')
    # awk exits 1 if no ami found
    RC=$?; error_check
    # this is a problem if we want to SKIP_TO_DEPLOYMENT
    # otherwise, we can short circuit having to recreate AMIs in case of rollback
    if [[ -z "$AMI_ID" ]] && [[ "$SKIP_TO_DEPLOYMENT" == "true" ]]; then
        RC=1; error_check
    elif [[ -z "$AMI_ID" ]]; then
        STEP="[find_ami] Could not find AMI for ${GIT_COMMIT_HASH}."; format_logs
    else
        # if we have found the AMI
        STEP="[find_ami] Found AMI $AMI_ID, getting AMI_NAME"; format_logs
        AMI_NAME=$(aws ec2 describe-images --image-id "${AMI_ID}" \
            --output text --query 'Images[0].Tags[?Key==`Name`].Value')
        RC=$?; error_check
    fi
}

function get_initial_instances() {
    # Get a list of existing instance ids to terminate later
    for ROLEENVNAME in $ROLES; do
        identify_role "$ROLEENVNAME"
        STEP="[get_initial_instances] Listing instances in ${AUTOSCALENAME}"; format_logs
        INITIAL_INSTANCES="${INITIAL_INSTANCES} $(aws autoscaling \
                          describe-auto-scaling-groups \
                          --auto-scaling-group-name "${AUTOSCALENAME}" \
                          --output text \
                          --query 'AutoScalingGroups[0].Instances[*].InstanceId')"
        RC=$?; error_check
    done
}

function scale_in_per_elb() {
    STEP="[scale_in_per_elb] Checking desired capacity for ${AUTOSCALENAME}"; format_logs
    # We'll set the initial capacity and go back to that at the end
    INITIAL_CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
                      --auto-scaling-group-names "${AUTOSCALENAME}" \
                      --output text \
                      --query 'AutoScalingGroups[0].DesiredCapacity')
    RC=$?; error_check

    # How many new nodes will we need to scale in for this deploy?
    DEPLOY_CAPACITY=$((INITIAL_CAPACITY*2))

    STEP="[scale_in_per_elb] Setting min and desired sizes for ${AUTOSCALENAME} to ${DEPLOY_CAPACITY}"; format_logs
    # Tell the AWS api to give us more instances in that role env.
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${AUTOSCALENAME}" --min-size "${DEPLOY_CAPACITY}"
    RC=$?; error_check

    aws autoscaling set-desired-capacity --auto-scaling-group-name "${AUTOSCALENAME}" --desired-capacity "${DEPLOY_CAPACITY}"
    RC=$?; error_check
}

function check_health_per_elb() {
    STEP="[check_health_per_elb] Checking desired capacity for ASG ${AUTOSCALENAME}"; format_logs
    # We'll want to ensure the number of healthy hosts is equal to total number of hosts
    ASG_CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
                 --auto-scaling-group-names "${AUTOSCALENAME}" \
                 --output text \
                 --query 'AutoScalingGroups[0].DesiredCapacity')
    RC=$?; error_check

    STEP="[check_health_per_elb] Checking instance health for ELB ${ELBNAME}"; format_logs
    HEALTHY_HOST_COUNT=$(aws elb describe-instance-health \
                       --load-balancer-name "${ELBNAME}" \
                       --query 'length(InstanceStates[?State==`InService`])')
    RC=$?; error_check

    CURRENT_HEALTH="${CURRENT_HEALTH} $(aws elb describe-instance-health \
                   --load-balancer-name "${ELBNAME}" \
                   --query 'length(InstanceStates[])')"
    RC=$?; error_check

    if [ "${HEALTHY_HOST_COUNT}" -lt "${ASG_CAPACITY}" ]; then
        CURRENT_HEALTH="UNHEALTHY"
    fi
    echo "$(date) -- ${AUTOSCALENAME} nodes healthy in ELB: ${HEALTHY_HOST_COUNT} / ${ASG_CAPACITY}"
}

function scale_in_all() {
    STEP="[scale_in_all] Scaling in per role"; format_logs
    # Each socorro env has its own master list in ./lib.
    # We iterate over that list to scale up and identify nodes to kill later
    for ROLEENVNAME in $ROLES; do
        identify_role "$ROLEENVNAME"
        scale_in_per_elb
    done
}

function monitor_overall_health() {
    STEP="[monitor_overall_health] Waiting for all ELBs to report healthy and full"; format_logs
    # If any elb is still unhealthy, we don't want to kill nodes
    ATTEMPT_COUNT=0;
    NO_HEALTH_ALERT=""
    OVERALL_HEALTH="UNHEALTHY"
    until [ "${OVERALL_HEALTH}" = "HEALTHY" ]; do
        CURRENT_HEALTH=""
        ATTEMPT_COUNT=$((ATTEMPT_COUNT+1))
        echo "$(date) -- Attempt ${ATTEMPT_COUNT} of 15 checking on healthy elbs"
        for ROLEENVNAME in $ROLES; do
            # Get the AS name and ELB name for this particular role/env
            identify_role "${ROLEENVNAME}"
            if [ "${ELBNAME}" = "NONE" ];then
                echo "No elb to check for ${ROLEENVNAME}" > /dev/null
            else
                check_health_per_elb
            fi
        done
        # Check for OutOfService in the saved string of statuses.    If it exists, reset and wait.
        if echo "${CURRENT_HEALTH}" | grep "UNHEALTHY" > /dev/null; then
            sleep 60 # We want to be polite to the API
            if [ "$ATTEMPT_COUNT" -gt 14 ]; then
                echo "$(date) -- ALERT!  We've tried for 15 minutes to wait for healthy nodes, continuing"
                NO_HEALTH_ALERT="true"
                # this breaks the until loop
                OVERALL_HEALTH="HEALTHY"
            fi
        else
            echo "$(date) -- ELBs are now healthy"
            OVERALL_HEALTH="HEALTHY"
        fi
    done
    if [ "${OVERALL_HEALTH}" = "HEALTHY" ] && [ "${NO_HEALTH_ALERT}" = "" ];then
        echo "$(date) -- We are bonafide healthy"
    fi
}

function instance_deregister() {
    # We check to see if each instance in a given ELB is one of the doomed nodes
    if echo "${INITIAL_INSTANCES}" | grep "$1" > /dev/null;then
        # doing this for consistency even though we don't error_check
        STEP="[instance_deregister] Deregistering ${1} from ${2}"; format_logs
        aws elb deregister-instances-from-load-balancer \
            --load-balancer-name "$2" \
            --instances "$1"
        rc=$?; if [[ $rc != 0 ]]; then
            echo "$(date) -- Attempt to deregister $1 from $2 failed with RC ${rc}"
        else
            echo "$(date) -- Deregistered $1 from $2 successfully."
        fi
    fi
}

function deregister_elb_nodes() {
    # We'll list every ELB involved, and for each, list every instance.    Then, for each instance
    # we check if it is on the doomed list.    If so, we deregister it to allow a 30s drain
    for ROLEENVNAME in $ROLES; do
        # Get ELB and AS group name.
        identify_role "${ROLEENVNAME}"
        if [ "${ELBNAME}" = "NONE" ];then
            echo "No ELB to check for ${ROLEENVNAME}"
        else
            echo "Deregistering initial instances from ${ELBNAME}"
            # For every instance in $ELBNAME, check if it's slated to be killed.
            STEP="[deregister_elb_nodes] Getting instances for ${ELBNAME}"; format_logs
            INSTANCES=$(aws elb describe-instance-health \
                         --load-balancer-name "${ELBNAME}" \
                         --output text --query 'InstanceStates[*].InstanceId')
            RC=$?; error_check
            for INSTANCETOCHECK in $INSTANCES; do
               instance_deregister "${INSTANCETOCHECK}" "${ELBNAME}"
            done
        fi
    done
    echo "$(date) -- All instances in ELBs deregistered, waiting for the 30 second drain period"
}

function terminate_instances() {
    # We iterate over the list of instances to terminate (${INITIAL_INSTANCES}) and send each one here to
    # be terminated and simultaneously drop the desired-capacity down by 1.
    STEP="[terminate_instances] Terminating ${1}"; format_logs
    aws autoscaling terminate-instance-in-auto-scaling-group --instance-id "$1" --should-decrement-desired-capacity
    rc=$?; if [[ $rc != 0 ]]; then
        echo "$(date) -- Attempt to terminate $1 failed with RC ${rc}"
    else
        echo "$(date) -- Terminated $1 successfully."
    fi
}

function apply_ami() {
    # For each of our apps, we want to use terraform to apply the new base AMI we've just created
    for ROLEENVNAME in $ROLES; do
            # Get AS group name for each ROLE
            echo "$(date) -- Checking role for ${ROLEENVNAME}"
            identify_role "${ROLEENVNAME}"
            infra_report "${AUTOSCALENAME}" >> "${STARTLOG}"
            STEP="[apply_ami] Getting capacity of ${AUTOSCALENAME} (${ROLEENVNAME})"; format_logs
            ASG_CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
                         --auto-scaling-group-names "${AUTOSCALENAME}" \
                         --output text \
                         --query 'AutoScalingGroups[0].DesiredCapacity')
            RC=$?; error_check

            cd "${SOCORRO_INFRA_PATH}/terraform"
            RC=$?; error_check

            echo "$(date) -- Attempting to terraform plan and apply ${AUTOSCALENAME}"
            STEP="[apply_ami] Terraform plan for ${ROLEENVNAME}"; format_logs
            # note: wrapper.sh will add /home/centos/terraform to PATH if terraform is not in PATH
            ${SOCORRO_INFRA_PATH}/terraform/wrapper.sh "plan -var base_ami={us-west-2=\"${AMI_ID}\"} -var ${SCALEVARIABLE}=${ASG_CAPACITY}" "${ENVIRONMENT}" "${TERRAFORMNAME}"
            RC=$?; error_check

            echo -e "\n\n==================================\n"
            STEP="[apply_ami] Terraform apply for ${ROLEENVNAME}"; format_logs
            ${SOCORRO_INFRA_PATH}/terraform/wrapper.sh "apply -var base_ami={us-west-2=\"${AMI_ID}\"} -var ${SCALEVARIABLE}=${ASG_CAPACITY}" "${ENVIRONMENT}" "${TERRAFORMNAME}"
            RC=$?; error_check
        done
    echo "$(date) -- All roles updated"
}

function terminate_instances_all() {
    for ROLEENVNAME in $ROLES; do
        # First, we halve the number of minimum size for each group
        echo "$(date) -- Setting min size for ${ROLEENVNAME}"
        identify_role "${ROLEENVNAME}"
        STEP="[terminate_instances_all] Describe instances for ${AUTOSCALENAME} (${ROLEENVNAME})"; format_logs
        ASG_CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
                     --auto-scaling-group-names "${AUTOSCALENAME}" \
                     --output text \
                     --query 'AutoScalingGroups[0].DesiredCapacity')
        RC=$?; error_check
        # lol integer division => lose an instance if ASG size was odd
        SCALEDOWNCAPACITY=$((ASG_CAPACITY/2))
        if [ "${SCALEDOWNCAPACITY}" -lt 1 ]; then
            SCALEDOWNCAPACITY=1
        fi
        # Scale back to half current min size, unless that'd bring us to 0
        STEP="[terminate_instances_all] Setting ${AUTOSCALENAME} from ${ASG_CAPACITY} min size to ${SCALEDOWNCAPACITY} (${ROLEENVNAME})"; format_logs
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${AUTOSCALENAME}" --min-size "${SCALEDOWNCAPACITY}"
        RC=$?; error_check

    done
    # With the list we built earlier of old instances, iterate over it and terminate/decrement
    for doomedinstances in ${INITIAL_INSTANCES}; do
        terminate_instances "$doomedinstances"
    done
}

function query_end_scale() {
    echo "END STATE FOR AUTO SCALING GROUPS"
    for ROLEENVNAME in $ROLES; do
        identify_role "${ROLEENVNAME}"
        infra_report "${AUTOSCALENAME}" >> "${ENDLOG}"
    done
}
