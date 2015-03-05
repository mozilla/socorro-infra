provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

# Once you're in, you're in.
resource "aws_security_group" "private_to_private__any" {
    name = "${var.environment}__private_to_private__any"
    description = "Allow all private traffic."
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
            ]
        }
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "172.31.0.0/16"
            ]
        }
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

resource "aws_security_group" "internet_to_any__ssh" {
    name = "${var.environment}__internet_to_any__ssh"
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
    }
}

resource "aws_security_group" "internet_to_elb__http" {
    name = "${var.environment}__internet_to_elb__http"
    description = "Allow incoming traffic from Internet to HTTP(S) on ELBs."
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

resource "aws_security_group" "elb_to_symbolapi__http" {
    name = "${var.environment}__elb_to_symbolapi__http"
    description = "Allow HTTP(S) from ELBs to symbolapi."
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_elb__http.id}"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_elb" "elb_for_symbolapi" {
    name = "${var.environment}--elb-for-symbolapi"
    availability_zones = [
        "${var.region}a",
        "${var.region}b"
    ]
    listener {
        instance_port = 8000
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.internet_to_elb__http.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_symbolapi_asg" {
    name = "${var.environment}__lc_for_symbolapi_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.infra_repo} symbolapi"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "c4.xlarge"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.internet_to_elb__http.name}",
        "${aws_security_group.elb_to_symbolapi__http.name}",
        "${aws_security_group.internet_to_any__ssh.name}",
        "${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_launch_configuration" "lc_for_consul_asg" {
    name = "${var.environment}__lc_for_consul_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.infra_repo} consul"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
        "${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_autoscaling_group" "asg_for_symbolapi" {
    name = "${var.environment}__asg_for_symbolapi"
    availability_zones = [
        "${var.region}a",
        "${var.region}b"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_symbolapi_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_symbolapi_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-symbolapi"
    ]
}

resource "aws_autoscaling_group" "asg_for_consul" {
    name = "${var.environment}__asg_for_consul"
    availability_zones = [
        "${var.region}a",
        "${var.region}b"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_consul_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_consul_asg.id}"
    max_size = 5
    min_size = 3
    desired_capacity = 3
    health_check_type = "EC2"
}
