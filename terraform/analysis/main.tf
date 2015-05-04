provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-socorroanalysis-sg" {
    name = "ec2-socorroanalysis-${var.environment}-sg"
    description = "Crashanalysis node."
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
    ingress {
        from_port = 443
        to_port = 443
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
        role = "socorroanalysis"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorroanalysis" {
    name = "elb-${var.environment}-socorroanalysis"
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
        ssl_certificate_id = "${var.analysis_cert}"
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "TCP:80"
      interval = 12
    }
    tags {
        Environment = "${var.environment}"
        role = "socorroanalysis"
        project = "socorro"
    }
    cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "lc-socorroanalysis" {
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} analysis ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroanalysis-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroanalysis" {
    name = "as-${var.environment}-socorroanalysis"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-socorroanalysis"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroanalysis.id}"
    max_size = 10
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "elb-${var.environment}-socorroanalysis"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorroanalysis"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
