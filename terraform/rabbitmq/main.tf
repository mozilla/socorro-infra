provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "private_to_rabbitmq__rabbitmq" {
    name = "${var.environment}__private_to_rabbitmq__rabbitmq"
    description = "Allow internal access to RabbitMQ."
    ingress {
        from_port = 5672
        to_port = 5672
        protocol = "tcp"
        cidr_blocks = [
            "172.31.0.0/16"
        ]
    }
}

resource "aws_security_group" "any_to_rabbitmq__ssh" {
    name = "${var.environment}__any_to_rabbitmq__ssh"
    description = "Allow (alt) SSH to the RabbitMQ node."
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
        role = "rabbitmq"
        project = "socorro"
    }
}

resource "aws_elb" "elb_for_rabbitmq" {
    name = "${var.environment}--elb-for-rabbitmq"
    internal = true
    subnets = ["${split(",", var.subnets)}"]
    listener {
        instance_port = 5672
        instance_protocol = "tcp"
        lb_port = 5672
        lb_protocol = "tcp"
    }
    security_groups = [
        "${aws_security_group.private_to_rabbitmq__rabbitmq.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_rabbitmq_asg" {
    name = "${var.environment}__lc_for_rabbitmq_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} rabbitmq ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.private_to_rabbitmq__rabbitmq.id}",
        "${aws_security_group.any_to_rabbitmq__ssh.id}"
    ]
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.any_to_rabbitmq__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_rabbitmq" {
    name = "${var.environment}__asg_for_rabbitmq"
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    depends_on = [
        "aws_launch_configuration.lc_for_rabbitmq_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_rabbitmq_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-rabbitmq"
    ]
}
