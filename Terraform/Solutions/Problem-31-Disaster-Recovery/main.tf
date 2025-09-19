# Problem 31: Disaster Recovery - Multi-Region Backup and Recovery
# This configuration demonstrates disaster recovery patterns

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

# Multi-region providers
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "primary" {
  provider = aws.primary
}
data "aws_region" "secondary" {
  provider = aws.secondary
}

# Generate disaster recovery project ID
resource "random_id" "dr_id" {
  byte_length = 6
}

# Primary region VPC
resource "aws_vpc" "primary" {
  provider = aws.primary

  cidr_block           = var.primary_vpc_cr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-primary-vpc-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "primary"
  }
}

# Secondary region VPC
resource "aws_vpc" "secondary" {
  provider = aws.secondary

  cidr_block           = var.secondary_vpc_cr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-secondary-vpc-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "secondary"
  }
}

# Primary region subnets
resource "aws_subnet" "primary" {
  provider = aws.primary
  count    = 2

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cr, 8, count.index)
  availability_zone       = data.aws_region.primary.name
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-primary-subnet-${count.index + 1}-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "primary"
  }
}

# Secondary region subnets
resource "aws_subnet" "secondary" {
  provider = aws.secondary
  count    = 2

  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cr, 8, count.index)
  availability_zone       = data.aws_region.secondary.name
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-secondary-subnet-${count.index + 1}-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "secondary"
  }
}

# Primary region S3 bucket for data
resource "aws_s3_bucket" "primary_data" {
  provider = aws.primary

  bucket = "${var.project_name}-primary-data-${random_id.dr_id.hex}"

  tags = {
    Name        = "${var.project_name}-primary-data-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "primary"
  }
}

# Secondary region S3 bucket for backup
resource "aws_s3_bucket" "secondary_backup" {
  provider = aws.secondary

  bucket = "${var.project_name}-secondary-backup-${random_id.dr_id.hex}"

  tags = {
    Name        = "${var.project_name}-secondary-backup-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "secondary"
  }
}

# Cross-region replication
resource "aws_s3_bucket_replication_configuration" "primary_to_secondary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary_data.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-to-secondary"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary_backup.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  provider = aws.primary

  name = "${var.project_name}-replication-role-${random_id.dr_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-replication-role-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
  }
}

# Primary region EC2 instance
resource "aws_instance" "primary" {
  provider = aws.primary

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary[0].id

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    region       = "primary"
    dr_enabled   = true
  })

  tags = {
    Name        = "${var.project_name}-primary-instance-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "primary"
  }
}

# Secondary region EC2 instance (standby)
resource "aws_instance" "secondary" {
  provider = aws.secondary

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secondary[0].id

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    region       = "secondary"
    dr_enabled   = true
  })

  tags = {
    Name        = "${var.project_name}-secondary-instance-${random_id.dr_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "disaster-recovery"
    Region      = "secondary"
  }
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  provider = aws.primary

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
