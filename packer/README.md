# Socorro default box

The base AMI used for the default box is "CentOS 7 (x86_64) with Updates HVM"
which then undergoes a full `yum upgrade` before being provisioned by
master-less Puppet.

The image proposed by this repo is entirely usable and will likely not change
significantly going forward.  That said, there are some things to watch out
for:
* `$aws_access_key` and `$aws_secret_key` must either be valid environment
  variables *or* be defined in an override.
* This profile will only create a `t1.micro` instance in `us-west-2`; this
  will obviously be templated in the near future.

## SSHd

SSHd is configured to run on both ports `22` and `22123`; the former is meant
for internal (private) use only, while the latter is meant for external
(public) exposure.
