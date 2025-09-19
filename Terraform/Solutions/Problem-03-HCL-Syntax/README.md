# Problem 03: HCL Syntax Deep Dive

## Overview

This solution provides comprehensive understanding of HashiCorp Configuration Language (HCL) syntax, data types, expressions, and advanced features. Mastering HCL is essential for writing effective Terraform configurations.

## Learning Objectives

- Understand HCL syntax rules and structure
- Master all HCL data types and their usage
- Learn HCL expressions, functions, and operators
- Understand string interpolation and templating
- Master attribute references and data flow
- Learn advanced HCL features like heredoc and dynamic blocks
- Understand HCL validation and error handling

## Problem Statement

You've successfully installed Terraform and created your first resource. Now your team lead wants you to become proficient in HCL syntax before moving to more complex infrastructure. You need to understand the language deeply to write maintainable, efficient, and error-free Terraform configurations.

## Solution Components

This solution includes:
1. **HCL Syntax Guide** - Complete syntax rules and structure
2. **Data Types Reference** - All HCL data types with examples
3. **Expressions and Functions** - Advanced expression usage
4. **String Interpolation** - Templating and dynamic values
5. **Attribute References** - Data flow and dependencies
6. **Advanced Features** - Heredoc, dynamic blocks, and more
7. **Validation and Debugging** - Error handling and troubleshooting

## Implementation Guide

### Step 1: Understanding HCL Syntax Rules

#### Basic Syntax Structure
HCL uses a block-based syntax with attributes and expressions:

```hcl
# Block syntax
block_type "block_name" {
  # Attributes
  attribute_name = "value"
  
  # Nested blocks
  nested_block {
    nested_attribute = "value"
  }
}
```

#### Key Syntax Rules
1. **Case Sensitivity:** HCL is case-sensitive
2. **Indentation:** Use consistent indentation (spaces or tabs)
3. **Quotes:** Use double quotes for strings
4. **Comments:** Use `#` for single-line comments
5. **Identifiers:** Must start with letter or underscore

#### Valid Identifiers
```hcl
# Valid identifiers
resource "aws_instance" "web_server" { }
variable "instance_count" { }
data "aws_ami" "ubuntu" { }

# Invalid identifiers (will cause errors)
resource "aws_instance" "web-server" { }  # Hyphens not allowed in resource names
variable "123count" { }                    # Cannot start with number
```

### Step 2: Mastering HCL Data Types

#### Primitive Types

**String**
```hcl
# String values
variable "instance_name" {
  type    = string
  default = "web-server"
}

# Multi-line strings
variable "user_data" {
  type = string
  default = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
  EOF
}
```

**Number**
```hcl
# Integer
variable "instance_count" {
  type    = number
  default = 3
}

# Float
variable "cpu_utilization_threshold" {
  type    = number
  default = 80.5
}
```

**Boolean**
```hcl
# Boolean values
variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "enable_debug_logging" {
  type    = bool
  default = false
}
```

#### Collection Types

**List**
```hcl
# List of strings
variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# List of numbers
variable "port_numbers" {
  type    = list(number)
  default = [80, 443, 8080]
}

# List of objects
variable "security_groups" {
  type = list(object({
    name        = string
    description = string
    ports       = list(number)
  }))
  default = [
    {
      name        = "web"
      description = "Web server security group"
      ports       = [80, 443]
    },
    {
      name        = "database"
      description = "Database security group"
      ports       = [3306, 5432]
    }
  ]
}
```

**Set**
```hcl
# Set of strings (unique values)
variable "unique_tags" {
  type    = set(string)
  default = ["production", "web", "frontend"]
}

# Set of numbers
variable "unique_ports" {
  type    = set(number)
  default = [80, 443, 8080]
}
```

**Map**
```hcl
# Map of strings
variable "environment_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "web-app"
    Owner       = "devops-team"
  }
}

# Map of objects
variable "server_configs" {
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

**Tuple**
```hcl
# Tuple (fixed-length list with different types)
variable "server_info" {
  type    = tuple([string, number, bool])
  default = ["web-server", 3, true]
}
```

**Object**
```hcl
# Object (structured data)
variable "database_config" {
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
}
```

### Step 3: Learning HCL Expressions

#### Arithmetic Operators
```hcl
# Basic arithmetic
locals {
  total_instances = var.web_count + var.db_count
  half_instances  = var.total_count / 2
  remaining_count = var.total_count % 3
}

