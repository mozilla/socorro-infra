#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.

TFVARS="terraform.tfvars"
ROLES=(admin buildbox collector consul elasticsearch postgres processor rabbitmq symbolapi webapp)
HELPARGS=("help" "-help" "--help" "-h" "-?")

function help {
    echo "USAGE: ${0} <environment> <role>"
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

# Is this a cry for help?
contains_element $1 "${HELPARGS[@]}"
if [ $? -eq 0 ]; then
    help
fi

# Need to specify both the environment and the role.
if [ $# != 2 ]; then
    help
fi

# Validate the desired role.
contains_element $2 "${ROLES[@]}"
if [ $? -ne 0 ]; then
    echo "ERROR: $2 is not a valid role."
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
ENV=$1
ROLE=$2

# Be verbose and bail on errors.
set -ex

# Grab tfstate from S3
aws s3 sync --exclude="*" --include="terraform.tfstate" s3://${BUCKET}/tfstate/${ENV}/ ./

# Run TF
pushd $ROLE
terraform apply -var "environment=${ENV}"
popd

# Upload tfstate to S3
aws s3 sync --exclude="*" --include="terraform.tfstate" ./ s3://${BUCKET}/tfstate/${ENV}/
