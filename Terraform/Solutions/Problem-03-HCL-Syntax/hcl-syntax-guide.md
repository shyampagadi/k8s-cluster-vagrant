# HCL Syntax Guide - Complete Reference

## Overview

HashiCorp Configuration Language (HCL) is a declarative language designed for human readability and machine processing. This guide provides comprehensive coverage of HCL syntax rules, structure, and best practices.

## Basic Syntax Structure

### Block Syntax

HCL uses a block-based syntax where configurations are organized into blocks:

```hcl
# Basic block syntax
block_type "block_name" {
  attribute_name = "value"
  
  nested_block {
    nested_attribute = "value"
  }
}
```

### Attribute Syntax

Attributes assign values to names within blocks:

```hcl
# Simple attribute
attribute_name = "value"

# Attribute with expression
attribute_name = var.variable_name

# Attribute with function
attribute_name = format("%s-%s", var.prefix, var.suffix)
```

### Expression Syntax

Expressions are used to compute values:

```hcl
# Simple expression
count = var.instance_count

# Complex expression
name = "${var.project_name}-${var.environment}-${count.index + 1}"

# Function expression
bucket_name = format("%s-%s-%s", var.project, var.env, random_id.suffix.hex)
```

## Syntax Rules

### 1. Case Sensitivity

HCL is case-sensitive:

```hcl
# Correct
resource "aws_instance" "web_server" { }
variable "instance_count" { }

# Incorrect (will cause errors)
resource "aws_instance" "Web_Server" { }  # Different from above
variable "Instance_Count" { }             # Different from above
```

### 2. Identifiers

Identifiers must follow specific rules:

```hcl
# Valid identifiers
resource "aws_instance" "web_server" { }
variable "instance_count" { }
data "aws_ami" "ubuntu" { }
local "common_tags" { }

# Invalid identifiers
resource "aws_instance" "web-server" { }  # Hyphens not allowed in resource names
variable "123count" { }                    # Cannot start with number
data "aws_ami" "ubuntu 20.04" { }         # Spaces not allowed
```

### 3. String Literals

Strings must be enclosed in double quotes:

```hcl
# Correct string syntax
name = "web-server"
description = "Web server instance"

# Multi-line strings
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
EOF

# Incorrect string syntax
name = web-server        # Missing quotes
description = 'Web server'  # Single quotes not allowed
```

### 4. Comments

HCL supports single-line comments:

```hcl
# This is a single-line comment
resource "aws_instance" "web" {
  ami           = "ami-12345678"  # Inline comment
  instance_type = "t3.micro"
  
  # Block comment
  tags = {
    Name = "Web Server"
  }
}
```

### 5. Indentation

Consistent indentation is required:

```hcl
# Correct indentation
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name        = "Web Server"
    Environment = "production"
  }
}

# Incorrect indentation (will cause errors)
resource "aws_instance" "web" {
ami = "ami-12345678"  # Wrong indentation
instance_type = "t3.micro"
}
```

## Block Types

### 1. Resource Blocks

Resources represent infrastructure components:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "Web Server"
  }
}
```

### 2. Variable Blocks

Variables define input parameters:

```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0
    error_message = "Instance count must be greater than 0."
  }
}
```

### 3. Output Blocks

Outputs expose values from the configuration:

```hcl
output "instance_id" {
  description = "ID of the created instance"
  value       = aws_instance.web.id
}
```

### 4. Data Source Blocks

Data sources fetch information from external sources:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

### 5. Local Value Blocks

Local values define computed values:

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
  
  instance_name = "${var.project_name}-${var.environment}-web"
}
```

### 6. Provider Blocks

Providers configure Terraform plugins:

```hcl
provider "aws" {
  region = "us-west-2"
  
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}
```

### 7. Terraform Blocks

Terraform blocks configure Terraform behavior:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "path/to/my/key"
    region = "us-west-2"
  }
}
```

## Data Types

### Primitive Types

#### String
```hcl
# Simple string
name = "web-server"

# Multi-line string
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
EOF

# String with interpolation
bucket_name = "${var.project_name}-${var.environment}"
```

#### Number
```hcl
# Integer
count = 3

# Float
cpu_threshold = 80.5

# Number with expression
total_cost = var.instance_count * var.hourly_rate
```

#### Boolean
```hcl
# Boolean values
enable_monitoring = true
enable_debug_logging = false

# Boolean with expression
is_production = var.environment == "production"
```

### Collection Types

#### List
```hcl
# List of strings
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# List of numbers
port_numbers = [80, 443, 8080]

