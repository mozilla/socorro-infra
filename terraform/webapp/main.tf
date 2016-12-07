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
    egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    egress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    # Consul (tcp and udp).
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
    port = 11211
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
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        security_groups = [
            "${var.elb_master_web_sg_id}"
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
        from_port = 0
        to_port = 65535
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
        instance_port = 443
        instance_protocol = "http"
        lb_port = 443
        lb_protocol = "https"
        ssl_certificate_id = "${lookup(var.webapp_cert, var.environment)}"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:443/monitoring/healthcheck/?elb=true"
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
    connection_draining = true
    connection_draining_timeout = 30
    # give extra time for symbol uploads
    idle_timeout = 300
}

resource "aws_launch_configuration" "lc-socorroweb" {
    user_data = "${file("../socorro_role.sh")} webapp ${var.secret_bucket} ${var.environment}"
    image_id = "${var.base_ami}"
    instance_type = "${lookup(var.socorroweb_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroweb-sg.id}"
    ]
    root_block_device {
      volume_size = "20"
    }
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
    max_size = 10
    min_size = "${lookup(var.socorroweb_num, var.environment)}"
    desired_capacity = "${lookup(var.socorroweb_num, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorroweb"
    ]
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "Name"
      value = "socorroweb-${var.environment}"
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
