# Problem 06: Variables - Basic Types and Usage

## Overview

This solution provides comprehensive understanding of Terraform variables, focusing on basic data types, variable definitions, usage patterns, and best practices. Mastering variables is essential for creating flexible and reusable Terraform configurations.

## Learning Objectives

- Understand Terraform variable concepts and purposes
- Master basic variable data types (string, number, bool)
- Learn variable definition syntax and best practices
- Understand variable precedence and resolution
- Learn variable validation and constraints
- Master variable usage patterns and expressions
- Understand variable file organization and management

## Problem Statement

You've mastered resource lifecycle and state management concepts. Now your team lead wants you to become proficient in Terraform variables, starting with basic types and usage patterns. You need to understand how to define, validate, and use variables effectively in your configurations.

## Solution Components

This solution includes:
1. **Variable Fundamentals** - Understanding what variables are and why they're important
2. **Basic Data Types** - String, number, and boolean variables
3. **Variable Definition** - Syntax, validation, and best practices
4. **Variable Usage** - Referencing variables in configurations
5. **Variable Precedence** - Understanding how Terraform resolves variable values
6. **Variable Files** - Organization and management of variable files
7. **Best Practices** - Security, validation, and maintenance

## Implementation Guide

### Step 1: Understanding Variable Fundamentals

#### What are Variables?
Variables in Terraform are input parameters that allow you to customize your configuration without modifying the code. They make your configurations:
- **Flexible**: Same code for different environments
- **Reusable**: Share configurations across projects
- **Maintainable**: Change values without code changes

#### Variable Benefits
- **Environment-specific values**: Different values for dev/staging/prod
- **Team collaboration**: Share configurations with different settings
- **Security**: Keep sensitive values out of code
- **Flexibility**: Easy to modify without code changes

### Step 2: Basic Data Types

#### String Variables
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
```

#### Number Variables
```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "instance_size" {
  description = "Instance size multiplier"
  type        = number
  default     = 1.0
}

variable "port" {
  description = "Port number"
  type        = number
  default     = 80
}
```

#### Boolean Variables
```hcl
variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}

variable "create_database" {
  description = "Create database instance"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable encryption"
  type        = bool
  default     = true
}
```

### Step 3: Variable Definition Best Practices

#### Complete Variable Definition
```hcl
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type."
  }
}
```

#### Variable Components
- **description**: Documentation for the variable
- **type**: Data type constraint
- **default**: Default value if not provided
- **validation**: Rules to validate input values

### Step 4: Variable Usage Patterns

#### Basic Variable References
```hcl
# Reference variables with var. prefix
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  count         = var.instance_count
  
  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}
```

#### Conditional Variable Usage
```hcl
# Use variables in conditional expressions
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.environment == "production" ? "t3.large" : var.instance_type
  
  monitoring = var.enable_monitoring
}
```

#### Variable Interpolation
```hcl
# Use variables in string interpolation
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-bucket"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### Step 5: Variable Precedence

#### Precedence Order (highest to lowest)
1. **Command line**: `-var` flag
2. **Environment variables**: `TF_VAR_*`
3. **Variable files**: `terraform.tfvars`
4. **Default values**: In variable definition

#### Examples
```bash
# Command line (highest precedence)
terraform apply -var="instance_count=5"

# Environment variable
export TF_VAR_instance_count=3

# Variable file
echo 'instance_count = 2' > terraform.tfvars

# Default value (lowest precedence)
variable "instance_count" {
  default = 1
}
```

### Step 6: Variable Files Organization

#### terraform.tfvars
```hcl
# Main variable file
project_name = "my-web-app"
environment = "production"
instance_count = 3
instance_type = "t3.large"
enable_monitoring = true
```

#### terraform.tfvars.example
```hcl
# Example variable file
project_name = "example-project"
environment = "development"
instance_count = 1
instance_type = "t3.micro"
enable_monitoring = false
```

#### Environment-specific files
```hcl
# production.tfvars
environment = "production"
instance_count = 5
instance_type = "t3.large"
enable_monitoring = true

# development.tfvars
environment = "development"
instance_count = 1
instance_type = "t3.micro"
enable_monitoring = false
```

### Step 7: Variable Validation

#### String Validation
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}
```

#### Number Validation
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
```

#### Boolean Validation
```hcl
variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}
```

## Expected Deliverables

### 1. Variable Definition Examples
- Complete variable definitions for all basic types
- Validation rules and error messages
- Default values and descriptions
- Best practices implementation

### 2. Variable Usage Patterns
- Basic variable references in resources
- Conditional variable usage
- String interpolation with variables
- Complex variable expressions

### 3. Variable File Organization
- Main terraform.tfvars file
- Example variable file
- Environment-specific variable files
- Variable file naming conventions

### 4. Variable Validation Implementation
- String validation with regex and contains
- Number validation with ranges
- Boolean validation patterns
- Custom validation functions

### 5. Variable Precedence Documentation
- Complete precedence order explanation
- Examples of each precedence level
- Best practices for variable resolution
- Troubleshooting variable conflicts

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are Terraform variables, and why are they important?**
   - Variables are input parameters that customize configurations
   - They make configurations flexible, reusable, and maintainable
   - They enable environment-specific values and team collaboration

2. **What are the three basic variable data types, and how do you define them?**
   - String: text values
   - Number: numeric values (integers and floats)
   - Boolean: true/false values

3. **How do you reference variables in Terraform configurations?**
   - Use var. prefix followed by variable name
   - Example: var.project_name, var.instance_count

4. **What is variable precedence, and what is the order from highest to lowest?**
   - Command line (-var flag)
   - Environment variables (TF_VAR_*)
   - Variable files (terraform.tfvars)
   - Default values

5. **How do you validate variable input values?**
   - Use validation blocks with condition and error_message
   - Use functions like contains, regex, and range checks

6. **What are the best practices for variable file organization?**
   - Use terraform.tfvars for main values
   - Create terraform.tfvars.example for documentation
   - Use environment-specific files for different environments

7. **How do you use variables in conditional expressions and string interpolation?**
   - Conditional: var.environment == "production" ? "t3.large" : "t3.micro"
   - Interpolation: "${var.project_name}-${var.environment}"

## Troubleshooting

### Common Variable Issues

#### 1. Variable Not Found
```bash
# Error: Reference to undeclared variable
# Solution: Define the variable
variable "missing_variable" {
  description = "Missing variable"
  type        = string
  default     = "default-value"
}
```

#### 2. Type Mismatch
```bash
# Error: Type mismatch
# Solution: Correct the type
variable "count" {
  type    = number  # Not string
  default = 3
}
```

#### 3. Validation Failure
```bash
# Error: Validation failed
# Solution: Check validation rules
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform variables
- Knowledge of basic data types and usage patterns
- Understanding of variable precedence and validation
- Ability to organize and manage variable files

Proceed to [Problem 07: Variables - Complex Types and Validation](../Problem-07-Variables-Complex/) to learn about advanced variable types and validation patterns.
