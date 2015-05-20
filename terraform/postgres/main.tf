provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_db_subnet_group" "default" {
    name = "main"
    description = "Our main group of subnets"
    subnet_ids = ["${split(",", var.subnets)}"]
}

resource "aws_security_group" "rds-socorro-sg" {
    name = "rds-${var.environment}-socorro-sg"
    description = "Socorro RDS security group"
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "postgres"
        project = "socorro"
    }
}


resource "aws_db_instance" "socorro" {
    identifier = "rds-postgres-${var.environment}"
    allocated_storage = 2500
    engine = "postgres"
    engine_version = "9.4.1"
    instance_class = "db.r3.4xlarge"
    name = "breakpad"
    username = "root"
    password = "${var.rds_root_password}"
    parameter_group_name = "default.postgres9.4"
    vpc_security_group_ids = ["${aws_security_group.rds-socorro-sg.id}"]
    # provisioned IOPS SSD
    storage_type = "io1"
    iops = "10000"
    final_snapshot_identifier = "rds-postgres-${var.environment}-final"
    publicly_accessible = true
    tags {
        Name = "rds-postgres-${var.environment}"
        Environment = "${var.environment}"
        role = "postgres"
        project = "socorro"
    }
}
