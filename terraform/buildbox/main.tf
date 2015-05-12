provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "elb-socorrobuildbox-sg" {
    name = "elb-socorrobuildbox-${var.environment}-sg"
    description = "Allow internal access to RabbitMQ."
    ingress {
        from_port = 443
        to_port = 443
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

resource "aws_security_group" "ec2-socorrobuildbox-sg" {
    name = "ec2-socorrobuildbox-${var.environment}-sg"
    description = "Buildbox for socorro"
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_groups = [
          "${aws_security_group.elb-socorrobuildbox-sg.id}"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "socorrobuildbox"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorrobuildbox" {
    name = "elb-${var.environment}-socorrobuildbox"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    listener {
        instance_port = 8080
        instance_protocol = "http"
        lb_port = 443
        lb_protocol = "https"
        ssl_certificate_id = "${var.buildbox_cert}"
    }
    security_groups = [
        "${aws_security_group.elb-socorrobuildbox-sg.id}"
    ]
    cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "lc-socorrobuildbox" {
    user_data = "${file(\"socorro_role.sh\")} buildbox ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.buildbox_ami, var.region)}"
    instance_type = "c3.large"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "buildbox"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorrobuildbox-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorrobuildbox" {
    name = "as-${var.environment}-socorrobuildbox"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-socorrobuildbox"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorrobuildbox.id}"
    max_size = 10
    min_size = "${lookup(var.controllergroup_min_size, var.environment)}"
    desired_capacity = "${lookup(var.controllergroup_desired_capacity, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorrobuildbox"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorrobuildbox"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
