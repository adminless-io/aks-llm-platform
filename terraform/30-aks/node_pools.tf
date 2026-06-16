// CPU user pool: GitOps controllers, observability agents, APIs, OpenCost.
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = local.net.subnet_ids.user
  orchestrator_version  = var.kubernetes_version
  zones                 = ["1", "2", "3"]
  mode                  = "User"
  os_sku                = "AzureLinux"
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 6
  max_pods              = 60

  node_labels = {
    "workload" = "general"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

// GPU pool: Spot + scale-to-zero. Tainted sku=gpu:NoSchedule so only LLM pods
// that tolerate it land here. nvidia.com/gpu is exposed by the device plugin
// installed via GitOps (KAITO / NVIDIA GPU Operator). This is the single
// biggest cost lever — see FinOps notes in README.
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.gpu_node_vm_size
  vnet_subnet_id        = local.net.subnet_ids.gpu
  orchestrator_version  = var.kubernetes_version
  zones                 = var.gpu_node_zones
  mode                  = "User"
  os_sku                = "Ubuntu" // GPU driver image support

  auto_scaling_enabled = true
  min_count            = var.gpu_node_min_count
  max_count            = var.gpu_node_max_count
  max_pods             = 30

  // Spot = cheap + evictable (scale-to-zero); Regular = guaranteed fleet (H100).
  priority        = var.gpu_node_priority
  eviction_policy = var.gpu_node_priority == "Spot" ? "Delete" : null
  spot_max_price  = var.gpu_node_priority == "Spot" ? var.gpu_spot_max_price : null

  // Pin guaranteed H100 capacity when a reservation group is supplied (Regular).
  capacity_reservation_group_id = var.gpu_capacity_reservation_group_id

  // scalesetpriority label/taint only applies to Spot; Regular nodes omit it.
  node_labels = merge(
    {
      "workload"               = "gpu"
      "nvidia.com/gpu.present" = "true"
    },
    var.gpu_node_priority == "Spot" ? { "kubernetes.azure.com/scalesetpriority" = "spot" } : {}
  )

  node_taints = concat(
    ["sku=gpu:NoSchedule"],
    var.gpu_node_priority == "Spot" ? ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"] : []
  )

  upgrade_settings {
    max_surge = "1"
  }

  tags = merge(local.tags, {
    cost_lever = var.gpu_node_priority == "Spot" ? "gpu-spot-scale-to-zero" : "gpu-regular-guaranteed"
  })

  lifecycle {
    ignore_changes = [node_count]
  }
}
