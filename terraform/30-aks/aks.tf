// Private AKS cluster. Azure CNI Overlay + Cilium data plane (eBPF network
// policy enforcement — what kind cannot reproduce). Workload Identity + OIDC
// issuer on for credential-free Azure access. KEDA + VPA for event/right-size
// scaling; cluster autoscaler is configured per node pool.
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.name}-aks"
  location            = local.location
  resource_group_name = local.rg
  dns_prefix          = "${local.name}-aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${local.name}-aks-nodes-rg"
  sku_tier            = "Standard" // uptime SLA on the API server

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true
  local_account_disabled    = true

  private_cluster_enabled = true
  private_dns_zone_id     = "System"

  // System pool: tainted CriticalAddonsOnly so only system pods land here.
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = local.net.subnet_ids.system
    orchestrator_version         = var.kubernetes_version
    zones                        = ["1", "2", "3"]
    only_critical_addons_enabled = true
    auto_scaling_enabled         = true
    min_count                    = 1
    max_count                    = 3
    max_pods                     = 60
    os_sku                       = "AzureLinux"
    upgrade_settings {
      max_surge = "33%"
    }
    temporary_name_for_rotation = "systmp"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    pod_cidr            = "10.244.0.0/16"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  // Event-driven autoscaling + vertical right-sizing for FinOps.
  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  // Container Insights -> Log Analytics.
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
    msi_auth_for_monitoring_enabled = true
  }

  // Managed Prometheus -> Azure Monitor workspace (auto-creates DCR + DCRA).
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, // owned by the cluster autoscaler
      kubernetes_version,              // patch upgrades managed out-of-band
    ]
  }
}

// Bind managed Prometheus to the Azure Monitor workspace explicitly so metric
// collection targets the AMW created in monitoring.tf.
resource "azurerm_monitor_data_collection_endpoint" "prom" {
  name                = "${local.name}-dce-prom"
  location            = local.location
  resource_group_name = local.obs_rg
  kind                = "Linux"
  tags                = local.tags
}
