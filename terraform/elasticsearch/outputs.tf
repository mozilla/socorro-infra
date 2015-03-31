output "private_addr__elasticsearch__http" {
    value = "${aws_elb.elb_for_elasticsearch.dns_name}"
}
