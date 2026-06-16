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

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool (control-plane addons only)."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_vm_size" {
  description = "VM size for the CPU user pool (GitOps, observability, APIs)."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "gpu_node_vm_size" {
  description = "VM size for the GPU pool serving the LLM."
  type        = string
  default     = "Standard_NC24ads_A100_v4"
}

variable "gpu_node_min_count" {
  description = "Min GPU nodes. 0 = scale-to-zero when no model pods are scheduled."
  type        = number
  default     = 0
}

variable "gpu_node_max_count" {
  description = "Max GPU nodes the autoscaler may add."
  type        = number
  default     = 3
}

variable "gpu_node_priority" {
  description = "GPU pool priority. Spot = cheap/evictable (scale-to-zero); Regular = guaranteed capacity (e.g. a fixed 6x H100 fleet)."
  type        = string
  default     = "Spot"
  validation {
    condition     = contains(["Spot", "Regular"], var.gpu_node_priority)
    error_message = "gpu_node_priority must be \"Spot\" or \"Regular\"."
  }
}

variable "gpu_spot_max_price" {
  description = "Max hourly price for Spot GPU nodes. -1 = pay up to on-demand (no price eviction). Ignored when priority = Regular."
  type        = number
  default     = -1
}

variable "gpu_node_zones" {
  description = "Availability zones for the GPU pool. H100 SKUs are often single-zone; set e.g. [\"1\"] when AKS rejects [1,2,3]."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "gpu_capacity_reservation_group_id" {
  description = "Optional Capacity Reservation Group ID to pin guaranteed H100 capacity (Regular pools). null = none."
  type        = string
  default     = null
  nullable    = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}
