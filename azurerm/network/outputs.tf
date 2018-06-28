output "main_rg_name" {
  value = "${azurerm_resource_group.main.name}"
}

output "main_subnet_id" {
  value = "${azurerm_subnet.main.id}"
}

output "standby_rg_name" {
  value = "${azurerm_resource_group.standby.name}"
}

output "standby_subnet_id" {
  value = "${azurerm_subnet.standby.id}"
}
