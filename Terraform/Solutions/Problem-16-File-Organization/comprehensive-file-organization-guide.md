# Terraform File Organization and Project Structure - Complete Guide

## Overview

This comprehensive guide covers Terraform project organization, file structure patterns, naming conventions, and enterprise-grade project management strategies for scalable infrastructure codebases.

## Project Structure Fundamentals

### Basic Project Structure

```
terraform-project/
├── README.md                 # Project documentation
├── main.tf                   # Primary resources
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── versions.tf               # Provider versions
├── terraform.tfvars.example  # Example variables
├── .gitignore               # Git ignore rules
└── .terraform-version       # Terraform version pin
```

### Enterprise Project Structure

```
enterprise-infrastructure/
├── README.md
├── .gitignore
├── .terraform-version
├── .pre-commit-config.yaml
├── Makefile
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── networking/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── examples/
│   ├── compute/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── examples/
│   └── database/
│       ├── README.md
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── examples/
├── shared/
│   ├── data-sources.tf
│   ├── locals.tf
│   └── remote-state.tf
├── scripts/
│   ├── deploy.sh
│   ├── validate.sh
│   └── cleanup.sh
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── troubleshooting.md
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
```

## File Naming Conventions

### Standard File Names

```hcl
# Core configuration files
main.tf                 # Primary resource definitions
variables.tf            # Input variable declarations
outputs.tf              # Output value declarations
versions.tf             # Provider version constraints
locals.tf               # Local value definitions
data.tf                 # Data source definitions

# Environment-specific files
terraform.tfvars        # Variable values
backend.tf              # Backend configuration
providers.tf            # Provider configurations

# Optional organization files
networking.tf           # Network-related resources
compute.tf              # Compute-related resources
database.tf             # Database-related resources
security.tf             # Security-related resources
monitoring.tf           # Monitoring-related resources
```

### Resource-Specific Organization

```
project/
├── main.tf              # Module calls and high-level resources
├── variables.tf         # All input variables
├── outputs.tf           # All outputs
├── versions.tf          # Provider versions
├── locals.tf            # Computed values
├── data.tf              # Data sources
├── networking.tf        # VPC, subnets, routing
├── security.tf          # Security groups, NACLs
├── compute.tf           # EC2, ASG, launch templates
├── database.tf          # RDS, ElastiCache
├── storage.tf           # S3, EBS, EFS
├── monitoring.tf        # CloudWatch, alarms
├── dns.tf               # Route53 resources
└── iam.tf               # IAM roles, policies
```

## Environment Management Patterns

### Pattern 1: Environment Directories

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── modules/
    ├── app/
    ├── database/
    └── networking/
```

**Environment Configuration Example:**

```hcl
# environments/prod/main.tf
module "networking" {
  source = "../../modules/networking"
  
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  tags = local.common_tags
}

module "compute" {
  source = "../../modules/compute"
  
  environment = "prod"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  
  instance_type  = "t3.large"
  instance_count = 5
  
  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "prod"
    Project     = "web-app"
    ManagedBy   = "Terraform"
  }
}
```

```hcl
# environments/prod/terraform.tfvars
environment = "prod"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Compute
instance_type = "t3.large"
min_size = 3
max_size = 10
desired_capacity = 5

# Database
db_instance_class = "db.r5.xlarge"
db_allocated_storage = 100
backup_retention_period = 30

# Monitoring
enable_detailed_monitoring = true
log_retention_days = 90
```

### Pattern 2: Workspace-Based Organization

```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── modules/
    ├── app/
    ├── database/
    └── networking/
```

**Workspace Configuration:**

```hcl
# main.tf with workspace-aware configuration
locals {
  environment_configs = {
    dev = {
      instance_type = "t3.micro"
      instance_count = 1
      db_instance_class = "db.t3.micro"
      backup_retention = 1
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
      db_instance_class = "db.t3.small"
      backup_retention = 7
    }
    prod = {
      instance_type = "t3.large"
      instance_count = 5
      db_instance_class = "db.r5.xlarge"
      backup_retention = 30
    }
  }
  
  current_config = local.environment_configs[terraform.workspace]
}

module "app" {
  source = "./modules/app"
  
  environment    = terraform.workspace
  instance_type  = local.current_config.instance_type
  instance_count = local.current_config.instance_count
}
```

## Module Organization

### Module Structure Standards

```
modules/networking/
├── README.md           # Module documentation
├── main.tf             # Primary resources
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider requirements
├── examples/           # Usage examples
│   ├── basic/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── advanced/
│       ├── main.tf
│       └── variables.tf
├── tests/              # Module tests
│   ├── unit/
│   └── integration/
└── docs/               # Additional documentation
    ├── architecture.md
    └── troubleshooting.md
