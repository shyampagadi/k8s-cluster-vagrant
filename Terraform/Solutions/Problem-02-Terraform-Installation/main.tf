# Configure the AWS Provider
terraform {
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
  
  required_version = ">= 1.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Generate a random suffix for bucket name to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "My First Terraform S3 Bucket"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Learning Terraform"
  }
}

# Configure S3 bucket versioning
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "my_bucket_pab" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a simple text file to upload to the bucket
resource "aws_s3_object" "sample_file" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "sample.txt"
  content = "Hello from Terraform! This is my first S3 object."
  content_type = "text/plain"
  
  tags = {
    Name        = "Sample File"
    Environment = var.environment
    Project     = var.project_name
  }
}
