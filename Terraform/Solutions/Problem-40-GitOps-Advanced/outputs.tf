output "gitops_namespace" {
  description = "GitOps namespace"
  value       = kubernetes_namespace.gitops.metadata[0].name
}

output "argocd_status" {
  description = "ArgoCD installation status"
  value       = var.enable_argocd ? "installed" : "disabled"
}

output "flux_status" {
  description = "Flux installation status"
  value       = var.enable_flux ? "installed" : "disabled"
}
