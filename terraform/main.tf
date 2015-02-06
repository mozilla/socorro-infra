provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

# This is potentially dangerous; may require review.
resource "aws_security_group" "private_to_private__any" {
    name = "private_to_private__any"
    description = "Allow all private traffic."
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "172.0.0.0/16"
        ]
    }
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "172.0.0.0/16"
        ]
    }
    ingress {
        from_port = "-1"
        to_port = "-1"
        protocol = "icmp"
        cidr_blocks = [
            "172.0.0.0/16"
        ]
    }
}

resource "aws_security_group" "internet_to_any__ssh" {
    name = "internet_to_any__ssh"
    description = "Allow (alt) SSH to any given node."
    ingress {
        from_port = "${var.alt_ssh_port}"
        to_port = "${var.alt_ssh_port}"
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
}

resource "aws_security_group" "internet_to_elb__http" {
    name = "internet_to_elb__http"
    description = "Allow incoming traffic from Internet to HTTP(S) on ELBs."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
}

resource "aws_security_group" "elb_to_webheads__http" {
    name = "elb_to_webheads__http"
    description = "Allow HTTP(S) from ELBs to webheads."
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_elb__http.id}"
        ]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        security_groups = [
            "${aws_security_group.internet_to_elb__http.id}"
        ]
    }
}

resource "aws_elb" "elb_for_collectors" {
    name = "elb-for-collectors"
    availability_zones = [
        "${aws_instance.collectors.*.availability_zone}"
    ]
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    /* Requires SSLCertificateId
    listener {
        instance_port = 443
        instance_protocol = "https"
        lb_port = 443
        lb_protocol = "https"
    }
    */
    # Sit in front of the collectors.
    instances = [
        "${aws_instance.collectors.*.id}"
    ]
    security_groups = [
        "${aws_security_group.internet_to_elb__http.id}"
    ]
}

resource "aws_elb" "elb_for_webheads" {
    name = "elb-for-webheads"
    availability_zones = [
        "${aws_instance.webheads.*.availability_zone}"
    ]
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    /* Requires SSLCertificateId
    listener {
        instance_port = 443
        instance_protocol = "https"
        lb_port = 443
        lb_protocol = "https"
    }
    */
    # Sit in front of the webheads.
    instances = [
        "${aws_instance.webheads.*.id}"
    ]
    security_groups = [
        "${aws_security_group.internet_to_elb__http.id}"
    ]
}

resource "aws_instance" "webheads" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.elb_to_webheads__http.name}",
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
    provisioner "remote-exec" {
        connection {
            user = "centos"
            key_file = "${lookup(var.ssh_key_file, var.region)}"
            port = "${var.alt_ssh_port}"
        }
        inline = [
            "sudo sh -c 'echo web_server > /var/www/html/index.html'",
            "sudo systemctl start httpd"
        ]
    }
}

resource "aws_instance" "collectors" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.elb_to_webheads__http.name}",
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
    provisioner "remote-exec" {
        connection {
            user = "centos"
            key_file = "${lookup(var.ssh_key_file, var.region)}"
            port = "${var.alt_ssh_port}"
        }
        inline = [
            "sudo sh -c 'echo collector > /var/www/html/index.html'",
            "sudo systemctl start httpd"
        ]
    }
}

resource "aws_instance" "processors" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_instance" "middleware" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_instance" "rabbitmq" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_instance" "elasticsearch" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_instance" "postgres" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    count = 1
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}

resource "aws_instance" "admin_host" {
    ami = "${lookup(var.base_ami, var.region)}"
    instance_type = "t2.micro"
    key_name = "${lookup(var.ssh_key_name, var.region)}"
    security_groups = [
        "${aws_security_group.internet_to_any__ssh.name}",
		"${aws_security_group.private_to_private__any.name}"
    ]
}
