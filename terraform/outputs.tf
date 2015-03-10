output "public_addr__symbolapi__http" {
    value = "${aws_elb.elb_for_symbolapi.dns_name}"
}
output "public_addr__collectors__http" {
    value = "${aws_elb.elb_for_collectors.dns_name}"
}
output "public_addr__webapp__http" {
    value = "${aws_elb.elb_for_webapp.dns_name}"
}
output "public_addr__middleware__http" {
    value = "${aws_elb.elb_for_middleware.dns_name}"
}
