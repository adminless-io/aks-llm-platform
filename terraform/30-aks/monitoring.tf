// Monitoring substrate created HERE because AKS references both at creation:
//   - Log Analytics workspace  -> Container Insights (oms_agent addon)
//   - Azure Monitor workspace  -> managed Prometheus (monitor_metrics block)
// 50-observability builds everything downstream of these (Grafana, dashboards,
// recording/alert rules, Action Groups) by reading their IDs from this layer.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name}-law"
  location            = local.location
  resource_group_name = local.obs_rg
  sku                 = "PerGB2018"
  retention_in_days   = 30 // FinOps: 30d hot logs; export to Storage for cold.
  tags                = local.tags
}

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "${local.name}-amw"
  location            = local.location
  resource_group_name = local.obs_rg
  tags                = local.tags
}
