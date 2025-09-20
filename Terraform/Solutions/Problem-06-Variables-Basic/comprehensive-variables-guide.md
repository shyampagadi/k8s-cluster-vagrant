# Terraform Variables - Complete Implementation Guide

## Overview

This comprehensive guide covers Terraform variable fundamentals, including basic types, validation, defaults, and advanced usage patterns. Mastering variables is essential for creating flexible, reusable infrastructure configurations.

## Variable Fundamentals

### What are Terraform Variables?

Variables serve as parameters for Terraform modules, allowing:
- **Parameterization**: Make configurations flexible and reusable
- **Environment Separation**: Different values for dev/staging/prod
- **Security**: Separate sensitive data from code
- **Validation**: Ensure input correctness

### Variable Declaration Syntax

```hcl
variable "variable_name" {
  description = "Description of the variable"
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

## Basic Variable Types

### String Variables

```hcl
# Simple string variable
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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Sensitive string
variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
}

# Usage in resources
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name        = "${var.project_name}-web"
    Environment = var.environment
  }
}
```

### Number Variables

```hcl
# Integer variable
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Float variable
variable "cpu_threshold" {
  description = "CPU utilization threshold for scaling"
  type        = number
  default     = 80.5
  
  validation {
    condition     = var.cpu_threshold >= 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

# Usage in resources
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
}
```

### Boolean Variables

```hcl
# Boolean variable
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "create_database" {
  description = "Whether to create database instance"
  type        = bool
  default     = false
}

# Usage with conditional logic
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  monitoring    = var.enable_monitoring
}

resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier     = "main-database"
  engine         = "mysql"
  instance_class = "db.t3.micro"
}
```

## Variable Assignment Methods

### 1. Default Values

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### 2. Command Line

```bash
# Single variable
terraform apply -var="instance_type=t3.small"

# Multiple variables
terraform apply \
  -var="instance_type=t3.small" \
  -var="instance_count=3" \
  -var="environment=prod"
```

### 3. Variable Files (.tfvars)

```hcl
# terraform.tfvars
instance_type  = "t3.medium"
instance_count = 5
environment    = "production"
enable_monitoring = true

# List of strings
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Map
tags = {
  Environment = "production"
  Project     = "web-app"
  Owner       = "devops-team"
}
```

```bash
# Use specific tfvars file
terraform apply -var-file="production.tfvars"

# Multiple tfvars files
terraform apply \
  -var-file="common.tfvars" \
  -var-file="production.tfvars"
```

### 4. Environment Variables

```bash
# Set environment variables
export TF_VAR_instance_type="t3.large"
export TF_VAR_instance_count=3
export TF_VAR_environment="production"

# Apply without additional flags
terraform apply
```

### 5. Interactive Input

```bash
# Terraform will prompt for missing variables
terraform apply
# var.instance_type
#   Enter a value: t3.medium
```

## Variable Validation

### Basic Validation

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 instance type."
  }
}
```

### Advanced Validation

```hcl
# CIDR block validation
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
  
  validation {
    condition = can(regex("^10\\.|^172\\.(1[6-9]|2[0-9]|3[01])\\.|^192\\.168\\.", var.vpc_cidr))
    error_message = "VPC CIDR must be within private IP ranges."
  }
}

# String length validation
variable "project_name" {
  description = "Project name"
  type        = string
  
  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 20
    error_message = "Project name must be between 3 and 20 characters."
  }
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name can only contain lowercase letters, numbers, and hyphens."
  }
}

# Number range validation
variable "port" {
  description = "Port number"
  type        = number
  
  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}
```

### Multiple Validation Rules

```hcl
variable "email" {
  description = "Email address"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email))
    error_message = "Email must be a valid email address."
  }
  
  validation {
    condition     = length(var.email) <= 254
    error_message = "Email must be 254 characters or less."
  }
}
```

## Variable Precedence

Terraform uses the following precedence order (highest to lowest):

1. Command line `-var` flags
2. `*.auto.tfvars` files (alphabetical order)
3. `terraform.tfvars` file
4. `*.tfvars` files specified with `-var-file`
5. Environment variables (`TF_VAR_*`)
6. Default values in variable declarations

