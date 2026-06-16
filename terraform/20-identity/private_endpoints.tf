// Private endpoints land NICs in snet-pe and register A-records in the private
// DNS zones created by 10-network, so in-cluster DNS resolves KV/ACR to private
// IPs with no public egress path.
resource "azurerm_private_endpoint" "kv" {
  name                = "${local.name}-pe-kv"
  location            = local.location
  resource_group_name = local.rg
  subnet_id           = local.pe_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv"
    private_dns_zone_ids = [local.net.private_dns_zone_ids.kv]
  }
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${local.name}-pe-acr"
  location            = local.location
  resource_group_name = local.rg
  subnet_id           = local.pe_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr"
    private_dns_zone_ids = [local.net.private_dns_zone_ids.acr]
  }
}
