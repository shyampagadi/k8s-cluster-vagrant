# Problem 15: Workspaces and Environment Management

## Overview

This solution provides comprehensive understanding of Terraform workspaces and environment management, focusing on workspace strategies, environment isolation, and production-grade environment management. These are essential for creating scalable, maintainable, and secure infrastructure deployments across multiple environments.

## Learning Objectives

- Understand Terraform workspace concepts and purposes
- Master workspace creation and management
- Learn environment isolation strategies
- Understand workspace-specific configurations
- Master advanced workspace patterns and scenarios
- Learn production-grade environment management
- Understand troubleshooting workspace issues

## Problem Statement

You've mastered lifecycle rules and resource management. Now your team lead wants you to become proficient in Terraform workspaces and environment management, focusing on workspace strategies, environment isolation, and production-grade environment management. You need to understand how to create scalable, maintainable, and secure infrastructure deployments across multiple environments.

## Solution Components

This solution includes:
1. **Workspace Fundamentals** - Understanding what workspaces are and why they're important
2. **Workspace Management** - Creating, switching, and managing workspaces
3. **Environment Isolation** - Strategies for isolating environments
4. **Workspace-Specific Configurations** - Environment-specific resource configurations
5. **Advanced Workspace Patterns** - Complex workspace scenarios
6. **Production Strategies** - Production-grade environment management
7. **Best Practices** - When and how to use workspaces effectively

## Implementation Guide

### Step 1: Understanding Workspace Fundamentals

#### What are Terraform Workspaces?
Terraform workspaces are named state containers that allow you to manage multiple environments with the same configuration. They serve several purposes:
- **Environment Isolation**: Separate state for different environments
- **Configuration Reuse**: Use the same configuration for multiple environments
- **State Management**: Manage multiple state files efficiently
- **Deployment Flexibility**: Deploy to different environments easily

#### Workspace Benefits
- **Environment Isolation**: Separate state for dev/staging/prod
- **Configuration Reuse**: Single configuration for multiple environments
- **State Management**: Efficient state file management
- **Deployment Flexibility**: Easy environment switching

### Step 2: Workspace Management

#### Basic Workspace Operations
```hcl
# Workspace management commands
# terraform workspace list          # List all workspaces
# terraform workspace new dev      # Create new workspace
# terraform workspace select dev   # Switch to workspace
# terraform workspace show         # Show current workspace
# terraform workspace delete dev   # Delete workspace

# Workspace-aware configuration
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  
  tags = {
    Name = "web-instance-${terraform.workspace}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}

# Workspace-specific resource naming
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${terraform.workspace}-bucket"
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-bucket"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}
```

#### Advanced Workspace Management
```hcl
# Advanced workspace management with locals
locals {
  # Workspace-specific configurations
  workspace_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = false
      enable_encryption = false
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_encryption = true
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_encryption = true
    }
  }
  
  # Current workspace configuration
  current_config = local.workspace_config[terraform.workspace]
  
  # Workspace-specific resource naming
  resource_prefix = "${var.project_name}-${terraform.workspace}"
}

# Use workspace-specific configuration
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = var.ami_id
  instance_type = local.current_config.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  monitoring = local.current_config.enable_monitoring
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    InstanceType = local.current_config.instance_type
  }
}
```

### Step 3: Environment Isolation

#### Basic Environment Isolation
```hcl
# Environment isolation with workspaces
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-vpc"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-public-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-private-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}
```

#### Advanced Environment Isolation
```hcl
# Advanced environment isolation with workspace-specific configurations
locals {
  # Workspace-specific CIDR blocks
  workspace_cidrs = {
    dev = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod = "10.2.0.0/16"
  }
  
  # Workspace-specific availability zones
  workspace_azs = {
    dev = ["us-west-2a", "us-west-2b"]
    staging = ["us-west-2a", "us-west-2b", "us-west-2c"]
    prod = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
  
  # Current workspace configuration
  current_cidr = local.workspace_cidrs[terraform.workspace]
  current_azs = local.workspace_azs[terraform.workspace]
}

# Workspace-specific VPC
resource "aws_vpc" "main" {
  cidr_block = local.current_cidr
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-vpc"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    CIDR = local.current_cidr
  }
}

# Workspace-specific subnets
resource "aws_subnet" "public" {
  count = length(local.current_azs)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(local.current_cidr, 8, count.index)
  availability_zone = local.current_azs[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-public-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    AZ = local.current_azs[count.index]
  }
}
```

