// Federate each UAMI from 20-identity against this cluster's OIDC issuer. This
// closes the Workload Identity loop deferred from 20 (the issuer URL only
// exists once the cluster is created). Pods using the annotated service account
// in the matching namespace get tokens for the identity with no secrets.
resource "azurerm_federated_identity_credential" "wi" {
  for_each            = local.ident.workload_identities
  name                = "fic-${each.key}"
  resource_group_name = local.boot.platform_resource_group
  parent_id           = each.value.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}

// Kubelet identity pulls serving images from ACR. AcrPull is granted here
// because the kubelet identity is created by the cluster.
resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                = local.ident.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
