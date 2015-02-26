variable "environment" {}
variable "access_key" {}
variable "secret_key" {}
variable "ssh_key_file" {
    default = {
        us-west-2 = "socorro__us-west-2.pem"
    }
}
variable "region" {
    default = "us-west-2"
}
variable "ssh_key_name" {
    default = {
        us-west-2 = "socorro__us-west-2"
    }
}
variable "base_ami" {
    default = {
        us-west-2 = "ami-1d2e0b2d"
    }
}
variable "alt_ssh_port" {
    default = 22123
}
variable "del_on_term" {
    default = "false"
}
