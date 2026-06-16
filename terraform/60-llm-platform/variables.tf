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

variable "apim_sku_name" {
  description = "APIM SKU. Developer_1 for non-prod (no SLA); Premium_1 for VNet+prod."
  type        = string
  default     = "Developer_1"
}

variable "apim_publisher_name" {
  description = "APIM publisher (org) name."
  type        = string
  default     = "AI Consultancy Platform"
}

variable "apim_publisher_email" {
  description = "APIM publisher contact email."
  type        = string
  default     = "platform-team@example.com"
}

variable "model_backend_url" {
  description = "In-cluster OpenAI-compatible model endpoint APIM routes to."
  type        = string
  default     = "http://llm-serving.llm.svc.cluster.local:8000"
}

variable "secret_expiration_date" {
  description = "RFC3339 expiry stamped on Key Vault secrets (rotate before this)."
  type        = string
  default     = "2027-06-01T00:00:00Z"
}

variable "enable_azure_openai" {
  description = "Provision an Azure OpenAI account + deployment as a fallback model."
  type        = bool
  default     = true
}

variable "azure_openai_deployment_model" {
  description = "Azure OpenAI model for the fallback deployment."
  type        = string
  default     = "gpt-4o-mini"
}