```

### Module Documentation Template

```markdown
# Networking Module

## Description
This module creates a VPC with public and private subnets, internet gateway, NAT gateways, and route tables.

## Usage

```hcl
module "networking" {
  source = "./modules/networking"
  
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "prod"
    Project     = "web-app"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| vpc_cidr | VPC CIDR block | `string` | n/a | yes |
| public_subnet_cidrs | Public subnet CIDRs | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
```

### Nested Module Structure

```
modules/
├── app-platform/           # Composite module
│   ├── README.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/            # Sub-modules
│       ├── networking/
│       ├── compute/
│       ├── database/
│       └── monitoring/
├── shared-services/        # Shared infrastructure
│   ├── dns/
│   ├── logging/
│   └── monitoring/
└── security/               # Security-focused modules
    ├── iam/
    ├── kms/
    └── security-groups/
```

## Configuration Management

### Variable Organization

```hcl
# variables.tf - Organized by category
#
# Networking Variables
#
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

#
# Compute Variables
#
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 instance type."
  }
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

#
# Database Variables
#
variable "db_config" {
  description = "Database configuration"
  type = object({
    instance_class      = string
    allocated_storage   = number
    backup_retention    = number
    multi_az           = bool
  })
  
  default = {
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    backup_retention  = 7
    multi_az         = false
  }
}

#
# Monitoring Variables
#
variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enable_detailed_monitoring = bool
    log_retention_days        = number
    alarm_email              = string
  })
  
  default = {
    enable_detailed_monitoring = false
    log_retention_days        = 30
    alarm_email              = ""
  }
}
```

### Output Organization

```hcl
# outputs.tf - Organized by category
#
# Networking Outputs
#
output "networking" {
  description = "Networking configuration"
  value = {
    vpc_id     = aws_vpc.main.id
    vpc_cidr   = aws_vpc.main.cidr_block
    
    subnets = {
      public = {
        ids   = aws_subnet.public[*].id
        cidrs = aws_subnet.public[*].cidr_block
      }
      private = {
        ids   = aws_subnet.private[*].id
        cidrs = aws_subnet.private[*].cidr_block
      }
    }
    
    gateways = {
      internet_gateway_id = aws_internet_gateway.main.id
      nat_gateway_ids     = aws_nat_gateway.main[*].id
    }
  }
}

#
# Compute Outputs
#
output "compute" {
  description = "Compute resources"
  value = {
    instances = {
      ids         = aws_instance.app[*].id
      private_ips = aws_instance.app[*].private_ip
      public_ips  = aws_instance.app[*].public_ip
    }
    
    load_balancer = {
      dns_name = aws_lb.main.dns_name
      zone_id  = aws_lb.main.zone_id
      arn      = aws_lb.main.arn
    }
    
    auto_scaling = {
      group_name = aws_autoscaling_group.app.name
      group_arn  = aws_autoscaling_group.app.arn
    }
  }
}

#
# Database Outputs
#
output "database" {
  description = "Database information"
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    
    connection_info = {
      host     = aws_db_instance.main.address
      port     = aws_db_instance.main.port
      database = aws_db_instance.main.db_name
      username = aws_db_instance.main.username
    }
  }
  
  sensitive = true
}

#
# Security Outputs
#
output "security" {
  description = "Security group information"
  value = {
    security_groups = {
      web      = aws_security_group.web.id
      app      = aws_security_group.app.id
      database = aws_security_group.database.id
    }
    
    key_pairs = {
      app = aws_key_pair.app.key_name
    }
  }
}
```

## Documentation Standards

### Project README Template

```markdown
# Infrastructure Project

## Overview
This project manages the infrastructure for [Project Name] using Terraform.

## Architecture
![Architecture Diagram](docs/architecture.png)

## Prerequisites
- Terraform >= 1.0
- AWS CLI configured
- Required permissions: [list permissions]

## Quick Start

1. Clone the repository
```bash
git clone <repository-url>
cd infrastructure
```

2. Configure variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

3. Initialize and deploy
```bash
terraform init
terraform plan
terraform apply
```

## Project Structure
```
├── environments/     # Environment-specific configurations
├── modules/         # Reusable modules
├── shared/          # Shared resources
├── scripts/         # Deployment scripts
└── docs/           # Documentation
```

## Environments
- **dev**: Development environment
- **staging**: Staging environment  
- **prod**: Production environment

## Modules
- **networking**: VPC, subnets, routing
- **compute**: EC2, Auto Scaling, Load Balancers
- **database**: RDS, ElastiCache
- **monitoring**: CloudWatch, alarms

## Deployment

### Development
```bash
cd environments/dev
terraform init
terraform apply
```

### Production
```bash
cd environments/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Monitoring
- CloudWatch dashboards: [link]
- Alarms: [link]
- Logs: [link]

