terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }
  // Partial config — resource_group_name / storage_account_name /
  // container_name / key supplied at init time (see scripts/apply.sh).
  backend "azurerm" {}
}
