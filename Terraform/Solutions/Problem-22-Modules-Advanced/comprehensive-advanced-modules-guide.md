# Problem 22: Advanced Terraform Modules - Enterprise Patterns

## Advanced Module Architecture

### Hierarchical Module Design
```hcl
# Root module structure
module "platform" {
  source = "./modules/platform"
  
  environment = var.environment
  region      = var.aws_region
  
  # Platform-wide configuration
  platform_config = {
    vpc_cidr           = var.vpc_cidr
    availability_zones = var.availability_zones
    enable_flow_logs   = var.environment == "production"
    enable_nat_gateway = var.environment != "development"
  }
  
  tags = local.common_tags
}

module "applications" {
  source = "./modules/applications"
  
  # Dependency on platform module
  vpc_id             = module.platform.vpc_id
  private_subnet_ids = module.platform.private_subnet_ids
  public_subnet_ids  = module.platform.public_subnet_ids
  
  # Application configuration
  applications = var.applications
  
  depends_on = [module.platform]
  tags       = local.common_tags
}

module "data_services" {
  source = "./modules/data-services"
  
  # Dependencies on both platform and applications
  vpc_id                = module.platform.vpc_id
  database_subnet_ids   = module.platform.database_subnet_ids
  application_sg_ids    = module.applications.security_group_ids
  
  # Data service configuration
  databases = var.databases
  caches    = var.caches
  
  depends_on = [module.platform, module.applications]
  tags       = local.common_tags
}
```

### Module Composition Patterns
```hcl
# modules/platform/main.tf - Platform module
module "networking" {
  source = "../networking"
  
  vpc_cidr           = var.platform_config.vpc_cidr
  availability_zones = var.platform_config.availability_zones
  enable_nat_gateway = var.platform_config.enable_nat_gateway
  
  tags = var.tags
}

module "security" {
  source = "../security"
  
  vpc_id = module.networking.vpc_id
  
  security_config = {
    enable_flow_logs   = var.platform_config.enable_flow_logs
    enable_guardduty   = var.environment == "production"
    enable_config      = var.environment != "development"
  }
  
  depends_on = [module.networking]
  tags       = var.tags
}

module "monitoring" {
  source = "../monitoring"
  
  vpc_id = module.networking.vpc_id
  
  monitoring_config = {
    retention_days     = var.environment == "production" ? 90 : 30
    detailed_monitoring = var.environment == "production"
    enable_xray        = true
  }
  
  depends_on = [module.networking]
  tags       = var.tags
}

# Platform outputs
output "vpc_id" {
  description = "VPC ID from networking module"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "security_group_ids" {
  description = "Security group IDs from security module"
  value       = module.security.security_group_ids
}
```

## Advanced Module Patterns

