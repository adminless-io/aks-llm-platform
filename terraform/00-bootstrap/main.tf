// --- Remote-state backend storage ----------------------------------------
// Created here on a LOCAL backend, then this layer migrates its own state into
// the container (terraform init -migrate-state). All other layers point their
// azurerm backend at this account.
resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_resource_group
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.tfstate_storage_account
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "ZRS" // zone-redundant: state survives an AZ loss
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true // recover from a bad apply that corrupts state
    delete_retention_policy {
      days = 30
    }
  }

  // State holds resource IDs, not customer data, but lock it down anyway.
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.tfstate_container
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

// --- Platform resource groups --------------------------------------------
// One RG per concern keeps RBAC scoping and cost views clean. Downstream
// layers place resources into these by name (read via remote state).
resource "azurerm_resource_group" "platform" {
  name     = "${local.name}-platform-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "network" {
  name     = "${local.name}-network-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "observability" {
  name     = "${local.name}-observability-rg"
  location = var.location
  tags     = local.tags
}
