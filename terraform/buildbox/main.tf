provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-socorrobuildbox-sg" {
    name = "ec2-socorrobuildbox-sg"
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
        from_port = 8888
        to_port = 8888
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
        instance_port = 8888
        instance_protocol = "http"
        lb_port = 8888
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.ec2-socorrobuildbox-sg.id}"
    ]
    cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "lc-socorrobuildbox" {
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} buildbox ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.buildbox_ami, var.region)}"
    instance_type = "t2.micro"
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
    min_size = 1
    desired_capacity = 1
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
