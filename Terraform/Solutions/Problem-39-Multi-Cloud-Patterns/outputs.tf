output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "all_networks" {
  description = "All cloud networks"
  value       = local.all_networks
}

output "all_storage" {
  description = "All cloud storage"
  value       = local.all_storage
}
