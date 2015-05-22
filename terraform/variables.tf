variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "secret_bucket" {}
variable "subnets" {}
variable "collector_cert" {}
variable "webapp_cert" {}
variable "analysis_cert" {}
variable "buildbox_cert" {}
variable "rds_root_password" {}
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
# Start App Tier scale type block
variable "socorroadmin_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "socorroadmin_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "t2.micro"
    }
}
variable "socorroanalysis_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "socorroanalysis_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "t2.micro"
    }
}
variable "socorrobuildbox_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "socorrobuildbox_ec2_type" {
    default = {
        stage = "c3.large"
        prod = "c3.large"
    }
}
variable "socorroconsul_num" {
    default = {
        stage = "3"
        prod = "3"
    }
}
variable "socorroconsul_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "m3.medium"
    }
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
variable "processor_num" {
    default = {
        stage = "1"
        prod = "3"
    }
}
variable "processor_ec2_type" {
    default = {
        stage = "r3.large"
        prod = "r3.xlarge"
    }
}
variable "socorrorabbitmq_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "socorrorabbitmq_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "m3.medium"
    }
}
variable "symbolapi_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "symbolapi_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "r3.xlarge"
    }
}
variable "socorroweb_num" {
    default = {
        stage = "1"
        prod = "3"
    }
}
variable "socorroweb_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "m3.medium"
    }
}
# Start Elasticsearch block
variable "es_master_ec2_type" {
    default = {
        stage = "t2.medium"
        prod = "t2.medium"
    }
}
variable "es_master_num" {
    default = {
        stage = "2"
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
        stage = "i2.xlarge"
        prod = "i2.2xlarge"
    }
}
variable "es_data_num" {
    default = {
        stage = "3"
        prod = "9"
    }
}
# End Elasticsearch block
# NOTE - this deletes EBS devices, only change it for testing purposes!
variable "del_on_term" {
    default = "false"
}
