#!/usr/bin/env bash

set -e

TFORM_VERSION="0.7.13"
TFORM_PLATFORM="linux_amd64"

gem install puppet puppet-lint
puppet-lint --with-filename --no-140chars-check --no-autoloader_layout-check --fail-on-warnings puppet/
puppet parser validate `find puppet/ -name '*.pp'`

pushd terraform
wget "https://releases.hashicorp.com/terraform/${TFORM_VERSION}/terraform_${TFORM_VERSION}_${TFORM_PLATFORM}.zip"
unzip -u terraform_${TFORM_VERSION}_${TFORM_PLATFORM}.zip
popd

for role in $(find ./terraform/* -maxdepth 1 -type d); do
    ../terraform validate $role
done
