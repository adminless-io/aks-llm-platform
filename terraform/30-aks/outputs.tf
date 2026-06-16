output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.main.name
}

output "node_resource_group" {
  description = "AKS-managed node resource group (MC_*)."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "oidc_issuer_url" {
  description = "Cluster OIDC issuer URL (Workload Identity)."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (Container Insights)."
  value       = azurerm_log_analytics_workspace.main.id
}

output "monitor_workspace_id" {
  description = "Azure Monitor workspace ID (managed Prometheus)."
  value       = azurerm_monitor_workspace.prometheus.id
}

// Sensitive: used by 40-gitops kubernetes/helm providers via exec auth.
output "host" {
  description = "AKS API server host."
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA cert (base64) for provider config."
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}