## Troubleshooting
See [troubleshooting guide](docs/troubleshooting.md)

## Contributing
See [contributing guide](CONTRIBUTING.md)
```

### Module README Template

```markdown
# Module Name

## Description
Brief description of what this module does.

## Usage
```hcl
module "example" {
  source = "./modules/module-name"
  
  # Required variables
  vpc_id = "vpc-12345"
  
  # Optional variables
  instance_type = "t3.micro"
  
  tags = {
    Environment = "prod"
  }
}
```

## Examples
- [Basic Example](examples/basic/)
- [Advanced Example](examples/advanced/)

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers
| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Resources
| Name | Type |
|------|------|
| aws_instance.main | resource |
| aws_security_group.main | resource |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | VPC ID | `string` | n/a | yes |
| instance_type | Instance type | `string` | `"t3.micro"` | no |

## Outputs
| Name | Description |
|------|-------------|
| instance_id | ID of the instance |
| security_group_id | ID of the security group |

## Testing
```bash
cd tests
terraform test
```
```

## Automation and Tooling

### Makefile for Common Tasks

```makefile
# Makefile
.PHONY: help init plan apply destroy validate format lint test clean

# Default environment
ENV ?= dev

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	cd environments/$(ENV) && terraform init

plan: ## Plan Terraform changes
	cd environments/$(ENV) && terraform plan

apply: ## Apply Terraform changes
	cd environments/$(ENV) && terraform apply

destroy: ## Destroy Terraform resources
	cd environments/$(ENV) && terraform destroy

validate: ## Validate Terraform configuration
	terraform validate
	@for dir in environments/*/; do \
		echo "Validating $$dir"; \
		cd $$dir && terraform validate && cd ../..; \
	done

format: ## Format Terraform files
	terraform fmt -recursive

lint: ## Lint Terraform files
	tflint --recursive
	checkov -d .

test: ## Run tests
	cd tests && terraform test

clean: ## Clean temporary files
	find . -name ".terraform" -type d -exec rm -rf {} +
	find . -name "*.tfplan" -delete
	find . -name ".terraform.lock.hcl" -delete

docs: ## Generate documentation
	terraform-docs markdown table --output-file README.md modules/
```

### Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: checkov

  - repo: https://github.com/bridgecrewio/checkov
    rev: 2.3.228
    hooks:
      - id: checkov
        args: [--framework, terraform]
```

### Git Configuration

```gitignore
# .gitignore
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
*tfplan*

# Ignore CLI configuration files
.terraformrc
terraform.rc

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
```

## Security and Compliance

### Sensitive Data Management

```hcl
# variables.tf - Sensitive variable handling
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "api_keys" {
  description = "API keys for external services"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# Use external secret management
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### Security Scanning Configuration

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform
        output_format: sarif
        output_file_path: reports/results.sarif
        
    - name: Run TFSec
      uses: aquasecurity/tfsec-action@v1.0.0
      with:
        working_directory: .
        
    - name: Run Terrascan
      uses: accurics/terrascan-action@main
      with:
        iac_type: terraform
        iac_dir: .
```

## Best Practices Summary

### 1. Consistent Structure

```
# Use consistent file organization
main.tf          # Primary resources
variables.tf     # Input variables  
outputs.tf       # Output values
versions.tf      # Provider versions
```

### 2. Clear Naming

```hcl
# Good: Descriptive and consistent
resource "aws_instance" "web_server" { }
variable "web_server_instance_type" { }
output "web_server_public_ip" { }

# Avoid: Generic or unclear names
resource "aws_instance" "instance" { }
variable "type" { }
output "ip" { }
```

### 3. Environment Separation

```
# Separate environments clearly
environments/
├── dev/
├── staging/
└── production/
```

### 4. Module Organization

```
# Organize modules by function
modules/
├── networking/
├── compute/
├── database/
└── monitoring/
```

### 5. Documentation

```markdown
# Always include:
- README.md with usage examples
- Variable descriptions
- Output descriptions
- Architecture diagrams
- Troubleshooting guides
```

## Conclusion

Proper file organization enables:
- **Maintainability**: Easy to understand and modify
- **Scalability**: Structure grows with project complexity
- **Collaboration**: Team members can navigate easily
- **Automation**: Consistent structure enables tooling
- **Security**: Proper separation of sensitive data

Key takeaways:
- Use consistent file naming conventions
- Organize by environment and function
- Document everything thoroughly
- Implement security scanning
- Automate common tasks
- Follow established patterns
