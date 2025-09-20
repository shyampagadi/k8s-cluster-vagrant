# Problem 3: HCL Syntax - Hands-On Exercises

## 🎯 Exercise 1: Basic HCL Blocks (30 min)

### Resource Block Syntax
```hcl
# Basic resource block
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# Data source block
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Variable block
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

## 🎯 Exercise 2: HCL Data Types (45 min)

### String Operations
```hcl
locals {
  # String interpolation
  server_name = "web-${var.environment}-${formatdate("YYYY-MM-DD", timestamp())}"
  
  # String functions
  uppercase_name = upper(var.project_name)
  formatted_name = format("%s-%s", var.project_name, var.environment)
  
  # Heredoc strings
  user_data = <<-EOF
    #!/bin/bash
    echo "Server: ${local.server_name}"
    yum update -y
    yum install -y httpd
    systemctl start httpd
  EOF
}
```

### Complex Data Types
```hcl
variable "server_config" {
  type = object({
    name         = string
    instance_type = string
    ports        = list(number)
    tags         = map(string)
    monitoring   = bool
  })
  
  default = {
    name         = "web-server"
    instance_type = "t3.micro"
    ports        = [80, 443]
    tags = {
      Environment = "dev"
      Team        = "platform"
    }
    monitoring = true
  }
}
```

## 🎯 Exercise 3: Dynamic Blocks (60 min)

### Dynamic Security Group Rules
```hcl
variable "ingress_rules" {
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

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}
```

## 🎯 Exercise 4: Functions and Expressions (45 min)

### Built-in Functions
```hcl
locals {
  # Collection functions
  unique_azs = distinct(data.aws_availability_zones.available.names)
  subnet_count = length(var.availability_zones)
  
  # String functions
  region_short = substr(var.aws_region, 0, 6)
  env_upper = upper(var.environment)
  
  # Numeric functions
  max_instances = max(var.min_size, var.desired_capacity)
  
  # Date functions
  deployment_date = formatdate("YYYY-MM-DD", timestamp())
  
  # Encoding functions
  user_data_b64 = base64encode(local.user_data_script)
  
  # Type conversion
  port_strings = [for port in var.ports : tostring(port)]
}
```

## 🎯 Exercise 5: Advanced HCL Patterns (90 min)

### Conditional Expressions
```hcl
resource "aws_instance" "web" {
  count = var.create_instance ? var.instance_count : 0
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.environment == "production" ? "m5.large" : "t3.micro"
  
  monitoring = var.environment == "production" ? true : false
  
  vpc_security_group_ids = var.enable_security_group ? [aws_security_group.web[0].id] : []
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${count.index + 1}"
      Type = var.environment == "production" ? "prod-server" : "dev-server"
    }
  )
}

# Conditional resource creation
resource "aws_security_group" "web" {
  count = var.enable_security_group ? 1 : 0
  
  name_prefix = "${var.project_name}-web-"
  description = "Security group for ${var.project_name}"
}
```

### For Expressions
```hcl
locals {
  # Transform list to map
  instance_map = {
    for idx, instance in aws_instance.web :
    instance.tags.Name => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
  
  # Filter and transform
  production_instances = {
    for name, instance in local.instance_map :
    name => instance
    if contains(split("-", name), "prod")
  }
  
  # Nested for expressions
  subnet_route_associations = {
    for subnet in var.subnets :
    subnet.name => {
      for route in subnet.routes :
      route.destination => route.target
    }
  }
}
```

## 📊 Validation Exercises

### HCL Syntax Validation
```bash
# Format check
terraform fmt -check

# Validate syntax
terraform validate

# Parse and analyze
terraform console
> var.server_config
> local.instance_map
> length(aws_instance.web)
```

### Testing HCL Expressions
```hcl
# Test file: test-expressions.tf
output "test_string_interpolation" {
  value = "Server: ${var.project_name}-${var.environment}"
}

output "test_conditional" {
  value = var.environment == "production" ? "prod-config" : "dev-config"
}

output "test_for_expression" {
  value = [for i in range(3) : "instance-${i}"]
}

output "test_function_chain" {
  value = upper(substr(var.project_name, 0, 3))
}
```

## 📋 Success Checklist
- [ ] Create basic resource, data, and variable blocks
- [ ] Implement string interpolation and heredoc syntax
- [ ] Use complex data types (objects, lists, maps)
- [ ] Build dynamic blocks with for_each
- [ ] Apply built-in functions and expressions
- [ ] Implement conditional logic and for expressions
- [ ] Validate HCL syntax and formatting
- [ ] Test expressions in Terraform console
