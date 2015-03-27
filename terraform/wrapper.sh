#!/usr/bin/env bash
# This script should be run as a wrapper to Terraform.
# It should be symlinked in consul/ as well.

TFVARS="terraform.tfvars"

# Bail on errors and be verbose.
set -ex

# Need to specify the environment.
if [ "${1}x" == "x" ]; then
    echo "USAGE: ${0} <environment>"
    exit 1
fi

# The secret_bucket is specified here.
if [ ! -r $TFVARS ]; then
    echo "ERROR: Could not read ${TFVARS}"
    exit 1
fi

BUCKET=$(grep secret_bucket terraform.tfvars | awk -F\" '{print $2}')
ENV=$1

# Grab tfstate from S3
aws s3 sync --exclude="*" --include="terraform.tfstate" s3://${BUCKET}/tfstate/${ENV}/ ./

# Run TF
terraform apply -var "environment=${ENV}"

# Upload tfstate to S3
aws s3 sync --exclude="*" --include="terraform.tfstate" ./ s3://${BUCKET}/tfstate/${ENV}/

