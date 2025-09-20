# Terraform Workspaces and Environment Management - Complete Guide

## Overview

This comprehensive guide covers Terraform workspaces, environment management strategies, and production-grade deployment patterns. Workspaces enable managing multiple environments with the same configuration while maintaining isolation and consistency.

## Workspace Fundamentals

### What are Terraform Workspaces?

Workspaces are named state containers that allow you to:
- **Environment Isolation**: Separate state for different environments
- **Configuration Reuse**: Use same code for multiple environments
- **State Management**: Manage multiple deployments efficiently
- **Team Collaboration**: Enable parallel development

### Workspace Benefits

- **Cost Efficiency**: Share infrastructure code across environments
- **Consistency**: Ensure identical configurations across environments
- **Isolation**: Prevent accidental cross-environment changes
- **Scalability**: Support multiple teams and projects

## Workspace Operations

### Basic Workspace Commands

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch between workspaces
terraform workspace select development
terraform workspace select production

# Delete workspace (must be empty)
terraform workspace delete development
```

### Workspace State Management

```bash
# Each workspace has its own state file
# Default workspace: terraform.tfstate
# Named workspace: terraform.tfstate.d/workspace_name/terraform.tfstate

# View workspace state
terraform workspace select production
terraform state list

# Different state per workspace
terraform workspace select development
terraform state list  # Different resources
```

## Environment-Specific Configurations

### Workspace-Aware Variables

```hcl
# variables.tf
variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    instance_type    = string
    instance_count   = number
    enable_monitoring = bool
    backup_retention = number
  }))
  
  default = {
    development = {
      instance_type     = "t3.micro"
      instance_count    = 1
      enable_monitoring = false
      backup_retention  = 1
    }
    staging = {
      instance_type     = "t3.small"
      instance_count    = 2
      enable_monitoring = true
      backup_retention  = 7
    }
    production = {
      instance_type     = "t3.medium"
      instance_count    = 3
      enable_monitoring = true
      backup_retention  = 30
    }
  }
}

# Get current workspace configuration
locals {
  current_config = var.environment_configs[terraform.workspace]
  
  # Environment-specific naming
  name_prefix = "${terraform.workspace}-myapp"
  
  # Environment-specific tags
  common_tags = {
    Environment = terraform.workspace
    Workspace   = terraform.workspace
    ManagedBy   = "Terraform"
  }
}
```

### Workspace-Conditional Resources

```hcl
# Create resources based on workspace
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_config.instance_type
  
  monitoring = local.current_config.enable_monitoring
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
  })
}

# Production-only resources
resource "aws_db_instance" "replica" {
  count = terraform.workspace == "production" ? 1 : 0
  
  identifier             = "${local.name_prefix}-replica"
  replicate_source_db    = aws_db_instance.main.id
  instance_class         = "db.t3.small"
  
  tags = local.common_tags
}

# Development-only resources
resource "aws_instance" "debug" {
  count = terraform.workspace == "development" ? 1 : 0
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-debug"
    Type = "debug"
  })
}
```

## Advanced Workspace Patterns

### Multi-Region Workspaces

```hcl
# Multi-region workspace configuration
variable "region_configs" {
  description = "Region-specific configurations"
  type = map(object({
    region             = string
    availability_zones = list(string)
    vpc_cidr          = string
  }))
  
  default = {
    "dev-us-west-2" = {
      region             = "us-west-2"
      availability_zones = ["us-west-2a", "us-west-2b"]
      vpc_cidr          = "10.0.0.0/16"
    }
    "prod-us-east-1" = {
      region             = "us-east-1"
      availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      vpc_cidr          = "10.1.0.0/16"
    }
    "prod-eu-west-1" = {
      region             = "eu-west-1"
      availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
      vpc_cidr          = "10.2.0.0/16"
    }
  }
}

# Provider configuration based on workspace
provider "aws" {
  region = var.region_configs[terraform.workspace].region
  
  default_tags {
    tags = {
      Environment = terraform.workspace
      Region      = var.region_configs[terraform.workspace].region
    }
  }
}

# Resources using workspace-specific configuration
resource "aws_vpc" "main" {
  cidr_block = var.region_configs[terraform.workspace].vpc_cidr
  
  tags = {
    Name = "${terraform.workspace}-vpc"
  }
}
```

### Workspace Validation

```hcl
# Validate workspace names
locals {
  valid_workspaces = ["development", "staging", "production"]
  
  # Ensure workspace is valid
  workspace_validation = contains(local.valid_workspaces, terraform.workspace) ? null : file("ERROR: Invalid workspace '${terraform.workspace}'. Valid workspaces: ${join(", ", local.valid_workspaces)}")
}

