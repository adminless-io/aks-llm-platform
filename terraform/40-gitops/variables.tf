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

variable "gitops_repo_url" {
  description = "Git URL that Argo CD and Flux reconcile from."
  type        = string
}

variable "gitops_repo_branch" {
  description = "Git branch/ref to track."
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "Path within the repo holding the GitOps tree."
  type        = string
  default     = "gitops"
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version."
  type        = string
  default     = "7.7.11"
}

variable "flux_chart_version" {
  description = "flux2 (fluxcd-community) Helm chart version."
  type        = string
  default     = "2.14.1"
}
