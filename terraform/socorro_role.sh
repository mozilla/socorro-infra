#!/bin/sh

DIR="/tmp/${RANDOM}-${RANDOM}"

function socorro_role {
    git clone $1 $DIR
    /usr/bin/env FACTER_socorro_role=$2 \
        puppet apply \
        --modulepath=${DIR}/puppet/modules \
        ${DIR}/puppet/manifests/default.pp
}

# Required variables will be inserted by Terraform.
socorro_role \
