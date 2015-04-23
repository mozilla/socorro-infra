provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_security_group" "any_to_webapp__ssh" {
    name = "${var.environment}__any_to_webapp__ssh"
    description = "Allow (alt) SSH to the Webapp node."
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
        role = "crash-stats"
        project = "socorro"
    }
}

resource "aws_security_group" "internet_to_webapp_elb__http" {
    name = "${var.environment}__internet_to_webapp_elb__http"
    description = "Allow incoming traffic from Internet to HTTP on ELBs."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "crash-stats"
        project = "socorro"
    }
}

resource "aws_security_group" "internet_to_webapp_elb__https" {
    name = "${var.environment}__internet_to_webapp_elb__https"
    description = "Allow incoming traffic from Internet to HTTPS on ELBs."
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    tags {
        Environment = "${var.environment}"
    }
}

resource "aws_security_group" "elb_to_webapp__http" {
    name = "${var.environment}__elb_to_webapp__http"
    description = "Allow HTTP from ELBs to webapp."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_webapp_elb__http.id}"
        ]
    }
    tags {
        Environment = "${var.environment}"
        role = "crash-stats"
        project = "socorro"
    }
}

resource "aws_elb" "elb_for_webapp" {
    name = "${var.environment}--elb-for-webapp"
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
    security_groups = [
        "${aws_security_group.internet_to_webapp_elb__https.id}",
        "${aws_security_group.internet_to_webapp_elb__http.id}"
    ]
}

resource "aws_launch_configuration" "lc_for_webapp_asg" {
    name = "${var.environment}__lc_for_webapp_asg"
    user_data = "${file(\"socorro_role.sh\")} ${var.puppet_archive} webapp ${var.secret_bucket} ${var.environment}"
    image_id = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    iam_instance_profile = "generic"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.elb_to_webapp__http.id}",
        "${aws_security_group.any_to_webapp__ssh.id}"
    ]
}

resource "aws_autoscaling_group" "asg_for_webapp" {
    name = "${var.environment}__asg_for_webapp"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    availability_zones = [
        "${var.region}a",
        "${var.region}b",
        "${var.region}c"
    ]
    depends_on = [
        "aws_launch_configuration.lc_for_webapp_asg"
    ]
    launch_configuration = "${aws_launch_configuration.lc_for_webapp_asg.id}"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    load_balancers = [
        "${var.environment}--elb-for-webapp"
    ]
}
