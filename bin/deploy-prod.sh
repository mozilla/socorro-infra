#!/bin/bash

### this executes socorro prod build and can run without arguments
### by default builds most recent commit to master
### optional argument $1: socorro tag to deploy
### optional argument $2: "redeploy" to force a redeploy of the build for the current tag
### # note: does not rebuild RPM or AMI, use deploy-stage.sh for that

### adapted from deploy-socorro

set +u
set +x

format_logs() {
    # requires figlet installed
    echo -e "$(date)\n$(figlet -f stop "${ENVIRONMENT}")\n\"${STEP}\"\n\n"
}

error_check() {
    if [ "${RC}" -ne 0 ]; then
        echo "$(date) -- Error encountered during ${STEP}"
        echo "Fatal, exiting"
        echo "Instances which may need to be terminated manually: ${INITIAL_INSTANCES}"
        exit 1
    fi
}

LIVE_ENV_URL="https://crash-stats.mozilla.org/status/revision/"

SHOULD_DEPLOY="true"
# provide an existing tag
if [[ -n $1 ]] && [[ $1 =~ [0-9]{4} ]]; then
    # properly formatted tag
    SPECIFIED_TAG=$1
elif [[ -n $1 ]] &&  [[ $1 =~ [0-9a-f]{40} ]]; then
    SPECIFIED_HASH=$1
elif [[ -n $1 ]] && [[ $1 == "redeploy" ]]; then
    # redeploy
    set -- "" "redeploy"
elif [[ -n $1 ]]; then
    # invalid tag or SHA, redeploy not specified
    # tags need to be [0-9]{4}, SHAs need to be [0-9a-f]{40}
    STEP="[skip_to_deployment] $1 is not a correctly formatted tag"; format_logs
    RC=1; error_check
fi

FORCE_REDEPLOY="false"
if [[ -n $2 ]] && [[ "$2" == "redeploy" ]]; then
    STEP="[redeploy] Redeploy enabled for this build."; format_logs
    FORCE_REDEPLOY="redeploy"
fi

SCRIPT_PATH=$(dirname "$(realpath "$0")")
SOCORRO_INFRA_PATH="/home/centos/socorro-infra"
ENVIRONMENT="prod"
ENDRC=0

readonly EXPECTED_TERRAFORM_VERSION="Terraform v0.7.13"
readonly EXPECTED_PACKER_VERSION="Packer v0.7.5"
readonly EXPECTED_PYTHON_VERSION="Python 2.7.11"

STARTLOG=$(mktemp)
ENDLOG=$(mktemp)

# Roles / instance types to deploy for prod
ROLES=$(cat "${SCRIPT_PATH}/lib/${ENVIRONMENT}_socorro_master.list")

INITIAL_INSTANCES=

# imports
. "${SCRIPT_PATH}/lib/identify_role.sh"
. "${SCRIPT_PATH}/lib/infra_status.sh"
. "${SCRIPT_PATH}/deploy-functions.sh"

# for postgres and python
PATH="${PATH}:/usr/pgsql-9.3/bin:/usr/local/bin/"
echo "PATH: ${PATH}"

function get_prod_git_info() {
    # most recent tag on master
    MOST_RECENT_TAG=$(git describe --tags ${SPECIFIED_HASH})
    # short sha of commit most recent tag points to
    # git's API is inconsistent.
    GIT_COMMIT_HASH=$(git rev-list -n 1 ${MOST_RECENT_TAG})
    COMMITTER_INFO=$(git log ${SPECIFIED_HASH} -n 1 --pretty="format:%cN committed ${MOST_RECENT_TAG} (%h) %ad")
    echo "Lastest tag on master: ${COMMITTER_INFO}"
}

get_infra_git_info() {
    # latest commit on master
    echo "git info for $(basename "$(git remote show -n origin | grep Fetch | cut -d: -f2-)")"
    echo "Latest commit on master: $(git log -n 1 --format="%an committed %h %ad" "$(git rev-parse master)")"
}

clone_repo_prod() {
    STEP="[clone_repo_prod] Moving to ${DATA_DIRECTORY}"; format_logs
    cd "$DATA_DIRECTORY"
    RC=$?; error_check

    STEP="[clone_repo_prod] Removing old repo"; format_logs
    rm --preserve-root -rf "${DATA_DIRECTORY}/socorro"
    RC=$?; error_check

    STEP="[clone_repo_prod] Cloning repo"; format_logs
    echo "Cloning the socorro repo into ${DATA_DIRECTORY}/socorro"
    git clone https://github.com/mozilla/socorro.git
    RC=$?; error_check

    cd "$DATA_DIRECTORY/socorro"
    RC=$?; error_check

    # hash specified => set tag
    if [[ -n "$SPECIFIED_HASH" ]]; then
        SPECIFIED_TAG=$(git describe --tags ${SPECIFIED_HASH})
    fi

    # tag specified => set hash
    if [[ -n "$SPECIFIED_TAG" ]] && [[ -z "$SPECIFIED_HASH" ]]; then
        SPECIFIED_HASH=$(git rev-parse ${SPECIFIED_TAG})
    fi

    # tag not specified, hash not specified
    # defaults to most recent tag
    if [[ -z "$SPECIFIED_TAG" ]] && [[ -z "$SPECIFIED_HASH" ]]; then
        SPECIFIED_TAG=$(git describe --tags master)
        SPECIFIED_HASH=$(git rev-parse ${SPECIFIED_TAG})
    fi

    # reset to the commit associated with the specified tag or hash
    STEP="[clone_repo_prod] Checking out tag ${SPECIFIED_TAG} (${SPECIFIED_HASH})"; format_logs
    git reset --hard "${SPECIFIED_HASH}"
    RC=$?; error_check

    STEP="[clone_repo_prod] Acquiring git metadata"; format_logs
    # print socorro commit info
    get_prod_git_info
}

### Script execution
check_for_dependencies

# print socorro-infra latest commit info
get_infra_git_info

# clone_repo_prod checks latest tag on master
clone_repo_prod

check_if_should_deploy

if [[ "$SHOULD_DEPLOY" == "false" ]] && [[ "$FORCE_REDEPLOY" != "redeploy" ]]; then
    STEP="[main_script] SHOULD_DEPLOY => ${SHOULD_DEPLOY}"
    echo "Live revision at ${LIVE_ENV_URL} is same as latest master."
    echo "Live: ${LIVE_GIT_COMMIT_HASH} == ${GIT_COMMIT_HASH}"
    exit 0
fi


# find_ami checks whether an AMI for that
# commit already exists
find_ami

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
