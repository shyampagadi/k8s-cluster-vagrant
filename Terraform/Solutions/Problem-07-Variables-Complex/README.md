# Problem 07: Variables - Complex Types and Validation

## Overview

This solution provides comprehensive understanding of Terraform complex variable types, including lists, sets, maps, tuples, and objects. It also covers advanced validation patterns, variable constraints, and best practices for complex data structures.

## Learning Objectives

- Master complex variable data types (list, set, map, tuple, object)
- Learn advanced validation patterns and constraints
- Understand variable precedence with complex types
- Master variable usage patterns for complex data structures
- Learn variable file organization for complex configurations
- Understand performance considerations for complex variables
- Master troubleshooting complex variable issues

## Problem Statement

You've mastered basic variable types and usage patterns. Now your team lead wants you to become proficient in complex variable types and advanced validation. You need to understand how to define, validate, and use complex data structures effectively in your configurations.

## Solution Components

This solution includes:
1. **Complex Data Types** - List, set, map, tuple, and object variables
2. **Advanced Validation** - Complex validation patterns and constraints
3. **Variable Usage Patterns** - Working with complex data structures
4. **Variable Precedence** - Complex type precedence and resolution
5. **Performance Considerations** - Optimizing complex variable usage
6. **Best Practices** - Security, validation, and maintenance
7. **Troubleshooting** - Common issues and solutions

## Implementation Guide

### Step 1: Understanding Complex Data Types

#### List Variables
```hcl
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

variable "port_numbers" {
  description = "List of port numbers"
  type        = list(number)
  default     = [80, 443, 8080]
  
  validation {
    condition     = alltrue([for port in var.port_numbers : port > 0 && port <= 65535])
    error_message = "All ports must be between 1 and 65535."
  }
}
```

#### Set Variables
```hcl
variable "unique_tags" {
  description = "Set of unique tags"
  type        = set(string)
  default     = ["production", "web", "frontend"]
}

variable "unique_ports" {
  description = "Set of unique port numbers"
  type        = set(number)
  default     = [80, 443, 8080, 8443]
}
```

#### Map Variables
```hcl
variable "environment_tags" {
  description = "Map of environment-specific tags"
  type        = map(string)
  default     = {
    Environment = "development"
    Project     = "web-app"
    Owner       = "devops-team"
  }
  
  validation {
    condition     = contains(keys(var.environment_tags), "Environment")
    error_message = "Environment tag is required."
  }
}

variable "server_configs" {
  description = "Map of server configurations"
  type = map(object({
    instance_type = string
    disk_size     = number
    monitoring    = bool
  }))
  default = {
    web = {
      instance_type = "t3.micro"
      disk_size     = 20
      monitoring    = true
    }
    db = {
      instance_type = "t3.small"
      disk_size     = 100
      monitoring    = true
    }
  }
}
```

#### Tuple Variables
```hcl
variable "server_info" {
  description = "Tuple containing server information"
  type        = tuple([string, number, bool])
  default     = ["web-server", 3, true]
}

variable "database_info" {
  description = "Tuple containing database information"
  type        = tuple([string, string, number, bool])
  default     = ["mysql", "8.0", 100, false]
}
```

#### Object Variables
```hcl
variable "database_config" {
  description = "Database configuration object"
  type = object({
    engine    = string
    version   = string
    instance_class = string
    allocated_storage = number
    backup_retention_period = number
    multi_az  = bool
  })
  default = {
    engine    = "mysql"
    version   = "8.0"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    backup_retention_period = 7
    multi_az  = false
  }
  
  validation {
    condition     = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}
```

### Step 2: Advanced Validation Patterns

#### Complex String Validation
```hcl
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "example.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}
```

#### Complex Number Validation
```hcl
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "cpu_threshold" {
  description = "CPU utilization threshold"
  type        = number
  default     = 80.0
  
  validation {
    condition     = var.cpu_threshold >= 0.0 && var.cpu_threshold <= 100.0
    error_message = "CPU threshold must be between 0 and 100."
  }
}
```

#### Complex Collection Validation
```hcl
variable "ingress_ports" {
  description = "List of ingress port configurations"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  validation {
    condition     = alltrue([for rule in var.ingress_ports : rule.port > 0 && rule.port <= 65535])
    error_message = "All ports must be between 1 and 65535."
  }
}
```

### Step 3: Variable Usage Patterns

#### List Usage Patterns
```hcl
# Using lists in resource creation
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
}

# Using lists in security group rules
resource "aws_security_group" "web" {
  dynamic "ingress" {
    for_each = var.port_numbers
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

#### Map Usage Patterns
```hcl
# Using maps for resource configuration
resource "aws_instance" "web" {
  for_each = var.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  
  tags = merge(var.environment_tags, {
    Name = each.key
    Type = "Web Server"
  })
}

