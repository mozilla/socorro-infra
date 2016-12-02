#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.

TFVARS="terraform.tfvars"
ROLES=(admin analysis buildbox collector consul elasticsearch postgres processor rabbitmq symbolapi webapp)
HELPARGS=("help" "-help" "--help" "-h" "-?")

function help {
    echo "USAGE: ${0} <action> <environment> <role>"
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

# Is terraform in PATH?  If not, it should be.
if which terraform > /dev/null;then
    PATH=$PATH:/home/centos/terraform
fi

# Is this a cry for help?
contains_element "$1" "${HELPARGS[@]}"
if [ "${1}x" == "x" ]; then
    help
fi

# All of the args are mandatory.
if [ $# != 3 ]; then
    help
fi

# Validate the desired role.
contains_element "$3" "${ROLES[@]}"
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
    BUCKET=$(echo "$BUCKET" | awk -F\" '{print $2}')
fi

# Pre-flight check is good, let's continue.
ACTION=$1
ENV=$2
ROLE=$3

# Be verbose and bail on errors.
set -ex
pushd "$ROLE"

# Nab the latest tfstate.
aws s3 sync --exclude="*" --include="terraform.tfstate" "s3://${BUCKET}/tfstate/${ENV}/${ROLE}/" ./

# Run TF; if this errors out we need to keep going.
set +e
terraform $ACTION -no-color -var "environment=${ENV}"
EXIT_CODE=$?
set -e

# Upload tfstate to S3.
aws s3 sync --exclude="*" --include="terraform.tfstate" ./ "s3://${BUCKET}/tfstate/${ENV}/${ROLE}/"
popd

exit $EXIT_CODE
