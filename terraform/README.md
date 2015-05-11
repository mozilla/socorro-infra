# Socorro model

The AMI used for spinning up new instances is built using Packer (also in this
repo).  This AMI comes pre-installed with all of the bits and pieces required
to run pretty much every aspect of Socorro; however, by default, all of the
possible services are disabled.  There are a number of *roles* which determine
which aspects of the default AMI are configured and activated.

## Details

These variables have no useful default and must be supplied:
* `access_key`: The AWS access key.
* `secret_key`: The AWS secret key.
* `environment`: A prefix used to designate a logical deployment group.
* `secret_bucket`: The name of the bucket in which *secrets* are stored; more
   on this below.
* `subnets`: The name of one or more VPC subnets (comma-delimited) that you wish to launch infra in.
* `*_cert`: ARN ID's of various SSL certificates for web-facing services.

You're welcome to deal with this in any number of ways. I suggest putting the
keys and bucket name in `terraform.tfvars` and specifying the environment at
runtime.

## Secret bucket

The `secret_bucket` is more or less exactly what it sounds like: an S3 bucket
that has strict access controls and is considered a safe place to store
sensitive data.  The wrapper expects this bucket to have a read-writeable
`tfstate/` directory at the root level.

The secret bucket also contains hiera keys, in the `hiera/` directory at the
root level. You must specify the hostname of the ELB to the consul
cluster, inside a file named `hiera/${environment}/consul_hostname`, and the
hostname to a syslog server inside a file named
`hiera/${environment}/logging_hostname`

Puppet will use this to ensure that all nodes automatically join the Consul
and logging services, respectively.

Puppet will use this to ensure that all nodes automatically join the consul
cluster.

## Runtime

The `wrapper.sh` script should be used instead of calling `terraform` directly.
This script effectively does two important things:
* Manages the idea of roles for you.
* Ensures that you're using the freshest `.tfstate` for a given role.

```bash
./wrapper.sh apply staging elasticsearch
```

That would:
* Obtain the latest `.tfstate` for the `elasticsearch` role (from the secret
  bucket as described above).
* Run `terraform apply -var "environment=staging"` for that role.
* Upload the resulting `.tfstate` to the secret bucket.

## Making changes live in staging and production

Anything landed on master will go to staging and be considered eligible for
pushing to production. Tags will be pushed to production.
