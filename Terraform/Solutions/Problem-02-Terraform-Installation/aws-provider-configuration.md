# AWS Provider Configuration - Complete Guide

## Provider Configuration Methods

### 1. Basic Provider Configuration
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

### 2. Multiple Provider Configurations
```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

# Use specific provider
resource "aws_s3_bucket" "east" {
  provider = aws.us-east-1
  bucket   = "my-east-bucket"
}
```

### 3. Assume Role Configuration
```hcl
provider "aws" {
  region = "us-west-2"
  
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformRole"
    session_name = "terraform-session"
  }
}
```

## Authentication Methods

### 1. AWS Credentials File
```bash
# ~/.aws/credentials
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[production]
aws_access_key_id = PROD_ACCESS_KEY
aws_secret_access_key = PROD_SECRET_KEY
```

```hcl
provider "aws" {
  region  = "us-west-2"
  profile = "production"
}
```

### 2. Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
export AWS_PROFILE="production"
```

### 3. IAM Roles (EC2/ECS/Lambda)
```hcl
provider "aws" {
  region = "us-west-2"
  # Automatically uses IAM role attached to EC2 instance
}
```

### 4. Shared Configuration File
```bash
# ~/.aws/config
[default]
region = us-west-2
output = json

[profile production]
region = us-east-1
role_arn = arn:aws:iam::123456789012:role/ProductionRole
source_profile = default
```

## Provider Features

### Default Tags
```hcl
provider "aws" {
  region = "us-west-2"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "my-project"
      ManagedBy   = "terraform"
    }
  }
}
```

### Ignore Tags
```hcl
provider "aws" {
  region = "us-west-2"
  
  ignore_tags {
    keys = ["CreatedBy", "LastModified"]
    key_prefixes = ["kubernetes.io/"]
  }
}
```

### Custom Endpoints
```hcl
provider "aws" {
  region = "us-west-2"
  
  endpoints {
    s3  = "http://localhost:4566"  # LocalStack
    ec2 = "http://localhost:4566"
  }
}
```

## Security Best Practices

### 1. Least Privilege IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "iam:ListRoles",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. Cross-Account Access
```hcl
provider "aws" {
  region = "us-west-2"
  
  assume_role {
    role_arn         = "arn:aws:iam::ACCOUNT-ID:role/TerraformRole"
    session_name     = "terraform"
    external_id      = "unique-external-id"
    duration_seconds = 3600
  }
}
```

### 3. MFA Requirements
```hcl
provider "aws" {
  region = "us-west-2"
  
  assume_role {
    role_arn    = "arn:aws:iam::123456789012:role/TerraformRole"
    session_name = "terraform"
    
    # MFA token required
    duration_seconds = 3600
  }
}
```

## Validation and Testing

### Provider Validation
```hcl
# Test provider configuration
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
```

### Region Validation
```hcl
data "aws_region" "current" {}

output "current_region" {
  value = data.aws_region.current.name
}
```

### Availability Zones
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

output "available_zones" {
  value = data.aws_availability_zones.available.names
}
```

## Common Configuration Patterns

### Multi-Environment Setup
```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# main.tf
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

### Provider Version Constraints
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Troubleshooting

### Common Issues
1. **Invalid Credentials**: Check AWS credentials and permissions
2. **Region Mismatch**: Ensure region consistency across configuration
3. **Version Conflicts**: Pin provider versions to avoid conflicts
4. **Rate Limiting**: Implement retry logic and respect API limits

### Debug Configuration
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run Terraform with detailed logging
terraform plan
```

### Credential Chain Order
1. Environment variables
2. Shared credentials file
3. Shared configuration file
4. Container credentials (ECS)
5. Instance profile credentials (EC2)

This comprehensive guide ensures proper AWS provider setup for all Terraform operations.
