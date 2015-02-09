output "public_addr__webheads__http" {
    value = "${aws_elb.elb_for_webheads.dns_name}"
}

output "public_addr__collectors__http" {
    value = "${aws_elb.elb_for_collectors.dns_name}"
}
