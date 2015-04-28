# Socorro Initial Configuration

## Introduction

Initial Socorro configuration to bootstrap a distributed production system.

By default, Socorro ships defaults that assume you are running on a single
node - this can be changed at configuration time, since there are quite a
few settings to worry about this project will automate loading the intial
configuration for you.

## Replace placeholders

Some config files contain placeholders for things such as hostnames and
passwords. You'll need to modify these before loading into consul, they
are surrounded by "@@@" tags so you can find them easily:

`grep '@@@' *.conf`

## Bulk load production configs:

Assuming your local host is connected to a healthy consul cluster, you can
bulk load your configuration into Consul:

`./bulk_load.sh`

From now on you can just use Consul.
