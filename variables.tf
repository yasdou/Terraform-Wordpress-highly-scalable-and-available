//variables.tf
variable "ami_id" {
    default = "ami-0df24e148fdb9f1d8"
}
variable "instance_type" {
    default = "t2.micro"
}
variable "ami_key_pair_name" {
    default = "vockey"
}
variable "region"{
    default = "us-west-2"
}