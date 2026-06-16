data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "00-bootstrap.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "10-network.tfstate"
  }
}

data "azurerm_client_config" "current" {}

locals {
  boot     = data.terraform_remote_state.bootstrap.outputs
  net      = data.terraform_remote_state.network.outputs
  name     = local.boot.name
  location = local.boot.location
  rg       = local.boot.platform_resource_group
  tags     = merge(local.boot.tags, { layer_owner = "20-identity" })

  pe_subnet_id = local.net.subnet_ids.pe
}