# List of objects
security_groups = [
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
```

#### Set
```hcl
# Set of strings (unique values)
unique_tags = ["production", "web", "frontend"]

# Set of numbers
unique_ports = [80, 443, 8080]
```

#### Map
```hcl
# Map of strings
environment_tags = {
  Environment = "production"
  Project     = "web-app"
  Owner       = "devops-team"
}

# Map of objects
server_configs = {
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
```

#### Tuple
```hcl
# Tuple (fixed-length list with different types)
server_info = ["web-server", 3, true]
```

#### Object
```hcl
# Object (structured data)
database_config = {
  engine    = "mysql"
  version   = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  backup_retention_period = 7
  multi_az  = false
}
```

## Expressions

### Arithmetic Operators

```hcl
# Addition
total_instances = var.web_count + var.db_count

# Subtraction
remaining_count = var.total_count - var.used_count

# Multiplication
total_cost = var.instance_count * var.hourly_rate

# Division
average_cost = total_cost / var.instance_count

# Modulo
remainder = var.total_count % 3
```

### Comparison Operators

```hcl
# Equality
is_production = var.environment == "production"

# Inequality
is_not_development = var.environment != "development"

# Greater than
has_enough_instances = var.instance_count > 3

# Greater than or equal
meets_minimum = var.instance_count >= 2

# Less than
under_limit = var.instance_count < 10

# Less than or equal
within_budget = var.cost <= var.budget
```

### Logical Operators

```hcl
# Logical AND
enable_monitoring = var.environment == "production" && var.monitoring_enabled

# Logical OR
is_development = var.environment == "development" || var.environment == "staging"

# Logical NOT
should_backup = !var.skip_backup
```

### String Functions

```hcl
# Format strings
formatted_name = format("%s-%s-%d", var.project_name, var.environment, random_id.suffix.hex)

# String case conversion
upper_name = upper(var.project_name)
lower_name = lower(var.project_name)

# String trimming
trimmed_name = trimspace(var.project_name)

# String replacement
clean_name = replace(var.project_name, "_", "-")

# String splitting
parts = split("-", var.project_name)

# String joining
joined_name = join("-", ["web", "server", "01"])
```

### Collection Functions

```hcl
# List functions
first_item = var.items[0]
last_item = var.items[length(var.items) - 1]
item_count = length(var.items)

# Map functions
has_key = contains(keys(var.tags), "Environment")
tag_count = length(var.tags)

# Set functions
unique_items = toset(var.items)
set_size = length(toset(var.items))
```

## String Interpolation

### Basic Interpolation

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

### Advanced Interpolation

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

### Template Functions

```hcl
# Using templatefile function
resource "aws_instance" "web" {
  user_data = templatefile("${path.module}/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    db_host     = aws_db_instance.main.endpoint
  })
}

# Using jsonencode function
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

## Attribute References

### Resource Attributes

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

### Data Source Attributes

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

### Variable References

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

### Local Value References

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

## Advanced Features

### Heredoc Syntax

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

### Dynamic Blocks

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

### For Expressions

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

## Validation and Error Handling

### Variable Validation

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

### Error Handling with Try Function

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

## Best Practices

### 1. Consistent Naming

```hcl
# Use consistent naming conventions
resource "aws_instance" "web_server" { }
resource "aws_security_group" "web_server_sg" { }
resource "aws_subnet" "web_server_subnet" { }
```

### 2. Clear Structure

```hcl
# Organize blocks logically
# 1. Terraform configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# 2. Provider configuration
provider "aws" {
  region = var.aws_region
}

# 3. Data sources
data "aws_ami" "ubuntu" { }

# 4. Local values
locals {
  common_tags = { }
}

# 5. Resources
resource "aws_vpc" "main" { }
resource "aws_subnet" "public" { }
resource "aws_instance" "web" { }

# 6. Outputs
output "instance_id" { }
```

### 3. Use Comments

```hcl
# Add comments for complex logic
resource "aws_instance" "web" {
  # Use conditional creation based on environment
  count = var.environment == "production" ? 3 : 1
  
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Apply common tags to all instances
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
  })
}
```

### 4. Validate Inputs

```hcl
# Always validate variable inputs
variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

## Common Errors and Solutions

### 1. Syntax Errors

```hcl
# Error: Missing quotes
ami = ami-12345678

# Solution: Add quotes
ami = "ami-12345678"
```

### 2. Type Errors

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

### 3. Reference Errors

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

## Conclusion

HCL syntax is the foundation of Terraform configurations. By mastering:

1. **Basic syntax rules** and structure
2. **Data types** and their usage
3. **Expressions** and functions
4. **String interpolation** and templating
5. **Attribute references** and data flow
6. **Advanced features** like heredoc and dynamic blocks
7. **Validation** and error handling

You'll be able to write maintainable, efficient, and error-free Terraform configurations. Remember to follow best practices and validate your inputs to ensure robust infrastructure code.
