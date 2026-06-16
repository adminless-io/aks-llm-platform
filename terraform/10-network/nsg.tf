// One NSG per node subnet. AKS manages most intra-cluster flow; these enforce
// the coarse north-south posture. APIM is the only public ingress path to the
// model (it integrates into snet-apim), so node subnets take no inbound from
// the Internet.
resource "azurerm_network_security_group" "nodes" {
  for_each            = toset(["system", "user", "gpu"])
  name                = "${local.name}-nsg-${each.key}"
  location            = local.location
  resource_group_name = local.rg
  tags                = local.tags

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "system" {
  subnet_id                 = azurerm_subnet.system.id
  network_security_group_id = azurerm_network_security_group.nodes["system"].id
}

resource "azurerm_subnet_network_security_group_association" "user" {
  subnet_id                 = azurerm_subnet.user.id
  network_security_group_id = azurerm_network_security_group.nodes["user"].id
}

resource "azurerm_subnet_network_security_group_association" "gpu" {
  subnet_id                 = azurerm_subnet.gpu.id
  network_security_group_id = azurerm_network_security_group.nodes["gpu"].id
}
