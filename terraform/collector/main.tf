provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-collector-sg" {
    name = "ec2-collector-sg"
    description = "Security grup for ec2 as group for socorro collector."
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        security_groups = [
            "${var.elb_master_web_sg_id}"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "collector"
        project = "socorro"
    }
}

resource "aws_elb" "elb-collector" {
    name = "elb-${var.environment}-collector"
    availability_zones = [
        "${var.region}a",
        "${var.region}b"
    ]
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 443
        lb_protocol = "https"
        ssl_certificate_id = "${var.collector_cert}"
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "collector"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-collector" {
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} collector ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-collector-sg.id}",
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-collector" {
    name = "as-${var.environment}-collector"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-collector"
    ]
    launch_configuration = "${aws_launch_configuration.lc-collector.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "elb-${var.environment}-collector"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "collector"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
