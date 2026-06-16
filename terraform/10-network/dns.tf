// Private DNS zones for the private endpoints created in 20-identity (ACR,
// Key Vault, Blob). Linked to the VNet so in-cluster lookups resolve to the
// PE private IPs instead of public endpoints.
locals {
  private_dns_zones = {
    acr  = "privatelink.azurecr.io"
    kv   = "privatelink.vaultcore.azure.net"
    blob = "privatelink.blob.core.windows.net"
    aml  = "privatelink.api.azureml.ms" // for MLflow-on-AzureML seam
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = local.rg
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.private_dns_zones
  name                  = "${each.key}-link"
  resource_group_name   = local.rg
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}
