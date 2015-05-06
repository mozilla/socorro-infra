# Deployment scripts for Socorro

The scripts here used to deploy Socorro to numerous cluster roles are:

* `deploy-Socorro.sh`: This is the master deployment script. It accepts one
  argument: *environment* (commonly `stage` or `prod`). Calls a number of
  scripts in `deploylib/`.

* `deploylib/create_ami.sh`: Uses Packer to generate a deployable AMI. The
  resulting AMI will be tagged with the current Socorro git hash.

* `deploylib/create_rpm.sh`: Creates an updated RPM package with fpm, signs
  it, and uploads it to the `socorro-public` Yum repo.

* `deploylib/identify_role.sh`: Identifies the ELB, AS group, and Terraform
  name for a given *rolename-envname* combination.

* `deploylib/stage-Socorro-master.list`: A text list of all the
  *rolename-envname* combinations that a Socorro deploy must touch.


## Setup for Buildbox (Jenkins)

Additional steps are required to prepare Jenkins to properly use the
aforementioned deployment scripts.

### Jenkins IAM user

An IAM user for Jenkins must be created and granted the following permissions:

* Read/Write to the protected private bucket (for syncing Terraform state).
* Read/Write to the socorro-public Yum repo (for syncing the updated Socorro
  RPMs).
* Full access to the AWS EC2 API (`*`).
* Rights to AWS IAM `PassRole` (to apply roles to newly created
  infrastructure).

### Install AWS CLI

The AWS CLI tool must be available. This can be installed any number of ways
(via pip, for example) - a generic example is provided below.

```bash
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
```
### AWS config file

An executable config file in `/home/centos/.aws-config`:
```bash
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
export aws_access_key=<key>
export aws_secret_key=<secret>
export AWS_DEFAULT_REGION=<region> # us-west-2
```

*TODO*: Explain each of the above-noted variables.

### Path

Add the following locations to `$PATH`:
`/home/centos/terraform:/usr/pgsql-9.3/bin:/usr/local/bin`

### Install Jenkins

```bash
sudo wget -O /etc/yum.repos.d/Jenkins.repo http://pkg.Jenkins-ci.org/redhat/Jenkins.repo
sudo rpm --import https://Jenkins-ci.org/redhat/Jenkins-ci.org.key
sudo yum install Jenkins
```

### Modify the Jenkins user

For simplicity we run Jenkins under the default system user, `centos`. This
requires some minor configuration and file system permissions modifications.

* Update `/etc/sysconfig/Jenkins` and update user to be `centos` instead of
  `Jenkins`.
* Alter ownership on the related file system locations and restart Jenkins.

  ```bash
  sudo chown -R centos /var/lib/Jenkins \
    /var/log/Jenkins \
    /usr/lib/Jenkins \
    /var/cache/Jenkins
  sudo service Jenkins restart
  ```

### Install and configure Terraform and Packer

*TODO*

### Clone `socorro-infra` repo

*TODO*

### Jenkins-specific wrapper.sh

*TODO*
