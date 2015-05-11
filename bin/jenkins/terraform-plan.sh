#!/bin/bash

# Get AWS creds injected
. /home/centos/.aws-config

function log_format() {
  echo " ";echo "========================================="
  echo "=========================================";echo " ";echo " "
}

echo "`date` -- Beginning terraform plan run";log_format
for ROLENAME in $(ls -l /home/centos/socorro-infra/terraform | grep ^d | awk '{print $9}'); do
    cd /home/centos/socorro-infra/terraform
    echo "`date` -- Terraform Plan for ${ROLENAME} stage"
    /home/centos/socorro-infra/terraform/wrapper.sh plan stage ${ROLENAME}
    log_format
done


