# Provider Ecosystem Understanding - Variable Definitions

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "provider-ecosystem-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.aws_vpc_cidr, 0))
    error_message = "AWS VPC CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "aws_availability_zones" {
  description = "List of AWS availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
  
  validation {
    condition     = length(var.aws_availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

variable "aws_instance_count" {
  description = "Number of AWS instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.aws_instance_count > 0 && var.aws_instance_count <= 10
    error_message = "AWS instance count must be between 1 and 10."
  }
}

variable "aws_instance_type" {
  description = "AWS instance type"
  type        = string
  default     = "t3.micro"
}

variable "aws_assume_role_arn" {
  description = "ARN of the IAM role to assume for AWS"
  type        = string
  default     = null
}

variable "aws_endpoints" {
  description = "AWS service endpoints"
  type = object({
    s3  = optional(string)
    ec2 = optional(string)
  })
  default = null
}

# AWS Provider Aliases
variable "production_region" {
  description = "AWS region for production resources"
  type        = string
  default     = "us-east-1"
}

variable "development_region" {
  description = "AWS region for development resources"
  type        = string
  default     = "us-west-2"
}

variable "production_assume_role_arn" {
  description = "ARN of the IAM role to assume for production AWS resources"
  type        = string
  default     = null
}

variable "development_assume_role_arn" {
  description = "ARN of the IAM role to assume for development AWS resources"
  type        = string
  default     = null
}

# Azure Configuration
variable "azure_location" {
  description = "Azure location for resources"
  type        = string
  default     = "West US 2"
}

variable "azure_vnet_cidr" {
  description = "CIDR block for Azure virtual network"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.azure_vnet_cidr, 0))
    error_message = "Azure VNet CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "azure_subnet_cidrs" {
  description = "List of CIDR blocks for Azure subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
  
  validation {
    condition     = length(var.azure_subnet_cidrs) >= 2
    error_message = "At least 2 subnet CIDR blocks must be specified."
  }
}

# Azure Authentication
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}

variable "azure_client_id" {
  description = "Azure client ID"
  type        = string
  default     = null
}

variable "azure_client_secret" {
  description = "Azure client secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = null
}

# Azure Provider Aliases
variable "azure_production_subscription_id" {
  description = "Azure subscription ID for production"
  type        = string
  default     = null
}

variable "azure_production_client_id" {
  description = "Azure client ID for production"
  type        = string
  default     = null
}

variable "azure_production_client_secret" {
  description = "Azure client secret for production"
  type        = string
  default     = null
  sensitive   = true
}

variable "azure_production_tenant_id" {
  description = "Azure tenant ID for production"
  type        = string
  default     = null
}

variable "azure_development_subscription_id" {
  description = "Azure subscription ID for development"
  type        = string
  default     = null
}

variable "azure_development_client_id" {
  description = "Azure client ID for development"
  type        = string
  default     = null
}

variable "azure_development_client_secret" {
  description = "Azure client secret for development"
  type        = string
  default     = null
  sensitive   = true
}

variable "azure_development_tenant_id" {
  description = "Azure tenant ID for development"
  type        = string
  default     = null
}

# Google Cloud Configuration
variable "gcp_project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_subnet_cidrs" {
  description = "List of CIDR blocks for GCP subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
  
  validation {
    condition     = length(var.gcp_subnet_cidrs) >= 2
    error_message = "At least 2 subnet CIDR blocks must be specified."
  }
}

variable "gcp_service_account_key_path" {
  description = "Path to GCP service account key file"
  type        = string
  default     = null
}

# Google Cloud Provider Aliases
variable "gcp_production_project_id" {
  description = "Google Cloud project ID for production"
  type        = string
  default     = null
}

variable "gcp_production_region" {
  description = "Google Cloud region for production"
  type        = string
  default     = "us-east1"
}

variable "gcp_production_zone" {
  description = "Google Cloud zone for production"
  type        = string
  default     = "us-east1-a"
}

variable "gcp_development_project_id" {
  description = "Google Cloud project ID for development"
  type        = string
  default     = null
}

variable "gcp_development_region" {
  description = "Google Cloud region for development"
  type        = string
  default     = "us-central1"
}

variable "gcp_development_zone" {
  description = "Google Cloud zone for development"
  type        = string
  default     = "us-central1-a"
}

# Datadog Configuration
variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog application key"
  type        = string
  default     = null
  sensitive   = true
}

variable "datadog_api_url" {
  description = "Datadog API URL"
  type        = string
  default     = "https://api.datadoghq.com/"
}

variable "enable_datadog_monitoring" {
  description = "Enable Datadog monitoring"
  type        = bool
  default     = false
}

# GitHub Configuration
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  default     = null
  sensitive   = true
}

variable "github_base_url" {
  description = "GitHub base URL (for GitHub Enterprise)"
  type        = string
  default     = "https://api.github.com/"
}

variable "github_owner" {
  description = "GitHub owner (organization or user)"
  type        = string
  default     = null
}

variable "create_github_repo" {
  description = "Create GitHub repository"
  type        = bool
  default     = false
}

variable "github_repo_visibility" {
  description = "GitHub repository visibility"
  type        = string
  default     = "private"
  
  validation {
    condition     = contains(["public", "private", "internal"], var.github_repo_visibility)
    error_message = "GitHub repository visibility must be one of: public, private, internal."
  }
}

# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  type        = string
  default     = null
}

variable "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  default     = null
  sensitive   = true
}

variable "cluster_token" {
  description = "Kubernetes cluster token"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_kubernetes_namespace" {
  description = "Create Kubernetes namespace"
  type        = bool
  default     = false
}

# Provider Selection
variable "enable_aws_provider" {
  description = "Enable AWS provider"
  type        = bool
  default     = true
}

variable "enable_azure_provider" {
  description = "Enable Azure provider"
  type        = bool
  default     = true
}

variable "enable_gcp_provider" {
  description = "Enable Google Cloud provider"
  type        = bool
  default     = true
}

variable "enable_datadog_provider" {
  description = "Enable Datadog provider"
  type        = bool
  default     = false
}

variable "enable_github_provider" {
  description = "Enable GitHub provider"
  type        = bool
  default     = false
}

variable "enable_kubernetes_provider" {
  description = "Enable Kubernetes provider"
  type        = bool
  default     = false
}

# Additional Configuration
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_cross_provider_resources" {
  description = "Enable resources that span multiple providers"
  type        = bool
  default     = false
}
