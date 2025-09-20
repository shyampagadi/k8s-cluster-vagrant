# Problem 15: Terraform Workspaces and Environment Management

## Workspace Fundamentals

### What are Terraform Workspaces?
Workspaces allow you to manage multiple environments (dev, staging, prod) with the same Terraform configuration while maintaining separate state files.

### Basic Workspace Commands
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch between workspaces
terraform workspace select development
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace (must be empty)
terraform workspace delete development
```

## Environment-Specific Configurations

### Using terraform.workspace
```hcl
# Environment-specific variables based on workspace
locals {
  environment = terraform.workspace
  
  # Environment-specific configuration
  config = {
    development = {
      instance_type     = "t3.micro"
      instance_count    = 1
      db_instance_class = "db.t3.micro"
      backup_retention  = 1
      multi_az         = false
    }
    
    staging = {
      instance_type     = "t3.small"
      instance_count    = 2
      db_instance_class = "db.t3.small"
      backup_retention  = 7
      multi_az         = true
    }
    
    production = {
      instance_type     = "t3.medium"
      instance_count    = 3
      db_instance_class = "db.r5.large"
      backup_retention  = 30
      multi_az         = true
    }
  }
  
  # Get current environment config
  current_config = local.config[local.environment]
  
  # Common tags with workspace
  common_tags = {
    Environment = local.environment
    Workspace   = terraform.workspace
    ManagedBy   = "terraform"
  }
}

# Resources using workspace-specific configuration
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  tags = merge(local.common_tags, {
    Name = "${terraform.workspace}-web-${count.index + 1}"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${terraform.workspace}-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = local.current_config.db_instance_class
  
  allocated_storage       = 20
  backup_retention_period = local.current_config.backup_retention
  multi_az               = local.current_config.multi_az
  
  db_name  = "myapp"
  username = "admin"
  password = var.db_password
  
  tags = merge(local.common_tags, {
    Name = "${terraform.workspace}-database"
  })
}
```

### Workspace-Specific Resource Naming
```hcl
# S3 bucket with workspace prefix
resource "aws_s3_bucket" "app_data" {
  bucket = "${terraform.workspace}-${var.project_name}-app-data"
  
  tags = merge(local.common_tags, {
    Name = "${terraform.workspace} App Data"
  })
}

# VPC with workspace-specific CIDR
locals {
  vpc_cidrs = {
    development = "10.0.0.0/16"
    staging     = "10.1.0.0/16"
    production  = "10.2.0.0/16"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidrs[terraform.workspace]
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${terraform.workspace}-vpc"
  })
}
```

## Advanced Workspace Patterns

### Conditional Resource Creation
```hcl
# Create monitoring resources only in staging and production
resource "aws_cloudwatch_dashboard" "main" {
  count = contains(["staging", "production"], terraform.workspace) ? 1 : 0
  
  dashboard_name = "${terraform.workspace}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      }
    ]
  })
}

# Production-only resources
resource "aws_backup_vault" "main" {
  count = terraform.workspace == "production" ? 1 : 0
  
  name        = "${terraform.workspace}-backup-vault"
  kms_key_arn = aws_kms_key.backup[0].arn
  
  tags = local.common_tags
}

resource "aws_kms_key" "backup" {
  count = terraform.workspace == "production" ? 1 : 0
  
  description             = "Backup encryption key"
  deletion_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${terraform.workspace}-backup-key"
  })
}
```

### Workspace Validation
```hcl
# Validate workspace names
locals {
  valid_workspaces = ["development", "staging", "production"]
  
  workspace_validation = contains(local.valid_workspaces, terraform.workspace) ? null : file("ERROR: Invalid workspace '${terraform.workspace}'. Valid workspaces are: ${join(", ", local.valid_workspaces)}")
}

# Environment-specific validation
variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class      = string
    allocated_storage   = number
    backup_retention    = number
    multi_az           = bool
    deletion_protection = bool
  })
  
  validation {
    # Production databases must meet minimum requirements
    condition = terraform.workspace != "production" || (
      var.database_config.allocated_storage >= 100 &&
      var.database_config.backup_retention >= 7 &&
      var.database_config.multi_az == true &&
      var.database_config.deletion_protection == true
    )
    error_message = "Production databases must have at least 100GB storage, 7-day backup retention, multi-AZ enabled, and deletion protection enabled."
  }
}
```

This guide demonstrates comprehensive workspace management for multi-environment Terraform deployments.
