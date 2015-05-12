# socorro-infra (public)

This is the public Socorro Infra repository. It contains (most of) the bits and
pieces necessary to spin up an instance of Socorro in the cloud.

## Packer

[Packer](https://www.packer.io) is a tool for creating machine images.  We use
it for generating a generic image suitable for deploying any given Socorro
role.

## Puppet

[Puppet](https://puppetlabs.com) is a configuration management tool.  We use it
both for managing the Packer-built images as well as for provisioning nodes.

## Terraform

[Terraform](https://www.terraform.io) is a tool for building and maintaining
virtual infrastructure in a variety of environments.  We use it for managing
various elements of Socorro's cloud-based deployment.

## Socorro Config

The `socorro-config` directory holds the initial settings for bootstrapping
a distributed Socorro install. You'll need to customize the settings and
load them into your Consul cluster.

# Default manifest

There is a single "default" manifest (`manifests/default.pp`) which contains a
single node definition that is creatively named `default`. This definition
deals with two cases: `packer_profile` and `socorro_role`.

## `packer_profile`

This case deals with the [Packer](../packer/) phase. There is no reasonable
default.

## `socorro_role`

This case deals with the Provision phase, which occurs when a node is
instantiated. Each role is listed here in lexicographical order. There is no
reasonable default.

# Socorro module

There is only one module: `socorro`. This module contains the necessary items
for *both* the Packer and Provision phases. These phases are totally
independent from one another (i.e. one should not include elements from the
other).

## `init.pp`

The base manifest for this module contains elements which are common to all
*Packer profiles*, and is meant to be included at this phase. While there is
no technical reason it couldn't be included in the *Provision* phase, this
is not the intended use case.

## Packer

The base Packer manifest describes a *generic* node that can run the widest
possible range of roles. Briefly stated: install as much as necessary, but no
more than that, and deactivate everything by default. Oddball nodes may
have their own manifests, and may include the base Packer manifest (`base.pp`)
if desired.

## Role

Each Role has an associated manifest which is meant to configure and activate
the elements installed by the Packer phase. Roles should include the common
role manifest (`common.pp`).

# Building a Buildbox
## Deployment scripts for Socorro

The scripts here used to deploy Socorro to numerous cluster roles are:

* `deploy-socorro.sh`: This is the master deployment script. It accepts one
  argument: *environment* (commonly `stage` or `prod`). Calls a number of
  scripts in `lib/`.

* `lib/create_ami.sh`: Uses Packer to generate a deployable AMI. The
  resulting AMI will be tagged with the current Socorro git hash.

* `lib/create_rpm.sh`: Creates an updated RPM package with fpm, signs
  it, and uploads it to the `socorro-public` Yum repo.

* `lib/identify_role.sh`: Identifies the ELB, AS group, and Terraform
  name for a given *rolename-envname* combination.

* `lib/stage_socorro_master.list`: A text list of all the
  *rolename-envname* combinations that a Socorro deploy must touch.


## Setup for Buildbox (Jenkins)

Additional steps are required to prepare Jenkins to properly use the
aforementioned deployment scripts.

### Jenkins IAM user

An IAM user for Jenkins must be created and granted the following permissions:
* AWS IAM PassRole (to apply roles to newly created infrastructure)
* Put rights for Cloudwatch
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

### Terraform and Packer

RPMs for both Terraform and Packer are available in the `socorro-public` Yum
repo and can be installed in the usual fashion.

```sudo yum install packer terraform```

*TODO*: Config details.
* Put the signing key in ```/home/centos/.rpmsign

### Clone `socorro-infra` repo


*TODO*
