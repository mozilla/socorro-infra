#!/usr/bin/env bash

set -e

TFORM_VERSION="0.5.0_linux_amd64"

gem install puppet puppet-lint
puppet-lint --with-filename --no-80chars-check --no-autoloader_layout-check --fail-on-warnings puppet/
puppet parser validate `find puppet/ -name '*.pp'`

pushd terraform
wget "https://dl.bintray.com/mitchellh/terraform/terraform_${TFORM_VERSION}.zip"
unzip -u terraform_${TFORM_VERSION}.zip
./wrapper.sh symlinks
popd

for role in $(find ./terraform/* -maxdepth 1 -type d); do
    pushd $role
    ../terraform plan -var="environment=FAKE" \
                   -var="secret_key=FAKE" \
                   -var="access_key=FAKE" \
                   -var="subnets=FAKE" \
                   -var="secret_bucket=FAKE" \
                   -var="collector_cert=FAKE" \
                   -var="analysis_cert=FAKE" \
                   -var="buildbox_cert=FAKE" \
                   -var="webapp_cert=FAKE" \
                   -var="rds_root_password=FAKE" \
                   -var="base_ami=FAKE"
    popd
done
