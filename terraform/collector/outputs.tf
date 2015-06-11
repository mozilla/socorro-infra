output "public_addr__collector__http" {
    value = "${aws_elb.elb-collector.dns_name}"
}

output "public_addr__collector__oldssl" {
    value = "${aws_elb.elb-collector-oldssl.dns_name}"
}
