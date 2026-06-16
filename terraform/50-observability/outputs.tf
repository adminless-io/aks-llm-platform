output "grafana_endpoint" {
  description = "Managed Grafana endpoint URL."
  value       = azurerm_dashboard_grafana.main.endpoint
}

output "grafana_id" {
  description = "Managed Grafana resource ID."
  value       = azurerm_dashboard_grafana.main.id
}

output "action_group_id" {
  description = "Ops Action Group ID (reused by 60 for LLM-specific alerts)."
  value       = azurerm_monitor_action_group.ops.id
}
