# Problem 1: Understanding Infrastructure as Code (IaC)
# This is a conceptual demonstration of IaC principles

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

# Example: Simple S3 bucket to demonstrate IaC concepts
resource "aws_s3_bucket" "iac_demo" {
  bucket = "${var.project_name}-iac-demo-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "IaC Demonstration Bucket"
    Purpose     = "Learning Infrastructure as Code"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "iac_demo" {
  bucket = aws_s3_bucket.iac_demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "iac_demo" {
  bucket = aws_s3_bucket.iac_demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "iac_demo" {
  bucket = aws_s3_bucket.iac_demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random ID for unique naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Local values to demonstrate IaC concepts
locals {
  iac_principles = {
    declarative     = "Define desired state, not steps"
    version_control = "Infrastructure code in Git"
    reproducible    = "Same code produces same infrastructure"
    testable        = "Infrastructure can be tested"
    collaborative   = "Teams can work together on infrastructure"
  }

  iac_benefits = {
    consistency     = "Eliminates configuration drift"
    speed          = "Faster provisioning and deployment"
    cost_reduction = "Optimized resource usage"
    risk_reduction = "Fewer manual errors"
    documentation  = "Code serves as documentation"
  }
}

# CloudWatch log group for demonstration
resource "aws_cloudwatch_log_group" "iac_demo" {
  name              = "/aws/iac-demo/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "IaC Demo Log Group"
    Purpose     = "Demonstrate infrastructure logging"
    Environment = var.environment
  }
}
