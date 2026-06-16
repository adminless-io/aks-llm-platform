variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "location" {
  description = "Primary Azure region for all platform resources."
  type        = string
  default     = "westeurope"
}

variable "env" {
  description = "Environment short name (dev, stg, prd)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names (lowercase, no spaces)."
  type        = string
  default     = "llmops"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,10}$", var.name_prefix))
    error_message = "name_prefix must be 2-11 lowercase alphanumerics starting with a letter."
  }
}

// object/optional() pattern mirrors the miniclip tags variable. azurerm has no
// provider-level default_tags, so this is merged into local.tags and applied
// per-resource (see locals.tf).
variable "tags" {
  description = "Cost-allocation tags applied to every resource via local.tags."
  type = object({
    environment = optional(string, "dev")
    product     = optional(string, "llm-platform")
    cost_center = optional(string, "ai-consultancy")
    owner       = optional(string, "platform-team")
  })
  default = {}
}

variable "tfstate_resource_group" {
  description = "Resource group holding the remote-state Storage Account."
  type        = string
}

variable "tfstate_storage_account" {
  description = "Globally-unique Storage Account name for remote state (<=24 chars, lowercase)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.tfstate_storage_account))
    error_message = "Storage Account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "tfstate_container" {
  description = "Blob container for remote state."
  type        = string
  default     = "tfstate"
}
