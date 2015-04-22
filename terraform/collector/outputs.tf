output "public_addr__collector__http" {
    value = "${aws_elb.elb-collector.dns_name}"
}
