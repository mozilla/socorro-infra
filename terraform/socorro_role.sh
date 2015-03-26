#!/bin/sh

DIR="/tmp/${RANDOM}-${RANDOM}"

function socorro_role {
    # Set up the working dir.
    mkdir $DIR
    pushd $DIR

    # Provide the secret bucket name to Hiera (hiera-s3).
    sed -i "s:@@@SECRET_BUCKET@@@:${3}:" /etc/puppet/hiera.yaml

    # Acquire the Puppet archive.
    curl -O $1
    # Yoink the filename from the end of the URL
    ARCHIVE=`echo $1|awk -F'/' '{print $NF}'`
    tar -xvzf $ARCHIVE
    # Provision the role.
    /usr/bin/env FACTER_socorro_role=$2 \
        puppet apply \
        --modulepath=${DIR}/puppet/modules:/etc/puppet/modules \
        ${DIR}/puppet/manifests/default.pp
    popd
}

# Required variables will be inserted by Terraform.
socorro_role \
