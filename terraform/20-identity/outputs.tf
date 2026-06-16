output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault DNS URI (resolves to the private endpoint in-cluster)."
  value       = azurerm_key_vault.main.vault_uri
}

output "acr_id" {
  description = "Container Registry resource ID."
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "ACR login server FQDN."
  value       = azurerm_container_registry.main.login_server
}

// Map of role -> identity facts consumed by 30-aks (federation) and the GitOps
// manifests (serviceaccount annotations) in 40/60.
output "workload_identities" {
  description = "Map of role -> { client_id, principal_id, id, namespace, service_account }."
  value = {
    for k, v in local.workload_identities : k => {
      client_id       = azurerm_user_assigned_identity.this[k].client_id
      principal_id    = azurerm_user_assigned_identity.this[k].principal_id
      id              = azurerm_user_assigned_identity.this[k].id
      namespace       = v.ns
      service_account = v.sa
    }
  }
}