```bash
# Example demonstrating precedence
export TF_VAR_instance_type="t3.micro"  # Precedence: 5

# terraform.tfvars
instance_type = "t3.small"  # Precedence: 3

# Command line (highest precedence)
terraform apply -var="instance_type=t3.large"  # Precedence: 1
# Result: t3.large will be used
```

## Variable Organization Patterns

### Single Variables File

```hcl
# variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### Categorized Variables

```hcl
# variables-network.tf
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# variables-compute.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2
}

# variables-database.tf
variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}
```

## Environment-Specific Variables

### Directory Structure

```
environments/
├── dev/
│   ├── terraform.tfvars
│   └── main.tf
├── staging/
│   ├── terraform.tfvars
│   └── main.tf
└── prod/
    ├── terraform.tfvars
    └── main.tf
```

### Environment Files

```hcl
# environments/dev/terraform.tfvars
environment    = "dev"
instance_type  = "t3.micro"
instance_count = 1
enable_monitoring = false

# environments/staging/terraform.tfvars
environment    = "staging"
instance_type  = "t3.small"
instance_count = 2
enable_monitoring = true

# environments/prod/terraform.tfvars
environment    = "prod"
instance_type  = "t3.medium"
instance_count = 5
enable_monitoring = true
```

## Sensitive Variables

### Handling Sensitive Data

```hcl
# Sensitive variable declaration
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "api_keys" {
  description = "API keys for external services"
  type        = map(string)
  sensitive   = true
}

# Usage in resources
resource "aws_db_instance" "main" {
  identifier = "main-db"
  password   = var.database_password  # Won't be displayed in logs
}
```

### Sensitive Variable Sources

```bash
# Environment variables (recommended)
export TF_VAR_database_password="super-secret-password"

# External secret management
# Use AWS Secrets Manager, HashiCorp Vault, etc.
```

```hcl
# Using AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}

resource "aws_db_instance" "main" {
  password = local.db_password
}
```

## Variable Documentation

### Self-Documenting Variables

```hcl
variable "instance_configuration" {
  description = <<-EOT
    EC2 instance configuration including:
    - instance_type: The EC2 instance type (e.g., t3.micro, t3.small)
    - monitoring: Enable detailed CloudWatch monitoring
    - ebs_optimized: Enable EBS optimization for better performance
    
    Example:
    {
      instance_type  = "t3.medium"
      monitoring     = true
      ebs_optimized  = true
    }
  EOT
  
  type = object({
    instance_type  = string
    monitoring     = bool
    ebs_optimized  = bool
  })
  
  default = {
    instance_type  = "t3.micro"
    monitoring     = false
    ebs_optimized  = false
  }
}
```

### Variable Documentation Template

```hcl
variable "example_variable" {
  description = "Brief description of what this variable does"
  type        = string
  default     = "default_value"
  sensitive   = false
  nullable    = true
  
  validation {
    condition     = length(var.example_variable) > 0
    error_message = "Variable cannot be empty."
  }
}

# Usage example:
# terraform apply -var="example_variable=my_value"
```

## Testing Variables

### Variable Testing Strategy

```hcl
# test-variables.tf
variable "test_instance_type" {
  description = "Instance type for testing"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium"
    ], var.test_instance_type)
    error_message = "Test instance type must be t3.micro, t3.small, or t3.medium."
  }
}
```

### Validation Testing

```bash
#!/bin/bash
# test-variables.sh

echo "Testing variable validation..."

# Test valid values
terraform validate -var="test_instance_type=t3.micro"
terraform validate -var="test_instance_type=t3.small"

# Test invalid values (should fail)
if terraform validate -var="test_instance_type=invalid"; then
    echo "ERROR: Invalid value should have failed validation"
    exit 1
else
    echo "SUCCESS: Invalid value correctly rejected"
fi

echo "All variable tests passed!"
```

## Common Patterns and Best Practices

### 1. Required vs Optional Variables

```hcl
# Required variable (no default)
variable "project_name" {
  description = "Name of the project (required)"
  type        = string
}

