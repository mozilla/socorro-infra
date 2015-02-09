variable "access_key" {}
variable "secret_key" {}
variable "ssh_key_file" {
    default = {
        eu-west-1 = "socorro__eu-west-1.pem"
        us-west-2 = "socorro__us-west-2.pem"
    }
}
variable "region" {
    default = "us-west-2"
}
variable "ssh_key_name" {
    default = {
        eu-west-1 = "socorro__eu-west-1"
        us-west-2 = "socorro__us-west-2"
    }
}
variable "base_ami" {
    default = {
        eu-west-1 = "ami-332fa744"
        us-west-2 = "ami-1d2e0b2d"
    }
}
variable "alt_ssh_port" {
    default = 22123
}
