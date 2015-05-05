# Deployment scripts for socorro

The scripts here used to deploy socorro to numerous cluster roles are:

```./deploy-socorro.sh```
Main script, passed an argument of stage or prod.  Calls a number of scripts in the deploylib subdirectory

```./deploylib/create_ami.sh```
Uses packer scripts from ```../packer``` to generate an AMI, tag it with the socorro git has

```./deploylib/create_rpm.sh```
Creates an updated RPM package with fpm, signs it, and uploads it to the S3 public repo

```./deploylib/identify_role.sh```
A script which, given an rolename-envname, will identify the ELB, AS Group, and terraform name to use

```./deploylib/stage-socorro-master.list```
A text list of all the rolename-envnames a socorro deploy must touch


## Setup for a  buildbox/jenkins install

A few steps are required to prepare Jenkins or another CI server to properly use this script.

### Install AWS CLI

```curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"```
```unzip awscli-bundle.zip```
```sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws```


### An IAM user for jenkins must be created and granted the following permissions

* Read/Write to the protected private bucket (for syncing terraform state)

* Read/Write to the public S3 rpm repo (for syncing the updated socorro rpms)

* AWS EC2 API's (* granted)

* Rights to AWS IAM PassRole (to apply roles to newly created infrastructure)

* A executable config file in ```/home/centos/.aws-config``` containing:
```export AWS_ACCESS_KEY_ID=KEY```
```export AWS_SECRET_ACCESS_KEY=SECRET```
```export aws_access_key=KEY```
```export aws_secret_key=SECRET```
```export AWS_DEFAULT_REGION=us-west-2```


### Add the following PATH locations in ```/home/centos/.bash_profile```

```/home/centos/terraform:/usr/pgsql-9.3/bin:/usr/local/bin```


### Jenkins installed on the buildbox

```sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo```

```sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key```

```sudo yum install jenkins```



### Jenkins user changed to centos default user and file perms updated

* Update ```/etc/sysconfig/jenkins``` and update user to be *centos* instead of *jenkins*


```sudo chown -R centos /var/lib/jenkins```
```sudo chown -R centos /var/log/jenkins```
```sudo chown -R centos /usr/lib/jenkins```
```sudo chown -R centos /var/cache/jenkins```
```sudo service jenkins restart```



### Install and configure terraform/packer

* Installed into ```/home/centos/terraform```

* Added all terraform variable symbolic links

* Installed packer


### Clone socorro-infra repo

* Cloned to ```/home/centos/socorro-infra```


### Created a jenkins-specific wrapper.sh

* So as to fully qualify terraform commands (which would break localdev), created a copy of wrapper.sh for jenkins

