output "private_addr__rabbitmq__http" {
    value = "${aws_elb.elb-socorrorabbitmq.dns_name}"
}
