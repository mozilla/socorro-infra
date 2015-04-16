# CONSUL CLUSTER ONLY. NOTHING ELSE BELONGS HERE.
provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

# Source: https://consul.io/docs/agent/options.html
resource "aws_security_group" "private_to_consul__consul" {
    name = "${var.environment}__private_to_consul__consul"
    description = "Allow internal access to various Consul services."
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
    ingress {
        from_port = 8400
        to_port = 8400
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    ingress {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    ingress {
        from_port = 8600
        to_port = 8600
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    ingress {
        from_port = 8600
        to_port = 8600
        protocol = "udp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "consul"
        project = "socorro"
    }
}

resource "aws_security_group" "internet_to_consul__ssh" {
    name = "${var.environment}__internet_to_consul__ssh"
    description = "Allow (alt) SSH to any given node."
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
        role = "consul"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc_for_consul_asg" {
    name = "${var.environment}__lc_for_consul_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} consul ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.internet_to_consul__ssh.id}",
        "${aws_security_group.private_to_consul__consul.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_consul" {
    name = "${var.environment}__asg_for_consul"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_consul_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_consul_asg.id}"
    max_size = 3
    min_size = 3
    desired_capacity = 3
    health_check_type = "EC2"
}
