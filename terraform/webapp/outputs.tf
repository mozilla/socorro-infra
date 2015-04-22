output "public_addr__webapp__http" {
    value = "${aws_elb.elb-socorroweb.dns_name}"
}
