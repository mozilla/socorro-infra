provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "private_to_postgres__postgres" {
    name = "${var.environment}__private_to_postgres__postgres"
    description = "Allow access to the Postgres service itself."
    ingress {
        from_port = "5432"
        to_port = "5432"
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "postgres"
        project = "socorro"
    }
}

resource "aws_security_group" "any_to_postgres__ssh" {
    name = "${var.environment}__any_to_postgres__ssh"
    description = "Allow (alt) SSH to the Postgres node."
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "postgres"
        project = "socorro"
    }
}

resource "aws_instance" "postgres" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.private_to_postgres__postgres.name}",
        "${aws_security_group.any_to_postgres__ssh.name}"
    ]
    ebs_block_device {
        device_name = "/dev/sda1"
        delete_on_termination = "${var.del_on_term}"
    }
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} postgres ${var.secret_bucket}"
    tags {
        Name = "${var.environment}__postgres_${count.index}"
        Environment = "${var.environment}"
        role = "postgres"
        project = "socorro"
    }
    iam_instance_profile = "generic"
}

