output "private_subnet_id" {
  value = "${module.network.private_subnet_id}"
}

output "db_connection_name" {
  value = "${module.pes.db_connection_name}"
}
