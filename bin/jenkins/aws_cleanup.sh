#!/bin/bash
# Script: aws_cleanup.sh
# Purpose: Cleanup unused volumes, launch configs, etc

############################
# COMMON FUNCTIONS AND SETTINGS
# Show usage instructions for noobs
function show_usage() {
    echo " =================== ";echo " ";
    echo " Syntax "
    echo "USAGE: $0"
    echo " "
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
    aws ec2 describe-volumes --filters Name=status,Values="available"
}

############################
# PROGRAM FUNCTIONS
function cleanup_unused_volumes() {
    PROGSTEP="Cleaning up unused volumes"
    echo "`date` -- Getting list of unused volumes"
    UNUSEDVOLUMES=`aws ec2 describe-volumes --filters Name=status,Values="available"|grep VolumeId|sed 's/"/ /g'|awk '{print $3}'`
    echo "`date` -- The following list of unused volumes is set to be deleted"
    echo "${UNUSEDVOLUMES}"
    echo ${UNUSEDVOLUMES}|xargs -n1 aws ec2 delete-volume --volume-id
        RETURNCODE=$?
    echo "`date` -- Unused volumes have been deleted with a return code of ${RETURNCODE} for the last one"
}

function cleanup_unused_launch_configurations() {
    PROGSTEP="Cleaning up unused launch configurations"
    echo "`date` -- Gathering list of currently used launch configs"
    USEDLAUNCHCONFIGS=`aws autoscaling describe-auto-scaling-groups |grep LaunchConfigurationName|sed 's/"/ /g'|awk '{print $3}'`
    for LAUNCHCONFIGNAME in $(aws autoscaling describe-launch-configurations|grep LaunchConfigurationName|sed 's/"/ /g'|awk '{print $3}')
        do
        if grep ${LAUNCHCONFIGNAME} ${USEDLAUNCHCONFIGS}
            then
            echo "`date` -- Keeping ${LAUNCHCONFIGNAME}"
        else
            aws autoscaling delete-launch-configuration --launch-configuration-name ${LAUNCHCONFIGNAME}
                RETURNCODE=$?
            echo "`date` -- Deleted ${LAUNCHCONFIGNAME} with return code ${RETURNCODE}"
        fi
    done
}

############################
# PROGRAM RUN
cleanup_unused_volumes
cleanup_unused_launch_configurations
