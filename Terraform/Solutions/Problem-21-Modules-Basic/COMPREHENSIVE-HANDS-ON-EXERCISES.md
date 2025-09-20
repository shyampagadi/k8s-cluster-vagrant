# Problem 21: Comprehensive Hands-On Exercises

## 🎯 Exercise Overview

This comprehensive exercise set transforms you from a Terraform user into a module developer through progressive, hands-on challenges. Each exercise builds upon the previous one, culminating in enterprise-ready module development skills.

## 📋 Exercise Prerequisites

### Required Tools
- Terraform >= 1.0
- AWS CLI configured
- Git for version control
- Code editor (VS Code recommended)
- AWS account with appropriate permissions

### Required Knowledge
- Basic Terraform syntax (Problems 1-5)
- Variables and outputs (Problems 6-8)
- Resource dependencies (Problem 13)

## 🏗️ Exercise 1: VPC Module Development (45 minutes)

### Objective
Create a reusable VPC module with proper variable validation and comprehensive outputs.

### Step 1: Module Structure Setup (10 minutes)
```bash
# Create module directory structure
mkdir -p modules/vpc
cd modules/vpc

# Create module files
touch main.tf variables.tf outputs.tf README.md
```

### Step 2: Variable Definition (10 minutes)
Create `variables.tf` with comprehensive validation:

```hcl
variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
  
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 32
    error_message = "Name must be between 1 and 32 characters."
  }
}

variable "cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required for high availability."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.public_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.private_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

### Step 3: VPC Implementation (15 minutes)
Create `main.tf` with VPC resources:

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Type = "Private"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && length(var.private_subnets) > 0 ? length(var.public_subnets) : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway && length(var.private_subnets) > 0 ? length(var.public_subnets) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${count.index + 1}"
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

### Step 4: Output Definition (5 minutes)
Create `outputs.tf`:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}
```

### Step 5: Module Testing (5 minutes)
Create test configuration in root directory:

```hcl
# test-vpc.tf
module "test_vpc" {
  source = "./modules/vpc"

  name               = "test-vpc"
  cidr               = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "test"
    Module      = "vpc"
  }
}

output "test_vpc_id" {
  value = module.test_vpc.vpc_id
}
```

Test the module:
```bash
terraform init
terraform plan
terraform apply
```

## 🖥️ Exercise 2: EC2 Module with Security Groups (60 minutes)

### Objective
Create an EC2 module with integrated security group management and advanced configuration options.

### Step 1: Security Group Module (20 minutes)
Create `modules/security-group/main.tf`:

```hcl
resource "aws_security_group" "main" {
  name_prefix = "${var.name}-"
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress_rules)
  
  type              = "ingress"
  security_group_id = aws_security_group.main.id
  
  from_port                = var.ingress_rules[count.index].from_port
  to_port                  = var.ingress_rules[count.index].to_port
  protocol                 = var.ingress_rules[count.index].protocol
  cidr_blocks              = lookup(var.ingress_rules[count.index], "cidr_blocks", null)
  source_security_group_id = lookup(var.ingress_rules[count.index], "source_security_group_id", null)
  description              = var.ingress_rules[count.index].description
}

resource "aws_security_group_rule" "egress" {
  count = length(var.egress_rules)
  
  type              = "egress"
  security_group_id = aws_security_group.main.id
  
  from_port   = var.egress_rules[count.index].from_port
  to_port     = var.egress_rules[count.index].to_port
  protocol    = var.egress_rules[count.index].protocol
  cidr_blocks = var.egress_rules[count.index].cidr_blocks
  description = var.egress_rules[count.index].description
}
```

### Step 2: EC2 Module Implementation (25 minutes)
Create `modules/ec2/main.tf`:

```hcl
# Data source for latest AMI if not specified
data "aws_ami" "default" {
  count       = var.ami == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch Template for advanced configuration
resource "aws_launch_template" "main" {
  count = var.use_launch_template ? 1 : 0
  
  name_prefix   = "${var.name}-"
  image_id      = var.ami != "" ? var.ami : data.aws_ami.default[0].id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.vpc_security_group_ids

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        encrypted             = block_device_mappings.value.encrypted
        delete_on_termination = block_device_mappings.value.delete_on_termination
      }
    }
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = var.name
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instances
resource "aws_instance" "main" {
  count = var.instance_count

  # Use launch template if specified, otherwise direct configuration
  dynamic "launch_template" {
    for_each = var.use_launch_template ? [1] : []
    content {
      id      = aws_launch_template.main[0].id
      version = "$Latest"
    }
  }

  # Direct configuration when not using launch template
  ami                         = var.use_launch_template ? null : (var.ami != "" ? var.ami : data.aws_ami.default[0].id)
  instance_type               = var.use_launch_template ? null : var.instance_type
  key_name                    = var.use_launch_template ? null : var.key_name
  vpc_security_group_ids      = var.use_launch_template ? null : var.vpc_security_group_ids
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.use_launch_template ? null : var.user_data

  dynamic "root_block_device" {
    for_each = var.use_launch_template ? [] : [var.root_block_device]
    content {
      volume_type           = root_block_device.value.volume_type
      volume_size           = root_block_device.value.volume_size
      encrypted             = root_block_device.value.encrypted
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", true)
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${count.index + 1}"
  })

  lifecycle {
    create_before_destroy = true
  }
}
```

### Step 3: Module Integration Testing (15 minutes)
Create comprehensive test in root directory:

```hcl
# test-ec2.tf
module "web_security_group" {
  source = "./modules/security-group"

  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = module.test_vpc.vpc_id

  ingress_rules = [
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

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound"
    }
  ]

  tags = {
    Environment = "test"
  }
}

module "web_servers" {
  source = "./modules/ec2"

  name           = "web-server"
  instance_count = 2
  instance_type  = "t3.micro"
  
  vpc_security_group_ids = [module.web_security_group.security_group_id]
  subnet_ids            = module.test_vpc.public_subnets
  
  associate_public_ip_address = true
  
  root_block_device = {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Environment = "test"
    Tier        = "web"
  }
}
```

## 📊 Exercise Success Validation

### Validation Checklist
- [ ] VPC module creates all networking components
- [ ] Security group module handles ingress/egress rules
- [ ] EC2 module supports multiple instances
- [ ] All modules have proper variable validation
- [ ] Outputs are comprehensive and useful
- [ ] Resources are properly tagged
- [ ] Modules are reusable across environments

### Testing Commands
```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Verify outputs
terraform output

# Clean up
terraform destroy
```

This comprehensive exercise set provides hands-on experience with real-world module development patterns and enterprise best practices.
