output "apim_gateway_url" {
  description = "APIM gateway base URL (the LLM API entrypoint)."
  value       = azurerm_api_management.main.gateway_url
}

output "llm_api_path" {
  description = "Path suffix for the LLM API on the gateway."
  value       = azurerm_api_management_api.llm.path
}

output "content_safety_endpoint" {
  description = "Azure AI Content Safety endpoint."
  value       = azurerm_cognitive_account.content_safety.endpoint
}

output "azure_openai_endpoint" {
  description = "Azure OpenAI fallback endpoint (null when disabled)."
  value       = var.enable_azure_openai ? azurerm_cognitive_account.openai[0].endpoint : null
}
