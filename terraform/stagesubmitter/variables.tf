variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "secret_bucket" {}
variable "subnets" {}
variable "ssh_key_file" {
    default = {
        us-west-2 = "socorro__us-west-2.pem"
    }
}
variable "region" {
    default = "us-west-2"
}
variable "max_retries" {
    default = 5
}
variable "ssh_key_name" {
    default = {
        us-west-2 = "socorro__us-west-2"
    }
}
variable "base_ami" {
    default = {
        us-west-2 = "ami-e9734cd9"
    }
}
variable "alt_ssh_port" {
    default = 22123
}
variable "del_on_term" {
    default = "false"
}
variable "stagesubmitter_ec2_type" {
    default = {
        stage = "r3.2xlarge"
        prod = "r3.xlarge"
    }
}
variable "stagesubmitter_num" {
    default = {
        stage = "0"
        prod = "1"
    }
}