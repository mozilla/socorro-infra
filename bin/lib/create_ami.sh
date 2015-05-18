function create_ami() {
    if [ "${SKIPAMI}" = "true" ];then
        echo "`date` -- Skipping AMI"
    else
        PROGSTEP="Creating new AMI"
        echo "`date` -- Creating new AMI for deployment"
        cd /home/centos/socorro-infra/packer
        # We need to grab the new AMI id, so we send it to a log file to grep out
        TMPLOG=/home/centos/packer-socorro.${RANDOM_STRING}.out
        # Build the image using packer.
        /usr/bin/packer build /home/centos/socorro-infra/packer/socorro_base.json | tee ${TMPLOG}
            RETURNCODE=$?;error_check
        # Assign the sparkly new AMI id to a variable
        NEWAMI=`cat ${TMPLOG} |grep us-west-2|grep ami |awk '{print $2}'`
        echo "`date` -- New AMI ${NEWAMI} created with a return code of ${RETURNCODE}.    Tagging with ${SOCORROHASH}"
        # Tag that AMI with the github hash of this commit
        aws ec2 create-tags --resources ${NEWAMI} \
                            --tags Key=apphash,Value=${GITCOMMITHASH}
        aws ec2 create-tags --resources ${NEWAMI} \
                            --tags Key=Name,Value=${SOCORROAMINAME}
        echo "`date` -- New tag applied: apphash = ${SOCORROHASH}"
        rm ${TMPLOG} # Cleanup after yourself, you slob.
    fi
}