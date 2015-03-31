output "public_addr__processor__http" {
    value = "${aws_elb.elb_for_processor.dns_name}"
}
