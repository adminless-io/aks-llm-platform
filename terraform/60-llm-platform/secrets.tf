// Push endpoints/keys into Key Vault so workloads consume them via Workload
// Identity (Key Vault Secrets User) — never via env vars in Git or tfvars.
// NOTE: KV public access is off, so this layer (like 40-gitops) must be applied
// from an in-VNet runner that can reach the Key Vault private endpoint.
resource "azurerm_key_vault_secret" "content_safety_endpoint" {
  name            = "content-safety-endpoint"
  value           = azurerm_cognitive_account.content_safety.endpoint
  key_vault_id    = local.key_vault_id
  content_type    = "text/uri-list"
  expiration_date = var.secret_expiration_date
  tags            = local.tags
}

resource "azurerm_key_vault_secret" "content_safety_key" {
  name            = "content-safety-key"
  value           = azurerm_cognitive_account.content_safety.primary_access_key
  key_vault_id    = local.key_vault_id
  content_type    = "application/x-api-key"
  expiration_date = var.secret_expiration_date
  tags            = local.tags
}

resource "azurerm_key_vault_secret" "aoai_endpoint" {
  count           = var.enable_azure_openai ? 1 : 0
  name            = "azure-openai-endpoint"
  value           = azurerm_cognitive_account.openai[0].endpoint
  key_vault_id    = local.key_vault_id
  content_type    = "text/uri-list"
  expiration_date = var.secret_expiration_date
  tags            = local.tags
}

resource "azurerm_key_vault_secret" "aoai_key" {
  count           = var.enable_azure_openai ? 1 : 0
  name            = "azure-openai-key"
  value           = azurerm_cognitive_account.openai[0].primary_access_key
  key_vault_id    = local.key_vault_id
  content_type    = "application/x-api-key"
  expiration_date = var.secret_expiration_date
  tags            = local.tags
}
