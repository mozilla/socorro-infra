#!/usr/bin/env bash

### this executes socorro stage build and can run without arguments
### by default builds most recent commit to master
### optional argument $1: socorro SHA to deploy
### optional argument $2: "rebuild" to force a rebuild of the SHA (rpm + ami)
### optional argument $2: "redeploy" to force a redeploy

### adapted from deploy-socorro

set +u
set +x

LIVE_ENV_URL="https://crash-stats.allizom.org/status/revision/"

SHOULD_DEPLOY="true"
SKIP_TO_DEPLOYMENT="false"
# provide an existing AMI SHA and we will skip most of this!
if [[ -n $1 ]] && [[ $1 =~ [0-9a-f]{40} ]]; then
    # valid SHA
    SPECIFIED_HASH=$1
    SKIP_TO_DEPLOYMENT="true"
elif [[ -n $1 ]] && [[ $1 == "rebuild" ]]; then
    # rebuild
    set -- "" "rebuild"
elif [[ -n $1 ]] && [[ $1 == "redeploy" ]]; then
    # redeploy
    set -- "" "redeploy"
elif [[ -n $1 ]]; then
    # invalid SHA, rebuild not specified
    # SHAs need to be [0-9a-f]{40}
    STEP="[skip_to_deployment] $1 is not a properly formatted commit SHA"; format_logs
    RC=1; error_check
fi

FORCE_REBUILD="false"
FORCE_REDEPLOY="false"
if [[ -n $2 ]] && [[ "$2" == "rebuild" ]]; then
    STEP="[rebuild] Rebuilding RPM/AMI enabled for this build."; format_logs
    FORCE_REBUILD="rebuild"
elif [[ -n $2 ]] && [[ "$2" == "rebuild" ]]; then
    STEP="[redeploy] Redeploy enabled for this build."; format_logs
    FORCE_REDEPLOY="redeploy"
fi

SCRIPT_PATH=$(dirname "$(realpath "$0")")
ENVIRONMENT="stage"
ENDRC=0

STARTLOG=$(mktemp)
ENDLOG=$(mktemp)

# Roles / instance types to deploy for stage
ROLES=$(cat "${SCRIPT_PATH}/lib/${ENVIRONMENT}_socorro_master.list")

INITIAL_INSTANCES=

# imports
. "${SCRIPT_PATH}/common_vars.sh"
. "${SCRIPT_PATH}/lib/identify_role.sh"
. "${SCRIPT_PATH}/lib/infra_status.sh"
. "${SCRIPT_PATH}/deploy_functions.sh"

# for postgres and python and packer
# note: /usr/local/bin first for python
# /usr/sbin/ for packer
PATH="/usr/local/bin/:/usr/bin/:${PATH}:/usr/pgsql-9.3/bin"
echo "PATH: ${PATH}"

get_stage_git_info() {
    echo "git info for $(basename "$(git remote show -n origin | grep Fetch | cut -d: -f2-)")"
    # latest commit from master
    GIT_COMMIT_HASH=$(git rev-parse master)
    COMMITTER_INFO=$(git log -n 1 --format="%an committed %h %ad" "${GIT_COMMIT_HASH}")
    echo "Latest commit on master: ${COMMITTER_INFO}"
}

clone_repo_stage() {
    STEP="[clone_repo_stage] Moving to ${DATA_DIRECTORY}"; format_logs
    cd "$DATA_DIRECTORY"
    RC=$?; error_check

    STEP="[clone_repo_stage] Removing old repo"; format_logs
    rm --preserve-root -rf "${DATA_DIRECTORY}/socorro"
    RC=$?; error_check

    STEP="[clone_repo_stage] Cloning repo"; format_logs
    echo "Cloning the socorro repo into ${DATA_DIRECTORY}/socorro"
    git clone https://github.com/mozilla/socorro.git
    RC=$?; error_check

    cd "$DATA_DIRECTORY/socorro"
    RC=$?; error_check

    # reset to the specified commit
    # defaults to master
    if [[ -z "$SPECIFIED_HASH" ]]; then
        SPECIFIED_HASH=$(git rev-parse master)
    fi

    STEP="[clone_repo_stage] Checking out ${SPECIFIED_HASH}"; format_logs
    git reset --hard "${SPECIFIED_HASH}"
    RC=$?; error_check

    STEP="[clone_repo_stage] Acquiring git metadata"; format_logs
    # print socorro commit info
    get_stage_git_info
}

