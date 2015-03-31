provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "private_to_processor__icmp" {
    name = "${var.environment}__private_to_processor__icmp"
    description = "Allow pings from within the VPC."
    ingress {
        from_port = "-1"
        to_port = "-1"
        protocol = "icmp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_security_group" "any_to_processor__ssh" {
    name = "${var.environment}__any_to_processor__ssh"
    description = "Allow (alt) SSH to the Processor node."
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

resource "aws_security_group" "internet_to_processor_elb__http" {
    name = "${var.environment}__internet_to_processor_elb__http"
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

resource "aws_security_group" "elb_to_processor__http" {
    name = "${var.environment}__elb_to_processor__http"
    description = "Allow HTTP from ELBs to processor."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_processor_elb__http.id}"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_elb" "elb_for_processor" {
    name = "${var.environment}--elb-for-processor"
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
        "${aws_security_group.internet_to_processor_elb__http.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_processor_asg" {
    name = "${var.environment}__lc_for_processor_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} processor ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.elb_to_processor__http.name}",
        "${aws_security_group.any_to_processor__ssh.name}",
        "${aws_security_group.private_to_processor__icmp.name}"
    ]
    iam_instance_profile = "generic"
}

resource "aws_autoscaling_group" "asg_for_processor" {
    name = "${var.environment}__asg_for_processor"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_processor_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_processor_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-processor"
    ]
}
