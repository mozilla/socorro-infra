output "public_addr__webapp__http" {
    value = "${aws_elb.elb_for_webapp.dns_name}"
}
