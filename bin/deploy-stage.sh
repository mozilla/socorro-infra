#!/bin/bash

### this executes socorro stage build and can run without arguments
### by default builds most recent commit to master
### optional argument $1: socorro SHA corresponding to previously created AMI
### optional argument $2: "rebuild" to force a rebuild of the SHA (rpm + ami)

### adapted from deploy-socorro

set +u
set +x

format_logs() {
    # requires figlet installed
    echo -e "$(date)\n$(figlet -f stop "${ENVIRONMENT}")\n\"${STEP}\"\n\n"
}

error_check() {
    if [ "${RC}" -ne 0 ]; then
        echo "$(date) -- Error encountered during ${STEP}"
        echo "Fatal, exiting"
        echo "Instances which may need to be terminated manually: ${INITIAL_INSTANCES}"
        exit 1
    fi
}

SKIP_TO_DEPLOYMENT="false"
# provide an existing AMI SHA and we will skip most of this!
if [[ -n $1 ]]; then
    SPECIFIED_HASH=$1
    SKIP_TO_DEPLOYMENT="true"
fi

FORCE_REBUILD="false"
if [[ "$2" == "rebuild" ]]; then
    STEP="[rebuild] Rebuilding RPM/AMI enabled for this build."; format_logs
    FORCE_REBUILD="rebuild"
fi

SCRIPT_PATH=$(dirname "$(realpath "$0")")
SOCORRO_INFRA_PATH="/home/centos/socorro-infra"
ENVIRONMENT="stage"
ENDRC=0

STARTLOG=$(mktemp)
ENDLOG=$(mktemp)

# Roles / instance types to deploy for stage
ROLES=$(cat "${SCRIPT_PATH}/lib/${ENVIRONMENT}_socorro_master.list")

INITIAL_INSTANCES=

# imports
. "${SCRIPT_PATH}/lib/identify_role.sh"
. "${SCRIPT_PATH}/lib/infra_status.sh"

# for postgres and python
PATH="${PATH}:/usr/pgsql-9.3/bin:/usr/local/bin/"
echo "PATH: ${PATH}"

get_stage_git_info() {
    echo "git info for $(basename "$(git remote show -n origin | grep Fetch | cut -d: -f2-)")"
    # short sha of latest commit from master
    GIT_COMMIT_HASH=$(git rev-parse master)
    COMMITTER_INFO=$(git log -n 1 --format="%an committed %h %ad" "${GIT_COMMIT_HASH}")
    echo "Latest commit on master: ${COMMITTER_INFO}"
}

clone_repo() {
    STEP="[clone_repo] Creating TMP_DIR"; format_logs
    readonly TMP_DIR=$(mktemp -d) && cd "$TMP_DIR"
    RC=$?; error_check

    STEP="[clone_repo] Cloning repo"; format_logs
    echo "Cloning the socorro repo into ${TMP_DIR}/socorro"
    git clone https://github.com/mozilla/socorro.git
    RC=$?; error_check

    # reset to the specified commit
    # defaults to master
    git reset --hard "${SPECIFIED_HASH}"

    cd "$TMP_DIR/socorro"
    RC=$?; error_check

    STEP="[clone_repo] Acquiring git metadata"; format_logs
    # print socorro commit info
    get_stage_git_info
}

create_rpm() {
    # repeated so this code is a _little_ less stateful
    cd "$TMP_DIR/socorro"
    RC=$?; error_check

    STEP="[create_rpm] Creating RPM"; format_logs
    /usr/bin/env PYTHON=/usr/local/bin/python2.7 make package BUILD_TYPE=rpm
    RC=$?; error_check

    # Find the RPM
    RPM=$(ls "$TMP_DIR"/socorro/socorro*.rpm)

    # Sign the rpm file
    STEP="[create_rpm] Signing RPM"; format_logs
    echo "Refreshing RPM repo from S3"
    /home/centos/manage_repo.sh refresh
    rpm --addsign "${RPM}" < /home/centos/.rpmsign
    echo "Signed socorro package, now copying into local repo"
    # Copy to the local repo
    cp "${RPM}" ~/org.mozilla.crash-stats.packages-public/x86_64

    STEP="[create_rpm] Syncing local packages repo to S3"; format_logs
    echo "Uploading RPM package to S3"
    /home/centos/manage_repo.sh update
    RC=$?; error_check
}

