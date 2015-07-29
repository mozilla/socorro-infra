variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "secret_bucket" {}
variable "subnets" {}
variable "collector_cert" {
    default = {
        prod  = ""
        stage = ""
    }
}
variable "oldsslcollector_cert" {
    default = {
        prod  = ""
        stage = ""
    }
}
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
variable "elb_master_web_sg_id" {
    default = "sg-2dbfb048"
}
variable "alt_ssh_port" {
    default = 22123
}
variable "collector_num" {
    default = {
        stage = "1"
        prod = "6"
    }
}
variable "collector_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "m3.medium"
    }
}
# NOTE - this deletes EBS devices, only change it for testing purposes!
variable "del_on_term" {
    default = "false"
}