### Step 4: Workspace-Specific Configurations

#### Basic Workspace-Specific Configurations
```hcl
# Workspace-specific configurations
locals {
  # Workspace-specific instance configurations
  instance_configs = {
    dev = {
      count = 1
      type = "t3.micro"
      monitoring = false
      encryption = false
    }
    staging = {
      count = 2
      type = "t3.small"
      monitoring = true
      encryption = true
    }
    prod = {
      count = 3
      type = "t3.large"
      monitoring = true
      encryption = true
    }
  }
  
  # Workspace-specific database configurations
  database_configs = {
    dev = {
      instance_class = "db.t3.micro"
      allocated_storage = 20
      multi_az = false
      backup_retention = 1
    }
    staging = {
      instance_class = "db.t3.small"
      allocated_storage = 50
      multi_az = false
      backup_retention = 7
    }
    prod = {
      instance_class = "db.r5.large"
      allocated_storage = 100
      multi_az = true
      backup_retention = 30
    }
  }
  
  # Current workspace configurations
  current_instance_config = local.instance_configs[terraform.workspace]
  current_database_config = local.database_configs[terraform.workspace]
}

# Workspace-specific instances
resource "aws_instance" "web" {
  count = local.current_instance_config.count
  
  ami           = var.ami_id
  instance_type = local.current_instance_config.type
  subnet_id     = aws_subnet.public[count.index].id
  
  monitoring = local.current_instance_config.monitoring
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-web-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    InstanceType = local.current_instance_config.type
  }
}

# Workspace-specific database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${terraform.workspace}-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = local.current_database_config.instance_class
  
  allocated_storage     = local.current_database_config.allocated_storage
  max_allocated_storage = local.current_database_config.allocated_storage * 2
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  multi_az = local.current_database_config.multi_az
  backup_retention_period = local.current_database_config.backup_retention
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-db"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    InstanceClass = local.current_database_config.instance_class
  }
}
```

#### Advanced Workspace-Specific Configurations
```hcl
# Advanced workspace-specific configurations
locals {
  # Workspace-specific feature flags
  feature_flags = {
    dev = {
      enable_monitoring = false
      enable_logging = false
      enable_backup = false
      enable_ssl = false
      enable_waf = false
    }
    staging = {
      enable_monitoring = true
      enable_logging = true
      enable_backup = true
      enable_ssl = true
      enable_waf = false
    }
    prod = {
      enable_monitoring = true
      enable_logging = true
      enable_backup = true
      enable_ssl = true
      enable_waf = true
    }
  }
  
  # Workspace-specific security configurations
  security_configs = {
    dev = {
      allowed_cidrs = ["0.0.0.0/0"]
      ssl_certificate = "self-signed"
      encryption_at_rest = false
      encryption_in_transit = false
    }
    staging = {
      allowed_cidrs = ["10.0.0.0/8"]
      ssl_certificate = "staging-cert"
      encryption_at_rest = true
      encryption_in_transit = true
    }
    prod = {
      allowed_cidrs = ["10.0.0.0/8"]
      ssl_certificate = "production-cert"
      encryption_at_rest = true
      encryption_in_transit = true
    }
  }
  
  # Current workspace configurations
  current_features = local.feature_flags[terraform.workspace]
  current_security = local.security_configs[terraform.workspace]
}

# Workspace-specific security group
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${terraform.workspace}-web-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = local.current_security.allowed_cidrs
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  
  dynamic "ingress" {
    for_each = local.current_features.enable_ssl ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.current_security.allowed_cidrs
    }
  }
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-web-sg"
    Environment = terraform.workspace
    Workspace = terraform.workspace
  }
}
```

