provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "any_to_collector__ssh" {
    name = "${var.environment}__any_to_collector__ssh"
    description = "Allow (alt) SSH to the Collector node."
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
    }
}

resource "aws_security_group" "internet_to_collector_elb__http" {
    name = "${var.environment}__internet_to_collector_elb__http"
    description = "Allow incoming traffic from Internet to HTTP on ELBs."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_security_group" "elb_to_collector__http" {
    name = "${var.environment}__elb_to_collector__http"
    description = "Allow HTTP from ELBs to collector."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_collector_elb__http.id}"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_elb" "elb_for_collector" {
    name = "${var.environment}--elb-for-collector"
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
    security_groups = [
        "${aws_security_group.internet_to_collector_elb__http.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_collector_asg" {
    name = "${var.environment}__lc_for_collector_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} collector ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb_to_collector__http.id}",
        "${aws_security_group.any_to_collector__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_collector" {
    name = "${var.environment}__asg_for_collector"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc_for_collector_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_collector_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-collector"
    ]
}
