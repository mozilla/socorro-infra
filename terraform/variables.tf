# global vars
variable "environment" {}
variable "access_key" {}
variable "subnets" {}
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
variable "base_ami" {}
variable "buildbox_ami" {}
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

# secrets
variable "secret_key" {}
variable "secret_bucket" {}
variable "rds_root_password" {}

# admin
variable "socorroadmin_num" {
    default = {
        stage = "1"
        prod = "1"
    }
}
variable "socorroadmin_ec2_type" {
    default = {
        stage = "t2.micro"
        prod = "m3.medium"
    }
}

# analysis
variable "analysis_cert" {
    default = {
        prod = ""
        stage = ""
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
        prod = "m3.xlarge"
    }
}

# buildbox
variable "buildbox_cert" {}
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

# collector
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

# consul
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

# elasticsearch
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

# processor
variable "processor_num" {
    default = {
        stage = "1"
        prod = "9"
    }
}
variable "processor_ec2_type" {
    default = {
        stage = "r3.2xlarge"
        prod = "r3.2xlarge"
    }
}

# rabbitmq
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

# stagesubmitter
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

# symbolapi
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

# webapp
variable "socorroweb_num" {
    default = {
        stage = "1"
        prod = "3"
    }
}
variable "socorroweb_ec2_type" {
    default = {
        stage = "m3.xlarge"
        prod = "m3.xlarge"
    }
}
variable "webapp_cert" {
    default = {
        prod = ""
        stage = ""
    }
}
