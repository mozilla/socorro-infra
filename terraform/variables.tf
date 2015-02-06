variable "access_key" {}
variable "secret_key" {}
variable "ssh_key_file" {
    default = {
        eu-west-1 = "socorro__eu-west-1.pem"
    }
}
variable "region" {
    default = "eu-west-1"
}
variable "ssh_key_name" {
    default = {
        eu-west-1 = "socorro__eu-west-1"
    }
}
variable "base_ami" {
    default = {
        eu-west-1 = "ami-332fa744"
    }
}
variable "alt_ssh_port" {
    default = 22123
}
