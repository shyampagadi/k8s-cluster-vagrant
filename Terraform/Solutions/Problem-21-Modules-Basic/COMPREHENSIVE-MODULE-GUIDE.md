# Problem 21: Terraform Modules - Complete Development Guide

## Overview

This comprehensive guide addresses the detailed requirements for Problem 21, focusing on developing reusable Terraform modules for VPC, EC2, and database infrastructure. You'll learn to create production-ready modules with proper variable validation, comprehensive outputs, and detailed documentation.

## Learning Objectives Achieved

- ✅ Master module development from basic to advanced patterns
- ✅ Implement comprehensive variable validation and error handling
- ✅ Create reusable modules for VPC, EC2, and database infrastructure
- ✅ Understand module composition and dependency management
- ✅ Develop proper module documentation and usage examples

## Module Architecture Overview

### Directory Structure
```
modules/
├── vpc/
│   ├── main.tf          # VPC resources and networking
│   ├── variables.tf     # Input variables with validation
│   ├── outputs.tf       # VPC outputs for other modules
│   ├── README.md        # Module documentation
│   └── examples/        # Usage examples
├── ec2/
│   ├── main.tf          # EC2 instances and security groups
│   ├── variables.tf     # Instance configuration variables
│   ├── outputs.tf       # Instance information outputs
│   └── README.md        # Module documentation
└── database/
    ├── main.tf          # RDS instances and configurations
    ├── variables.tf     # Database configuration variables
    ├── outputs.tf       # Database connection information
    └── README.md        # Module documentation
```

## VPC Module Implementation

### VPC Module Core Features
- Configurable CIDR blocks and subnets
- Multi-AZ deployment support
- NAT Gateway and Internet Gateway management
- Route table configuration
- VPC Flow Logs for monitoring
- Comprehensive tagging strategy

### Key Implementation Patterns
```hcl
# Automatic subnet calculation
locals {
  # Calculate subnet CIDRs automatically
  public_subnet_cidrs = [
    for i in range(var.public_subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  private_subnet_cidrs = [
    for i in range(var.private_subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i + var.public_subnet_count)
  ]
}

# Multi-AZ subnet creation
resource "aws_subnet" "public" {
  count = var.public_subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "Public"
  })
}
```