create_rpm() {
    # repeated so this code is a _little_ less stateful
    cd "$DATA_DIRECTORY/socorro"
    RC=$?; error_check

    STEP="[create_rpm] Creating RPM"; format_logs
    /usr/bin/env PYTHON=/usr/local/bin/python2.7 make package BUILD_TYPE=rpm
    RC=$?; error_check

    # Find the RPM
    RPM=$(ls "$DATA_DIRECTORY"/socorro/socorro*.rpm)

    STEP="[create_rpm] Refreshing RPM repo from S3"; format_logs
    /home/centos/manage_repo.sh refresh
    RC=$?; error_check

    # Sign the rpm file
    STEP="[create_rpm] Signing RPM"; format_logs
    rpm --addsign "${RPM}" < /home/centos/.rpmsign
    RC=$?; error_check

    STEP="[create_rpm] Copying RPM into local repo"; format_logs
    # Copy to the local repo
    cp "${RPM}" ~/org.mozilla.crash-stats.packages-public/x86_64
    RC=$?; error_check

    STEP="[create_rpm] Syncing local packages repo to S3"; format_logs
    /home/centos/manage_repo.sh update
    RC=$?; error_check
}

function create_ami() {
    cd $SOCORRO_INFRA_PATH/packer/
    RC=$?; error_check

    # We need to grab the new AMI id, so we send it to a log file to grep out
    STEP="[create_ami] Creating TMP_PACKER_LOG"; format_logs
    TMP_PACKER_LOG=$(mktemp)
    RC=$?; error_check

    STEP="[create_ami] Executing packer build"; format_logs
    # Build the image using packer.
    packer build -color=false "$SOCORRO_INFRA_PATH"/packer/socorro_base.json | tee "${TMP_PACKER_LOG}"
    RC=${PIPESTATUS[0]}; error_check
    # Assign the sparkly new AMI id to a variable
    AMI_ID=$(grep 'us-west-2: ami-.*' "${TMP_PACKER_LOG}" | cut -f 2 -d ' ')

    STEP="[create_ami] Tagging AMI"; format_logs
    AMI_NAME="${GIT_COMMIT_HASH}-$(date +%Y-%m-%d-%H%M)"
    # Tag that AMI with the github hash of this commit
    aws ec2 create-tags --resources "${AMI_ID}" \
                        --tags "Key=apphash,Value=${GIT_COMMIT_HASH}"
    RC=$?; error_check
    aws ec2 create-tags --resources "${AMI_ID}" \
                        --tags "Key=Name,Value=${AMI_NAME}"
    RC=$?; error_check
    echo "Tagged AMI with apphash:${GIT_COMMIT_HASH}, Name:${AMI_NAME}"
    rm "${TMP_PACKER_LOG}"
}

### Script execution
check_for_dependencies

# print socorro-infra latest commit info
get_stage_git_info

# clone_repo_stage checks latest commit on master
clone_repo_stage

compare_live_to_deploy_sha
if [[ "$UP_TO_DATE" == "true" ]]; then
    SHOULD_DEPLOY="false"
fi

if [[ "$FORCE_REDEPLOY" == "redeploy" ]] || \
   [[ "$FORCE_REBUILD" == "rebuild" ]]; then
    SHOULD_DEPLOY="true"
fi

if [[ "$SHOULD_DEPLOY" == "false" ]]; then
    STEP="[main_script] SHOULD_DEPLOY => ${SHOULD_DEPLOY}"; format_logs
    echo "Live revision at ${LIVE_ENV_URL} is same as latest master."
    echo "Live: ${LIVE_GIT_COMMIT_HASH} == ${GIT_COMMIT_HASH}"
    exit 0
fi


# find_ami checks whether an AMI for that
# commit already exists
find_ami

# create_rpm and create_ami are time intensive
# so they are skipped in favor of existing AMI
if [[ -z "$AMI_ID" ]] || [[ "$FORCE_REBUILD" == "rebuild" ]]; then
    create_rpm
    create_ami
fi

get_initial_instances
apply_ami
scale_in_all

# Give API time to update the instances counts it returns
sleep 60

# After updates go out, monitor for all instances in all elbs to be healthy.
monitor_overall_health
if [[ $NO_HEALTH_ALERT == "true" ]]; then
    # This means earlier, the health check process tried 10 times, and never got an all healthy response
    echo "Not going to scale out, since we aren't all healthy"
    ENDRC=1
else
    # For anything with an elb, dereg instances to allow for connection drain
    deregister_elb_nodes
    # Wait for drain, default we set is to 30s
    sleep 30
    # Kill the instances we listed in ${INITIAL_INSTANCES}
    terminate_instances_all
fi

# All done, get our report.
STEP="[main script] post-deploy check-in"; format_logs
echo "$(date) -- Deployment complete"
echo "Nodes we think should have been killed:"
echo "${INITIAL_INSTANCES}"
query_end_scale # What did our groups end at?

# if we used an existing AMI, RPM is unset
if [[ -n $RPM ]]; then
    echo "Socorro RPM: ${RPM}"
fi

echo "AMI Name: ${AMI_NAME}"
echo "AMI ID: ${AMI_ID}"
echo "AMI app SHA: ${GIT_COMMIT_HASH}"

format_logs
echo "==========  BEGINNING STATE  =========="
cat "${STARTLOG}"

format_logs
echo "==========  ENDING STATE  ==========="
cat "${ENDLOG}"

rm "${STARTLOG}"
rm "${ENDLOG}"

exit ${ENDRC}
