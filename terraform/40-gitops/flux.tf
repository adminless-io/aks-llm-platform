// Flux owns the PLATFORM/INFRASTRUCTURE layer: HelmReleases for cert-manager,
// external-secrets, OpenCost, KEDA scalers, the GPU operator / KAITO, and the
// observability agents. Flux's HelmRelease/HelmRepository model and drift
// correction fit long-lived infra; Argo CD's app-of-apps + rich UI fit app
// delivery. Running both deliberately separates "platform" from "product"
// reconciliation and blast radius. (Standardization note in README.)
resource "helm_release" "flux" {
  name             = "flux"
  namespace        = "flux-system"
  create_namespace = true
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  version          = var.flux_chart_version

  values = [yamlencode({
    # Keep Flux controllers off the GPU pool.
    imageAutomationController = { create = true }
    imageReflectionController = { create = true }
  })]
}

// Flux source = the same Git repo. infra Kustomization reconciles the
// platform tree. Workload Identity annotation for source-controller (ACR/OCI
// pulls) is applied from the gitops repo itself, not here.
resource "kubectl_manifest" "flux_gitrepository" {
  depends_on = [helm_release.flux]
  yaml_body = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata   = { name = "platform", namespace = "flux-system" }
    spec = {
      interval = "1m"
      url      = var.gitops_repo_url
      ref      = { branch = var.gitops_repo_branch }
    }
  })
}

resource "kubectl_manifest" "flux_infra_kustomization" {
  depends_on = [kubectl_manifest.flux_gitrepository]
  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata   = { name = "infrastructure", namespace = "flux-system" }
    spec = {
      interval      = "5m"
      retryInterval = "1m"
      timeout       = "5m"
      sourceRef     = { kind = "GitRepository", name = "platform" }
      path          = "./${var.gitops_repo_path}/infrastructure"
      prune         = true
      wait          = true
    }
  })
}
