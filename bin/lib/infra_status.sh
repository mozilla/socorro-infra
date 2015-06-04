#!/bin/bash
function infra_report() {
    # Given an autoscale group name, we'll report on its current status
    AUTOSCALENAME=$1  # Passed to this function
    echo " ";echo " ";echo "================================================="
    echo "      ------ ${AUTOSCALENAME} STATUS   -----"
    LAUNCHCONFIGNAME=$(aws autoscaling describe-auto-scaling-groups \
                       --auto-scaling-group-names ${AUTOSCALENAME} \
                       --query 'AutoScalingGroups[*].LaunchConfigurationName' \
                       --output text)
    echo "=== LAUNCH CONFIG STATUS ==="
    echo "LaunchConfigName                        AMI             InstanceType      CreatedDate"
    # Show me a summary of what the launch config is set for
    aws autoscaling describe-launch-configurations \
        --launch-configuration-name ${LAUNCHCONFIGNAME} \
        --query 'LaunchConfigurations[*].[LaunchConfigurationName, ImageId, InstanceType, CreatedTime]' \
        --output text
    echo "=== EC2 STATUS ==="
    echo "InstanceId    AvailabilityZone  Health  State           LaunchConfig"
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names ${AUTOSCALENAME} \
        --query 'AutoScalingGroups[*].Instances[*].[InstanceId, AvailabilityZone, HealthStatus, LifecycleState,LaunchConfigurationName]' \
        --output text
    echo "=== CURRENT SCALE ==="
    echo "min / desired / max size"
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names ${AUTOSCALENAME} \
        --query 'AutoScalingGroups[*].[MinSize, DesiredCapacity, MaxSize]' \
        --output text

    ELBNAME=$(aws autoscaling describe-auto-scaling-groups \
              --auto-scaling-group-names ${AUTOSCALENAME} \
              --query 'AutoScalingGroups[*].LoadBalancerNames' \
              --output text)
    echo "=== ELB ENDPOINT ==="
    aws elb describe-load-balancers \
        --load-balancer-name ${ELBNAME} \
        --query 'LoadBalancerDescriptions[*].DNSName' \
        --output text
    echo "=== ELB HEALTH ==="
    echo "InstanceID      InstanceHealth"
    aws elb describe-instance-health \
        --load-balancer-name ${ELBNAME} \
        --query 'InstanceStates[*].[InstanceId, State]' \
        --output text
}