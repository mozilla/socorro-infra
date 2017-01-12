#### 1/12/17 -miles

deploy-prod.sh is adapted from deploy-socorro.sh.

deploy-prod.sh can be called without arguments, so that it could, in theory, be run on a schedule in CI/CD. When run, deploy-prod.sh can look at the current Socorro prod deployment, and based on the reported revision decide not to continue (if live version == SHA of most recent tag).

In the case of a manual rollback, provide the tag or SHA to rollback to as $1 and deploy-prod.sh will search for AMIs available (by AMI tag appsha == tag/SHA supplied in $1) to find the correct AMI to rollback to. The most recent AMI is always chosen.

If a redeploy of the running live tag or SHA is desired, simply specify "redeploy" as a positional argument (if specified along with a tag or SHA, $2). This will force a redeploy of the RPM and AMI, and then deploy from there.

At present, deploy-prod.sh works as follows:
  - takes two completely optional positional arguments
    - optional argument $1: socorro tag or app SHA that has a corresponding AMI already built
    - optional argument $2: set to "redeploy" to force the script to redeploy
  - the two positional arguments can be used separately or in conjunction
    - so if you want to redeploy and not specify a tag or SHA, you can - this will redeploy the most recent tag

  - prints info about the currently checked out mozilla/socorro-infra repo
  - clones a fresh mozilla/socorro repo into /data/socorro
    - if a SHA or tag was specified, `git reset --hard`'s to it
  - prints info about the freshly checked out mozilla/socorro repo

  - compares the live SHA at https://crash-stats.allizom.org/status/revision/ to the freshly checked out SHA
    - if they are the same and redeploy is not enabled, exits cleanly

  - checks to see if there is already an AMI for the checked out SHA
    - if not, fatal error

  - gets a list of initial instances running in prod with the roles that we care to replace (lib/prod_socorro_master.list)

  - using Terraform applies changes the LaunchConfigurations of all applicable autoscaling groups to use the new AMI

  - launches new instances for all applicable roles, waits for those in ELBs to become healthy, waits a short while, then deregisters old instances from ELBs, waits a while longer, then terminates them

  - prints logs about instances created/killed, what the new AMI and new deployed SHA are, etc.
