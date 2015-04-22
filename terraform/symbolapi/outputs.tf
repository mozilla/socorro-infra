output "public_addr__symbolapi__http" {
    value = "${aws_elb.elb-symbolapi.dns_name}"
}
