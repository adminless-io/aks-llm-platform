// User-assigned managed identities for Workload Identity. 30-aks federates each
// against the cluster OIDC issuer; pods assume them via the annotated service
// accounts with zero stored credentials.
resource "azurerm_user_assigned_identity" "this" {
  for_each            = local.workload_identities
  name                = "${local.name}-uami-${each.key}"
  resource_group_name = local.rg
  location            = local.location
  tags                = local.tags
}
