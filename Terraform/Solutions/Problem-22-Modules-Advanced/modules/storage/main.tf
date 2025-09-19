# Storage Module
# This module creates S3 buckets and EBS volumes

# Create S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.storage_type}-${var.project_suffix}"

  tags = {
    Name        = "${var.project_name}-${var.storage_type}-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "storage"
    Purpose     = var.storage_config.purpose
  }
}

# Enable bucket versioning (if configured)
resource "aws_s3_bucket_versioning" "main" {
  count = var.storage_config.versioning ? 1 : 0

  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption (if configured)
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.storage_config.encryption ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration (if configured)
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.storage_config.lifecycle ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 365
    }
  }
}

# Create EBS volumes
resource "aws_ebs_volume" "main" {
  count = 2  # Create 2 volumes per storage configuration

  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.project_name}-${var.storage_type}-volume-${count.index + 1}-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "storage"
    Purpose     = var.storage_config.purpose
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create EBS snapshots
resource "aws_ebs_snapshot" "main" {
  count = var.storage_config.lifecycle ? length(aws_ebs_volume.main) : 0

  volume_id = aws_ebs_volume.main[count.index].id

  tags = {
    Name        = "${var.project_name}-${var.storage_type}-snapshot-${count.index + 1}-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "storage"
    Purpose     = var.storage_config.purpose
  }
}
