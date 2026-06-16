// Read constants exported by 00-bootstrap from the azurerm backend.
data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = var.tfstate_container
    key                  = "00-bootstrap.tfstate"
  }
}

locals {
  boot     = data.terraform_remote_state.bootstrap.outputs
  name     = local.boot.name
  location = local.boot.location
  tags     = merge(local.boot.tags, { layer_owner = "10-network" })
  rg       = local.boot.network_resource_group

  // /20 node subnets (4094 IPs each) + /24 service subnets. Pods use Azure CNI
  // Overlay (pod CIDR is off-VNet), so node subnets only size for node ENIs.
  subnets = {
    system = cidrsubnet(var.vnet_cidr, 4, 0)  # 10.42.0.0/20  AKS system pool
    user   = cidrsubnet(var.vnet_cidr, 4, 1)  # 10.42.16.0/20 CPU user pool
    gpu    = cidrsubnet(var.vnet_cidr, 4, 2)  # 10.42.32.0/20 GPU pool
    apim   = cidrsubnet(var.vnet_cidr, 8, 48) # 10.42.48.0/24 APIM VNet integ.
    pe     = cidrsubnet(var.vnet_cidr, 8, 49) # 10.42.49.0/24 private endpoints
  }
}
