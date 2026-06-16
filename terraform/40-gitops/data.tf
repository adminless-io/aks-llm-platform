data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "00-bootstrap.tfstate"
  }
}

data "terraform_remote_state" "identity" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "20-identity.tfstate"
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

locals {
  boot  = data.terraform_remote_state.bootstrap.outputs
  ident = data.terraform_remote_state.identity.outputs
  aks   = data.terraform_remote_state.aks.outputs

  gitops_uami = local.ident.workload_identities.gitops
}
