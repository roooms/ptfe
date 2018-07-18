terraform {
  backend "s3" {
    region = "eu-west-1"
    bucket = "roooms-tfstate"
    key    = "roooms/ptfe/aws"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_route53_zone" "main" {
  name = "${var.route53_zone}."
}

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

module "demo" {
  source                 = "demo/"
  namespace              = "${var.namespace}"
  aws_instance_ami       = "${var.aws_instance_ami}"
  aws_instance_type      = "${var.aws_instance_type}"
  subnet_id              = "${module.network.public_subnet_ids[0]}"
  vpc_security_group_ids = "${module.network.security_group_id}"
  ssh_key_name           = "${var.ssh_key_name}"
  ssh_key_path           = "${var.ssh_key_path}"
  license_path           = "${var.license_path}"
  tls_cert_path          = "${var.tls_cert_path}"
  tls_key_path           = "${var.tls_key_path}"
  route53_zone_id        = "${data.aws_route53_zone.main.zone_id}"
  route53_zone           = "${var.route53_zone}"
  owner                  = "${var.owner}"
  ttl                    = "${var.ttl}"
}

#------------------------------------------------------------------------------
# production mounted disk ptfe 
#------------------------------------------------------------------------------

#module "pmd" {
#  source                 = "pmd/"
#  namespace              = "${var.namespace}"
#  aws_instance_ami       = "${var.aws_instance_ami}"
#  aws_instance_type      = "${var.aws_instance_type}"
#  subnet_id              = "${module.network.public_subnet_ids[0]}"
#  vpc_security_group_ids = "${module.network.security_group_id}"
#  ssh_key_name           = "${var.ssh_key_name}"
#  ssh_key_path           = "${var.ssh_key_path}"
#  license_path           = "${var.license_path}"
#  tls_cert_path          = "${var.tls_cert_path}"
#  tls_key_path           = "${var.tls_key_path}"
#  route53_zone_id        = "${data.aws_route53_zone.main.zone_id}"
#  route53_zone           = "${var.route53_zone}"
#  owner                  = "${var.owner}"
#  ttl                    = "${var.ttl}"
#}

#------------------------------------------------------------------------------
# production external-services ptfe 
#------------------------------------------------------------------------------

#module "pes" {
#  source                 = "pes/"
#  namespace              = "${var.namespace}"
#  aws_instance_ami       = "${var.aws_instance_ami}"
#  aws_instance_type      = "${var.aws_instance_type}"
#  subnet_ids             = "${module.network.public_subnet_ids}"
#  vpc_security_group_ids = "${module.network.security_group_id}"
#  ssh_key_name           = "${var.ssh_key_name}"
#  ssh_key_path           = "${var.ssh_key_path}"
#  license_path           = "${var.license_path}"
#  tls_cert_path          = "${var.tls_cert_path}"
#  tls_key_path           = "${var.tls_key_path}"
#  route53_zone_id        = "${data.aws_route53_zone.main.zone_id}"
#  route53_zone           = "${var.route53_zone}"
#  database_pwd           = "${random_pet.replicated-pwd.id}"
#  db_subnet_group_name   = "${module.network.db_subnet_group_id}"
#  owner                  = "${var.owner}"
#  ttl                    = "${var.ttl}"
#}