# Workspace-specific validation
variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class = string
    storage_size   = number
  })
  
  validation {
    condition = terraform.workspace == "production" ? var.database_config.storage_size >= 100 : true
    error_message = "Production database must have at least 100GB storage."
  }
}
```

## Environment Management Strategies

### Strategy 1: Single Configuration with Workspaces

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

```bash
# Deploy to different environments
terraform workspace new development
terraform apply -var-file="environments/dev.tfvars"

terraform workspace new production
terraform apply -var-file="environments/prod.tfvars"
```

### Strategy 2: Directory-Based Environments

```
project/
├── modules/
│   ├── networking/
│   ├── compute/
│   └── database/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
```

### Strategy 3: Hybrid Approach

```hcl
# environments/base/main.tf
module "networking" {
  source = "../../modules/networking"
  
  environment = terraform.workspace
  vpc_cidr    = local.current_config.vpc_cidr
}

module "compute" {
  source = "../../modules/compute"
  
  environment     = terraform.workspace
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnet_ids
  instance_type   = local.current_config.instance_type
  instance_count  = local.current_config.instance_count
}

# Environment-specific overrides
module "monitoring" {
  count  = terraform.workspace == "production" ? 1 : 0
  source = "../../modules/monitoring"
  
  environment = terraform.workspace
  vpc_id      = module.networking.vpc_id
}
```

## State Backend Configuration

### Remote State with Workspaces

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    
    # Workspace-specific state paths
    workspace_key_prefix = "workspaces"
  }
}

# State file paths:
# Default workspace: infrastructure/terraform.tfstate
# Named workspace: workspaces/development/infrastructure/terraform.tfstate
```

### Workspace-Specific Backends

```hcl
# Different backends per workspace
terraform {
  backend "s3" {
    bucket = "company-terraform-state-${terraform.workspace}"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

# Or use different keys
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "${terraform.workspace}/infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/terraform.yml
name: Terraform Multi-Environment

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
        
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Terraform Init
      run: terraform init
      
    - name: Create/Select Workspace
      run: |
        terraform workspace new ${{ matrix.environment }} || true
        terraform workspace select ${{ matrix.environment }}
    
    - name: Terraform Plan
      run: terraform plan -var-file="environments/${{ matrix.environment }}.tfvars"
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && matrix.environment != 'production'
      run: terraform apply -auto-approve -var-file="environments/${{ matrix.environment }}.tfvars"
      
    - name: Terraform Apply (Production)
      if: github.ref == 'refs/heads/main' && matrix.environment == 'production'
      run: terraform apply -var-file="environments/${{ matrix.environment }}.tfvars"
      # Manual approval required for production
```

### GitLab CI Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - deploy

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_IN_AUTOMATION: "true"

.terraform_template: &terraform_template
  image: hashicorp/terraform:latest
  before_script:
    - cd ${TF_ROOT}
    - terraform init
    - terraform workspace new ${ENVIRONMENT} || true
    - terraform workspace select ${ENVIRONMENT}

validate:
  <<: *terraform_template
  stage: validate
  script:
    - terraform validate
  only:
    - merge_requests
    - main

plan_dev:
  <<: *terraform_template
  stage: plan
  variables:
    ENVIRONMENT: development
  script:
    - terraform plan -var-file="environments/dev.tfvars" -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
  only:
    - merge_requests
    - main

deploy_dev:
  <<: *terraform_template
  stage: deploy
  variables:
    ENVIRONMENT: development
  script:
    - terraform apply -auto-approve tfplan
  dependencies:
    - plan_dev
  only:
    - main

deploy_prod:
  <<: *terraform_template
  stage: deploy
  variables:
    ENVIRONMENT: production
  script:
    - terraform apply -var-file="environments/prod.tfvars"
  when: manual
  only:
    - main
