output "public_addr__webapp__http" {
    value = "${aws_elb.elb-socorroweb.dns_name}"
}
output "socorroweb-cache-address" {
    value = "${aws_elasticache_cluster.ec-socorroweb.dns_name}"
}
