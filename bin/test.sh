#!/usr/bin/env bash

set -e

TFORM_VERSION="0.7.13"
TFORM_PLATFORM="linux_amd64"

gem install puppet puppet-lint
puppet-lint --with-filename --no-140chars-check --no-autoloader_layout-check --fail-on-warnings puppet/
puppet parser validate `find puppet/ -name '*.pp'`

cd terraform
wget "https://releases.hashicorp.com/terraform/${TFORM_VERSION}/terraform_${TFORM_VERSION}_${TFORM_PLATFORM}.zip"
unzip -u terraform_${TFORM_VERSION}_${TFORM_PLATFORM}.zip

for environment in stage prod; do
    ./terraform plan \
        -var="environment=$environment" \
        -var="secret_key=FAKE" \
        -var="access_key=FAKE" \
        -var="subnets=FAKE" \
        -var="secret_bucket=FAKE" \
        -var="buildbox_cert=FAKE" \
        -var="rds_root_password=FAKE"
    done
done