```

## Workspace Security

### Access Control

```hcl
# IAM policy for workspace-specific access
data "aws_iam_policy_document" "workspace_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::terraform-state/workspaces/${terraform.workspace}/*"
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/terraform-locks"
    ]
    condition {
      test     = "StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = ["workspaces/${terraform.workspace}/*"]
    }
  }
}
```

### Environment Isolation

```hcl
# Network isolation between environments
resource "aws_vpc" "main" {
  cidr_block = local.current_config.vpc_cidr
  
  tags = {
    Name        = "${terraform.workspace}-vpc"
    Environment = terraform.workspace
  }
}

# Environment-specific security groups
resource "aws_security_group" "app" {
  name_prefix = "${terraform.workspace}-app-"
  vpc_id      = aws_vpc.main.id
  
  # Production has stricter rules
  dynamic "ingress" {
    for_each = terraform.workspace == "production" ? [] : [1]
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  }
  
  tags = {
    Name        = "${terraform.workspace}-app-sg"
    Environment = terraform.workspace
  }
}
```

## Monitoring and Observability

### Workspace Metrics

```hcl
# CloudWatch dashboard per workspace
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${terraform.workspace}-infrastructure"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web[0].id],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "${terraform.workspace} - Application Metrics"
        }
      }
    ]
  })
}

# Workspace-specific alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.current_config.enable_monitoring ? 1 : 0
  
  alarm_name          = "${terraform.workspace}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = terraform.workspace == "production" ? "70" : "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[0].id
  }
  
  alarm_actions = [aws_sns_topic.alerts[0].arn]
}
```

### Workspace Logging

```hcl
# Centralized logging with workspace tags
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${terraform.workspace}/application"
  retention_in_days = terraform.workspace == "production" ? 90 : 30
  
  tags = {
    Environment = terraform.workspace
    Workspace   = terraform.workspace
  }
}

# Log aggregation across workspaces
resource "aws_cloudwatch_log_destination" "central" {
  count = terraform.workspace == "production" ? 1 : 0
  
  name       = "central-logging"
  role_arn   = aws_iam_role.log_destination[0].arn
  target_arn = aws_kinesis_stream.logs[0].arn
}
```

## Troubleshooting Workspaces

### Common Issues

#### 1. Workspace State Conflicts

```bash
# Problem: State locked in workspace
Error: Error acquiring the state lock

# Solution: Check workspace-specific locks
terraform workspace select production
terraform force-unlock <lock-id>
```

#### 2. Resource Naming Conflicts

```hcl
# Problem: Resources with same names across workspaces
resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket"  # Conflicts across workspaces
}

# Solution: Include workspace in names
resource "aws_s3_bucket" "app" {
  bucket = "${terraform.workspace}-my-app-bucket"
}
```

#### 3. Cross-Workspace Dependencies

```bash
# Problem: Trying to reference resources from other workspaces
# This won't work - workspaces are isolated

# Solution: Use data sources or remote state
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "shared/terraform.tfstate"
    region = "us-west-2"
  }
}
```

### Debugging Workspace Issues

```bash
# Check current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Verify workspace state
terraform state list

# Check workspace-specific variables
terraform console
> terraform.workspace
> local.current_config
```

## Best Practices

### 1. Workspace Naming

```bash
# Good naming conventions
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Environment-region combinations
terraform workspace new prod-us-east-1
terraform workspace new prod-eu-west-1

# Feature branches
terraform workspace new feature-new-api
```

### 2. Configuration Management

```hcl
# Centralized configuration
locals {
  environments = {
    development = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 2
    }
    staging = {
      instance_type = "t3.small"
      min_size      = 2
      max_size      = 4
    }
    production = {
      instance_type = "t3.medium"
      min_size      = 3
      max_size      = 10
    }
  }
  
  current_env = local.environments[terraform.workspace]
}
```

### 3. State Management

```hcl
# Separate state buckets per environment
terraform {
  backend "s3" {
    bucket = "terraform-state-${terraform.workspace}"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}
```

### 4. Security Considerations

```hcl
# Environment-specific security
locals {
  security_config = {
    development = {
      allow_ssh_from = ["10.0.0.0/8"]
      enable_logging = false
    }
    production = {
      allow_ssh_from = ["10.0.1.0/24"]  # Restricted
      enable_logging = true
    }
  }
}
```

## Conclusion

Terraform workspaces enable:
- **Environment Management**: Consistent infrastructure across environments
- **State Isolation**: Separate state management per environment
- **Cost Efficiency**: Shared code with environment-specific configurations
- **Team Collaboration**: Parallel development and deployment

Key takeaways:
- Use workspaces for environment isolation
- Implement workspace-aware configurations
- Secure workspace access and state management
- Monitor and log workspace-specific resources
- Follow consistent naming conventions
- Plan for cross-workspace data sharing needs