# Using maps for conditional logic
resource "aws_s3_bucket" "main" {
  bucket = "${var.environment_tags["Project"]}-${var.environment_tags["Environment"]}-bucket"
  
  tags = var.environment_tags
}
```

#### Object Usage Patterns
```hcl
# Using objects for complex configuration
resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine    = var.database_config.engine
  engine_version = var.database_config.version
  instance_class = var.database_config.instance_class
  
  allocated_storage     = var.database_config.allocated_storage
  backup_retention_period = var.database_config.backup_retention_period
  multi_az = var.database_config.multi_az
}
```

### Step 4: Variable Precedence with Complex Types

#### Complex Type Precedence
```bash
# Command line with complex types
terraform apply -var='availability_zones=["us-east-1a","us-east-1b"]'

# Environment variables
export TF_VAR_availability_zones='["us-west-2a","us-west-2b"]'

# Variable file
echo 'availability_zones = ["us-central1-a","us-central1-b"]' > terraform.tfvars

# Default value
variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
```

### Step 5: Performance Considerations

#### Optimizing Complex Variables
```hcl
# Use locals for computed values
locals {
  # Transform list
  instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
  
  # Transform map
  server_configs = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size     = config.disk_size * 1024  # Convert GB to MB
      monitoring    = config.monitoring
    }
  }
  
  # Filter and transform
  production_configs = {
    for name, config in var.server_configs : name => config
    if config.environment == "production"
  }
}
```

### Step 6: Best Practices

#### Security Best Practices
```hcl
# Mark sensitive variables
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

# Use validation for security
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
  
  validation {
    condition     = alltrue([for cidr in var.ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}
```

#### Validation Best Practices
```hcl
# Comprehensive validation
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Cross-variable validation
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

# Validation in locals
locals {
  validated_instance_count = var.instance_count <= var.max_instances ? var.instance_count : var.max_instances
}
```

## Expected Deliverables

### 1. Complex Variable Definitions
- Complete variable definitions for all complex types
- Advanced validation rules and error messages
- Default values and descriptions
- Best practices implementation

### 2. Variable Usage Patterns
- List usage in resource creation and configuration
- Map usage for resource iteration and conditional logic
- Object usage for complex configuration structures
- Tuple usage for fixed-length data

### 3. Advanced Validation Implementation
- Complex string validation with regex and functions
- Number validation with ranges and calculations
- Collection validation with for expressions
- Cross-variable validation patterns

### 4. Performance Optimization
- Local value usage for computed values
- Efficient data transformation patterns
- Filtering and mapping operations
- Best practices for large datasets

### 5. Troubleshooting Guide
- Common complex variable issues
- Validation failure debugging
- Performance optimization techniques
- Best practices for maintenance

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are the complex variable data types in Terraform, and when would you use each?**
   - List: Ordered collection of values of the same type
   - Set: Collection of unique values of the same type
   - Map: Key-value pairs where keys are strings
   - Tuple: Fixed-length list with elements of different types
   - Object: Structured data with named attributes

2. **How do you validate complex variable types?**
   - Use validation blocks with condition and error_message
   - Use functions like alltrue, anytrue, contains, regex
   - Use for expressions for collection validation
   - Use cross-variable validation patterns

3. **How do you use complex variables in resource configurations?**
   - Lists: Use with count and for_each
   - Maps: Use with for_each for resource iteration
   - Objects: Access attributes with dot notation
   - Tuples: Access elements by index

4. **What are the performance considerations for complex variables?**
   - Use locals for computed values
   - Avoid complex calculations in variable definitions
   - Use efficient data transformation patterns
   - Consider memory usage for large datasets

5. **How do you handle variable precedence with complex types?**
   - Command line: -var flag with JSON syntax
   - Environment variables: TF_VAR_* with JSON syntax
   - Variable files: terraform.tfvars
   - Default values: In variable definition

6. **What are the best practices for complex variable security?**
   - Mark sensitive variables with sensitive = true
   - Use validation for security constraints
   - Avoid hardcoding sensitive values
   - Use proper access controls

7. **How do you troubleshoot complex variable issues?**
   - Check variable definitions and types
   - Validate input values
   - Use terraform validate
   - Check variable precedence

## Troubleshooting

### Common Complex Variable Issues

#### 1. Type Mismatch
```bash
# Error: Type mismatch
# Solution: Correct the type
variable "items" {
  type    = list(string)  # Not string
  default = ["item1", "item2"]
}
```

#### 2. Validation Failure
```bash
# Error: Validation failed
# Solution: Check validation rules
variable "ports" {
  validation {
    condition     = alltrue([for port in var.ports : port > 0])
    error_message = "All ports must be greater than 0."
  }
}
```

#### 3. Complex Type Precedence
```bash
# Error: Complex type precedence issues
# Solution: Use proper JSON syntax
terraform apply -var='availability_zones=["us-east-1a","us-east-1b"]'
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of complex variable types
- Knowledge of advanced validation patterns
- Understanding of variable usage patterns
- Ability to optimize complex variable usage

Proceed to [Problem 08: Outputs - Basic and Advanced Usage](../Problem-08-Outputs-Basic/) to learn about Terraform outputs and their practical applications.
