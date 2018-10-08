variable "namespace" {}
variable "aws_instance_ami" {}
variable "aws_instance_type" {}
variable "ssh_key_name" {}
variable "ssh_key_path" {}
variable "owner" {}
variable "ttl" {}

variable "subnet_ids" {
  type = "list"
}

variable "vpc_id" {}
variable "route53_zone_id" {}
variable "route53_zone" {}
variable "database_pwd" {}
variable "db_subnet_group_name" {}
variable "license_path" {}
variable "tls_cert_path" {}
variable "tls_key_path" {}
