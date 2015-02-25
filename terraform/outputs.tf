output "public_addr__symbolapi__http" {
    value = "${aws_elb.elb_for_symbolapi.dns_name}"
}

output "public_addr__webhead__http" {
    value = "${aws_elb.elb_for_webhead.dns_name}"
}

output "public_addr__collector__http" {
    value = "${aws_elb.elb_for_collector.dns_name}"
}
