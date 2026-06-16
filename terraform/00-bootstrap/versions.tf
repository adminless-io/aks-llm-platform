terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }
  // 00-bootstrap is the ONLY layer on a local backend: it creates the Storage
  // Account that every other layer uses as its azurerm backend. After the
  // first apply, run `terraform init -migrate-state` here to push this state
  // into the bucket it just created (see README "Bootstrap" section).
}
