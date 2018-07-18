variable "aws_region" {
  description = "AWS region"
}

variable "namespace" {
  description = "Unique name to use for DNS and resource naming"
}

variable "route53_zone" {
  description = "Route 53 zone to use for domain name"
}

variable "aws_instance_ami" {
  description = "Amazon Machine Image ID"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
}

variable "ssh_key_name" {
  description = "AWS key pair name to install on the EC2 instance"
}

variable "ssh_key_path" {
  description = "Local path to your SSH key for provisioners to connect to the EC2 instance"
}

variable "owner" {
  description = "EC2 instance owner"
}

variable "ttl" {
  description = "EC2 instance TTL"
  default     = "168"
}

variable "license_path" {
  description = "Local path to your PTFE license file"
}

variable "tls_cert_path" {
  description = "Local path to your TLS (full-chain) certificate file"
}

variable "tls_key_path" {
  description = "Local path to your TLS private key"
}
