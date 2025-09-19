# Provider Ecosystem Understanding - Output Definitions

# Project Information
output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "resource_prefix" {
  description = "Resource prefix used for naming"
  value       = local.resource_prefix
}

# AWS Resources
output "aws_vpc_id" {
  description = "ID of the AWS VPC"
  value       = var.enable_aws_provider ? aws_vpc.main.id : null
}

output "aws_vpc_cidr_block" {
  description = "CIDR block of the AWS VPC"
  value       = var.enable_aws_provider ? aws_vpc.main.cidr_block : null
}

output "aws_subnet_ids" {
  description = "IDs of the AWS subnets"
  value       = var.enable_aws_provider ? aws_subnet.public[*].id : []
}

output "aws_subnet_cidrs" {
  description = "CIDR blocks of the AWS subnets"
  value       = var.enable_aws_provider ? aws_subnet.public[*].cidr_block : []
}

output "aws_security_group_id" {
  description = "ID of the AWS security group"
  value       = var.enable_aws_provider ? aws_security_group.web.id : null
}

output "aws_instance_ids" {
  description = "IDs of the AWS instances"
  value       = var.enable_aws_provider ? aws_instance.web[*].id : []
}

output "aws_instance_public_ips" {
  description = "Public IP addresses of the AWS instances"
  value       = var.enable_aws_provider ? aws_instance.web[*].public_ip : []
}

output "aws_instance_private_ips" {
  description = "Private IP addresses of the AWS instances"
  value       = var.enable_aws_provider ? aws_instance.web[*].private_ip : []
}

output "aws_s3_bucket_id" {
  description = "ID of the AWS S3 bucket"
  value       = var.enable_aws_provider ? aws_s3_bucket.main.id : null
}

output "aws_s3_bucket_arn" {
  description = "ARN of the AWS S3 bucket"
  value       = var.enable_aws_provider ? aws_s3_bucket.main.arn : null
}

# Azure Resources
output "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  value       = var.enable_azure_provider ? azurerm_resource_group.main.name : null
}

output "azure_resource_group_location" {
  description = "Location of the Azure resource group"
  value       = var.enable_azure_provider ? azurerm_resource_group.main.location : null
}

output "azure_vnet_id" {
  description = "ID of the Azure virtual network"
  value       = var.enable_azure_provider ? azurerm_virtual_network.main.id : null
}

output "azure_vnet_address_space" {
  description = "Address space of the Azure virtual network"
  value       = var.enable_azure_provider ? azurerm_virtual_network.main.address_space : []
}

output "azure_subnet_ids" {
  description = "IDs of the Azure subnets"
  value       = var.enable_azure_provider ? azurerm_subnet.public[*].id : []
}

output "azure_subnet_address_prefixes" {
  description = "Address prefixes of the Azure subnets"
  value       = var.enable_azure_provider ? azurerm_subnet.public[*].address_prefixes : []
}

output "azure_network_security_group_id" {
  description = "ID of the Azure network security group"
  value       = var.enable_azure_provider ? azurerm_network_security_group.web.id : null
}

output "azure_storage_account_name" {
  description = "Name of the Azure storage account"
  value       = var.enable_azure_provider ? azurerm_storage_account.main.name : null
}

output "azure_storage_account_id" {
  description = "ID of the Azure storage account"
  value       = var.enable_azure_provider ? azurerm_storage_account.main.id : null
}

# Google Cloud Resources
output "gcp_network_id" {
  description = "ID of the GCP network"
  value       = var.enable_gcp_provider ? google_compute_network.main.id : null
}

output "gcp_network_name" {
  description = "Name of the GCP network"
  value       = var.enable_gcp_provider ? google_compute_network.main.name : null
}

output "gcp_subnet_ids" {
  description = "IDs of the GCP subnets"
  value       = var.enable_gcp_provider ? google_compute_subnetwork.public[*].id : []
}

output "gcp_subnet_cidrs" {
  description = "CIDR blocks of the GCP subnets"
  value       = var.enable_gcp_provider ? google_compute_subnetwork.public[*].ip_cidr_range : []
}

output "gcp_firewall_id" {
  description = "ID of the GCP firewall"
  value       = var.enable_gcp_provider ? google_compute_firewall.web.id : null
}

output "gcp_storage_bucket_name" {
  description = "Name of the GCP storage bucket"
  value       = var.enable_gcp_provider ? google_storage_bucket.main.name : null
}

output "gcp_storage_bucket_url" {
  description = "URL of the GCP storage bucket"
  value       = var.enable_gcp_provider ? google_storage_bucket.main.url : null
}

# Datadog Resources
output "datadog_monitor_ids" {
  description = "IDs of the Datadog monitors"
  value       = var.enable_datadog_monitoring ? [datadog_monitor.aws_cpu[0].id, datadog_monitor.azure_cpu[0].id] : []
}

output "datadog_monitor_names" {
  description = "Names of the Datadog monitors"
  value       = var.enable_datadog_monitoring ? [datadog_monitor.aws_cpu[0].name, datadog_monitor.azure_cpu[0].name] : []
}

