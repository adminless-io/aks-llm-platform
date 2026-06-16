// --- Backbone vars (declared in every layer; fed from terraform.tfvars) ---
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

// --- Layer-specific ------------------------------------------------------
variable "vnet_cidr" {
  description = "Address space for the platform VNet."
  type        = string
  default     = "10.42.0.0/16"
}
