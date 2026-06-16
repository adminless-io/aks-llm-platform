// API Management fronts the model: single OpenAI-compatible entrypoint with
// auth (subscription keys / JWT), per-key rate + token throttling, and
// multi-tenant routing across client deployments. Internal VNet integration on
// Premium keeps the gateway private; Developer is single-instance/no-SLA for
// non-prod. NOTE: APIM provisioning takes ~30-45 min.
resource "azurerm_api_management" "main" {
  name                = substr("${local.flat_name}apim${local.suffix}", 0, 50)
  location            = local.location
  resource_group_name = local.rg
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name

  identity {
    type = "SystemAssigned"
  }

  // Internal VNet integration is Premium-only; guarded so Developer still
  // applies for non-prod.
  dynamic "virtual_network_configuration" {
    for_each = startswith(var.apim_sku_name, "Premium") ? [1] : []
    content {
      subnet_id = local.net.subnet_ids.apim
    }
  }
  virtual_network_type = startswith(var.apim_sku_name, "Premium") ? "Internal" : "None"

  tags = local.tags
}

resource "azurerm_api_management_api" "llm" {
  name                  = "llm"
  resource_group_name   = local.rg
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "LLM Inference API"
  path                  = "llm"
  protocols             = ["https"]
  subscription_required = true

  service_url = var.model_backend_url
}

// Gateway-wide policy: token-aware rate limiting + Content Safety hook point.
// llm-token-limit meters prompt/completion tokens per subscription key — the
// core FinOps + multi-tenant fairness control at the edge.
resource "azurerm_api_management_api_policy" "llm" {
  api_name            = azurerm_api_management_api.llm.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = local.rg

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <rate-limit-by-key calls="600" renewal-period="60"
      counter-key="@(context.Subscription?.Key ?? "anon")" />
    <llm-token-limit counter-key="@(context.Subscription?.Key ?? "anon")"
      tokens-per-minute="50000" estimate-prompt-tokens="true"
      remaining-tokens-header-name="x-tokens-remaining" />
    <set-header name="x-tenant" exists-action="override">
      <value>@(context.Subscription?.Name ?? "default")</value>
    </set-header>
  </inbound>
  <backend><base /></backend>
  <outbound>
    <base />
    <emit-metric name="llm_tokens" value="1" namespace="llmops">
      <dimension name="tenant" value="@(context.Subscription?.Name ?? "default")" />
    </emit-metric>
  </outbound>
  <on-error><base /></on-error>
</policies>
XML
}
