variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "tfstate_resource_group" {
  description = "RG of the remote-state Storage Account (from 00-bootstrap)."
  type        = string
}

variable "tfstate_storage_account" {
  description = "Remote-state Storage Account name (from 00-bootstrap)."
  type        = string
}

variable "tfstate_container" {
  description = "Remote-state blob container."
  type        = string
  default     = "tfstate"
}

variable "alert_email" {
  description = "Email subscribed to the ops Action Group (alerts + budget)."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget for the platform RG (FinOps guardrail)."
  type        = number
  default     = 3000
}

variable "budget_start_date" {
  description = "Budget start date (first of a month, RFC3339). Must be <= today."
  type        = string
  default     = "2026-06-01T00:00:00Z"
}

variable "grafana_admin_object_ids" {
  description = "Azure AD object IDs granted Grafana Admin."
  type        = list(string)
  default     = []
}
