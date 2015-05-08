#!/bin/sh

if [ $# != 3 ]; then
    echo "Syntax: $0 <role> <secret_bucket> <env>"
    exit 1
fi

ROLE=$1
SECRET_BUCKET=$2
ENV=$3

function socorro_role {
    DIR="/etc/puppet"

    # Provide the secret bucket name to Hiera (hiera-s3).
    sed -i "s:@@@SECRET_BUCKET@@@:${SECRET_BUCKET}:" /etc/puppet/hiera.yaml

    # Provision the role.
    /usr/bin/env FACTER_socorro_role=$ROLE FACTER_environment=$ENV \
        puppet apply \
        --modulepath=${DIR}/module-0:/etc/puppet/modules \
        ${DIR}/manifests/default.pp
}

# Required variables will be inserted by Terraform.
socorro_role \
