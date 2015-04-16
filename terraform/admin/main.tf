provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "any_to_admin__ssh" {
    name = "${var.environment}__any_to_admin__ssh"
    description = "Allow (alt) SSH to the Admin node."
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
        role = "crash-admin"
        project = "socorro"
    }
}

# Admin (crontabber, etc)
resource "aws_launch_configuration" "lc_for_admin_asg" {
    name = "${var.environment}__lc_for_admin_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} admin ${var.secret_bucket}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.any_to_admin__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_admin" {
    name = "${var.environment}__asg_for_admin"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_admin_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_admin_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
}
