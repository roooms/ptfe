output "available_zones" {
  value = "${data.google_compute_zones.main.names}"
}

output "private_subnet_id" {
  value = "${google_compute_subnetwork.private.id}"
}

output "private_subnet_self_link" {
  value = "${google_compute_subnetwork.private.self_link}"
}
