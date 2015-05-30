provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-processor-sg" {
    name = "ec2-processor-${var.environment}-sg"
    description = "Socorro processor security group."
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
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    # Consul (tcp and udp).
    ingress {
        from_port = 8300
        to_port = 8302
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    ingress {
        from_port = 8301
        to_port = 8302
        protocol = "udp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "processor"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-processor" {
    user_data = "${file(\"socorro_role.sh\")} processor ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.processor_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-processor-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-processor" {
    name = "as-${var.environment}-processor"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-processor"
    ]
    launch_configuration = "${aws_launch_configuration.lc-processor.id}"
    max_size = 30
    min_size = "${lookup(var.processor_num, var.environment)}"
    desired_capacity = "${lookup(var.processor_num, var.environment)}"
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "processor"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
