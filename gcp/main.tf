terraform {
  required_version = ">= 0.10.3"
}

provider "google" {
  credentials = "${file("service_account.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_project_metadata_item" "ssh_key" {
  key   = "ssh-keys"
  value = "${var.ssh_user}:${file("${var.ssh_public_key_file}")}"
}

#------------------------------------------------------------------------------
# instance user data 
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# network 
#------------------------------------------------------------------------------

module "network" {
  source    = "network/"
  namespace = "${var.namespace}"
}

#------------------------------------------------------------------------------
# demo/poc ptfe 
#------------------------------------------------------------------------------

#module "demo" {
#  source                 = "demo/"
#  namespace              = "${var.namespace}"
#  aws_instance_ami       = "${var.aws_instance_ami}"
#  aws_instance_type      = "${var.aws_instance_type}"
#  subnet_id              = "${module.network.subnet_ids[0]}"
#  vpc_security_group_ids = "${module.network.security_group_id}"
#  user_data              = ""
#  ssh_key_name           = "${var.ssh_key_name}"
#  hashidemos_zone_id     = "${data.aws_route53_zone.hashidemos.zone_id}"
#}

#------------------------------------------------------------------------------
# production mounted disk ptfe 
#------------------------------------------------------------------------------

#module "pmd" {
#  source                 = "pmd/"
#  namespace              = "${var.namespace}"
#  aws_instance_ami       = "${var.aws_instance_ami}"
#  aws_instance_type      = "${var.aws_instance_type}"
#  subnet_id              = "${module.network.subnet_ids[0]}"
#  vpc_security_group_ids = "${module.network.security_group_id}"
#  user_data              = ""
#  ssh_key_name           = "${var.ssh_key_name}"
#  hashidemos_zone_id     = "${data.aws_route53_zone.hashidemos.zone_id}"
#}

#------------------------------------------------------------------------------
# production external-services ptfe 
#------------------------------------------------------------------------------

module "pes" {
  source               = "pes/"
  namespace            = "${var.namespace}"
  region               = "${var.region}"
  zone                 = "${module.network.available_zones}"
  subnetwork           = "${module.network.private_subnet_self_link}"
  active_ptfe_instance = "${var.active_ptfe_instance}"
  active_alias_ip      = "${var.active_alias_ip}"
  standby_alias_ip     = "${var.standby_alias_ip}"
  gcp_machine_type     = "${var.gcp_machine_type}"
  gcp_machine_image    = "${var.gcp_machine_image}"
}

#------------------------------------------------------------------------------
# bastion host
#------------------------------------------------------------------------------

module "bastion" {
  source            = "bastion/"
  namespace         = "${var.namespace}"
  region            = "${var.region}"
  zone              = "${module.network.available_zones}"
  subnetwork        = "${module.network.private_subnet_self_link}"
  gcp_machine_type  = "${var.gcp_machine_type}"
  gcp_machine_image = "${var.gcp_machine_image}"
}
