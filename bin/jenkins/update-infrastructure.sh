#!/bin/bash
# Script: update-infrastructure.sh
# Purpose: Do a number of things Terraform does not do: SSL ciphers, ELB alarms, Autoscaling triggers/policies

# Set these variables to desired thresholds
SCALEUPADJUSTMENT=6  # How many nodes to scale in upon receiving a trigger?
SCALEDOWNADJUSTMENT=-3  # How many nodes to scale away upon receiving a trigger?  (Note, make this a -#)
SCALEUPCOOLDOWN=300  # Seconds to wait before allowing further scale up adjustments
SCALEUPCOOLDOWN=300  # Seconds to wait before allowing further scale down adjustments
SCALEUPTHRESHOLD=70  # Avg CPU utilization of cluster before scale up
SCALEDOWNTHRESHOLD=20  # Avg CPU utilization of cluster before scale down


# Source functions in lib scripts
. /home/centos/socorro-infra/bin/lib/identify_role.sh
. /home/centos/.aws-config

############################
# PROGRAM FUNCTIONS
function format_logs() {
    echo " ";echo " ";echo " ";echo "=================================================";echo " ";echo " ";echo " "
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

function create_scaling_notifications() {
    # This notification should be on every autoscaling group.  It will send an email every time
    # we autoscale, or have problems autoscaling.
    aws autoscaling put-notification-configuration \
        --auto-scaling-group-name ${AUTOSCALENAME} \
        --topic-arn arn:aws:sns:us-west-2:293989542403:AWS-scaling-notifications \
        --notification-type "autoscaling:EC2_INSTANCE_LAUNCH" "autoscaling:EC2_INSTANCE_LAUNCH_ERROR" \
        "autoscaling:EC2_INSTANCE_TERMINATE" "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  }

function create_scaling_trigger_and_policy() {
    # First, create the scaleup and scale down triggers, called UP and DOWN
    # NOTE:  You can adjust the scaling settings, such as # to scale in, here
    UP=$(aws autoscaling put-scaling-policy --policy-name ${AUTOSCALENAME}-scale-up \
        --auto-scaling-group-name ${AUTOSCALENAME} \
        --scaling-adjustment ${SCALEUPADJUSTMENT} \
        --adjustment-type ChangeInCapacity \
        --cooldown ${SCALEUPCOOLDOWN}| \
        grep Policy | sed 's/"/ /g'|awk '{print $3}')
    DOWN=$(aws autoscaling put-scaling-policy --policy-name ${AUTOSCALENAME}-scale-down \
        --auto-scaling-group-name ${AUTOSCALENAME} \
        --scaling-adjustment ${SCALEDOWNADJUSTMENT} \
        --adjustment-type ChangeInCapacity -\
        -cooldown ${SCALEDOWNCOOLDOWN}|grep Policy | sed 's/"/ /g'|awk '{print $3}')
    # Create a Cloudwatch alarm for high CPU average aggregate in the autoscale group, which triggers a scale up
    echo "`date` -- Creating a high CPU alarm to hook autoscaling to for ${AUTOSCALENAME}"
    aws cloudwatch put-metric-alarm \
        --alarm-name ${AUTOSCALENAME}-CPUHigh \
        --metric-name CPUUtilization \
        --namespace "AWS/EC2" \
        --period 300 \
        --evaluation-periods 1 \
        --threshold ${SCALEUPTHRESHOLD} \
        --statistic Average \
        --comparison-operator GreaterThanThreshold \
        --alarm-actions $UP \
        --dimensions Name=AutoScalingGroupName,Value=${AUTOSCALENAME}

    # Create a Cloudwatch alarm for low CPU average aggregate in the autoscale group, which triggers a scale down
    echo "`date` -- Creating a low CPU alarm to hook autoscaling to for ${AUTOSCALENAME}"
    aws cloudwatch put-metric-alarm \
        --alarm-name ${AUTOSCALENAME}-CPULow \
        --metric-name CPUUtilization \
        --namespace "AWS/EC2" \
        --period 300 \
        --evaluation-periods 1 \
        --threshold ${SCALEDOWNTHRESHOLD} \
        --statistic Average \
        --comparison-operator LessThanThreshold \
        --alarm-actions $DOWN \
        --dimensions Name=AutoScalingGroupName,Value=${AUTOSCALENAME}

    # Create a Cloudwatch policy to collect metrics for the autoscale group, or no autoscaling
    aws autoscaling enable-metrics-collection \
        --auto-scaling-group-name ${AUTOSCALENAME} \
        --granularity 1Minute \
        --metrics GroupInServiceInstances GroupTotalInstances
}

function customize_ciphers() {
    # You want an A rating on SSL Labs?  Why not A+?
    echo "`date` -- Applying cipher settings to ${ELBNAME}"
    python /home/centos/socorro-infra/bin/lib/cipher.py us-west-2 ${ELBNAME}
}

function create_unhealthy_elb_alarm() {
    # We want to know if nodes are dying off, or not ever getting healthy.  Create an alarm for it.
    aws cloudwatch put-metric-alarm \
        --alarm-name ${ELBNAME}-UnhealthyHostCount \
        --metric-name UnHealthyHostCount \
        --namespace "AWS/ELB" \
        --period 300 \
        --evaluation-periods 2 \
        --threshold 0 \
        --statistic Maximum \
        --comparison-operator GreaterThanThreshold \
        --alarm-actions arn:aws:sns:us-west-2:293989542403:AWS-alerts-mocotools \
        --dimensions Name=LoadBalancerName,Value=${ELBNAME}
}

############################
# PROGRAM RUN
echo "`date` -- Beginning updates of infrastructure"

# For every rolename-env we have launched, we'll first identify what updates we give it with the
# identify_role script, then apply those updates
for ROLEENVNAME in $(cat /home/centos/socorro-infra/bin/lib/infra_to_update.list)
    do
        identify_role
          RETURNCODE=$?;error_check
        echo "`date` -- Setting scaling notifications for ${AUTOSCALENAME}"
        create_scaling_notifications || echo "`date` -- Scaling notifications already set for ${AUTOSCALENAME}"
        # Decide if we apply good cipher policies to a SSL-enabled ELB
        if [ "${SSLELB}" = "true" ]; then
            echo "`date` -- Customizing ELB SSL ciphers for ${ELBNAME}"
            customize_ciphers
              RETURNCODE=$?
            echo "`date` -- Cipher customization returned code ${RETURNCODE}"
        fi
        # Decide if we create autoscaling for this group
        if [ "${APPLYSCALINGPOLICY}" = "true" ]; then
            echo "`date` -- Creating Cloudwatch alarms for scaling triggers and scaling policies for ${AUTOSCALENAME}"
            create_scaling_trigger_and_policy
        fi
        # Decide if we care about unhealthy nodes in the ELB enough to email us
        if [ "${NOTIFYFORUNHEALTHYELB}" = "true" ]; then
            echo "`date` -- Attempting to create a notification policy for unhealthy nodes in ${ELBNAME}"
            create_unhealthy_elb_alarm
        fi
    done
    echo "`date` -- Completed updates for ${ROLEENVNAME}, this app is ready for action"
    format_logs
echo "`date` -- Completed updates of all infrastructure, our kit is tight!"
