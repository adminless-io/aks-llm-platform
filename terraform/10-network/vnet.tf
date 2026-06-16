resource "azurerm_virtual_network" "main" {
  name                = "${local.name}-vnet"
  location            = local.location
  resource_group_name = local.rg
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "system" {
  name                 = "snet-aks-system"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnets.system]
}

resource "azurerm_subnet" "user" {
  name                 = "snet-aks-user"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnets.user]
}

resource "azurerm_subnet" "gpu" {
  name                 = "snet-aks-gpu"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnets.gpu]
}

resource "azurerm_subnet" "apim" {
  name                 = "snet-apim"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnets.apim]
}

// Private endpoints for ACR / Key Vault / Storage land here; disable network
// policies so the PE NICs can attach.
resource "azurerm_subnet" "pe" {
  name                              = "snet-pe"
  resource_group_name               = local.rg
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [local.subnets.pe]
  private_endpoint_network_policies = "Enabled"
}
