output "subscription_id" {
  description = "Azure subscription ID, re-exported for downstream provider config."
  value       = var.subscription_id
}

output "tenant_id" {
  description = "Azure AD tenant ID."
  value       = var.tenant_id
}

output "location" {
  description = "Primary region."
  value       = var.location
}

output "env" {
  description = "Environment short name."
  value       = var.env
}

output "name" {
  description = "Computed name stem (name_prefix-env)."
  value       = local.name
}

output "tags" {
  description = "Cost-allocation tag map inherited by every layer."
  value       = local.tags
}

output "platform_resource_group" {
  description = "RG for AKS / GitOps / LLM platform resources."
  value       = azurerm_resource_group.platform.name
}

output "network_resource_group" {
  description = "RG for VNet / NSG / private DNS."
  value       = azurerm_resource_group.network.name
}

output "observability_resource_group" {
  description = "RG for Log Analytics / managed Prometheus / Grafana."
  value       = azurerm_resource_group.observability.name
}

output "tfstate_storage_account" {
  description = "Storage Account backing remote state for all other layers."
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_resource_group" {
  description = "RG of the remote-state Storage Account."
  value       = azurerm_resource_group.tfstate.name
}

output "tfstate_container" {
  description = "Blob container for remote state."
  value       = azurerm_storage_container.tfstate.name
}
