// RBAC-authorized Key Vault. Public access off — reachable only via the private
// endpoint below. Secrets are read at runtime by workloads through Workload
// Identity (Key Vault Secrets User), never baked into manifests or state.
resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = local.location
  resource_group_name        = local.rg
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.tags
}

// Let the deploying principal manage secrets through the PE / portal.
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
