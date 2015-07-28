#!/bin/sh

function socorro_role {
    if [ $# != 3 ]; then
        echo "Syntax: $0 <role> <secret_bucket> <env>"
        exit 1
    fi

    ROLE=$1
    SECRET_BUCKET=$2
    ENV=$3
    DIR="/etc/puppet"

    # Provide the secret bucket name to Hiera (hiera-s3).
    sed -i "s:@@@SECRET_BUCKET@@@:${SECRET_BUCKET}:" /etc/puppet/hiera.yaml

    # Provision the role.
    /usr/bin/env FACTER_socorro_role=$ROLE FACTER_environment=$ENV \
    puppet apply \
    --modulepath=${DIR}/module-0:/etc/puppet/modules \
    ${DIR}/manifests/default.pp

    # Set hostname of $env-$role-instanceid
    # We'll get the instance id from ec2metadta
    INSTANCEID=$(/bin/ec2-metadata | grep instance-id | \
                 awk '{print $2}')
    NEWHOSTNAME=${ENV}-${ROLE}-${INSTANCEID}
    /bin/echo ${NEWHOSTNAME} > /etc/hostname
    /bin/hostname -F /etc/hostname
}

# Required variables will be inserted by Terraform.
socorro_role \
