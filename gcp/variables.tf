variable "region" {
  description = "GCP region"
}

variable "project" {
  description = "GCP project name"
}

variable "namespace" {
  description = "Unique name to use for DNS and resource naming"
}

variable "active_ptfe_instance" {
  description = "The active PTFE instance ie ptfe1 or ptfe2"
  default     = "ptfe1"
}

variable "active_alias_ip" {
  description = "Alias IP attached to the active PTFE VM instance"
}

variable "standby_alias_ip" {
  description = "Alias IP attached to the standby PTFE VM instance"
}

variable "gcp_machine_image" {
  description = "GCP machine image"
}

variable "gcp_machine_type" {
  description = "GCP machine type"
}

variable "ssh_user" {
  description = "User to create on VM instances for SSH access"
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file for VM instance access eg /home/user/.ssh/id_rsa.pub"
}
