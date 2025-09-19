# Backend Configuration for State Management
# This file demonstrates remote state backend configuration

# S3 Backend Configuration
# Note: Actual values should be provided via backend.tfvars or environment variables
# This is a template showing the required configuration

terraform {
  backend "s3" {
    # Bucket name for storing state files
    bucket = "terraform-state-bucket-name"
    
    # Key path for the state file
    key = "state-management/terraform.tfstate"
    
    # AWS region
    region = "us-west-2"
    
    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-lock"
    
    # Enable state encryption
    encrypt = true
    
    # State file versioning
    versioning = true
    
    # Server-side encryption algorithm
    sse_algorithm = "AES256"
  }
}

# Example backend.tfvars file content:
# bucket = "your-terraform-state-bucket"
# key = "state-management/terraform.tfstate"
# region = "us-west-2"
# dynamodb_table = "terraform-state-lock"
# encrypt = true
