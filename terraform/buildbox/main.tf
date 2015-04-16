provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "any_to_buildbox__ssh" {
    name = "${var.environment}__any_to_buildbox__ssh"
    description = "Allow (alt) SSH to the Buildbox node."
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
        role = "buildbox"
        project = "socorro"
    }
}

resource "aws_security_group" "internet_to_elb__deadci" {
    name = "${var.environment}__internet_to_elb__deadci"
    description = "Allow incoming traffic from Internet to DeadCI (HTTP) on ELBs."
    ingress {
        from_port = 8888
        to_port = 8888
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "buildbox"
        project = "socorro"
    }
}

resource "aws_security_group" "elb_to_buildbox__deadci" {
    name = "${var.environment}__elb_to_buildbox__deadci"
    description = "Allow HTTP from ELBs to buildbox."
    ingress {
        from_port = 8888
        to_port = 8888
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_elb__deadci.id}"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "buildbox"
        project = "socorro"
    }
}

resource "aws_elb" "elb_for_buildbox" {
    name = "${var.environment}--elb-for-buildbox"
    availability_zones = [
        "${var.region}a",
        "${var.region}b"
    ]
    listener {
        instance_port = 8888
        instance_protocol = "http"
        lb_port = 8888
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.internet_to_elb__deadci.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_buildbox_asg" {
    name = "${var.environment}__lc_for_buildbox_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} buildbox ${var.secret_bucket}"
    image_id = "${lookup(var.buildbox_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "buildbox"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb_to_buildbox__deadci.id}",
        "${aws_security_group.any_to_buildbox__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_buildbox" {
    name = "${var.environment}__asg_for_buildbox"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_buildbox_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_buildbox_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-buildbox"
    ]
}
