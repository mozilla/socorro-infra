#!/bin/bash

# Program: backup_consul.sh
# Purpose: Backup our consul servers to s3

# VARIABLES
export RUNDATE=$(date +%Y%m%d%H%M)
export SECRETBUCKET="<%= @secretbucket %>"
export AWS_DEFAULT_REGION="us-west-2"
export ENVIRONMENT="<%= @consul_environment %>"
export CONSULHOST=$(hostname)
export BACKUPFILE="s3://${SECRETBUCKET}/backups/${ENVIRONMENT}/consul/consul-backup-${RUNDATE}-${CONSULHOST}.json"

# COMMON FUNCTIONS
function error_check() {
    if [ ${RETURNCODE} -ne 0 ];then
        echo "`date` -- Error encountered during ${PROGSTEP} : ${RETURNCODE}"
        if [ "${NOTFATAL}" = "true" ];then
            echo "Not fatal, continuing"
            NOTFATAL="false"
        else
            echo "Fatal, exiting"
            echo "===================="
            exit 1
        fi
    fi
}

# PROGRAM RUN
PROGSTEP="Backup consul"
echo "`date` -- Beginning consul backup for ${ENV}"
/usr/bin/consulate kv backup | aws s3 cp - ${BACKUPFILE}
    RETURNCODE=$?;error_check
echo "`date` -- Consul backup ran with return code of ${RETURNCODE}"
exit 0