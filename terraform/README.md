# Socorro model

The AMI used for spinning up new instances is built using Packer (also in this
repo).  This AMI comes pre-installed with all of the bits and pieces required
to run pretty much every aspect of Socorro; however, by default, all of the
possible services are disabled.  There are a number of *roles* which determine
which aspects of the default AMI are activated - the details of this activation
process are still being worked on.

## Details

Performing a `terraform apply` on this repo will result in a small amount of
infrastructure being spun up in the `us-west-2` AWS zone.

Three variables have no useful default and must be supplied:
* `access_key`: The AWS access key.
* `secret_key`: The AWS secret key.
* `environment`: A prefix used to designate a logical deployment group.

For testing purposes, it is useful to enable `del_on_term`, which will remove
EBS volumes once their associated instances are terminated.

You're welcome to deal with this in any number of ways. I suggest putting the
keys in `terraform.tfvars` and specifying the rest at runtime:

```
terraform plan -var 'environment=foo' -var 'del_on_term=true' -out=foo.plan
terraform apply foo.plan
```

## Branches

The ```master``` branch contains production-ready configs, changes that are
ready for testing but not for prime-time should go to the ```stage``` branch
instead.
