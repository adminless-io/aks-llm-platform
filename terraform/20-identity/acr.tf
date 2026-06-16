// Premium ACR: required for private endpoints + zone redundancy. Holds the
// vLLM/KAITO serving images and any sidecars. Admin user disabled — pulls go
// through Workload Identity (AcrPull), pushes through CI federated creds.
resource "azurerm_container_registry" "main" {
  name                          = local.acr_name
  resource_group_name           = local.rg
  location                      = local.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = true

  // Keep image storage bounded — untagged manifests age out (FinOps).
  retention_policy_in_days = 14

  tags = local.tags
}
