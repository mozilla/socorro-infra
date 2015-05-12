function create_rpm() {
    PROGSTEP="Building rpm";echo "`date` -- Building RPM for $ROLENAME"
    # Make / prep the data directory if it does not exist
    . ~/.bash_profile
    echo "Path is $PATH"
    if [ "$SKIPRPM" = "true" ];
        then
        echo "`date` -- Skipping RPM build"
    else
        rm -rf /data || echo "`date` -- Socorro dir doesn't need removal"
        mkdir -p /data || echo "`date` -- /data already exists"
        chown centos /data
        cd /data
        echo "`date` -- Cloning the socorro repo into /data/socorro"
        git clone https://github.com/mozilla/socorro.git
            RETURNCODE=$?;error_check
        cd socorro
        # Get the hash for later use to feed packer
        export SOCORROHASH=`git log | head -n1 | awk '{print $2}'`
        echo "`date` -- Clone of commit for ${SOCORROHASH} returned ${RETURNCODE}"
        # Build the actual rpm file
        /usr/bin/env PYTHON=python make package BUILD_TYPE=rpm
            RETURNCODE=$?;error_check
    fi
    # Find the rpm file we created
    NEWRPM=$(ls -lart /data/socorro/socorro*.rpm|awk '{print $9}')
    # Get the version of that socorro rpm so we log it nicely.
    NEWSOCORROVERSION=$(ls -lart /home/centos/org.mozilla.crash-stats.packages-public/x86_64/socorro-*.rpm| \
                        tail -n1|sed 's/\// /g'|sed 's/\./ /g'|awk '{print $8}')
    # Get a version-date tag to apply as a name to the AMI
    SOCORROAMINAME="${NEWSOCORROVERSION}-`date +%Y%m%d`"
    if [ "$SKIPRPM" = "true" ];then
        echo "Skipping rpm upload"
        else
        echo "`date` -- Completed build of $ROLENAME rpm with a return code of $RETURNCODE, now signing the rpm"
        # Sign the rpm file
        echo "`date` -- Signing the RPM"
        rpm --addsign ${NEWRPM} < /etc/jenkins/passphrase.txt
            RETURNCODE=$?;error_check
        echo "`date` -- Signed ${NEWRPM} with the "
        echo "`date` -- Refreshing RPM repo from S3"
        /home/centos/manage_repo.sh refresh
            RETURNCODE=$?;error_check
        echo "`date` -- Refreshed repo with ${RETURNCODE}"
        # Copy to the local repo
        echo "`date` -- Copying ${NEWRPM} to the repo"
        cp ${NEWRPM} ~/org.mozilla.crash-stats.packages-public/x86_64
        echo "`date` -- Uploading RPM package to S3"
        /home/centos/manage_repo.sh update
            RETURNCODE=$?;error_check
        echo "`date` S3 update of yum repo exited with a return code of ${RETURNCODE}"
    fi
}
