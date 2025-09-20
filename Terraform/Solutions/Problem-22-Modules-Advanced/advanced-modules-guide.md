# Advanced Terraform Modules - Comprehensive Guide

## Overview
This guide covers advanced Terraform module concepts including module composition, inter-module communication, conditional module usage, and production-ready module architecture patterns.

## Advanced Module Patterns

### Module Composition
Module composition involves creating complex infrastructure by combining multiple modules in sophisticated ways:

```hcl
# Root module composition example
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id              = module.networking.vpc_id
  subnet_ids          = module.networking.private_subnet_ids
  security_group_ids  = module.networking.security_group_ids
  instance_count      = var.instance_count
  instance_type       = var.instance_type
}

module "storage" {
  source = "./modules/storage"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  environment = var.environment
}

module "monitoring" {
  source = "./modules/monitoring"
  
  vpc_id              = module.networking.vpc_id
  instance_ids        = module.compute.instance_ids
  database_endpoint   = module.storage.database_endpoint
  environment         = var.environment
}
```

### Inter-Module Communication
Modules communicate through well-defined interfaces using outputs and variables:

```hcl
# Networking module outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "IDs of the created security groups"
  value = {
    web_sg = aws_security_group.web.id
    db_sg  = aws_security_group.database.id
  }
}

# Compute module inputs
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type = object({
    web_sg = string
    db_sg  = string
  })
}
```

## Conditional Module Usage

### Feature Flags and Conditional Modules
```hcl
# Conditional module instantiation
module "database" {
  count  = var.create_database ? 1 : 0
  source = "./modules/database"
  
  vpc_id              = module.networking.vpc_id
  subnet_ids          = module.networking.private_subnet_ids
  security_group_ids  = module.networking.security_group_ids
  environment         = var.environment
}

module "cache" {
  count  = var.create_cache ? 1 : 0
  source = "./modules/cache"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  environment = var.environment
}

# Conditional outputs
output "database_endpoint" {
  description = "Database endpoint if created"
  value       = var.create_database ? module.database[0].endpoint : null
}

output "cache_endpoint" {
  description = "Cache endpoint if created"
  value       = var.create_cache ? module.cache[0].endpoint : null
}
```

### Environment-Specific Modules
```hcl
# Environment-specific module configuration
locals {
  environment_config = {
    development = {
      instance_count = 1
      instance_type  = "t3.micro"
      enable_monitoring = false
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      enable_monitoring = true
    }
    production = {
      instance_count = 3
      instance_type  = "t3.medium"
      enable_monitoring = true
    }
  }
}

module "compute" {
  source = "./modules/compute"
  
  instance_count     = local.environment_config[var.environment].instance_count
  instance_type      = local.environment_config[var.environment].instance_type
  enable_monitoring  = local.environment_config[var.environment].enable_monitoring
  
  vpc_id = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
}
```

## Production-Ready Module Architecture

### Module Versioning Strategy
```hcl
# Version constraints in modules
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Module version specification
module "networking" {
  source  = "git::https://github.com/company/terraform-modules.git//networking?ref=v2.1.0"
  
  vpc_cidr = var.vpc_cidr
  environment = var.environment
}
```

### Module Testing and Validation
```hcl
# Module validation example
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}
```

## Advanced Module Features

### Dynamic Module Blocks
```hcl
# Dynamic module instantiation
locals {
  environments = ["development", "staging", "production"]
}

module "environment" {
  for_each = toset(local.environments)
  source   = "./modules/environment"
  
  environment_name = each.key
  vpc_cidr        = "10.${index(local.environments, each.key)}.0.0/16"
  
  tags = {
    Environment = each.key
    ManagedBy   = "terraform"
  }
}

# Output all environment VPC IDs
output "environment_vpc_ids" {
  description = "VPC IDs for all environments"
  value = {
    for env, module in module.environment : env => module.vpc_id
  }
}
```

### Module Data Sources
```hcl
# Using data sources within modules
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
}

# Using data source outputs in resources
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  availability_zone = data.aws_availability_zones.available.names[0]
}
```

## Module Security and Compliance

### Security Best Practices
```hcl
# Secure module configuration
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = var.vpc_id
  
  # Restrictive ingress rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Restrictive egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-web-sg"
  })
}
```

### Compliance and Governance
```hcl
# Compliance tagging
locals {
  compliance_tags = {
    ComplianceFramework = "SOC2"
    DataClassification  = "Confidential"
    BackupRequired     = "true"
    EncryptionRequired  = "true"
    MonitoringRequired  = "true"
  }
}

resource "aws_instance" "compliant" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(var.tags, local.compliance_tags, {
    Name = "${var.project_name}-compliant-instance"
  })
}
```

## Module Performance Optimization

### Resource Optimization
```hcl
# Optimized resource configuration
resource "aws_autoscaling_group" "optimized" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  # Optimized launch template
  launch_template {
    id      = aws_launch_template.optimized.id
    version = "$Latest"
  }
  
  # Enable instance refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
    propagate_at_launch = true
  }
}
```

### State Management Optimization
```hcl
# Optimized state configuration
terraform {
  backend "s3" {
    bucket         = var.state_bucket
    key            = "${var.project_name}/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = var.state_lock_table
  }
}
```

## Module Documentation Standards

### Comprehensive Documentation
```markdown
# Module Name

## Description
Brief description of what this module does.

## Usage
```hcl
module "example" {
  source = "path/to/module"
  
  # Required variables
  vpc_cidr = "10.0.0.0/16"
  environment = "production"
  
  # Optional variables
  instance_count = 3
  instance_type  = "t3.medium"
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for VPC | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| instance_count | Number of instances | number | 1 | no |
| instance_type | Instance type | string | "t3.micro" | no |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| instance_ids | IDs of the created instances |
| security_group_id | ID of the security group |

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers
| Name | Version |
|------|---------|
| aws | >= 5.0 |
```

## Module Testing Strategies

### Comprehensive Testing
```hcl
# Test configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Test variables
variable "test_environment" {
  description = "Test environment name"
  type        = string
  default     = "test"
}

# Test resources
resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name        = "test-vpc"
    Environment = var.test_environment
  }
}
```

## Module Maintenance and Updates

### Version Management
- **Semantic Versioning**: Use semantic versioning for modules
- **Breaking Changes**: Document breaking changes clearly
- **Migration Guides**: Provide migration guides for major updates
- **Deprecation Policy**: Clear deprecation and sunset policies

### Continuous Improvement
- **Regular Updates**: Keep modules up-to-date with provider versions
- **Security Patches**: Apply security updates promptly
- **Performance Optimization**: Continuously optimize module performance
- **Feature Enhancements**: Add new features based on user feedback

## Conclusion

Advanced Terraform modules enable the creation of sophisticated, reusable, and maintainable infrastructure components. By following advanced patterns for module composition, conditional usage, and production-ready architecture, you can build enterprise-grade infrastructure solutions.

Regular review and updates of advanced modules ensure continued effectiveness and adaptation to evolving requirements and technology landscapes.