# Advanced calculations
locals {
  cost_per_hour = var.instance_count * var.hourly_rate
  total_cost    = cost_per_hour * 24 * 30  # Monthly cost
}
```

#### Comparison Operators
```hcl
# Comparison operations
locals {
  is_production = var.environment == "production"
  has_enough_instances = var.instance_count >= 3
  is_valid_region = var.region != "invalid-region"
}

# Conditional logic
resource "aws_instance" "web" {
  count = var.environment == "production" ? 3 : 1
  
  ami           = var.ami_id
  instance_type = var.instance_count > 5 ? "t3.large" : "t3.micro"
}
```

#### Logical Operators
```hcl
# Logical operations
locals {
  enable_monitoring = var.environment == "production" && var.monitoring_enabled
  is_development    = var.environment == "development" || var.environment == "staging"
  should_backup      = !var.skip_backup
}
```

#### String Functions
```hcl
# String manipulation
locals {
  formatted_name = format("%s-%s-%d", var.project_name, var.environment, random_id.suffix.hex)
  upper_name     = upper(var.project_name)
  lower_name     = lower(var.project_name)
  trimmed_name   = trimspace(var.project_name)
}

# String interpolation
resource "aws_instance" "web" {
  tags = {
    Name = "${var.project_name}-${var.environment}-web"
    Description = "Web server for ${var.project_name} in ${var.environment}"
  }
}
```

### Step 4: Understanding String Interpolation

#### Basic Interpolation
```hcl
# Simple interpolation
resource "aws_instance" "web" {
  ami           = "ami-${var.ami_suffix}"
  instance_type = "t3.${var.instance_size}"
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}
```

#### Advanced Interpolation
```hcl
# Complex interpolation
locals {
  bucket_name = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  dns_name    = "${var.subdomain}.${var.domain_name}"
  full_url    = "https://${dns_name}"
}

# Conditional interpolation
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Name = var.create_instances ? "${var.project_name}-web-${count.index + 1}" : "not-created"
  }
}
```

#### Template Functions
```hcl
# Using templatefile function
resource "aws_instance" "web" {
  user_data = templatefile("${path.module}/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    db_host     = aws_db_instance.main.endpoint
  })
}
```

### Step 5: Mastering Attribute References

#### Resource Attributes
```hcl
# Referencing resource attributes
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Reference to VPC ID
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id  # Reference to subnet ID
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

#### Data Source Attributes
```hcl
# Using data source attributes
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id  # Reference to data source
  instance_type = "t3.micro"
}
```

#### Variable References
```hcl
# Referencing variables
variable "instance_count" {
  type    = number
  default = 3
}

resource "aws_instance" "web" {
  count         = var.instance_count  # Reference to variable
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

#### Local Value References
```hcl
# Using local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
  
  instance_name = "${var.project_name}-${var.environment}-web"
}

resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-${count.index + 1}"
  })
}
```

### Step 6: Advanced HCL Features

#### Heredoc Syntax
```hcl
# Multi-line strings with heredoc
resource "aws_instance" "web" {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    
    # Configure Apache
    echo "ServerName ${var.domain_name}" >> /etc/httpd/conf/httpd.conf
    
    # Start Apache
    systemctl start httpd
    systemctl enable httpd
    
    # Create index page
    echo "<h1>Welcome to ${var.project_name}</h1>" > /var/www/html/index.html
  EOF
}

