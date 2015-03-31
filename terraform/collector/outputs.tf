output "public_addr__collector__http" {
    value = "${aws_elb.elb_for_collector.dns_name}"
}
