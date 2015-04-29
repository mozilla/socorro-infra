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
