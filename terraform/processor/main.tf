provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "any_to_processor__ssh" {
    name = "${var.environment}__any_to_processor__ssh"
    description = "Allow (alt) SSH to the Processor node."
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
        role = "crash-processor"
        project = "socorro"
    }
}

resource "aws_launch_configuration" "lc_for_processor_asg" {
    name = "${var.environment}__lc_for_processor_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} processor ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "r3.large"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.any_to_processor__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_processor" {
    name = "${var.environment}__asg_for_processor"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_processor_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_processor_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
}
