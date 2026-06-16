// Azure AI Content Safety: input/output guardrail. The serving sidecar (or
// APIM policy) calls this to screen prompts + completions. Endpoint + key are
// pushed to Key Vault; the workload reads them via Workload Identity.
resource "azurerm_cognitive_account" "content_safety" {
  name                  = "${local.name}-contentsafety"
  location              = local.location
  resource_group_name   = local.rg
  kind                  = "ContentSafety"
  sku_name              = "S0"
  custom_subdomain_name = "${local.flat_name}cs${local.suffix}"

  // Harden to a private endpoint in prod (privatelink.cognitiveservices.azure.com).
  public_network_access_enabled = true
  network_acls {
    default_action = "Allow" // tighten to Deny + PE for production
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
