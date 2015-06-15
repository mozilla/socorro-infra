provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "elb-socorroes-sg" {
    name = "elb-socorroes-${var.environment}-sg"
    description = "Allow ELB access to Elasticsearch."
    ingress {
        from_port = 9200
        to_port = 9200
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
    lifecycle {
        create_before_destroy = true
    }
    tags {
        Environment = "${var.environment}"
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_security_group" "ec2-socorroes-sg" {
    name = "ec2-socorroes-${var.environment}-sg"
    description = "Allow internal access to ES, etc."
    # phrawzty home
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "${var.phrawzty_ip}"
        ]
    }
    # jp home
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "${var.jp_ip}"
        ]
    }

    # rhelmer home
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "${var.rhelmer_ip}"
        ]
    }
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
    ingress {
        from_port = 9200
        to_port = 9200
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.elb-socorroes-sg.id}"
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
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_elb" "elb-socorroes" {
    name = "elb-${var.environment}-socorroes"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 9200
        instance_protocol = "http"
        lb_port = 9200
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.elb-socorroes-sg.id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-socorroes-master" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=master' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_master_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroes-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_launch_configuration" "lc-socorroes-interface" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=interface' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_interface_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroes-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_launch_configuration" "lc-socorroes-data" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=data' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_data_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-socorroes-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
    ebs_block_device {
        device_name = "/dev/xvdb"
        volume_type = "gp2"
        volume_size = "${lookup(var.es_data_ebs_size, var.environment)}"
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "as-socorroes-master" {
    name = "as-${var.environment}-socorroes-master"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroes-master"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroes-master.id}"
    max_size = "${lookup(var.es_master_num, var.environment)}"
    min_size = "${lookup(var.es_master_num, var.environment)}"
    desired_capacity = "${lookup(var.es_master_num, var.environment)}"
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

resource "aws_autoscaling_group" "as-socorroes-interface" {
    name = "as-${var.environment}-socorroes-interface"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroes-interface"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroes-interface.id}"
    max_size = "${lookup(var.es_interface_num, var.environment)}"
    min_size = "${lookup(var.es_interface_num, var.environment)}"
    desired_capacity = "${lookup(var.es_interface_num, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorroes"
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

resource "aws_autoscaling_group" "as-socorroes-data" {
    name = "as-${var.environment}-socorroes-data"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroes-data"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroes-data.id}"
    max_size = "${lookup(var.es_data_num, var.environment)}"
    min_size = "${lookup(var.es_data_num, var.environment)}"
    desired_capacity = "${lookup(var.es_data_num, var.environment)}"
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
