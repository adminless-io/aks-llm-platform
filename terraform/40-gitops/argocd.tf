// Argo CD delivers the LLM APPLICATION stack via the app-of-apps pattern.
// (Flux owns platform/infra HelmReleases — see flux.tf for the rationale.)
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  // HA-lite: keep the controller/repo-server on the CPU user pool, never GPU.
  values = [yamlencode({
    global = {
      nodeSelector = { workload = "general" }
    }
    configs = {
      params = {
        "server.insecure" = true // TLS terminated upstream by ingress/APIM
      }
    }
    controller = { replicas = 1 }
    repoServer = { replicas = 2 }
    server = {
      replicas = 2
      service  = { type = "ClusterIP" }
    }
    applicationSet = { replicas = 1 }
    dex            = { enabled = false }
  })]
}

// Root app-of-apps: points Argo CD at the LLM application tree in Git. Every
// child Application (the model serving stack, gateways, evals) is declared
// there, so adding an app is a Git commit — not a Terraform change.
resource "kubectl_manifest" "argocd_root_app" {
  depends_on = [helm_release.argocd]
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "root"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = "${var.gitops_repo_path}/argocd/apps"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })
}
