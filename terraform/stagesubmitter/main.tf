provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "ec2-stagesubmitter-sg" {
    name = "ec2-stagesubmitter-${var.environment}-sg"
    description = "Security group for socorro stage submitter"
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
}

resource "aws_launch_configuration" "lc-stagesubmitter" {
    user_data = "${file(\"socorro_role.sh\")} stagesubmitter ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "${lookup(var.stagesubmitter_ec2_type, var.environment)}"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.ec2-stagesubmitter-sg.id}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "as-stagesubmitter" {
    name = "as-${var.environment}-stagesubmitter"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc-stagesubmitter"
    ]
    launch_configuration = "${aws_launch_configuration.lc-stagesubmitter.id}"
    max_size = 1
    min_size = "${lookup(var.stagesubmitter_num, var.environment)}"
    desired_capacity = "${lookup(var.stagesubmitter_num, var.environment)}"
    tag {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
    tag {
      key = "role"
      value = "stagesubmitter"
      propagate_at_launch = true
    }
    tag {
      key = "project"
      value = "socorro"
      propagate_at_launch = true
    }
}
