provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-socorroadmin-sg" {
    name = "ec2-socorroadmin-${var.environment}-sg"
    description = "Allow (alt) SSH to the Admin node."
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
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
    egress {
        from_port = 1514
        to_port = 1514
        protocol = "udp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "socorroadmin"
        project = "socorro"
    }
}

# Admin (crontabber, etc)
resource "aws_launch_configuration" "lc-socorroadmin" {
    user_data = "${file(\"socorro_role.sh\")} admin ${var.secret_bucket} ${var.environment}"
    image_id = "${var.base_ami}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroadmin-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroadmin" {
    name = "as-${var.environment}-socorroadmin"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-socorroadmin"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroadmin.id}"
    max_size = 10
    min_size = 1
    desired_capacity = 1
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorroadmin"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
