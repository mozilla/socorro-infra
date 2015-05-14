provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "elb-socorrorabbitmq-sg" {
    name = "elb-socorrorabbitmq-${var.environment}-sg"
    description = "Allow internal access to RabbitMQ."
    ingress {
        from_port = 5672
        to_port = 5672
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "rabbitmq"
        project = "socorro"
    }
}

resource "aws_security_group" "ec2-socorrorabbitmq-sg" {
    name = "ec2-socorrorabbitmq-${var.environment}-sg"
    description = "EC2 security for rabbitmq."
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
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
        role = "rabbitmq"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorrorabbitmq" {
    name = "elb-${var.environment}-socorrorabbitmq"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 5672
        instance_protocol = "tcp"
        lb_port = 5672
        lb_protocol = "tcp"
    }
    security_groups = [
        "${aws_security_group.elb-socorrorabbitmq-sg.id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "rabbitmq"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-socorrorabbitmq" {
    user_data = "${file(\"socorro_role.sh\")} rabbitmq ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.appgroup_instance_size, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.ec2-socorrorabbitmq-sg.id}"
    ]
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorrorabbitmq" {
    name = "as-${var.environment}-socorrorabbitmq"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorrorabbitmq"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorrorabbitmq.id}"
    max_size = 1
    min_size = "${lookup(var.controllergroup_min_size, var.environment)}"
    desired_capacity = "${lookup(var.controllergroup_desired_capacity, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorrorabbitmq"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorrorabbitmq"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
