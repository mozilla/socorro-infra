provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-socorroweb-sg" {
    name = "ec2-socorroweb-${var.environment}-sg"
    description = "Security group for socorro web app"
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    ingress {
        from_port = 80
        to_port = 80
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
        role = "socorrowebapp"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorroweb" {
    name = "elb-${var.environment}-socorroweb"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
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
        ssl_certificate_id = "${var.webapp_cert}"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "TCP:80"
      interval = 12
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "socorrowebapp"
        project = "socorro"
    }
    cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "lc-socorroweb" {
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} webapp ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroweb-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroweb" {
    name = "as-${var.environment}-socorroweb"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-socorroweb"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroweb.id}"
    max_size = 10
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "elb-${var.environment}-socorroweb"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorroweb"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
