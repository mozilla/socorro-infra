output "public_addr__buildbox__deadci" {
    value = "${aws_elb.elb_for_buildbox.dns_name}"
}
