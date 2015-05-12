variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "secret_bucket" {}
variable "subnets" {}
variable "collector_cert" {}
variable "webapp_cert" {}
variable "analysis_cert" {}
variable "buildbox_cert" {}
variable "ssh_key_file" {
    default = {
        us-west-2 = "socorro__us-west-2.pem"
    }
}
variable "region" {
    default = "us-west-2"
}
variable "controllergroup_min_size" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "controllergroup_desired_capacity" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "appgroup_min_size" {
    default = {
        stage = "1"
        prod = "3"
    }
}
variable "appgroup_desired_capacity" {
    default = {
        stage = "1"
        prod = "3"
    }
}
variable "appgroup_instance_size" {
    default = {
        stage = "t1.micro"
        prod = "m3.medium"
    }
}
variable "processorgroup_instance_size" {
    default = {
        stage = "r3.large"
        prod = "r3.xlarge"
    }
}
variable "ssh_key_name" {
    default = {
        us-west-2 = "socorro__us-west-2"
    }
}
variable "base_ami" {
    default = {
        us-west-2 = "ami-51604e61"
    }
}
variable "buildbox_ami" {
    default = {
        us-west-2 = "ami-e9eedfd9"
    }
}
variable "elb_master_web_sg_id" {
    default = "sg-2dbfb048"
}
variable "alt_ssh_port" {
    default = 22123
}
# NOTE - this deletes EBS devices, only change it for testing purposes!
variable "del_on_term" {
    default = "false"
}
