#!/bin/bash

cd /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions

# Create variables.tf for Problem 38
cat > Problem-38-Policy-as-Code/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "policy-demo"
}
EOF

# Create outputs.tf for Problem 38
cat > Problem-38-Policy-as-Code/outputs.tf << 'EOF'
output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.policy_recorder.name
}

output "compliance_status" {
  description = "Policy compliance status"
  value       = local.policy_compliance
}
EOF

# Create variables.tf for Problem 39
cat > Problem-39-Multi-Cloud-Patterns/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "multi-cloud"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azure_vnet_cidr" {
  description = "Azure VNet CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aws_availability_zones" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "azure_subnet_cidrs" {
  description = "Azure subnet CIDRs"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "enable_cross_cloud_connectivity" {
  description = "Enable cross-cloud connectivity"
  type        = bool
  default     = false
}
EOF

# Create outputs.tf for Problem 39
cat > Problem-39-Multi-Cloud-Patterns/outputs.tf << 'EOF'
output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "all_networks" {
  description = "All cloud networks"
  value       = local.all_networks
}

output "all_storage" {
  description = "All cloud storage"
  value       = local.all_storage
}
EOF

# Create variables.tf for Problem 40
cat > Problem-40-GitOps-Advanced/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = true
}

variable "enable_flux" {
  description = "Enable Flux"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}

variable "git_repository_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/example/demo-app"
}
EOF

# Create outputs.tf for Problem 40
cat > Problem-40-GitOps-Advanced/outputs.tf << 'EOF'
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
EOF

echo "Missing files created successfully!"
