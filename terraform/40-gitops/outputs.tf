output "argocd_namespace" {
  description = "Namespace Argo CD is installed into."
  value       = helm_release.argocd.namespace
}

output "flux_namespace" {
  description = "Namespace Flux is installed into."
  value       = helm_release.flux.namespace
}

output "gitops_repo_url" {
  description = "Git repository both controllers reconcile from."
  value       = var.gitops_repo_url
}
