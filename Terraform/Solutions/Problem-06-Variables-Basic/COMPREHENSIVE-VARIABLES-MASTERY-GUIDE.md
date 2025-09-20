# Problem 6: Terraform Variables Mastery - Complete Implementation Guide

## Variable Fundamentals

### What are Terraform Variables?
Variables in Terraform allow you to parameterize your configurations, making them reusable across different environments and scenarios. They serve as input parameters to your Terraform modules and configurations.

### Variable Declaration Syntax
```hcl
variable "variable_name" {
  description = "Description of what this variable does"
  type        = string
  default     = "default_value"
  sensitive   = false
  nullable    = true
  
  validation {
    condition     = length(var.variable_name) > 0
    error_message = "Variable cannot be empty."
  }
}
```

## Variable Types in Detail

### String Variables
```hcl
# Basic string variable
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

# String with validation
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains([
      "development", 
      "staging", 
      "production"
    ], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# String with length validation
variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  
  validation {
    condition     = length(var.instance_name) >= 3 && length(var.instance_name) <= 63
    error_message = "Instance name must be between 3 and 63 characters."
  }
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.instance_name))
    error_message = "Instance name must start with a letter, end with alphanumeric, and contain only letters, numbers, and hyphens."
  }
}

# Sensitive string variable
variable "database_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}
```

### Number Variables
```hcl
# Basic number variable
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

# Number with range validation
variable "port" {
  description = "Port number for the application"
  type        = number
  default     = 80
  
  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# Number with specific values validation
variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.volume_size >= 8 && var.volume_size <= 16384
    error_message = "Volume size must be between 8 GB and 16,384 GB."
  }
  
  validation {
    condition     = var.volume_size % 1 == 0
    error_message = "Volume size must be a whole number."
  }
}

# Floating point number
variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for auto scaling"
  type        = number
  default     = 75.0
  
  validation {
    condition     = var.cpu_utilization_threshold >= 0 && var.cpu_utilization_threshold <= 100
    error_message = "CPU utilization threshold must be between 0 and 100."
  }
}
```

### Boolean Variables
```hcl
# Basic boolean variable
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = false
}

# Boolean with environment-based default
variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Boolean for feature flags
variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
  
  validation {
    condition     = var.enable_encryption == true
    error_message = "Encryption must be enabled for compliance."
  }
}
```

### List Variables
```hcl
# List of strings
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

# List of numbers
variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  default     = [80, 443, 22]
  
  validation {
    condition = alltrue([
      for port in var.allowed_ports : port >= 1 && port <= 65535
    ])
    error_message = "All ports must be between 1 and 65535."
  }
}

# List with specific allowed values
variable "instance_types" {
  description = "List of allowed instance types"
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t3.medium"]
  
  validation {
    condition = alltrue([
      for instance_type in var.instance_types : 
      contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge"], instance_type)
    ])
    error_message = "All instance types must be valid t3 instance types."
  }
}

# List of objects
variable "security_group_rules" {
  description = "List of security group rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}
```

### Map Variables
```hcl
# Simple map
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "terraform-learning"
    ManagedBy   = "terraform"
  }
}

# Map with validation
variable "environment_configs" {
  description = "Configuration for different environments"
  type = map(object({
    instance_type = string
    instance_count = number
    monitoring_enabled = bool
  }))
  
  default = {
    development = {
      instance_type = "t3.micro"
      instance_count = 1
      monitoring_enabled = false
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
      monitoring_enabled = true
    }
    production = {
      instance_type = "t3.medium"
      instance_count = 3
      monitoring_enabled = true
    }
  }
  
  validation {
    condition = alltrue([
      for env, config in var.environment_configs :
      contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], config.instance_type)
    ])
    error_message = "All instance types must be valid t3 instance types."
  }
}
```

### Complex Object Variables
```hcl
# Complex nested object
variable "application_config" {
  description = "Complete application configuration"
  type = object({
    name = string
    version = string
    
    web_tier = object({
      instance_type = string
      min_size = number
      max_size = number
      desired_capacity = number
      
      load_balancer = object({
        type = string
        scheme = string
        ports = list(number)
      })
    })
    
    database = object({
      engine = string
      version = string
      instance_class = string
      allocated_storage = number
      backup_retention_period = number
      multi_az = bool
    })
    
    monitoring = object({
      enabled = bool
      retention_days = number
      alert_email = string
    })
  })
  
  # Complex default value
  default = {
    name = "web-application"
    version = "1.0.0"
    
    web_tier = {
      instance_type = "t3.medium"
      min_size = 2
      max_size = 10
      desired_capacity = 3
      
      load_balancer = {
        type = "application"
        scheme = "internet-facing"
        ports = [80, 443]
      }
    }
    
    database = {
      engine = "mysql"
      version = "8.0"
      instance_class = "db.t3.medium"
      allocated_storage = 100
      backup_retention_period = 7
      multi_az = true
    }
    
    monitoring = {
      enabled = true
      retention_days = 30
      alert_email = "admin@example.com"
    }
  }
}
```

