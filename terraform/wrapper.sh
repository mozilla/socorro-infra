#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.

TFVARS="terraform.tfvars"
ROLES=(admin analysis buildbox collector consul elasticsearch postgres processor rabbitmq symbolapi webapp)
SYMLINKS=(socorro_role.sh terraform.tfvars variables.tf)
HELPARGS=("help" "-help" "--help" "-h" "-?")

function help {
    echo "USAGE: ${0} <action> <environment> <role>"
    echo "       ${0} [symlinks]"
    echo -n "Valid roles are: "
    local i
    for i in "${ROLES[@]}"; do
        echo -n "$i "
    done
    echo ""
    exit 1
}

function contains_element () {
    local i
    for i in "${@:2}"; do
        [[ "$i" == "$1" ]] && return 0
    done
    return 1
}

function check_symlinks {
    for i in ${SYMLINKS[@]}; do
        if [ ! -L $i ]; then
            ln -s ../$i $i
        fi
    done
}

function make_symlinks {
    set -e
    for i in ${ROLES[@]}; do
        pushd $i > /dev/null
        check_symlinks
        popd > /dev/null
    done
    set +e
}

# Is this a cry for help?
contains_element $1 "${HELPARGS[@]}"
if [ "${1}x" == "x" ]; then
    help
fi

# Did we want to generate symlinks?
if [ "$1" == "symlinks" ]; then
    make_symlinks
    exit 0
fi

# All of the args are mandatory.
if [ $# != 3 ]; then
    help
fi

# Validate the desired role.
contains_element $3 "${ROLES[@]}"
if [ $? -ne 0 ]; then
    echo "ERROR: $3 is not a valid role."
    exit 1
fi

# Get the secret bucket name.
BUCKET=$(grep secret_bucket $TFVARS 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Could not read secret_bucket from $TFVARS"
    exit 1
else
    BUCKET=$(echo $BUCKET | awk -F\" '{print $2}')
fi

# Pre-flight check is good, let's continue.
ACTION=$1
ENV=$2
ROLE=$3

# Be verbose and bail on errors.
set -ex
pushd $ROLE

# Ensure the symlinks exist; hopefully TF will support includes some day.
check_symlinks

# Nab the latest tfstate.
aws s3 sync --exclude="*" --include="terraform.tfstate" s3://${BUCKET}/tfstate/${ENV}/${ROLE}/ ./

# Run TF; if this errors out we need to keep going.
set +e
terraform $ACTION -var "environment=${ENV}"
set -e

# Upload tfstate to S3.
aws s3 sync --exclude="*" --include="terraform.tfstate" ./ s3://${BUCKET}/tfstate/${ENV}/${ROLE}/
popd
