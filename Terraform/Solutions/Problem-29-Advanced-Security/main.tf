# Problem 29: Advanced Security - Zero Trust and Compliance
# This configuration demonstrates advanced security patterns

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

# Generate security project ID
resource "random_id" "security_id" {
  byte_length = 6
}

# KMS Key for encryption
resource "aws_kms_key" "security" {
  description             = "Security encryption key for ${var.project_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-security-key-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Purpose     = "encryption"
  }
}

resource "aws_kms_alias" "security" {
  name          = "alias/${var.project_name}-security-${random_id.security_id.hex}"
  target_key_id = aws_kms_key.security.key_id
}

# VPC with security-focused configuration
resource "aws_vpc" "secure" {
  cidr_block           = var.vpc_cr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-secure-vpc-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Security    = "high"
  }
}

# Private subnets only (zero-trust approach)
resource "aws_subnet" "secure_private" {
  count = 3

  vpc_id            = aws_vpc.secure.id
  cidr_block        = cidrsubnet(var.vpc_cr, 8, count.index)
  availability_zone = data.aws_region.current.name

  tags = {
    Name        = "${var.project_name}-secure-private-subnet-${count.index + 1}-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Type        = "private"
    Security    = "high"
  }
}

# NAT Gateway for secure outbound access
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
  }
}

resource "aws_nat_gateway" "secure" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.secure_private[0].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
  }
}

# Security Groups with zero-trust principles
resource "aws_security_group" "secure_web" {
  name_prefix = "${var.project_name}-secure-web-sg-${random_id.security_id.hex}"
  vpc_id      = aws_vpc.secure.id

  # No inbound rules by default (zero-trust)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-secure-web-sg-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Type        = "web"
    Security    = "high"
  }
}

resource "aws_security_group" "secure_database" {
  name_prefix = "${var.project_name}-secure-db-sg-${random_id.security_id.hex}"
  vpc_id      = aws_vpc.secure.id

  # Only allow access from web security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.secure_web.id]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.secure_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-secure-db-sg-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Type        = "database"
    Security    = "high"
  }
}

# Encrypted S3 bucket for secure data storage
resource "aws_s3_bucket" "secure_data" {
  bucket = "${var.project_name}-secure-data-${random_id.security_id.hex}"

  tags = {
    Name        = "${var.project_name}-secure-data-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Purpose     = "secure-data"
    Security    = "high"
  }
}

# Enable encryption on S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.security.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "security_audit" {
  name                          = "${var.project_name}-security-audit-${random_id.security_id.hex}"
  s3_bucket_name                = aws_s3_bucket.secure_data.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  tags = {
    Name        = "${var.project_name}-security-audit-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Purpose     = "audit-logging"
  }
}

# CloudWatch Log Group for security monitoring
resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.project_name}-${random_id.security_id.hex}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.security.arn

  tags = {
    Name        = "${var.project_name}-security-log-group-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Purpose     = "security-monitoring"
  }
}

# Security monitoring EC2 instance
resource "aws_instance" "security_monitor" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secure_private[0].id
  vpc_security_group_ids = [aws_security_group.secure_web.id]

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    security_enabled = true
  })

  tags = {
    Name        = "${var.project_name}-security-monitor-${random_id.security_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "advanced-security"
    Purpose     = "security-monitoring"
    Security    = "high"
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
