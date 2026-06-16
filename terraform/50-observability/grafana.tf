// Azure Managed Grafana wired to the Azure Monitor workspace (managed
// Prometheus datasource). Dashboards for GPU / token-throughput / latency /
// cost are provisioned via GitOps (ConfigMap dashboards) so they version with
// the rest of the platform.
resource "azurerm_dashboard_grafana" "main" {
  name                              = substr("${local.name}-grafana", 0, 23)
  resource_group_name               = local.obs_rg
  location                          = local.location
  grafana_major_version             = "11"
  sku                               = "Standard"
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = local.amw_id
  }

  tags = local.tags
}

// Grafana's MSI must read metrics from the Azure Monitor workspace.
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = local.amw_id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

// Human admins.
resource "azurerm_role_assignment" "grafana_admins" {
  for_each             = toset(var.grafana_admin_object_ids)
  scope                = azurerm_dashboard_grafana.main.id
  role_definition_name = "Grafana Admin"
  principal_id         = each.value
}
