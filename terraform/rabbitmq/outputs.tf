output "private_addr__rabbitmq__http" {
    value = "${aws_elb.elb_for_rabbitmq.dns_name}"
}