### Step 5: Advanced Workspace Patterns

#### Complex Workspace Scenarios
```hcl
# Complex workspace scenarios
locals {
  # Workspace-specific resource counts
  resource_counts = {
    dev = {
      instances = 1
      subnets = 2
      security_groups = 2
      buckets = 1
    }
    staging = {
      instances = 2
      subnets = 3
      security_groups = 3
      buckets = 2
    }
    prod = {
      instances = 3
      subnets = 3
      security_groups = 4
      buckets = 3
    }
  }
  
  # Workspace-specific resource types
  resource_types = {
    dev = {
      instance_type = "t3.micro"
      database_class = "db.t3.micro"
      storage_type = "gp2"
    }
    staging = {
      instance_type = "t3.small"
      database_class = "db.t3.small"
      storage_type = "gp3"
    }
    prod = {
      instance_type = "t3.large"
      database_class = "db.r5.large"
      storage_type = "gp3"
    }
  }
  
  # Current workspace configurations
  current_counts = local.resource_counts[terraform.workspace]
  current_types = local.resource_types[terraform.workspace]
}

# Workspace-specific instances
resource "aws_instance" "web" {
  count = local.current_counts.instances
  
  ami           = var.ami_id
  instance_type = local.current_types.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-web-${count.index + 1}"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    InstanceType = local.current_types.instance_type
  }
}

# Workspace-specific database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${terraform.workspace}-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = local.current_types.database_class
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  tags = {
    Name = "${var.project_name}-${terraform.workspace}-db"
    Environment = terraform.workspace
    Workspace = terraform.workspace
    InstanceClass = local.current_types.database_class
  }
}
```

### Step 6: Production Strategies

#### Production-Grade Environment Management
```hcl
# Production-grade environment management
locals {
  # Production-grade workspace configurations
  production_configs = {
    dev = {
      environment = "development"
      tier = "development"
      cost_center = "engineering"
      backup_schedule = "daily"
      monitoring_level = "basic"
      alerting = false
    }
    staging = {
      environment = "staging"
      tier = "staging"
      cost_center = "engineering"
      backup_schedule = "daily"
      monitoring_level = "standard"
      alerting = true
    }
    prod = {
      environment = "production"
      tier = "production"
      cost_center = "operations"
      backup_schedule = "hourly"
      monitoring_level = "comprehensive"
      alerting = true
    }
  }
  
  # Current workspace configuration
  current_config = local.production_configs[terraform.workspace]
  
  # Production-grade resource naming
  resource_naming = {
    prefix = "${var.project_name}-${terraform.workspace}"
    suffix = terraform.workspace
    environment = terraform.workspace
  }
}

# Production-grade instances
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Production-grade lifecycle rules
  lifecycle {
    create_before_destroy = terraform.workspace == "prod" ? true : false
    prevent_destroy = terraform.workspace == "prod" ? true : false
    ignore_changes = [
      tags["LastModified"],
      tags["ModifiedBy"]
    ]
  }
  
  tags = merge({
    Name = "${local.resource_naming.prefix}-web-${count.index + 1}"
    Environment = local.current_config.environment
    Workspace = terraform.workspace
    Tier = local.current_config.tier
    CostCenter = local.current_config.cost_center
    BackupSchedule = local.current_config.backup_schedule
    MonitoringLevel = local.current_config.monitoring_level
    Alerting = local.current_config.alerting
  }, var.additional_tags)
}
```

### Step 7: Best Practices

