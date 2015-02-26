provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

# This is potentially dangerous; may require review.
resource "aws_security_group" "private_to_private__any" {
    name = "${var.environment}__private_to_private__any"
    description = "Allow all private traffic."
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "172.0.0.0/16"
        ]
    }
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "172.0.0.0/16"
        ]
    }
    ingress {
        from_port = "-1"
        to_port = "-1"
        protocol = "icmp"
        cidr_blocks = [
            "172.0.0.0/16"
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
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_security_group" "internet_to_snowflakes__http" {
    name = "${var.environment}__internet_to_snowflakes__http"
    description = "Allow HTTP access to some oddball nodes."
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

resource "aws_elb" "elb_for_symbolapi" {
    name = "${var.environment}--elb-for-symbolapi"
    availability_zones = [
        "${aws_instance.symbolapi.*.availability_zone}"
    ]
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    # Sit in front of the symbolapi.
    instances = [
        "${aws_instance.symbolapi.*.id}"
    ]
    security_groups = [
        "${aws_security_group.internet_to_elb__http.id}"
    ]
}

resource "aws_instance" "symbolapi" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "c4.xlarge"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
        "${aws_security_group.internet_to_snowflakes__http.name}",
        "${aws_security_group.private_to_private__any.name}"
    ]
    block_device {
        device_name = "/dev/sda1"
        delete_on_termination = "${var.del_on_term}"
        tags {
            Name = "${var.environment}__symbolapi_${count.index}__sda1"
        }
    }
    tags {
        Name = "${var.environment}__symbolapi_${count.index}"
        Environment = "${var.environment}"
    }
}
