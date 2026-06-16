locals {
  // Deterministic 6-char suffix from the subscription ID keeps globally-unique
  // names (Key Vault, ACR) stable across applies without a random provider.
  suffix    = substr(sha1(var.subscription_id), 0, 6)
  flat_name = replace(local.name, "-", "")

  kv_name  = substr("${local.flat_name}kv${local.suffix}", 0, 24)
  acr_name = substr("${local.flat_name}acr${local.suffix}", 0, 50)

  // Workload-identity consumers: each maps to a (namespace, service account)
  // that 30-aks federates against the cluster OIDC issuer.
  workload_identities = {
    workload        = { ns = "llm", sa = "llm-serving" }
    external_secret = { ns = "external-secrets", sa = "external-secrets" }
    gitops          = { ns = "flux-system", sa = "kustomize-controller" }
  }
}