#### Workspace Best Practices
```hcl
# Best practices for workspace management
locals {
  # Workspace validation
  valid_workspaces = ["dev", "staging", "prod"]
  
  # Validate current workspace
  current_workspace = contains(local.valid_workspaces, terraform.workspace) ? terraform.workspace : "dev"
  
  # Workspace-specific configurations
  workspace_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = false
      enable_encryption = false
      backup_retention = 1
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_encryption = true
      backup_retention = 7
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_encryption = true
      backup_retention = 30
    }
  }
  
  # Current workspace configuration
  current_config = local.workspace_config[local.current_workspace]
}

# Use validated workspace configuration
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = var.ami_id
  instance_type = local.current_config.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  monitoring = local.current_config.enable_monitoring
  
  tags = {
    Name = "${var.project_name}-${local.current_workspace}-web-${count.index + 1}"
    Environment = local.current_workspace
    Workspace = local.current_workspace
    InstanceType = local.current_config.instance_type
    Monitoring = local.current_config.enable_monitoring ? "Enabled" : "Disabled"
    Encryption = local.current_config.enable_encryption ? "Enabled" : "Disabled"
  }
}
```

## Expected Deliverables

### 1. Workspace Management Examples
- Basic workspace operations and management
- Advanced workspace management with locals
- Workspace-specific resource naming
- Performance optimization techniques

### 2. Environment Isolation Examples
- Basic environment isolation with workspaces
- Advanced environment isolation strategies
- Workspace-specific CIDR blocks and availability zones
- Security isolation patterns

### 3. Workspace-Specific Configuration Examples
- Basic workspace-specific configurations
- Advanced workspace-specific configurations
- Feature flags and security configurations
- Environment-specific resource configurations

### 4. Advanced Workspace Patterns
- Complex workspace scenarios
- Production-grade environment management
- Workspace validation and error handling
- Advanced workspace patterns

### 5. Best Practices Implementation
- Workspace validation and error handling
- Performance optimization techniques
- Security best practices
- Maintenance guidelines

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are Terraform workspaces, and why are they important?**
   - Workspaces are named state containers that allow managing multiple environments
   - They enable environment isolation, configuration reuse, and efficient state management

2. **What are the main workspace operations?**
   - terraform workspace list: List all workspaces
   - terraform workspace new: Create new workspace
   - terraform workspace select: Switch to workspace
   - terraform workspace show: Show current workspace

3. **How do you create workspace-specific configurations?**
   - Use terraform.workspace variable in configurations
   - Create workspace-specific locals and variables
   - Use workspace-specific resource naming

4. **What are the best practices for workspace management?**
   - Use meaningful workspace names
   - Validate workspace names
   - Use workspace-specific configurations
   - Document workspace usage

5. **How do you isolate environments with workspaces?**
   - Use workspace-specific CIDR blocks
   - Use workspace-specific availability zones
   - Use workspace-specific resource naming
   - Use workspace-specific security configurations

6. **What are the production strategies for workspace management?**
   - Use production-grade workspace configurations
   - Implement workspace validation
   - Use workspace-specific lifecycle rules
   - Implement comprehensive monitoring

7. **How do you troubleshoot workspace issues?**
   - Check workspace selection
   - Validate workspace configurations
   - Check workspace-specific variables
   - Verify workspace state

## Troubleshooting

### Common Workspace Issues

#### 1. Workspace Selection Issues
```bash
# Error: Workspace not found
# Solution: Check workspace name and create if needed
terraform workspace select dev
terraform workspace new dev  # If workspace doesn't exist
```

#### 2. Workspace Configuration Issues
```bash
# Error: Workspace configuration not found
# Solution: Check workspace-specific configurations
locals {
  workspace_config = {
    dev = { ... }
    staging = { ... }
    prod = { ... }
  }
  current_config = local.workspace_config[terraform.workspace]
}
```

#### 3. Workspace State Issues
```bash
# Error: Workspace state issues
# Solution: Check workspace state and switch workspaces
terraform workspace show
terraform workspace select dev
terraform state list
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform workspaces
- Knowledge of workspace management and environment isolation
- Understanding of workspace-specific configurations
- Ability to create scalable, maintainable environment management

Proceed to [Problem 16: File Organization and Project Structure](../Problem-16-File-Organization/) to learn about Terraform project structure and file organization best practices.