# Optional variable (with default)
variable "instance_type" {
  description = "EC2 instance type (optional)"
  type        = string
  default     = "t3.micro"
}
```

### 2. Variable Naming Conventions

```hcl
# Good naming conventions
variable "vpc_cidr_block" {        # Descriptive and specific
  type = string
}

variable "enable_monitoring" {     # Boolean prefix with "enable_"
  type = bool
}

variable "instance_count" {        # Clear what it counts
  type = number
}

# Avoid these patterns
variable "data" {                  # Too generic
  type = string
}

variable "flag" {                  # Unclear purpose
  type = bool
}
```

### 3. Variable Grouping

```hcl
# Group related variables
variable "network_config" {
  description = "Network configuration"
  type = object({
    vpc_cidr             = string
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
    availability_zones   = list(string)
  })
}

variable "compute_config" {
  description = "Compute configuration"
  type = object({
    instance_type  = string
    instance_count = number
    key_pair_name  = string
  })
}
```

## Troubleshooting Variables

### Common Variable Issues

#### 1. Type Mismatch

```bash
# Error: Invalid value for variable
Error: Invalid value for variable "instance_count": number required.

# Solution: Check variable type
variable "instance_count" {
  type = number  # Not string
}
```

#### 2. Validation Failures

```bash
# Error: Invalid value for variable
Error: Invalid value for variable "environment": Environment must be dev, staging, or prod.

# Solution: Check validation rules
terraform apply -var="environment=development"  # Should be "dev"
```

#### 3. Missing Required Variables

```bash
# Error: No value for required variable
Error: No value for required variable "project_name".

# Solution: Provide value
terraform apply -var="project_name=my-project"
```

### Debugging Variables

```hcl
# Debug variable values
output "debug_variables" {
  value = {
    project_name   = var.project_name
    environment    = var.environment
    instance_type  = var.instance_type
    instance_count = var.instance_count
  }
}
```

```bash
# Check variable values
terraform console
> var.project_name
> var.environment
```

## Security Best Practices

### 1. Sensitive Data Handling

```hcl
# Mark sensitive variables
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Use external secret management
data "aws_secretsmanager_secret_version" "secrets" {
  secret_id = "prod/app/secrets"
}

locals {
  secrets = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)
}
```

### 2. Input Validation

```hcl
# Validate security-related inputs
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
  
  validation {
    condition = !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Cannot allow access from anywhere (0.0.0.0/0)."
  }
}
```

### 3. Audit Trail

```hcl
# Include metadata for auditing
variable "created_by" {
  description = "Who created this infrastructure"
  type        = string
}

variable "purpose" {
  description = "Purpose of this infrastructure"
  type        = string
}

# Apply to all resources
locals {
  common_tags = {
    CreatedBy   = var.created_by
    Purpose     = var.purpose
    CreatedDate = timestamp()
  }
}
```

## Performance Considerations

### 1. Variable Processing

```hcl
# Efficient variable usage
locals {
  # Process complex variables once
  processed_config = {
    for key, value in var.complex_config :
    key => merge(value, {
      computed_field = "${key}-${value.name}"
    })
  }
}

# Use processed values
resource "aws_instance" "web" {
  for_each = local.processed_config
  
  tags = {
    Name = each.value.computed_field
  }
}
```

### 2. Variable Validation Performance

```hcl
# Efficient validation
variable "instance_types" {
  description = "List of instance types"
  type        = list(string)
  
  validation {
    # Use contains() instead of complex regex
    condition = alltrue([
      for type in var.instance_types :
      contains(["t3.micro", "t3.small", "t3.medium"], type)
    ])
    error_message = "All instance types must be valid t3 types."
  }
}
```

## Conclusion

Mastering Terraform variables enables:
- **Flexible Configurations**: Adapt to different environments and requirements
- **Secure Operations**: Proper handling of sensitive data
- **Maintainable Code**: Clear, validated, and documented inputs
- **Team Collaboration**: Standardized variable patterns and conventions

Key takeaways:
- Always validate variable inputs
- Use appropriate types for better error detection
- Document variables thoroughly
- Handle sensitive data securely
- Follow consistent naming conventions
- Test variable validation rules
