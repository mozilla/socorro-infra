# CONSUL CLUSTER ONLY. NOTHING ELSE BELONGS HERE.
provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

# Source: https://consul.io/docs/agent/options.html
resource "aws_security_group" "ec2-consul-sg" {
    name = "ec2-consul-${var.environment}-sg"
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
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
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
        from_port = 1514
        to_port = 1514
        protocol = "udp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "consul"
        project = "devops"
    }
}

resource "aws_elb" "elb-consul" {
    name = "elb-${var.environment}-consul"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 8301
        instance_protocol = "tcp"
        lb_port = 8301
        lb_protocol = "tcp"
    }
    security_groups = [
        "${aws_security_group.ec2-consul-sg.id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "consul"
        project = "devops"
    }
}

resource "aws_launch_configuration" "lc-consul" {
    user_data = "${file(\"socorro_role.sh\")} consul ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.socorroconsul_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-consul-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-consul" {
    name = "as-${var.environment}-consul"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-consul"
    ]
    launch_configuration = "${aws_launch_configuration.lc-consul.id}"
    max_size = 30
    min_size = "${lookup(var.socorroconsul_num, var.environment)}"
    desired_capacity = "${lookup(var.socorroconsul_num, var.environment)}"
    health_check_type = "EC2"
    load_balancers = [
        "elb-${var.environment}-consul"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "consul"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
