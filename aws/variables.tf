variable "aws_region" {
  description = "AWS region"
}

variable "service_name" {
  description = "Unique service name to use for DNS and tag all resources with"
}

variable "aws_instance_ami" {
  description = "Amazon Machine Image ID"
}

variable "ssh_key_name" {
  description = "AWS key pair name to install on the EC2 instance"
}

variable "owner" {
  description = "EC2 instance owner"
}

variable "ttl" {
  description = "EC2 instance TTL"
  default = "168"
}