### Advanced Variable Validation
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
  
  validation {
    condition = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", var.vpc_cidr))
    error_message = "VPC CIDR must use private IP ranges (10.x.x.x, 172.16-31.x.x, or 192.168.x.x)."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.availability_zones) == 0 || (
      length(var.availability_zones) >= 2 && 
      length(var.availability_zones) <= 6
    )
    error_message = "Must specify 2-6 availability zones, or leave empty for automatic selection."
  }
}
```

## EC2 Module Implementation

### EC2 Module Features
- Dynamic instance configuration
- Security group integration
- User data template support
- EBS volume management
- Instance profile attachment
- Monitoring and logging setup

### Security Group Integration
```hcl
# Dynamic security group rules
resource "aws_security_group" "instance" {
  name_prefix = "${var.name}-"
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self            = lookup(ingress.value, "self", null)
    }
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}
```

### Instance Configuration with User Data
```hcl
# EC2 instance with templated user data
resource "aws_instance" "main" {
  count = var.instance_count
  
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id             = var.subnet_ids[count.index % length(var.subnet_ids)]
  iam_instance_profile  = var.iam_instance_profile
  
  user_data = var.user_data_template != "" ? templatefile(var.user_data_template, {
    instance_name = "${var.name}-${count.index + 1}"
    environment   = var.environment
    custom_vars   = var.user_data_vars
  }) : null
  
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted            = var.encrypt_root_volume
    delete_on_termination = true
  }
  
  monitoring = var.detailed_monitoring
  
  tags = merge(var.tags, {
    Name = "${var.name}-${count.index + 1}"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
```

## Database Module Implementation

### RDS Module Features
- Multi-engine support (MySQL, PostgreSQL, etc.)
- Subnet group management
- Parameter group customization
- Backup and maintenance configuration
- Security group integration
- Read replica support

### Database Configuration
```hcl
# RDS subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

# RDS parameter group
resource "aws_db_parameter_group" "main" {
  count = var.create_parameter_group ? 1 : 0
  
  family = var.parameter_group_family
  name   = "${var.name}-params"
  
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  
  tags = var.tags
}

# RDS instance
resource "aws_db_instance" "main" {
  identifier = var.name
  
  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  
  # Database configuration
  db_name  = var.database_name
  username = var.username
  password = var.password
  port     = var.port
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = var.publicly_accessible
  
  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  # Parameter group
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.main[0].name : var.parameter_group_name
  
  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn
  
  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  
  tags = var.tags
}
```

## Module Composition Example

### Main Configuration Using All Modules
```hcl
# Local values for common configuration
locals {
  name = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  name     = local.name
  vpc_cidr = var.vpc_cidr
  
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  
  enable_nat_gateway = var.environment == "production"
  enable_vpn_gateway = var.enable_vpn_gateway
  enable_flow_logs   = true
  
  tags = local.common_tags
}

# EC2 Module for Web Servers
module "web_servers" {
  source = "./modules/ec2"
  
  name           = "${local.name}-web"
  instance_count = var.web_instance_count
  instance_type  = var.web_instance_type
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  ingress_rules = [
    {
      description = "HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      security_groups = [module.alb.security_group_id]
    },
    {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      security_groups = [module.bastion.security_group_id]
    }
  ]
  
  user_data_template = "${path.module}/templates/web-server-userdata.sh"
  user_data_vars = {
    database_endpoint = module.database.endpoint
    app_version      = var.app_version
  }
  
  tags = merge(local.common_tags, {
    Type = "WebServer"
  })
  
  depends_on = [module.vpc]
}

# Database Module
module "database" {
  source = "./modules/database"
  
  name = "${local.name}-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  database_name = var.database_name
  username      = var.db_username
  password      = var.db_password
  
  subnet_ids = module.vpc.database_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  allowed_security_groups = [module.web_servers.security_group_id]
  
  backup_retention_period = var.environment == "production" ? 7 : 1
  deletion_protection     = var.environment == "production"
  
  tags = merge(local.common_tags, {
    Type = "Database"
  })
  
  depends_on = [module.vpc]
}
```

## Advanced Module Patterns

### Module Versioning Strategy
```hcl
# Using versioned modules from Git
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//vpc?ref=v2.1.0"
  
  # Configuration...
}

# Using Terraform Registry with version constraints
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  
  # Configuration...
}
```

### Conditional Module Usage
```hcl
# Create bastion host only in non-production environments
module "bastion" {
  count = var.environment != "production" ? 1 : 0
  
  source = "./modules/ec2"
  
  name          = "${local.name}-bastion"
  instance_type = "t3.micro"
  subnet_ids    = module.vpc.public_subnet_ids
  
  # Configuration...
}
```

## Module Testing and Validation

### Example Testing Structure
```hcl
# modules/vpc/examples/basic/main.tf
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

module "vpc_test" {
  source = "../../"
  
  name     = "test-vpc"
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_count  = 2
  private_subnet_count = 2
  
  enable_nat_gateway = true
  enable_flow_logs   = true
  
  tags = {
    Environment = "test"
    Purpose     = "module-validation"
  }
}

# Validation outputs
output "vpc_validation" {
  value = {
    vpc_id              = module.vpc_test.vpc_id
    public_subnet_count = length(module.vpc_test.public_subnet_ids)
    private_subnet_count = length(module.vpc_test.private_subnet_ids)
    nat_gateway_count   = length(module.vpc_test.nat_gateway_ids)
  }
}
```

## Best Practices and Recommendations

### Module Design Principles
1. **Single Responsibility**: Each module should have a clear, focused purpose
2. **Composability**: Modules should work well together
3. **Reusability**: Design for multiple use cases and environments
4. **Testability**: Include examples and validation
5. **Documentation**: Comprehensive README and inline comments

### Security Considerations
- Always encrypt storage and data in transit
- Use least privilege access principles
- Implement proper network segmentation
- Enable logging and monitoring
- Regular security updates and patches

### Performance Optimization
- Use data sources efficiently
- Minimize API calls with proper resource organization
- Implement proper dependency management
- Use parallel execution where possible

This comprehensive guide provides everything needed to master Terraform module development, from basic concepts to advanced enterprise patterns.
