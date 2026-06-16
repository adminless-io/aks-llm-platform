output "vnet_id" {
  description = "Platform VNet resource ID."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Platform VNet name."
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of role -> subnet ID (system/user/gpu/apim/pe)."
  value = {
    system = azurerm_subnet.system.id
    user   = azurerm_subnet.user.id
    gpu    = azurerm_subnet.gpu.id
    apim   = azurerm_subnet.apim.id
    pe     = azurerm_subnet.pe.id
  }
}

output "private_dns_zone_ids" {
  description = "Map of role -> private DNS zone ID for private endpoints."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}
