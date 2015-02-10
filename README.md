# socorro-infra (public)

This is the public Socorro Infra repository. It contains (most of) the bits and
pieces necessary to spin up an instance of Socorro in the cloud.

## Packer

[Packer](https://www.packer.io) is a tool for creating machine images. We use
it for generating a generic image suitable for deploying any given Socorro
role.

## Terraform

[Terraform](https://www.terraform.io) is a tool for building and maintaining
virtual infrastructure in a variety of environments.  We use it for managing
various elements of Socorro's cloud-based deployment.
