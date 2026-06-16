// Least-privilege data-plane grants on KV + ACR for the workload identities.
// Cluster kubelet AcrPull is granted in 30-aks (it owns the kubelet identity).

resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = toset(["workload", "external_secret"])
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this[each.key].principal_id
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each             = toset(["workload", "gitops"])
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this[each.key].principal_id
}
