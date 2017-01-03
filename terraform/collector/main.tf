provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-collector-sg" {
    name = "ec2-collector-${var.environment}-sg"
    description = "Security group for EC2 socorro collector."
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
        role = "collector"
        project = "socorro"
    }
}

resource "aws_elb" "elb-collector" {
    name = "elb-${var.environment}-collector"
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
        ssl_certificate_id = "${lookup(var.collector_cert, var.environment)}"
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "TCP:80"
        interval = 12
    }
    tags {
        Environment = "${var.environment}"
        role = "collector"
        project = "socorro"
    }
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 30
    # give extra time for crash reports
    idle_timeout = 300
}

resource "aws_elb" "elb-collector-oldssl" {
    name = "elb-${var.environment}-collector-oldssl"
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
        ssl_certificate_id = "${lookup(var.oldsslcollector_cert, var.environment)}"
    }
    security_groups = [
        "${var.elb_master_web_sg_id}"
    ]
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "TCP:80"
        interval = 12
    }
    tags {
        Environment = "${var.environment}"
        role = "collector"
        project = "socorro"
    }
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 30
}

# this is based off of ELBSecurityPolicy-2016-08
# SSLv3 and DES-CBC3-SHA have been added
# see: https://wiki.mozilla.org/Security/Server_Side_TLS#Old_backward_compatibility
resource "aws_lb_ssl_negotiation_policy" "oldssl" {
  name = "oldssl_policy"
  load_balancer = "${aws_elb.elb-collector-oldssl.id}"
  lb_port = 443
  attribute {
    name = "Protocol-TLSv1",
    value = "true"
  },
  attribute {
    name = "Protocol-SSLv3",
    value = "false"
  },
  attribute {
    name = "Protocol-TLSv1.1",
    value = "true"
  },
  attribute {
    name = "Protocol-TLSv1.2",
    value = "true"
  },
  attribute {
    name = "Server-Defined-Cipher-Order",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES128-GCM-SHA256",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES128-GCM-SHA256",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES128-SHA256",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES128-SHA256",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES128-SHA",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES128-SHA",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES256-GCM-SHA384",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES256-GCM-SHA384",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES256-SHA384",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES256-SHA384",
    value = "true"
  },
  attribute {
    name = "ECDHE-RSA-AES256-SHA",
    value = "true"
  },
  attribute {
    name = "ECDHE-ECDSA-AES256-SHA",
    value = "true"
  },
  attribute {
    name = "AES128-GCM-SHA256",
    value = "true"
  },
  attribute {
    name = "AES128-SHA256",
    value = "true"
  },
  attribute {
    name = "AES128-SHA",
    value = "true"
  },
  attribute {
    name = "AES256-GCM-SHA384",
    value = "true"
  },
  attribute {
    name = "AES256-SHA256",
    value = "true"
  },
  attribute {
    name = "AES256-SHA",
    value = "true"
  },
  attribute {
    name = "DES-CBC3-SHA",
    value = "true"
  }
}

resource "aws_launch_configuration" "lc-collector" {
    user_data = "${file("socorro_role.sh")} collector ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.collector_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-collector-sg.id}",
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-collector" {
    name = "as-${var.environment}-collector"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-collector"
    ]
    launch_configuration = "${aws_launch_configuration.lc-collector.id}"
    max_size = 30
    min_size = "${lookup(var.collector_num, var.environment)}"
    desired_capacity = "${lookup(var.collector_num, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-collector",
        "elb-${var.environment}-collector-oldssl"
    ]
    tag {
        key = "Environment"
        value = "${var.environment}"
        propagate_at_launch = true
    }
    tag {
        key = "Name"
        value = "collector-${var.environment}"
        propagate_at_launch = true
    }
    tag {
        key = "role"
        value = "collector"
        propagate_at_launch = true
    }
    tag {
        key = "project"
        value = "socorro"
        propagate_at_launch = true
    }
}