function create_ami() {
    cd $SOCORRO_INFRA_PATH/packer/
    RC=$?; error_check

    # We need to grab the new AMI id, so we send it to a log file to grep out
    STEP="[create_ami] Creating TMP_PACKER_LOG"; format_logs
    TMP_PACKER_LOG=$(mktemp)
    RC=$?; error_check

    STEP="[create_ami] Executing packer build"; format_logs
    # Build the image using packer.
    /usr/bin/packer build -color=false "$SOCORRO_INFRA_PATH"/packer/socorro_base.json | tee "${TMP_PACKER_LOG}"
    RC=${PIPESTATUS[0]}; error_check
    # Assign the sparkly new AMI id to a variable
    AMI_ID=$(grep 'us-west-2: ami-.*' "${TMP_PACKER_LOG}" | cut -f 2 -d ' ')

    STEP="[create_ami] Tagging AMI"; format_logs
    AMI_NAME="${GIT_COMMIT_HASH}-$(date +%Y-%m-%d-%H%M)"
    # Tag that AMI with the github hash of this commit
    aws ec2 create-tags --resources "${AMI_ID}" \
                        --tags "Key=apphash,Value=${GIT_COMMIT_HASH}"
    RC=$?; error_check
    aws ec2 create-tags --resources "${AMI_ID}" \
                        --tags "Key=Name,Value=${AMI_NAME}"
    RC=$?; error_check
    echo "Tagged AMI with apphash:${GIT_COMMIT_HASH}, Name:${AMI_NAME}"
    rm "${TMP_PACKER_LOG}"
}

function find_ami() {
    # find_ami based on latest commit
    if [[ -z "$SPECIFIED_HASH" ]]; then
        SPECIFIED_HASH="$GIT_COMMIT_HASH"
    fi

    STEP="[find_ami] Finding AMI by apphash ${SPECIFIED_HASH}"; format_logs
    AMI_ID=$(aws ec2 describe-images \
             --filters Name=tag:apphash,Values="${SPECIFIED_HASH}" \
             --output text --query 'Images[0].ImageId')
    AMI_NAME=$(aws ec2 describe-images --image-ids "${AMI_ID}" \
             --output text --query 'Images[0].Tags[?Key==`Name`].Value')
    # None is returned if no AMI is found
    # this is a problem if we want to SKIP_TO_DEPLOYMENT
    # otherwise, we can short circuit having to recreate AMIs in case of rollback
    if [[ "$AMI_ID" == "None" ]] && [[ "$SKIP_TO_DEPLOYMENT" == "true" ]]; then
        RC=1; error_check
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

### Script execution
# print socorro-infra latest commit info
get_stage_git_info

# clone_repo checks latest commit on master
clone_repo

# find_ami checks whether an AMI for that
# commit already exists
find_ami

# create_rpm and create_ami are time intensive
# so they are skipped in favor of existing AMI
if [[ "$AMI_ID" == "None" ]] || [[ "$FORCE_REBUILD" == "rebuild" ]]; then
    create_rpm
    create_ami
fi

get_initial_instances
apply_ami
scale_in_all

# Give API time to update the instances counts it returns
sleep 60

# After updates go out, monitor for all instances in all elbs to be healthy.
monitor_overall_health
if [[ $NO_HEALTH_ALERT == "true" ]]; then
    # This means earlier, the health check process tried 10 times, and never got an all healthy response
    echo "Not going to scale out, since we aren't all healthy"
    ENDRC=1
else
    # For anything with an elb, dereg instances to allow for connection drain
    deregister_elb_nodes
    # Wait for drain, default we set is to 30s
    sleep 30
    # Kill the instances we listed in ${INITIAL_INSTANCES}
    terminate_instances_all
fi

# All done, get our report.
STEP="[main script] post-deploy check-in"
echo "$(date) -- Deployment complete"
echo "Nodes we think should have been killed:"
echo "${INITIAL_INSTANCES}"
query_end_scale # What did our groups end at?

# if we used an existing AMI, RPM is unset
if [[ -n $RPM ]]; then
    echo "Socorro RPM: ${RPM}"
fi

echo "AMI Name: ${AMI_NAME}"
echo "AMI ID: ${AMI_ID}"
echo "AMI app SHA: ${GIT_COMMIT_HASH}"

format_logs
echo "==========  BEGINNING STATE  =========="
cat "${STARTLOG}"

format_logs
echo "==========  ENDING STATE  ==========="
cat "${ENDLOG}"

rm "${STARTLOG}"
rm "${ENDLOG}"
if [[ "$TMP_DIR" =~ ^/tmp/.*$ ]]; then
    rm --preserve-root -rf "${TMP_DIR}"
fi
exit ${ENDRC}
