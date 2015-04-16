provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "private_to_elasticsearch__elasticsearch" {
    name = "${var.environment}__private_to_elasticsearch__elasticsearch"
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
}

resource "aws_security_group" "any_to_elasticsearch__ssh" {
    name = "${var.environment}__any_to_elasticsearch__ssh"
    description = "Allow (alt) SSH to the Elasticsearch node."
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
        role = "elasticsearch"
        project = "socorro"
    }
}

resource "aws_elb" "elb_for_elasticsearch" {
    name = "${var.environment}--elb-for-elasticsearch"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 9200
        instance_protocol = "http"
        lb_port = 9200
        lb_protocol = "http"
    }
    security_groups = [
        "${aws_security_group.private_to_elasticsearch__elasticsearch.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_elasticsearch_asg" {
    name = "${var.environment}__lc_for_elasticsearch_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} elasticsearch ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.private_to_elasticsearch__elasticsearch.id}",
        "${aws_security_group.any_to_elasticsearch__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_elasticsearch" {
    name = "${var.environment}__asg_for_elasticsearch"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc_for_elasticsearch_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_elasticsearch_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-elasticsearch"
    ]
}
