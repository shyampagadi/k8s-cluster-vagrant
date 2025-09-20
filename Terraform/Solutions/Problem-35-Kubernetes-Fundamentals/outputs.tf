# Problem 35: Kubernetes Fundamentals - Outputs

output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.apps.metadata[0].name
}

output "web_app_service_name" {
  description = "Name of the web application service"
  value       = kubernetes_service.web_app.metadata[0].name
}

output "web_app_service_cluster_ip" {
  description = "Cluster IP of the web application service"
  value       = kubernetes_service.web_app.spec[0].cluster_ip
}

output "api_app_service_name" {
  description = "Name of the API application service"
  value       = kubernetes_service.api_app.metadata[0].name
}

output "api_app_service_cluster_ip" {
  description = "Cluster IP of the API application service"
  value       = kubernetes_service.api_app.spec[0].cluster_ip
}

output "database_service_name" {
  description = "Name of the database service"
  value       = kubernetes_service.database.metadata[0].name
}

output "database_service_cluster_ip" {
  description = "Cluster IP of the database service"
  value       = kubernetes_service.database.spec[0].cluster_ip
}

output "ingress_name" {
  description = "Name of the ingress resource"
  value       = kubernetes_ingress_v1.web_app.metadata[0].name
}

output "configmap_name" {
  description = "Name of the application ConfigMap"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "secret_name" {
  description = "Name of the application Secret"
  value       = kubernetes_secret.app_secrets.metadata[0].name
}

output "persistent_volume_name" {
  description = "Name of the persistent volume"
  value       = kubernetes_persistent_volume.database_pv.metadata[0].name
}

output "persistent_volume_claim_name" {
  description = "Name of the persistent volume claim"
  value       = kubernetes_persistent_volume_claim.database_pvc.metadata[0].name
}

output "network_policy_name" {
  description = "Name of the network policy"
  value       = kubernetes_network_policy.app_network_policy.metadata[0].name
}

output "hpa_web_app_name" {
  description = "Name of the web app HPA"
  value       = kubernetes_horizontal_pod_autoscaler_v2.web_app.metadata[0].name
}

output "hpa_api_app_name" {
  description = "Name of the API app HPA"
  value       = kubernetes_horizontal_pod_autoscaler_v2.api_app.metadata[0].name
}

output "job_name" {
  description = "Name of the database migration job"
  value       = kubernetes_job_v1.db_migration.metadata[0].name
}

output "cronjob_name" {
  description = "Name of the backup CronJob"
  value       = kubernetes_cron_job_v1.backup.metadata[0].name
}

output "service_account_name" {
  description = "Name of the application service account"
  value       = kubernetes_service_account.app_service_account.metadata[0].name
}

output "role_name" {
  description = "Name of the application role"
  value       = kubernetes_role.app_role.metadata[0].name
}

output "role_binding_name" {
  description = "Name of the application role binding"
  value       = kubernetes_role_binding.app_role_binding.metadata[0].name
}