# GitHub Resources
output "github_repository_name" {
  description = "Name of the GitHub repository"
  value       = var.create_github_repo ? github_repository.main[0].name : null
}

output "github_repository_url" {
  description = "URL of the GitHub repository"
  value       = var.create_github_repo ? github_repository.main[0].html_url : null
}

output "github_repository_clone_url" {
  description = "Clone URL of the GitHub repository"
  value       = var.create_github_repo ? github_repository.main[0].clone_url : null
}

# Kubernetes Resources
output "kubernetes_namespace_name" {
  description = "Name of the Kubernetes namespace"
  value       = var.create_kubernetes_namespace ? kubernetes_namespace.main[0].metadata[0].name : null
}

output "kubernetes_config_map_name" {
  description = "Name of the Kubernetes config map"
  value       = var.create_kubernetes_namespace ? kubernetes_config_map.main[0].metadata[0].name : null
}

# Provider Information
output "enabled_providers" {
  description = "List of enabled providers"
  value = {
    aws         = var.enable_aws_provider
    azure       = var.enable_azure_provider
    gcp         = var.enable_gcp_provider
    datadog     = var.enable_datadog_provider
    github      = var.enable_github_provider
    kubernetes  = var.enable_kubernetes_provider
  }
}

output "provider_regions" {
  description = "Regions used by each provider"
  value = {
    aws   = var.enable_aws_provider ? var.aws_region : null
    azure = var.enable_azure_provider ? var.azure_location : null
    gcp   = var.enable_gcp_provider ? var.gcp_region : null
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    project_name = var.project_name
    environment = var.environment
    resource_prefix = local.resource_prefix
    
    aws_resources = var.enable_aws_provider ? {
      vpc_id = aws_vpc.main.id
      subnet_count = length(aws_subnet.public)
      instance_count = length(aws_instance.web)
      bucket_name = aws_s3_bucket.main.id
    } : null
    
    azure_resources = var.enable_azure_provider ? {
      resource_group = azurerm_resource_group.main.name
      vnet_id = azurerm_virtual_network.main.id
      subnet_count = length(azurerm_subnet.public)
      storage_account = azurerm_storage_account.main.name
    } : null
    
    gcp_resources = var.enable_gcp_provider ? {
      network_id = google_compute_network.main.id
      subnet_count = length(google_compute_subnetwork.public)
      bucket_name = google_storage_bucket.main.name
    } : null
    
    monitoring_resources = var.enable_datadog_monitoring ? {
      monitor_count = 2
      monitors = [datadog_monitor.aws_cpu[0].name, datadog_monitor.azure_cpu[0].name]
    } : null
    
    github_resources = var.create_github_repo ? {
      repository_name = github_repository.main[0].name
      repository_url = github_repository.main[0].html_url
    } : null
    
    kubernetes_resources = var.create_kubernetes_namespace ? {
      namespace = kubernetes_namespace.main[0].metadata[0].name
      config_map = kubernetes_config_map.main[0].metadata[0].name
    } : null
  }
}

# Cross-Provider Information
output "cross_provider_networks" {
  description = "Network information across all providers"
  value = {
    aws_vpc_cidr = var.enable_aws_provider ? aws_vpc.main.cidr_block : null
    azure_vnet_cidr = var.enable_azure_provider ? azurerm_virtual_network.main.address_space[0] : null
    gcp_network_cidr = var.enable_gcp_provider ? "auto" : null
  }
}

output "cross_provider_storage" {
  description = "Storage information across all providers"
  value = {
    aws_s3_bucket = var.enable_aws_provider ? aws_s3_bucket.main.id : null
    azure_storage_account = var.enable_azure_provider ? azurerm_storage_account.main.name : null
    gcp_storage_bucket = var.enable_gcp_provider ? google_storage_bucket.main.name : null
  }
}

# Provider Authentication Status
output "authentication_status" {
  description = "Authentication status for each provider"
  value = {
    aws_authenticated = var.enable_aws_provider ? "configured" : "disabled"
    azure_authenticated = var.enable_azure_provider ? "configured" : "disabled"
    gcp_authenticated = var.enable_gcp_provider ? "configured" : "disabled"
    datadog_authenticated = var.enable_datadog_provider ? "configured" : "disabled"
    github_authenticated = var.enable_github_provider ? "configured" : "disabled"
    kubernetes_authenticated = var.enable_kubernetes_provider ? "configured" : "disabled"
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Provider Ecosystem Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Enabled Providers:
  - AWS: %s
  - Azure: %s
  - Google Cloud: %s
  - Datadog: %s
  - GitHub: %s
  - Kubernetes: %s
  
  Next Steps:
  1. Verify resources in each cloud provider console
  2. Test cross-provider connectivity
  3. Configure monitoring and alerting
  4. Set up CI/CD pipelines
  5. Implement backup and disaster recovery
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  var.enable_aws_provider ? "✓" : "✗",
  var.enable_azure_provider ? "✓" : "✗",
  var.enable_gcp_provider ? "✓" : "✗",
  var.enable_datadog_provider ? "✓" : "✗",
  var.enable_github_provider ? "✓" : "✗",
  var.enable_kubernetes_provider ? "✓" : "✗"
  )
}
