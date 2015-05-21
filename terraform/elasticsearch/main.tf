provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "elb-socorroelasticsearch-sg" {
    name = "elb-socorroelasticsearch-${var.environment}-sg"
    description = "Allow internal access to Elasticsearch."
    ingress {
        from_port = 9200
        to_port = 9200
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
    ingress {
        from_port = 9300
        to_port = 9300
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
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
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_security_group" "ec2-socorroelasticsearch-sg" {
    name = "ec2-socorroelasticsearch-${var.environment}-sg"
    description = "Allow (alt) SSH to the Elasticsearch node."
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
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorroelasticsearch" {
    name = "elb-${var.environment}-socorroelasticsearch"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 9200
        instance_protocol = "http"
        lb_port = 9200
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch-sg.id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-socorroelasticsearch" {
    user_data = "${file(\"socorro_role.sh\")} elasticsearch ${var.secret_bucket} ${var.environment}"
    image_id = "${var.base_ami}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch-sg.id}",
        "${aws_security_group.ec2-socorroelasticsearch-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroelasticsearch" {
    name = "as-${var.environment}-socorroelasticsearch"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroelasticsearch"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroelasticsearch.id}"
    max_size = 10
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "elb-${var.environment}-socorroelasticsearch"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "elasticsearch"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
