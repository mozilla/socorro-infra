#!/bin/sh

DIR="/tmp/${RANDOM}-${RANDOM}"

function socorro_role {
    mkdir $DIR
    pushd $DIR
    curl -O $1
    # Yoink the filename from the end of the URL
    ARCHIVE=`echo $1|awk -F'/' '{print $NF}'`
    tar -xvzf $ARCHIVE
    /usr/bin/env FACTER_socorro_role=$2 \
        puppet apply \
        --modulepath=${DIR}/puppet/modules \
        ${DIR}/puppet/manifests/default.pp
    popd
}

# Required variables will be inserted by Terraform.
socorro_role \
