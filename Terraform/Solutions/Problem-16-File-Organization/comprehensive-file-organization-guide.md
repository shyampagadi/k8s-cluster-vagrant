# Problem 16: Terraform File Organization and Project Structure

## Project Structure Fundamentals

### Basic Terraform Project Structure
```
terraform-project/
├── main.tf                    # Primary resource definitions
├── variables.tf               # Input variable declarations
├── outputs.tf                 # Output value declarations
├── versions.tf                # Provider version constraints
├── terraform.tfvars          # Variable values (gitignored)
├── terraform.tfvars.example  # Example variable values
├── .gitignore                # Git ignore patterns
├── README.md                 # Project documentation
└── .terraform/               # Terraform working directory (gitignored)
```

### Advanced Project Structure
```
enterprise-terraform/
├── environments/              # Environment-specific configurations
│   ├── development/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/                   # Reusable modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── ec2/
│   └── rds/
├── shared/                    # Shared configurations
│   ├── data-sources.tf
│   ├── locals.tf
│   └── providers.tf
├── scripts/                   # Automation scripts
│   ├── deploy.sh
│   ├── validate.sh
│   └── cleanup.sh
├── docs/                      # Documentation
│   ├── architecture.md
│   ├── deployment.md
│   └── troubleshooting.md
└── tests/                     # Infrastructure tests
    ├── unit/
    ├── integration/
    └── e2e/
```

## File Naming Conventions

### Standard File Names
```hcl
# main.tf - Primary resource definitions
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
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Core infrastructure resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}
```

```hcl
# variables.tf - Input variable declarations
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains([
      "development", "staging", "production"
    ], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}
```

```hcl
# outputs.tf - Output value declarations
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    vpc_id           = aws_vpc.main.id
    public_subnets   = length(aws_subnet.public)
    private_subnets  = length(aws_subnet.private)
    availability_zones = length(data.aws_availability_zones.available.names)
    environment      = var.environment
    region          = var.aws_region
  }
}
```

### Specialized File Names
```hcl
# locals.tf - Local value definitions
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  }
  
  # Environment-specific configuration
  environment_config = {
    development = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    staging = {
      instance_type = "t3.small"
      min_size     = 2
      max_size     = 4
    }
    production = {
      instance_type = "t3.medium"
      min_size     = 3
      max_size     = 10
    }
  }
  
  current_config = local.environment_config[var.environment]
}
```

```hcl
# data-sources.tf - Data source definitions
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
```

## Environment-Specific Organization

### Multi-Environment Structure
```
# environments/development/main.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state-dev"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

module "infrastructure" {
  source = "../../modules/infrastructure"
  
  environment    = "development"
  project_name   = var.project_name
  aws_region     = "us-west-2"
  
  # Development-specific overrides
  instance_type  = "t3.micro"
  instance_count = 1
  enable_backup  = false
  
  tags = {
    Environment = "development"
    CostCenter  = "engineering"
  }
}

# environments/development/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-application"
}

# environments/development/terraform.tfvars
project_name = "my-app-dev"
```

### Workspace-Based Organization
```hcl
# Single configuration with workspace logic
locals {
  environment = terraform.workspace
  
  # Workspace-specific backend configuration
  backend_configs = {
    development = {
      bucket = "terraform-state-dev"
      key    = "dev/terraform.tfstate"
    }
    staging = {
      bucket = "terraform-state-staging"
      key    = "staging/terraform.tfstate"
    }
    production = {
      bucket = "terraform-state-prod"
      key    = "prod/terraform.tfstate"
    }
  }
  
  # Environment-specific variable files
  tfvars_files = {
    development = "environments/development.tfvars"
    staging     = "environments/staging.tfvars"
    production  = "environments/production.tfvars"
  }
}
```

## Module Organization

### Module Structure Standards
```
modules/vpc/
├── main.tf                   # Primary VPC resources
├── variables.tf              # Module input variables
├── outputs.tf                # Module outputs
├── versions.tf               # Provider requirements
├── README.md                 # Module documentation
├── examples/                 # Usage examples
│   ├── basic/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── advanced/
│       ├── main.tf
│       └── variables.tf
└── tests/                    # Module tests
    ├── vpc_test.go
    └── fixtures/
```

### Module Documentation Template
```markdown
# VPC Module

## Description
This module creates a VPC with public and private subnets across multiple availability zones.

## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Environment = "production"
  }
}
```

## Requirements
- Terraform >= 1.0
- AWS Provider >= 5.0

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the VPC | string | n/a | yes |
| cidr_block | CIDR block for VPC | string | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | IDs of public subnets |
```

## Team Collaboration Patterns

### Git Repository Structure
```
.gitignore
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Secrets
secrets/
*.pem
*.key
```

### Code Review Guidelines
```hcl
# terraform.tf - Version constraints for team consistency
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
```

### Documentation Standards
```markdown
# Project Documentation Structure
docs/
├── README.md                 # Project overview
├── ARCHITECTURE.md           # System architecture
├── DEPLOYMENT.md             # Deployment procedures
├── TROUBLESHOOTING.md        # Common issues and solutions
├── CONTRIBUTING.md           # Contribution guidelines
└── CHANGELOG.md              # Version history
```

## Large-Scale Organization

### Multi-Service Architecture
```
infrastructure/
├── shared-services/          # Shared infrastructure
│   ├── networking/
│   │   ├── vpc/
│   │   ├── dns/
│   │   └── cdn/
│   ├── security/
│   │   ├── iam/
│   │   ├── kms/
│   │   └── secrets/
│   └── monitoring/
│       ├── logging/
│       ├── metrics/
│       └── alerting/
├── applications/             # Application-specific infrastructure
│   ├── web-app/
│   │   ├── compute/
│   │   ├── storage/
│   │   └── database/
│   ├── api-service/
│   └── worker-service/
└── platform/                # Platform services
    ├── ci-cd/
    ├── container-registry/
    └── service-mesh/
```

### Enterprise Governance Structure
```
terraform-enterprise/
├── governance/               # Governance and compliance
│   ├── policies/
│   │   ├── security.rego
│   │   ├── cost.rego
│   │   └── naming.rego
│   ├── standards/
│   │   ├── tagging.tf
│   │   ├── naming.tf
│   │   └── security.tf
│   └── templates/
│       ├── module-template/
│       └── project-template/
├── shared-modules/           # Organization-wide modules
│   ├── aws-vpc/
│   ├── aws-eks/
│   ├── aws-rds/
│   └── monitoring/
├── environments/             # Environment configurations
│   ├── sandbox/
│   ├── development/
│   ├── staging/
│   └── production/
└── tools/                    # Automation and tooling
    ├── scripts/
    ├── ci-cd/
    └── validation/
```

This comprehensive guide provides enterprise-ready file organization patterns for scalable Terraform projects and team collaboration.
