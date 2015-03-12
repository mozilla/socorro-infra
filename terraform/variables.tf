variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "ssh_key_file" {
    default = {
        us-west-2 = "socorro__us-west-2.pem"
    }
}
variable "region" {
    default = "us-west-2"
}
variable "ssh_key_name" {
    default = {
        us-west-2 = "socorro__us-west-2"
    }
}
variable "base_ami" {
    default = {
        us-west-2 = "ami-7b64474b"
    }
}
variable "alt_ssh_port" {
    default = 22123
}
variable "puppet_archive" {
    default = "https://s3-us-west-2.amazonaws.com/org.mozilla.crash-stats.packages-public/prov_cache/socorro-infra__puppet.tar.gz"
}
# NOTE - this deletes EBS devices, only change it for testing purposes!
variable "del_on_term" {
    default = "false"
}
