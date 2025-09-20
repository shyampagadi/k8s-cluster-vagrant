# Problem 28: CI/CD Integration - DevOps Automation
# This configuration demonstrates CI/CD integration patterns

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate CI/CD project ID
resource "random_id" "cicd_id" {
  byte_length = 6
}

# VPC for CI/CD infrastructure
resource "aws_vpc" "cicd" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-cicd-vpc-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# Subnets for CI/CD
resource "aws_subnet" "cicd_public" {
  count = 2

  vpc_id                  = aws_vpc.cicd.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_region.current.name
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-cicd-public-subnet-${count.index + 1}-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cicd" {
  vpc_id = aws_vpc.cicd.id

  tags = {
    Name        = "${var.project_name}-cicd-igw-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# Security Group for CI/CD
resource "aws_security_group" "cicd" {
  name_prefix = "${var.project_name}-cicd-sg-${random_id.cicd_id.hex}"
  vpc_id      = aws_vpc.cicd.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-cicd-sg-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# CI/CD EC2 Instance
resource "aws_instance" "cicd_runner" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.cicd_public[0].id
  vpc_security_group_ids = [aws_security_group.cicd.id]

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    cicd_enabled = true
  })

  tags = {
    Name        = "${var.project_name}-cicd-runner-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# S3 Bucket for CI/CD artifacts
resource "aws_s3_bucket" "cicd_artifacts" {
  bucket = "${var.project_name}-cicd-artifacts-${random_id.cicd_id.hex}"

  tags = {
    Name        = "${var.project_name}-cicd-artifacts-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
    Purpose     = "artifacts"
  }
}

# Enable versioning on artifacts bucket
resource "aws_s3_bucket_versioning" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudWatch Log Group for CI/CD
resource "aws_cloudwatch_log_group" "cicd" {
  name              = "/aws/ec2/${var.project_name}-cicd-${random_id.cicd_id.hex}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-cicd-log-group-${random_id.cicd_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ci-cd-integration"
  }
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
