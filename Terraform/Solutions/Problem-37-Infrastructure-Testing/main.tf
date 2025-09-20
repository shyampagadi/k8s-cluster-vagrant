# Problem 37: Infrastructure Testing with Terratest and Validation
# Comprehensive testing patterns for Terraform infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Validation rules for variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 instance type."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Test infrastructure
resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-test-vpc"
    Environment = var.environment
    Testing     = "true"
  }
}

resource "aws_subnet" "test" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment}-test-subnet"
  }
}

resource "aws_security_group" "test" {
  name_prefix = "${var.environment}-test-"
  vpc_id      = aws_vpc.test.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-test-sg"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Test assertions using check blocks
check "vpc_cidr_validation" {
  assert {
    condition     = can(cidrhost(aws_vpc.test.cidr_block, 0))
    error_message = "VPC CIDR block is not valid"
  }
}

check "security_group_rules" {
  assert {
    condition = length([
      for rule in aws_security_group.test.ingress :
      rule if rule.from_port == 22 && rule.to_port == 22
    ]) == 1
    error_message = "Security group must have exactly one SSH rule"
  }
}

# Locals for testing
locals {
  test_tags = {
    Environment = var.environment
    Testing     = "true"
    CreatedBy   = "terraform"
  }
  
  # Test data transformations
  subnet_cidrs = [
    for i in range(3) : cidrsubnet(aws_vpc.test.cidr_block, 8, i)
  ]
}

# Test outputs
output "test_results" {
  description = "Test validation results"
  value = {
    vpc_id              = aws_vpc.test.id
    vpc_cidr_valid      = can(cidrhost(aws_vpc.test.cidr_block, 0))
    subnet_count        = length(local.subnet_cidrs)
    security_group_rules = length(aws_security_group.test.ingress)
    environment_valid   = contains(["dev", "staging", "prod"], var.environment)
  }
}
