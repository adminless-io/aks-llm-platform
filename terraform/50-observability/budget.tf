// FinOps guardrail: monthly budget on the platform RG with actual + forecast
// notifications routed to the same ops Action Group. Catches a runaway GPU bill
// (e.g. scale-to-zero broken, Spot churn) before it compounds.
resource "azurerm_consumption_budget_resource_group" "platform" {
  name              = "${local.name}-budget"
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.plat_rg}"

  amount     = var.monthly_budget_usd
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_groups = [azurerm_monitor_action_group.ops.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_groups = [azurerm_monitor_action_group.ops.id]
  }
}
