# Problem 23: Terraform State Management - Remote Backends and Team Collaboration

## State Management Fundamentals

### What is Terraform State?
Terraform state is a JSON file that maps your configuration to real-world resources. It tracks resource metadata, dependencies, and enables Terraform to plan changes accurately.

### State File Structure
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 15,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "vpc_id": {
      "value": "vpc-12345678",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_vpc",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "vpc-12345678",
            "cidr_block": "10.0.0.0/16",
            "tags": {
              "Name": "main-vpc"
            }
          }
        }
      ]
    }
  ]
}
```

## Remote Backend Configuration

### S3 Backend with DynamoDB Locking
```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/production/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Optional: KMS encryption
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

# Create S3 bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "company-terraform-state"
  
  tags = {
    Name        = "Terraform State"
    Environment = "shared"
    Purpose     = "terraform-state-storage"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "Terraform State Lock"
    Environment = "shared"
    Purpose     = "terraform-state-locking"
  }
}
```

### Multi-Environment State Organization
```hcl
# environments/development/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/development/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# environments/staging/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/staging/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# environments/production/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/production/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Cross-Stack State References
```hcl
# Reference state from another stack
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "infrastructure/${var.environment}/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "infrastructure/${var.environment}/security/terraform.tfstate"
    region = "us-west-2"
  }
}

# Use remote state outputs
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
  vpc_security_group_ids = [data.terraform_remote_state.security.outputs.web_security_group_id]
  
  tags = {
    Name = "web-server"
  }
}
```

## Advanced State Management

### State Splitting Strategies
```hcl
# Split large state into smaller, focused states

# 1. Networking stack (networking/main.tf)
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

# 2. Security stack (security/main.tf)
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "infrastructure/${var.environment}/networking/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# 3. Application stack (applications/main.tf)
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "infrastructure/${var.environment}/networking/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "infrastructure/${var.environment}/security/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_instance" "web" {
  count = var.instance_count
  
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.networking.outputs.private_subnet_ids[count.index % length(data.terraform_remote_state.networking.outputs.private_subnet_ids)]
  vpc_security_group_ids = [data.terraform_remote_state.security.outputs.web_security_group_id]
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}
```

### State Import and Migration
```bash
# Import existing resources into Terraform state

# 1. Import VPC
terraform import aws_vpc.main vpc-12345678

# 2. Import subnets
terraform import 'aws_subnet.public[0]' subnet-12345678
terraform import 'aws_subnet.public[1]' subnet-87654321

# 3. Import security groups
terraform import aws_security_group.web sg-12345678

# 4. Import instances with for_each
terraform import 'aws_instance.web["web-1"]' i-1234567890abcdef0
terraform import 'aws_instance.web["web-2"]' i-0987654321fedcba0

# 5. Verify imports
terraform plan
```

### State Backup and Recovery
```bash
# Backup state before major changes
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Remove resource from state (without destroying)
terraform state rm aws_instance.old_web

# Move resource in state
terraform state mv aws_instance.web aws_instance.web_server

# Replace resource in state
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

## Team Collaboration Patterns

### State Locking and Concurrency
```hcl
# Proper state locking configuration
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/production/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Workspace-specific state paths
    workspace_key_prefix = "workspaces"
  }
}

# Handle state lock issues
# If state is locked and process died:
# terraform force-unlock LOCK_ID
```

### Multi-Team State Management
```hcl
# Team-specific state organization
# teams/platform/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "teams/platform/${var.environment}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# teams/applications/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "teams/applications/${var.environment}/${var.application_name}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# teams/data/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "teams/data/${var.environment}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

This comprehensive guide covers all aspects of Terraform state management, from basic remote backends to advanced enterprise patterns for team collaboration and state organization.
