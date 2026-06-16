locals {
  // Single source of truth for naming + tags. Every downstream layer reads
  // these via terraform_remote_state instead of recomputing them.
  name = "${var.name_prefix}-${var.env}"

  tags = merge(
    {
      environment = var.tags.environment
      product     = var.tags.product
      cost_center = var.tags.cost_center
      owner       = var.tags.owner
      managed_by  = "terraform"
      layer_owner = "00-bootstrap"
    },
  )
}
