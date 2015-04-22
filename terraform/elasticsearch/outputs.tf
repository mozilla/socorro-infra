output "private_addr__elasticsearch__http" {
    value = "${aws_elb.elb-socorroelasticsearch.dns_name}"
}
