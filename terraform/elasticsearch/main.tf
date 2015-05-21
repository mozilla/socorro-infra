provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "elb-socorroelasticsearch2-sg" {
    name = "elb-socorroelasticsearch2-${var.environment}-sg"
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

resource "aws_security_group" "ec2-socorroelasticsearch2-sg" {
    name = "ec2-socorroelasticsearch2-${var.environment}-sg"
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

resource "aws_elb" "elb-socorroelasticsearch2" {
    name = "elb-${var.environment}-socorroelasticsearch2"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 9200
        instance_protocol = "http"
        lb_port = 9200
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch2-sg.id}"
    ]
    tags {
        Environment = "${var.environment}"
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc-socorroelasticsearch2-master" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=master' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_master_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch2-sg.id}",
        "${aws_security_group.ec2-socorroelasticsearch2-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_launch_configuration" "lc-socorroelasticsearch2-interface" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=interface' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_interface_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch2-sg.id}",
        "${aws_security_group.ec2-socorroelasticsearch2-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_launch_configuration" "lc-socorroelasticsearch2-data" {
    user_data = "${file(\"socorro_role.sh\")} 'elasticsearch FACTER_elasticsearch_role=data' ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.es_data_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "socorro_elasticsearch"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb-socorroelasticsearch2-sg.id}",
        "${aws_security_group.ec2-socorroelasticsearch2-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-socorroelasticsearch2-master" {
    name = "as-${var.environment}-socorroelasticsearch2-master"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroelasticsearch2-master"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroelasticsearch2-master.id}"
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

resource "aws_autoscaling_group" "as-socorroelasticsearch2-interface" {
    name = "as-${var.environment}-socorroelasticsearch2-interface"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroelasticsearch2-interface"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroelasticsearch2-interface.id}"
    max_size = "${lookup(var.es_interface_num, var.environment)}"
    min_size = "${lookup(var.es_interface_num, var.environment)}"
    desired_capacity = "${lookup(var.es_interface_num, var.environment)}"
    load_balancers = [
        "elb-${var.environment}-socorroelasticsearch2"
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

resource "aws_autoscaling_group" "as-socorroelasticsearch2-data" {
    name = "as-${var.environment}-socorroelasticsearch2-data"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc-socorroelasticsearch2-data"
    ]
    launch_configuration = "${aws_launch_configuration.lc-socorroelasticsearch2-data.id}"
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
