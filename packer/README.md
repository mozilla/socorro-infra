# Packer

[Packer](https://www.packer.io) is a tool for creating machine images. We use
it for generating a generic image suitable for deploying any given Socorro
role.

## Socorro default box

The base AMI used for the default box is "CentOS 6 w/ updates" which then
undergoes a full `yum upgrade` before being provisioned by Puppet.

The image proposed by this repo is entirely usable and will likely not change
significantly going forward.  That said, there are some things to watch out
for:
* `$aws_access_key` and `$aws_secret_key` must either be valid environment
  variables *or* be defined in an override.
* This profile will only create a `t1.micro` instance in `eu-west-1`; this
  will obviously be templated in the near future.