# JSON heredoc
resource "aws_iam_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}
```

#### Dynamic Blocks
```hcl
# Dynamic blocks for variable configurations
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
```

#### For Expressions
```hcl
# For expressions for data transformation
locals {
  # Transform list
  instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
  
  # Transform map
  instance_configs = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size     = config.disk_size * 1024  # Convert GB to MB
      monitoring    = config.monitoring
    }
  }
  
  # Filter and transform
  production_instances = {
    for name, config in var.server_configs : name => config
    if config.environment == "production"
  }
}
```

### Step 7: Validation and Error Handling

#### Variable Validation
```hcl
# String validation
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Number validation
variable "instance_count" {
  type        = number
  description = "Number of instances"
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Complex validation
variable "cidr_block" {
  type        = string
  description = "CIDR block for VPC"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
}
```

#### Error Handling with Try Function
```hcl
# Using try function for error handling
locals {
  # Try to get value, use default if error
  instance_type = try(var.instance_type, "t3.micro")
  
  # Try multiple values
  ami_id = try(
    var.ami_id,
    data.aws_ami.ubuntu.id,
    "ami-0c55b159cbfafe1d0"
  )
  
  # Try with complex expressions
  database_endpoint = try(
    aws_db_instance.main.endpoint,
    "localhost:3306"
  )
}
```

## Expected Deliverables

### 1. Comprehensive HCL Syntax Reference
- Complete syntax rules and structure documentation
- Examples of valid and invalid HCL syntax
- Best practices for HCL code organization
- Common syntax errors and how to avoid them

### 2. Data Types Implementation
- Working examples of all HCL data types
- Complex data structures (nested objects, lists of objects)
- Data type validation and constraints
- Type conversion examples and best practices

### 3. Advanced Expression Examples
- Complex arithmetic and logical expressions
- String manipulation and formatting
- Conditional logic and ternary operators
- Function usage and custom expressions

### 4. String Interpolation Mastery
- Basic and advanced interpolation examples
- Template functions and dynamic content
- Conditional interpolation patterns
- Best practices for string handling

### 5. Attribute Reference Documentation
- Resource attribute referencing patterns
- Data source attribute usage
- Variable and local value references
- Dependency management through references

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are the key syntax rules in HCL, and how do they differ from other configuration languages?**
   - Case sensitivity, indentation requirements, quote usage
   - Block-based structure with attributes and expressions
   - Identifier naming conventions and restrictions

2. **How do you handle different data types in HCL, and what are the use cases for each?**
   - Primitive types: string, number, bool
   - Collection types: list, set, map, tuple, object
   - When to use each type and their limitations

3. **What are the different types of expressions in HCL, and how do you use them effectively?**
   - Arithmetic, comparison, and logical operators
   - String functions and manipulation
   - Conditional expressions and ternary operators

4. **How does string interpolation work in HCL, and what are the advanced techniques?**
   - Basic interpolation with variables and attributes
   - Template functions and dynamic content
   - Conditional interpolation patterns

5. **What are attribute references, and how do they enable data flow between resources?**
   - Resource attribute referencing
   - Data source attribute usage
   - Dependency management through references

6. **What are the advanced HCL features, and when should you use them?**
   - Heredoc syntax for multi-line strings
   - Dynamic blocks for variable configurations
   - For expressions for data transformation

7. **How do you implement validation and error handling in HCL?**
   - Variable validation rules
   - Try function for error handling
   - Best practices for robust configurations

## Troubleshooting

### Common HCL Errors

#### 1. Syntax Errors
```hcl
# Error: Invalid syntax
resource "aws_instance" "web" {
  ami = "ami-12345678"  # Missing quotes
  instance_type = t3.micro  # Missing quotes
}

# Solution: Proper syntax
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}
```

#### 2. Type Errors
```hcl
# Error: Type mismatch
variable "count" {
  type    = string
  default = 3  # Number assigned to string type
}

# Solution: Correct type
variable "count" {
  type    = number
  default = 3
}
```

#### 3. Reference Errors
```hcl
# Error: Undefined reference
resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id  # Resource doesn't exist
}

# Solution: Define resource first
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of HCL syntax and structure
- Mastery of all HCL data types
- Proficiency in expressions and functions
- Understanding of string interpolation and templating
- Knowledge of advanced HCL features

Proceed to [Problem 04: Provider Ecosystem Understanding](../Problem-04-Provider-Ecosystem/) to learn about Terraform providers and their configuration.
