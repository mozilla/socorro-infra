provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-symbolapi-sg" {
    name = "ec2-symbolapi-${var.environment}-sg"
    description = "SG for socorro symbolapi"
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
        role = "symbolapi"
        project = "socorro"
    }
}

resource "aws_elb" "elb-symbolapi" {
    name = "elb-${var.environment}-symbolapi"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    listener {
        instance_port = 8000
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "TCP:8000"
      interval = 12
    }
    tags {
        Environment = "${var.environment}"
        role = "symbolapi"
        project = "socorro"
    }
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 30
}

resource "aws_launch_configuration" "lc-symbolapi" {
    user_data = "${file("../socorro_role.sh")} symbolapi ${var.secret_bucket} ${var.environment}"
    image_id = "${var.base_ami}"
    instance_type = "${lookup(var.symbolapi_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-symbolapi-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-symbolapi" {
    name = "as-${var.environment}-symbolapi"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-symbolapi"
    ]
    launch_configuration = "${aws_launch_configuration.lc-symbolapi.id}"
    max_size = 10
    min_size = "${lookup(var.symbolapi_num, var.environment)}"
    desired_capacity = "${lookup(var.symbolapi_num, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-symbolapi"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "Name"
      value = "symbolapi-${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "symbolapi"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