## Variable Validation Patterns

### String Validation Patterns
```hcl
# Email validation
variable "admin_email" {
  description = "Administrator email address"
  type        = string
  
  validation {
    condition = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "Admin email must be a valid email address."
  }
}

# CIDR block validation
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
  
  validation {
    condition = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", var.vpc_cidr))
    error_message = "VPC CIDR must use private IP ranges."
  }
}

# AWS region validation
variable "aws_region" {
  description = "AWS region"
  type        = string
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}
```

### Numeric Validation Patterns
```hcl
# Range validation with multiple conditions
variable "database_storage" {
  description = "Database storage size in GB"
  type        = number
  
  validation {
    condition     = var.database_storage >= 20 && var.database_storage <= 65536
    error_message = "Database storage must be between 20 GB and 65,536 GB."
  }
  
  validation {
    condition     = var.database_storage % 10 == 0
    error_message = "Database storage must be in increments of 10 GB."
  }
}

# Power of 2 validation
variable "memory_size" {
  description = "Memory size in MB (must be power of 2)"
  type        = number
  
  validation {
    condition = var.memory_size > 0 && (var.memory_size & (var.memory_size - 1)) == 0
    error_message = "Memory size must be a power of 2."
  }
}
```

### List Validation Patterns
```hcl
# List length validation
variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  
  validation {
    condition     = length(var.subnet_cidrs) >= 2 && length(var.subnet_cidrs) <= 6
    error_message = "Must specify between 2 and 6 subnet CIDR blocks."
  }
  
  validation {
    condition = alltrue([
      for cidr in var.subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }
}

# Unique values validation
variable "instance_names" {
  description = "List of unique instance names"
  type        = list(string)
  
  validation {
    condition     = length(var.instance_names) == length(toset(var.instance_names))
    error_message = "All instance names must be unique."
  }
}
```

## Variable Input Methods

### Command Line
```bash
# Single variable
terraform apply -var="instance_count=3"

# Multiple variables
terraform apply -var="instance_count=3" -var="environment=production"

# Variable file
terraform apply -var-file="production.tfvars"
```

### Environment Variables
```bash
# Set environment variables
export TF_VAR_instance_count=3
export TF_VAR_environment=production
export TF_VAR_database_password="super-secret-password"

# Run terraform
terraform apply
```

### Variable Files (.tfvars)
```hcl
# terraform.tfvars
instance_count = 3
environment = "production"
project_name = "ecommerce-app"

availability_zones = [
  "us-west-2a",
  "us-west-2b", 
  "us-west-2c"
]

tags = {
  Environment = "production"
  Project     = "ecommerce"
  Owner       = "devops-team"
  CostCenter  = "engineering"
}

application_config = {
  name = "ecommerce-app"
  version = "2.1.0"
  
  web_tier = {
    instance_type = "t3.large"
    min_size = 3
    max_size = 15
    desired_capacity = 5
    
    load_balancer = {
      type = "application"
      scheme = "internet-facing"
      ports = [80, 443]
    }
  }
  
  database = {
    engine = "mysql"
    version = "8.0"
    instance_class = "db.r5.xlarge"
    allocated_storage = 500
    backup_retention_period = 30
    multi_az = true
  }
  
  monitoring = {
    enabled = true
    retention_days = 90
    alert_email = "alerts@company.com"
  }
}
```

### Auto-loaded Variable Files
```bash
# Terraform automatically loads these files:
terraform.tfvars
terraform.tfvars.json
*.auto.tfvars
*.auto.tfvars.json

# Environment-specific files
development.auto.tfvars
staging.auto.tfvars
production.auto.tfvars
```

## Variable Usage Patterns

### Local Values for Processing
```hcl
# Process variables with locals
locals {
  # Normalize environment name
  environment = lower(var.environment)
  
  # Create resource prefix
  name_prefix = "${var.project_name}-${local.environment}"
  
  # Process tags
  common_tags = merge(var.tags, {
    Environment = local.environment
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  })
  
  # Calculate derived values
  instance_count = var.environment == "production" ? max(var.instance_count, 2) : var.instance_count
  
  # Process complex configurations
  web_config = var.application_config.web_tier
  db_config = var.application_config.database
  
  # Create subnet configurations
  subnet_configs = {
    for i, cidr in var.subnet_cidrs : 
    "subnet-${i + 1}" => {
      cidr_block = cidr
      availability_zone = var.availability_zones[i % length(var.availability_zones)]
      map_public_ip = i < var.public_subnet_count
    }
  }
}
```

### Conditional Resource Creation
```hcl
# Use variables for conditional creation
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Conditional configuration
  monitoring = var.environment == "production" ? true : var.enable_monitoring
  
  # Conditional security groups
  vpc_security_group_ids = var.environment == "production" ? [
    aws_security_group.web.id,
    aws_security_group.monitoring.id
  ] : [aws_security_group.web.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
  })
}
```

This comprehensive guide covers all aspects of Terraform variable usage, from basic declarations to complex validation patterns and real-world usage scenarios.
