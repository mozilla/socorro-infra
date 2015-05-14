provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_elasticache_subnet_group" "ec-socorroweb-sub" {
    name = "ec-${var.environment}-socorroweb-sub"
    description = "Socorro webapp elasticache subnet"
    subnet_ids = ["${split(",", var.subnets)}"]
}

resource "aws_security_group" "ec-socorroweb-sg" {
    name = "ec-${var.environment}-socorroweb-sg"
    description = "Security group for socorro web app to memcached"
    ingress {
        from_port = 11211
        to_port = 11211
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.ec2-socorroweb-sg.id}"
        ]
    }
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "socorrowebapp"
        project = "socorro"
    }
}

resource "aws_elasticache_cluster" "ec-socorroweb" {
    cluster_id = "ec-${var.environment}-socorroweb"
    engine = "memcached"
    node_type = "cache.m1.small"
    num_cache_nodes = 1
    parameter_group_name = "default.memcached1.4"
    security_group_ids = [ "${aws_security_group.ec-socorroweb-sg.id}" ]
    subnet_group_name = "${aws_elasticache_subnet_group.ec-socorroweb-sub.name}"
}

resource "aws_security_group" "ec2-socorroweb-sg" {
    name = "ec2-socorroweb-${var.environment}-sg"
    description = "Security group for socorro web app"
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
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "socorrowebapp"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorroweb" {
    name = "elb-${var.environment}-socorroweb"
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
        ssl_certificate_id = "${var.webapp_cert}"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "TCP:80"
      interval = 12
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "socorrowebapp"
        project = "socorro"
    }
    cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "lc-socorroweb" {
    user_data = "${file(\"socorro_role.sh\")} webapp ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroweb-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroweb" {
    name = "as-${var.environment}-socorroweb"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-socorroweb"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroweb.id}"
    max_size = 1
    min_size = "${lookup(var.appgroup_min_size, var.environment)}"
    desired_capacity = "${lookup(var.appgroup_desired_capacity, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorroweb"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "socorroweb"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
