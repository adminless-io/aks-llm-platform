data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "00-bootstrap.tfstate"
  }
}

data "terraform_remote_state" "aks" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "30-aks.tfstate"
  }
}

data "azurerm_client_config" "current" {}

locals {
  boot     = data.terraform_remote_state.bootstrap.outputs
  aks      = data.terraform_remote_state.aks.outputs
  name     = local.boot.name
  location = local.boot.location
  obs_rg   = local.boot.observability_resource_group
  plat_rg  = local.boot.platform_resource_group
  tags     = merge(local.boot.tags, { layer_owner = "50-observability" })

  amw_id = local.aks.monitor_workspace_id
  law_id = local.aks.log_analytics_workspace_id
}