### Dynamic Module Configuration
```hcl
# modules/applications/main.tf
# Dynamic application deployment based on configuration
locals {
  # Process application configurations
  processed_apps = {
    for app_name, app_config in var.applications : app_name => merge(app_config, {
      # Add computed values
      full_name = "${var.environment}-${app_name}"
      
      # Environment-specific overrides
      instance_count = var.environment == "production" ? app_config.instance_count : min(app_config.instance_count, 2)
      instance_type  = var.environment == "development" ? "t3.micro" : app_config.instance_type
      
      # Security settings
      enable_waf = var.environment == "production" && lookup(app_config, "public", false)
      enable_ssl = lookup(app_config, "enable_ssl", var.environment != "development")
    })
  }
  
  # Group applications by type
  web_applications = {
    for name, config in local.processed_apps : name => config
    if config.type == "web"
  }
  
  api_applications = {
    for name, config in local.processed_apps : name => config
    if config.type == "api"
  }
  
  worker_applications = {
    for name, config in local.processed_apps : name => config
    if config.type == "worker"
  }
}

# Web applications with load balancers
module "web_applications" {
  source = "../web-application"
  
  for_each = local.web_applications
  
  name           = each.key
  configuration  = each.value
  vpc_id         = var.vpc_id
  subnet_ids     = var.public_subnet_ids
  
  # Load balancer configuration
  load_balancer = {
    type               = "application"
    scheme             = "internet-facing"
    enable_waf         = each.value.enable_waf
    ssl_certificate_arn = each.value.enable_ssl ? var.ssl_certificate_arn : null
  }
  
  tags = var.tags
}

# API applications with internal load balancers
module "api_applications" {
  source = "../api-application"
  
  for_each = local.api_applications
  
  name          = each.key
  configuration = each.value
  vpc_id        = var.vpc_id
  subnet_ids    = var.private_subnet_ids
  
  # Internal load balancer
  load_balancer = {
    type   = "application"
    scheme = "internal"
  }
  
  tags = var.tags
}

# Worker applications without load balancers
module "worker_applications" {
  source = "../worker-application"
  
  for_each = local.worker_applications
  
  name          = each.key
  configuration = each.value
  vpc_id        = var.vpc_id
  subnet_ids    = var.private_subnet_ids
  
  # Queue configuration for workers
  queue_config = {
    visibility_timeout = lookup(each.value, "queue_timeout", 300)
    message_retention  = lookup(each.value, "message_retention", 1209600)
  }
  
  tags = var.tags
}
```

### Module Versioning and Registry
```hcl
# Using versioned modules from private registry
module "vpc" {
  source  = "company.terraform.io/infrastructure/vpc/aws"
  version = "~> 2.1.0"
  
  name               = "${var.project_name}-vpc"
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  database_subnets   = var.database_subnet_cidrs
  
  enable_nat_gateway = var.environment != "development"
  enable_vpn_gateway = var.enable_vpn_gateway
  enable_flow_logs   = var.environment == "production"
  
  tags = local.common_tags
}

# Using Git-based versioned modules
module "monitoring" {
  source = "git::https://github.com/company/terraform-modules.git//monitoring?ref=v3.2.1"
  
  vpc_id = module.vpc.vpc_id
  
  monitoring_config = {
    retention_days = var.environment == "production" ? 90 : 30
    alert_email    = var.alert_email
  }
  
  tags = local.common_tags
}

# Local module with version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Module Testing and Validation

### Module Testing Structure
```hcl
# modules/vpc/examples/complete/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "vpc_complete_example" {
  source = "../../"
  
  name = "vpc-complete-example"
  cidr = "10.0.0.0/16"
  
  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_flow_logs   = true
  
  tags = {
    Environment = "test"
    Example     = "complete"
  }
}

# Test outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc_complete_example.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc_complete_example.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc_complete_example.public_subnets
}
```

### Module Validation Patterns
```hcl
# modules/vpc/variables.tf with comprehensive validation
variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The CIDR block must be a valid CIDR."
  }
  
  validation {
    condition = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", var.cidr))
    error_message = "The CIDR block must use private IP ranges (10.x.x.x, 172.16-31.x.x, or 192.168.x.x)."
  }
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  
  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 6
    error_message = "The number of availability zones must be between 2 and 6."
  }
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.private_subnets) == 0 || (
      length(var.private_subnets) == length(var.azs) &&
      alltrue([for cidr in var.private_subnets : can(cidrhost(cidr, 0))])
    )
    error_message = "Private subnets must match the number of AZs and be valid CIDR blocks."
  }
}

# Module-level validation
locals {
  # Validate subnet CIDR blocks are within VPC CIDR
  private_subnets_valid = alltrue([
    for subnet in var.private_subnets :
    cidrsubnet(var.cidr, 0, 0) == var.cidr  # Ensure subnet is within VPC CIDR
  ])
  
  # Validate no overlapping subnets
  all_subnets = concat(var.private_subnets, var.public_subnets, var.database_subnets)
  no_overlapping_subnets = length(local.all_subnets) == length(toset(local.all_subnets))
  
  # Validation errors
  validation_errors = compact([
    !local.private_subnets_valid ? "Private subnets must be within VPC CIDR range" : null,
    !local.no_overlapping_subnets ? "Subnet CIDR blocks must not overlap" : null,
  ])
}

