# Problem 23: State Management - Hands-On Exercises

## 🎯 Exercise 1: Remote State Setup (30 min)

### S3 Backend Configuration
```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-${RANDOM}

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## 🎯 Exercise 2: State Migration (45 min)

### Local to Remote Migration
```bash
# Initialize with local state
terraform init

# Configure remote backend
# Edit backend.tf with S3 configuration

# Migrate state
terraform init -migrate-state

# Verify migration
terraform state list
```

### Cross-Region State Migration
```hcl
# Source backend
terraform {
  backend "s3" {
    bucket = "source-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

# Target backend
terraform {
  backend "s3" {
    bucket = "target-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## 🎯 Exercise 3: State Manipulation (60 min)

### Resource Import
```bash
# Import existing AWS resource
terraform import aws_instance.web i-1234567890abcdef0

# Import with module
terraform import module.vpc.aws_vpc.main vpc-12345678
```

### State Surgery
```bash
# Move resource between modules
terraform state mv aws_instance.web module.compute.aws_instance.web

# Remove resource from state
terraform state rm aws_instance.old

# Replace provider
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

## 🎯 Exercise 4: Workspace Management (45 min)

### Multi-Environment Workspaces
```bash
# Create workspaces
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch workspace
terraform workspace select production

# List workspaces
terraform workspace list
```

### Workspace-Specific Configuration
```hcl
locals {
  environment_config = {
    development = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    production = {
      instance_type = "m5.large"
      min_size     = 3
      max_size     = 10
    }
  }
  
  config = local.environment_config[terraform.workspace]
}

resource "aws_instance" "app" {
  instance_type = local.config.instance_type
  # ... other configuration
}
```

This provides comprehensive hands-on practice for state management concepts.
