// Single ops Action Group: alerts AND budget notifications fan out here.
// Threshold/severity start deliberately conservative so wiring is verifiable
// on day 1 (mirrors the miniclip "low billing alarm" approach).
resource "azurerm_monitor_action_group" "ops" {
  name                = "${local.name}-ag-ops"
  resource_group_name = local.obs_rg
  short_name          = "llmops"

  email_receiver {
    name          = "oncall"
    email_address = var.alert_email
  }

  tags = local.tags
}

// Managed-Prometheus rule group: LLM-shaped recording + alerting rules sitting
// directly on the Azure Monitor workspace. Expressions assume vLLM/DCGM
// exporters scraped by managed Prometheus (deployed via GitOps).
resource "azurerm_monitor_alert_prometheus_rule_group" "llm" {
  name                = "${local.name}-prom-llm"
  location            = local.location
  resource_group_name = local.obs_rg
  cluster_name        = local.aks.cluster_name
  scopes              = [local.amw_id]
  rule_group_enabled  = true
  interval            = "PT1M"

  // Recording rule: fleet GPU utilisation (DCGM).
  rule {
    record     = "job:gpu_utilization:avg"
    expression = "avg(DCGM_FI_DEV_GPU_UTIL)"
  }

  // Recording rule: request latency p95 from vLLM histogram.
  rule {
    record     = "job:llm_request_latency:p95"
    expression = "histogram_quantile(0.95, sum(rate(vllm_request_latency_seconds_bucket[5m])) by (le))"
  }

  // Alert: GPU saturated -> autoscaler should add a node; page if sustained.
  rule {
    alert      = "GPUSaturated"
    expression = "job:gpu_utilization:avg > 90"
    for        = "PT15M"
    severity   = 3
    action {
      action_group_id = azurerm_monitor_action_group.ops.id
    }
    annotations = {
      summary = "GPU utilisation > 90% for 15m — serving may be queueing."
    }
  }

  // Alert: tail latency breach (user-facing SLO).
  rule {
    alert      = "LLMLatencyHigh"
    expression = "job:llm_request_latency:p95 > 5"
    for        = "PT10M"
    severity   = 2
    action {
      action_group_id = azurerm_monitor_action_group.ops.id
    }
    annotations = {
      summary = "p95 inference latency > 5s for 10m."
    }
  }

  // Alert: GPU pool idle but nodes still up -> scale-to-zero not engaging.
  rule {
    alert      = "GPUIdleButProvisioned"
    expression = "count(DCGM_FI_DEV_GPU_UTIL) > 0 and avg(DCGM_FI_DEV_GPU_UTIL) < 2"
    for        = "PT30M"
    severity   = 3
    action {
      action_group_id = azurerm_monitor_action_group.ops.id
    }
    annotations = {
      summary = "GPU nodes provisioned but idle 30m — check scale-to-zero / KEDA."
    }
  }
}

// AKS control-plane logs + metrics to Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-to-law"
  target_resource_id         = local.aks.cluster_id
  log_analytics_workspace_id = local.law_id

  enabled_log {
    category = "kube-apiserver"
  }
  enabled_log {
    category = "kube-controller-manager"
  }
  enabled_log {
    category = "cluster-autoscaler"
  }
  enabled_log {
    category = "guard"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
