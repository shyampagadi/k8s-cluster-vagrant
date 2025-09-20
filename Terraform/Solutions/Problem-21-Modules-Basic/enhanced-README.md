# Problem 21: Terraform Modules - Basic Development and Usage

## Overview

This solution provides comprehensive understanding of Terraform modules, including module development, structure, versioning, and best practices. Modules are essential for creating reusable, maintainable, and scalable infrastructure code.

## Learning Objectives

- Understand Terraform module concepts and architecture
- Learn module development best practices and structure
- Master module inputs, outputs, and variable management
- Understand module versioning and distribution strategies
- Learn module testing and validation techniques
- Master module composition and dependency management
- Understand module security and compliance considerations

## Problem Statement

You've mastered advanced Terraform concepts and now need to create reusable infrastructure components. Your team lead wants you to develop Terraform modules that can be shared across projects and teams, following enterprise-grade development practices.

## Module Architecture Fundamentals

### What are Terraform Modules?

Modules are containers for multiple resources that are used together. They enable:
- **Code Reusability**: Write once, use many times
- **Abstraction**: Hide complexity behind simple interfaces
- **Standardization**: Enforce organizational standards
- **Collaboration**: Share infrastructure patterns across teams

### Module Types

1. **Root Module**: The main working directory containing .tf files
2. **Child Modules**: Modules called by other modules
3. **Published Modules**: Modules shared via Terraform Registry
4. **Local Modules**: Modules stored in the same repository

## Module Development Structure

### Standard Module Layout

```
terraform-aws-vpc/
├── README.md                 # Module documentation
├── main.tf                   # Primary resource definitions
├── variables.tf              # Input variable declarations
├── outputs.tf                # Output value declarations
├── versions.tf               # Provider version constraints
├── examples/                 # Usage examples
│   ├── basic/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── advanced/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── modules/                  # Sub-modules
│   ├── subnets/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security-groups/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── tests/                    # Module tests
    ├── unit/
    └── integration/
```

### Module Implementation Example

**main.tf**
```hcl
# VPC Module - main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# VPC Resource
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_igw ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index + 1}"
      Type = "public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${count.index + 1}"
      Type = "private"
    }
  )
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  count = var.create_igw && length(var.public_subnet_cidrs) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = var.create_igw && length(var.public_subnet_cidrs) > 0 ? length(var.public_subnet_cidrs) : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  
  domain = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip-${count.index + 1}"
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt-${count.index + 1}"
    }
  )
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

**variables.tf**
```hcl
# VPC Module - variables.tf

variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
  
  validation {
    condition     = length(var.name) > 0
    error_message = "Name cannot be empty."
  }
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "A list of public subnet CIDR blocks"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "A list of private subnet CIDR blocks"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.tags : length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be 128 characters or less, and values must be 256 characters or less."
  }
}
```

**outputs.tf**
```hcl
# VPC Module - outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}
```

## Module Usage Examples

### Basic Usage

```hcl
# Basic VPC Module Usage
module "vpc" {
  source = "./modules/vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Advanced Usage with Multiple Modules

```hcl
# Advanced Multi-Module Usage
module "vpc" {
  source = "./modules/vpc"
  
  name               = "production-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = data.aws_availability_zones.available.names
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  
  tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security-groups"
  
  vpc_id = module.vpc.vpc_id
  
  security_groups = {
    web = {
      description = "Security group for web servers"
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
    }
    database = {
      description = "Security group for database servers"
      ingress_rules = [
        {
          from_port       = 3306
          to_port         = 3306
          protocol        = "tcp"
          security_groups = ["web"]
        }
      ]
    }
  }
  
  tags = local.common_tags
}

module "application" {
  source = "./modules/application"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.security_group_ids["web"]
  
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 10
  desired_size  = 3
  
  tags = local.common_tags
}
```

## Module Versioning and Distribution

### Semantic Versioning

```hcl
# Using specific module version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"  # Allow patch updates
  
  # Module configuration
}

# Using version constraints
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 3.14.0, < 4.0.0"  # Allow minor updates
  
  # Module configuration
}
```

### Git-based Module Sources

```hcl
# Using Git repository
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//vpc?ref=v1.2.0"
  
  # Module configuration
}

# Using SSH
module "vpc" {
  source = "git::ssh://git@github.com/company/terraform-modules.git//vpc?ref=v1.2.0"
  
  # Module configuration
}

# Using specific branch
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//vpc?ref=feature/new-functionality"
  
  # Module configuration
}
```

## Module Testing Strategies

### Unit Testing with Terratest

```go
// test/vpc_test.go
package test

import (
    "testing"
    
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
        
        Vars: map[string]interface{}{
            "name":               "test-vpc",
            "cidr_block":         "10.0.0.0/16",
            "availability_zones": []string{"us-west-2a", "us-west-2b"},
            "public_subnet_cidrs": []string{"10.0.1.0/24", "10.0.2.0/24"},
            "private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    // Test outputs
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
    
    publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
    assert.Len(t, publicSubnetIds, 2)
    
    privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    assert.Len(t, privateSubnetIds, 2)
}
```

### Integration Testing

```bash
#!/bin/bash
# test/integration_test.sh

set -e

echo "Running integration tests..."

# Test basic example
cd examples/basic
terraform init
terraform plan
terraform apply -auto-approve

# Verify resources exist
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# Cleanup
terraform destroy -auto-approve

echo "Integration tests passed!"
```

## Module Documentation

### README.md Template

```markdown
# AWS VPC Terraform Module

This module creates a VPC with public and private subnets, internet gateway, and NAT gateways.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all resources | `string` | n/a | yes |
| cidr_block | The CIDR block for the VPC | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| public_subnet_cidrs | List of public subnet CIDR blocks | `list(string)` | `[]` | no |
| private_subnet_cidrs | List of private subnet CIDR blocks | `list(string)` | `[]` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `false` | no |
| tags | Map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_arn | ARN of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |

## Examples

- [Basic](examples/basic) - Basic VPC with public and private subnets
- [Advanced](examples/advanced) - Advanced VPC with multiple features

## License

Apache 2 Licensed. See LICENSE for full details.
```

## Module Security Best Practices

### Input Validation

```hcl
# Comprehensive input validation
variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
  
  validation {
    condition     = can(regex("^10\\.|^172\\.(1[6-9]|2[0-9]|3[01])\\.|^192\\.168\\.", var.cidr_block))
    error_message = "CIDR block must be within private IP ranges (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.tags : 
      length(key) <= 128 && 
      length(value) <= 256 &&
      !contains(["aws:", "AWS:"], substr(key, 0, 4))
    ])
    error_message = "Tag keys must be 128 characters or less, values must be 256 characters or less, and keys cannot start with 'aws:' or 'AWS:'."
  }
}
```

### Sensitive Data Handling

```hcl
# Handle sensitive outputs
output "database_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}

# Use random passwords
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "main" {
  password = random_password.db_password.result
  # Other configuration
}
```

## Module Composition Patterns

### Nested Modules

```hcl
# Parent module calling child modules
module "networking" {
  source = "./modules/networking"
  
  vpc_config = var.vpc_config
  tags       = local.common_tags
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  instance_config = var.instance_config
  tags           = local.common_tags
}

module "database" {
  source = "./modules/database"
  
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.database_subnet_ids
  allowed_cidr_blocks  = [module.networking.vpc_cidr_block]
  
  database_config = var.database_config
  tags           = local.common_tags
}
```

### Module Dependencies

```hcl
# Explicit dependencies between modules
module "vpc" {
  source = "./modules/vpc"
  # VPC configuration
}

module "security_groups" {
  source = "./modules/security-groups"
  
  vpc_id = module.vpc.vpc_id
  
  depends_on = [module.vpc]
}

module "application" {
  source = "./modules/application"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.web_sg_id
  
  depends_on = [
    module.vpc,
    module.security_groups
  ]
}
```

## Troubleshooting Common Issues

### Module Source Issues

```bash
# Problem: Module not found
Error: Module not found

# Solution: Check module source path
module "vpc" {
  source = "./modules/vpc"  # Correct relative path
  # or
  source = "git::https://github.com/user/repo.git//modules/vpc"
}
```

### Variable Type Mismatches

```hcl
# Problem: Type mismatch
variable "subnet_cidrs" {
  type = list(string)
}

# Calling with wrong type
module "vpc" {
  subnet_cidrs = "10.0.1.0/24"  # Should be list
}

# Solution: Use correct type
module "vpc" {
  subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
}
```

### Output Reference Issues

```hcl
# Problem: Output not available
resource "aws_instance" "web" {
  subnet_id = module.vpc.subnet_id  # Output doesn't exist
}

# Solution: Check module outputs
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]  # Correct output
}
```

## Best Practices Summary

### Module Design Principles

1. **Single Responsibility**: Each module should have one clear purpose
2. **Composability**: Modules should work well together
3. **Reusability**: Design for multiple use cases
4. **Testability**: Include comprehensive tests
5. **Documentation**: Provide clear usage examples

### Variable Management

1. **Validation**: Always validate inputs
2. **Defaults**: Provide sensible defaults
3. **Types**: Use specific types, not `any`
4. **Descriptions**: Write clear descriptions
5. **Sensitivity**: Mark sensitive variables appropriately

### Output Management

1. **Completeness**: Expose all useful attributes
2. **Naming**: Use consistent naming conventions
3. **Descriptions**: Document what each output provides
4. **Sensitivity**: Mark sensitive outputs appropriately

### Security Considerations

1. **Least Privilege**: Follow principle of least privilege
2. **Encryption**: Enable encryption by default
3. **Secrets**: Never hardcode secrets
4. **Validation**: Validate security-related inputs
5. **Compliance**: Follow organizational security standards

This comprehensive guide provides the foundation for developing professional-grade Terraform modules that are reusable, maintainable, and secure.
