provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}
}

// AKS is a PRIVATE cluster: these providers must reach the API server from
// inside the VNet (self-hosted CI agent / jumpbox / `az aks command invoke`),
// or via API Server VNet Integration. exec auth uses kubelogin against AAD.
provider "kubernetes" {
  host                   = local.aks.host
  cluster_ca_certificate = base64decode(local.aks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token", "--login", "azurecli",
      "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", // AKS AAD server app
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = local.aks.host
    cluster_ca_certificate = base64decode(local.aks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token", "--login", "azurecli",
        "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630",
      ]
    }
  }
}

provider "kubectl" {
  host                   = local.aks.host
  cluster_ca_certificate = base64decode(local.aks.cluster_ca_certificate)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token", "--login", "azurecli",
      "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630",
    ]
  }
}
