// Optional Azure OpenAI fallback: when the self-hosted GPU model is scaled to
// zero / evicted (Spot) or saturated, APIM can fail over to a managed AOAI
// deployment. Pay-per-token, no GPU floor — the cost/reliability hedge.
resource "azurerm_cognitive_account" "openai" {
  count                 = var.enable_azure_openai ? 1 : 0
  name                  = "${local.name}-aoai"
  location              = local.location
  resource_group_name   = local.rg
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "${local.flat_name}aoai${local.suffix}"

  public_network_access_enabled = true
  network_acls {
    default_action = "Allow" // tighten to Deny + PE for production
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_cognitive_deployment" "fallback" {
  count                = var.enable_azure_openai ? 1 : 0
  name                 = "fallback"
  cognitive_account_id = azurerm_cognitive_account.openai[0].id

  model {
    format  = "OpenAI"
    name    = var.azure_openai_deployment_model
    version = "" // pinned by Azure to the default for the model
  }

  // Standard (pay-go) over Provisioned: no reserved-capacity floor for a
  // fallback path (FinOps).
  sku {
    name = "Standard"
  }
}