# Use validation in resources
resource "aws_vpc" "this" {
  count = length(local.validation_errors) == 0 ? 1 : 0
  
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(
    { Name = var.name },
    var.tags
  )
}

# Output validation errors if any
output "validation_errors" {
  description = "List of validation errors"
  value       = local.validation_errors
}
```

## Enterprise Module Patterns

### Multi-Environment Module Design
```hcl
# modules/application-stack/main.tf
locals {
  # Environment-specific defaults
  environment_defaults = {
    development = {
      instance_type     = "t3.micro"
      min_capacity      = 1
      max_capacity      = 2
      desired_capacity  = 1
      enable_monitoring = false
      enable_backup     = false
      storage_size      = 20
    }
    
    staging = {
      instance_type     = "t3.small"
      min_capacity      = 2
      max_capacity      = 4
      desired_capacity  = 2
      enable_monitoring = true
      enable_backup     = true
      storage_size      = 100
    }
    
    production = {
      instance_type     = "t3.medium"
      min_capacity      = 3
      max_capacity      = 10
      desired_capacity  = 5
      enable_monitoring = true
      enable_backup     = true
      storage_size      = 500
    }
  }
  
  # Merge environment defaults with user overrides
  final_config = merge(
    local.environment_defaults[var.environment],
    var.application_config
  )
}

# Application infrastructure
module "compute" {
  source = "../compute"
  
  name             = var.application_name
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  instance_type    = local.final_config.instance_type
  min_capacity     = local.final_config.min_capacity
  max_capacity     = local.final_config.max_capacity
  desired_capacity = local.final_config.desired_capacity
  
  tags = var.tags
}

module "storage" {
  source = "../storage"
  
  name         = var.application_name
  storage_size = local.final_config.storage_size
  encrypted    = var.environment == "production"
  
  tags = var.tags
}

module "monitoring" {
  count  = local.final_config.enable_monitoring ? 1 : 0
  source = "../monitoring"
  
  application_name = var.application_name
  resources = {
    compute_resources = module.compute.resource_ids
    storage_resources = module.storage.resource_ids
  }
  
  tags = var.tags
}

module "backup" {
  count  = local.final_config.enable_backup ? 1 : 0
  source = "../backup"
  
  application_name = var.application_name
  resources = {
    storage_resources = module.storage.resource_ids
  }
  
  backup_schedule = var.environment == "production" ? "daily" : "weekly"
  retention_days  = var.environment == "production" ? 30 : 7
  
  tags = var.tags
}
```

### Module Registry and Documentation
```hcl
# modules/vpc/README.md (auto-generated with terraform-docs)
# VPC Module

## Description
This module creates a VPC with public, private, and database subnets across multiple availability zones.

## Usage
```hcl
module "vpc" {
  source = "company.terraform.io/infrastructure/vpc/aws"
  version = "~> 2.1.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  
  enable_nat_gateway = true
  enable_flow_logs   = true
  
  tags = {
    Environment = "production"
  }
}
```

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers
| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Modules
No modules.

## Resources
| Name | Type |
|------|------|
| aws_vpc.this | resource |
| aws_subnet.private | resource |
| aws_subnet.public | resource |
| aws_internet_gateway.this | resource |
| aws_nat_gateway.this | resource |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all resources | `string` | n/a | yes |
| cidr | The CIDR block for the VPC | `string` | n/a | yes |
| azs | Availability zones for the VPC | `list(string)` | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| private_subnets | List of IDs of private subnets |
| public_subnets | List of IDs of public subnets |
```

This comprehensive guide demonstrates advanced module patterns for enterprise-scale Terraform deployments with proper testing, validation, and documentation practices.
