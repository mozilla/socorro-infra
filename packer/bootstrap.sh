#!/usr/bin/env bash

function techo {
    STAMP=`date '+%b %d %H:%M:%S'`
    echo "${STAMP} BOOTSTRAP: ${@}"
}

techo "start"
techo "install puppet yum repo"
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
techo "yum check-update"
yum check-update
techo "yum upgrade"
yum -y upgrade
techo "yum install puppet"
yum -y install puppet
techo "end"
