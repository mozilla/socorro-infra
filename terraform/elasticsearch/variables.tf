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
variable "elb_master_web_sg_id" {
    default = "sg-2dbfb048"
}
variable "alt_ssh_port" {
    default = 22123
}
# Start App Tier scale type block
variable "socorroadmin_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "es_master_ec2_type" {
    default = {
        stage = "t2.medium"
        prod = "t2.medium"
    }
}
variable "es_master_num" {
    default = {
        stage = "3"
        prod = "3"
    }
}
variable "es_interface_ec2_type" {
    default = {
        stage = "r3.large"
        prod = "r3.xlarge"
    }
}
variable "es_interface_num" {
    default = {
        stage = "2"
        prod = "3"
    }
}
variable "es_data_ec2_type" {
    default = {
        stage = "r3.xlarge"
        prod = "r3.2xlarge"
    }
}
variable "es_data_num" {
    default = {
        stage = "3"
        prod = "9"
    }
}
variable "es_data_ebs_size" {
    default = {
        stage = "1024"
        prod = "1024"
    }
}
# NOTE - this deletes EBS devices, only change it for testing purposes!
variable "del_on_term" {
    default = "false"
}
