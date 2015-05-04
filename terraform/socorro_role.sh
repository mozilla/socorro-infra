#!/bin/sh

function socorro_role {
    DIR="/etc/puppet"

    # Provide the secret bucket name to Hiera (hiera-s3).
    sed -i "s:@@@SECRET_BUCKET@@@:${3}:" /etc/puppet/hiera.yaml

    # Provision the role.
    /usr/bin/env FACTER_socorro_role=$1 FACTER_environment=$3 \
        puppet apply \
        --modulepath=${DIR}/module-0:/etc/puppet/modules \
        ${DIR}/manifests/default.pp
}

# Required variables will be inserted by Terraform.
socorro_role \
