# HCL Syntax Deep Dive - Complete Reference

## HCL Fundamentals

### What is HCL?
HashiCorp Configuration Language (HCL) is a structured configuration language designed to be both human and machine-readable. It's the native language for Terraform configurations.

### HCL vs JSON Comparison
```hcl
# HCL - Human-readable
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

```json
// JSON - Machine-readable
{
  "resource": {
    "aws_instance": {
      "web": {
        "ami": "ami-0c02fb55956c7d316",
        "instance_type": "t3.micro",
        "tags": {
          "Name": "WebServer"
        }
      }
    }
  }
}
```

## Core HCL Constructs

### 1. Blocks
Blocks are containers for other content and represent configuration objects.

```hcl
# Block syntax: block_type "label1" "label2" {
#   argument = value
# }

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

### 2. Arguments
Arguments assign values to names within blocks.

```hcl
resource "aws_instance" "web" {
  # Simple arguments
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  # Complex arguments
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Nested block arguments
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }
}
```

### 3. Expressions
Expressions represent values and can be literals, references, or function calls.

```hcl
# Literal expressions
ami           = "ami-0c02fb55956c7d316"
instance_type = "t3.micro"
count         = 3
enabled       = true

# Reference expressions
subnet_id = aws_subnet.main.id
vpc_id    = data.aws_vpc.default.id

# Function call expressions
availability_zone = data.aws_availability_zones.available.names[0]
instance_name     = format("%s-%02d", var.prefix, count.index + 1)
```

## Data Types in Detail

### Strings
```hcl
# Simple strings
name = "web-server"

# Multi-line strings
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
EOF

# Heredoc with indentation
script = <<-SCRIPT
  #!/bin/bash
  echo "Starting setup..."
  # Commands here
SCRIPT
```

### Numbers
```hcl
# Integers
count = 3
port  = 80

# Floats
cpu_utilization = 75.5
memory_ratio    = 0.8
```

### Booleans
```hcl
# Boolean values
enabled                = true
delete_on_termination = false
associate_public_ip    = var.environment == "production" ? false : true
```

### Lists
```hcl
# Simple lists
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
ports             = [80, 443, 8080]

# Complex lists
ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

### Maps
```hcl
# Simple maps
tags = {
  Name        = "web-server"
  Environment = "production"
  Owner       = "devops-team"
}

# Nested maps
instance_config = {
  web = {
    instance_type = "t3.medium"
    disk_size     = 20
  }
  db = {
    instance_type = "t3.large"
    disk_size     = 100
  }
}
```

## String Interpolation and Expressions

### Basic Interpolation
```hcl
# Variable interpolation
name = "${var.project_name}-web-server"

# Resource attribute interpolation
subnet_id = aws_subnet.main.id

# Complex interpolation
instance_name = "${var.environment}-${var.application}-${formatdate("YYYY-MM-DD", timestamp())}"
```

### Conditional Expressions
```hcl
# Ternary operator
instance_type = var.environment == "production" ? "t3.large" : "t3.micro"

# Complex conditionals
security_groups = var.environment == "production" ? [
  aws_security_group.web.id,
  aws_security_group.monitoring.id
] : [aws_security_group.web.id]
```

### Function Calls
```hcl
# String functions
upper_name = upper(var.project_name)
formatted_date = formatdate("YYYY-MM-DD", timestamp())

# Collection functions
first_az = element(data.aws_availability_zones.available.names, 0)
subnet_count = length(var.subnet_cidrs)

# Encoding functions
user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  database_url = var.database_url
}))
```

## Advanced HCL Features

### For Expressions
```hcl
# List comprehension
instance_names = [for i in range(var.instance_count) : "${var.prefix}-${i}"]

# Map comprehension
instance_tags = {
  for i, instance in aws_instance.web : 
  instance.id => {
    Name = "${var.prefix}-${i}"
    Index = i
  }
}

# Filtering
production_instances = [
  for instance in aws_instance.web : instance
  if instance.tags.Environment == "production"
]
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### Splat Expressions
```hcl
# Get all instance IDs
instance_ids = aws_instance.web[*].id

# Get specific attributes
instance_private_ips = aws_instance.web[*].private_ip

# Complex splat with filtering
web_instance_ids = [
  for instance in aws_instance.web : instance.id
  if instance.tags.Type == "web"
]
```

## Comments and Documentation

### Comment Styles
```hcl
# Single-line comment
resource "aws_instance" "web" {
  ami = "ami-0c02fb55956c7d316"  # Inline comment
  
  /*
   * Multi-line comment
   * Useful for longer explanations
   */
  instance_type = "t3.micro"
}
```

### Documentation Best Practices
```hcl
# Resource: Web Server Instance
# Purpose: Hosts the main web application
# Dependencies: VPC, Security Group, Key Pair
resource "aws_instance" "web" {
  # AMI: Latest Amazon Linux 2
  ami = data.aws_ami.amazon_linux.id
  
  # Instance type based on environment
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  # Security: Attach web security group
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Networking: Place in private subnet
  subnet_id = aws_subnet.private[0].id
  
  # Monitoring: Enable detailed monitoring in production
  monitoring = var.environment == "production"
  
  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Purpose     = "Web application hosting"
    ManagedBy   = "Terraform"
  }
}
```

## HCL Syntax Rules and Conventions

### Naming Conventions
```hcl
# Resource names: lowercase with underscores
resource "aws_instance" "web_server" {}

# Variable names: lowercase with underscores
variable "instance_count" {}

# Tag names: PascalCase
tags = {
  Name        = "WebServer"
  Environment = "Production"
}
```

### Formatting Rules
```hcl
# Proper indentation (2 spaces)
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# Alignment for readability
variable "instance_config" {
  type = object({
    ami           = string
    instance_type = string
    key_name      = string
  })
}
```

### Error Handling and Validation
```hcl
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

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

## Common Patterns and Idioms

### Resource Naming Pattern
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
    Type = "WebServer"
  })
}
```

### Conditional Resource Creation
```hcl
# Create load balancer only in production
resource "aws_lb" "web" {
  count = var.environment == "production" ? 1 : 0
  
  name               = "${local.name_prefix}-web-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  
  tags = local.common_tags
}
```

This comprehensive guide covers all aspects of HCL syntax needed for mastering Terraform configurations.
