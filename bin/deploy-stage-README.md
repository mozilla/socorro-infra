#### 1/11/17 -miles

deploy-stage.sh is adapted from deploy-socorro.sh.

deploy-stage.sh can be called without arguments, so that it can be run on a schedule in CI/CD. When run, deploy-stage.sh can look at the current Socorro stage deployment, and based on the reported revision decide not to continue (live version == tip of master branch).

In the case of a manual rollback, provide the commit SHA to rollback to as $1 and deploy-stage.sh will search for AMIs available (by tag appsha == $1) to find the correct AMI to rollback to. This prevents the need for a total rebuild in the case of a rollback. The most recent AMI is always chosen.

If a rebuild is desired, simply specify "rebuild" as a positional argument (if specified along with a SHA, $2). This will force a rebuild of the RPM and AMI, and then deploy from there.

If a redeploy without a rebuild is desired, simply specify "redeploy" as a positional argument (if specified along with a SHA, $2).

At present, deploy-stage.sh works as follows:
  - takes two completely optional positional arguments
    - optional argument $1: socorro commit SHA
    - optional argument $2:
      - set to "rebuild" to force the script to recreate the RPM and AMI for a given commit
      - set to "redeploy" to force a redeploy
  - the two positional arguments can be used separately or in conjunction
    - so if you want to rebuild and not specify a SHA, you can - this will rebuild the current tip of the master branch

  - prints info about the currently checked out mozilla/socorro-infra repo
  - clones a fresh mozilla/socorro repo into /data/socorro
    - if a SHA was specified, `git reset --hard`'s to it
  - prints info about the freshly checked out mozilla/socorro repo

  - compares the live SHA at https://crash-stats.allizom.org/status/revision/ to the freshly checked out SHA
    - if they are the same and rebuild or redeploy are not enabled, exits cleanly

  - checks to see if there is already an AMI for the checked out SHA
    - if so, and rebuild is not enabled, skips to deployment using that AMI
    - if not, creates an RPM using the checked out mozilla/socorro repository, and then creates a base AMI with that RPM installed using Packer

  - gets a list of initial instances running in stage with the roles that we care to replace (lib/stage_socorro_master.list)

  - using Terraform applies changes the LaunchConfigurations of all applicable autoscaling groups to use the new AMI

  - launches new instances for all applicable roles, waits for those in ELBs to become healthy, waits a short while, then deregisters old instances from ELBs, waits a while longer, then terminates them

  - prints logs about instances created/killed, what the new AMI and new deployed SHA are, etc.
