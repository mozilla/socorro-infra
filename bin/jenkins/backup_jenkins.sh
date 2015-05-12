#!/bin/bash
# Script: backup_buildbox.sh
# Purpose: Get image of buildbox, apply it to the AS group

############################
# COMMON FUNCTIONS AND SETTINGS
# Show usage instructions for noobs
function show_usage() {
        echo " =================== ";echo " ";
        echo " Syntax "
        echo " ./deploy-socorro.sh $env (stage or prod)"
        echo " "
        echo " Example: ./deploy-socorro.sh stage"
        exit 0
}

function error_check() {
    if [ ${RETURNCODE} -ne 0 ];then
        echo "`date` -- Error encountered during ${PROGSTEP} : ${RETURNCODE}"
        if [ "${NOTFATAL}" = "true" ];then
            echo "Not fatal, continuing"
            NOTFATAL="false"
        else
            echo "Fatal, exiting"
            echo "===================="
            echo "Instances which may need to be terminated manually: ${INITIALINSTANCES}"
            exit 1
        fi
    fi
}

function format_logs() {
    echo " ";echo " ";echo " ";echo "=================================================";echo " ";echo " ";echo " "
}

####################################
## PROGRAM FUNCTIONS
function create_ami()  {
    PROGSTEP="Creating AMI"
    AMINAME="`date +%Y%m%d%H%M`-stage-socorrobuildbox"
    INSTANCEID=`aws elb describe-instance-health --load-balancer-name elb-stage-socorrobuildbox | grep InstanceId | sed 's/"/ /g' | awk '{print $3}'`
    echo "`date` -- Taking AMI snapshot of instance id ${INSTANCEID} named ${AMINAME}"
    AMIID=`aws ec2 create-image --instance-id ${INSTANCEID} --no-reboot --name "${AMINAME}" --description "${AMINAME} - Buildbox Socorro"|grep ImageId | sed 's/"/ /g' | awk '{print $3}' | head -n1`
        RETURNCODE=$?;error_check
    echo "`date` -- AMI snapshot ${AMIID} started with a return code of ${RETURNCODE}"
}

function wait_for_ami() {
    PROGSTEP="Waiting for AMI"
    echo "`date` -- Waiting 300 seconds for ${AMIID} to become available"
    sleep 300
    until aws ec2 describe-images --image-id | grep State| grep available > /dev/null;
        do
        echo "`date` -- Waiting for ${AMIID} to become available"
        sleep 30
    done
}

function tag_ami() {
    PROGSTEP="Tagging AMI"
    echo "`date` -- Applying tags to buildbox AMI ${AMIID}"
    aws ec2 create-tags --resources ${NEWAMI} --tags Key=role,Value=Buildbox
    aws ec2 create-tags --resources ${NEWAMI} --tags Key=project,Value=socorro
    aws ec2 create-tags --resources ${NEWAMI} --tags Key=Environment,Value=stage
}

function update_buildbox_as_group() {
    PROGSTEP="Updating buildbox autoscale group"
    echo "`date` -- Setting ${AMIID} to be the default base AMI for the as-stage-socorrobuildbox group"
    cd /home/centos/socorro-infra/terraform
    echo "`date` -- Attempting to terraform plan and apply ${AUTOSCALENAME} with new AMI id ${AMIID} and tagging with ${SOCORROHASH}"
    /home/centos/socorro-infra/terraform/wrapper.sh "plan -var base_ami.us-west-2=${AMIID}" stage buildbox
    echo " ";echo " ";echo "==================================";echo " "
    /home/centos/socorro-infra/terraform/wrapper.sh "apply -var base_ami.us-west-2=${AMIID}" stage buildbox
        RETURNCODE=$?;error_check
    echo "`date` -- Got return code ${RETURNCODE} applying terraform update"
}


####################################
## PROGRAM RUN
time create_ami;format_logs
time wait_for_ami;format_logs
time tag_ami;format_logs
time update_buildbox_as_group;format_logs

