# Problem 18: Security Fundamentals

## Overview

This solution provides comprehensive understanding of Terraform security fundamentals, including secure state management, provider authentication, resource security, and compliance best practices. Security is paramount in infrastructure management and must be built into every aspect of Terraform configurations.

## Learning Objectives

- Understand Terraform security best practices and principles
- Learn secure state management and remote state configuration
- Master provider authentication and credential management
- Understand resource security and access control
- Learn compliance and governance strategies
- Master security scanning and validation techniques
- Understand secrets management and sensitive data handling

## Problem Statement

You've mastered error handling and validation. Now your team lead wants you to become proficient in Terraform security fundamentals, focusing on secure infrastructure deployment, proper credential management, and compliance with security standards. You need to understand how to create secure, compliant infrastructure that follows security best practices.

## Solution Components

This solution includes:
1. **Security Principles** - Understanding Terraform security fundamentals
2. **State Security** - Secure state management and remote state
3. **Provider Authentication** - Secure credential management
4. **Resource Security** - Access control and resource protection
5. **Compliance and Governance** - Security standards and compliance
6. **Secrets Management** - Handling sensitive data securely
7. **Security Scanning** - Validation and security assessment

## Implementation Guide

### Step 1: Understanding Security Principles

#### Terraform Security Fundamentals
```hcl
# Security Principles
# 1. Least Privilege - Grant minimum required permissions
# 2. Defense in Depth - Multiple layers of security
# 3. Secure by Default - Secure configurations by default
# 4. Principle of Separation - Separate environments and resources
# 5. Audit and Compliance - Track and monitor all changes
```

#### Security Best Practices
```hcl
# Use specific provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Pin to specific version
    }
  }
}

# Use least privilege IAM policies
resource "aws_iam_policy" "minimal" {
  name = "minimal-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}
```

### Step 2: State Security

#### Remote State Configuration
```hcl
# Secure remote state backend
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "path/to/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Additional security options
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

#### State Security Best Practices
```hcl
# State file security
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  
  # Enable versioning
  versioning {
    enabled = true
  }
  
  # Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Block public access
  public_access_block {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  
  tags = {
    Name = "terraform-state-bucket"
    Environment = "shared"
    Purpose = "terraform-state"
  }
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
    Name = "terraform-state-lock"
    Environment = "shared"
    Purpose = "terraform-state-lock"
  }
}
```

### Step 3: Provider Authentication

#### Secure Credential Management
```hcl
# Use IAM roles for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2-terraform-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach minimal policy
resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-terraform-profile"
  role = aws_iam_role.ec2_role.name
}
```

#### Environment Variables for Credentials
```bash
# Secure credential management
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"  # For temporary credentials
export AWS_DEFAULT_REGION="us-west-2"

# Use AWS CLI profiles
aws configure --profile terraform-profile
export AWS_PROFILE="terraform-profile"
```

### Step 4: Resource Security

#### VPC Security Configuration
```hcl
# Secure VPC configuration
resource "aws_vpc" "secure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "secure-vpc"
    Environment = var.environment
    SecurityLevel = "high"
  }
}

# Private subnets for sensitive resources
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "private-subnet-${count.index + 1}"
    Type = "Private"
    SecurityLevel = "high"
  }
}

# Public subnets for load balancers
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = "10.0.${count.index + 10}.0/24"
  availability_zone        = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
    Type = "Public"
    SecurityLevel = "medium"
  }
}
```

#### Security Groups with Least Privilege
```hcl
# Web security group
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # HTTP access from load balancer only
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # HTTPS access from load balancer only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # SSH access from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "web-security-group"
    Type = "Web"
    SecurityLevel = "high"
  }
}

# Database security group
resource "aws_security_group" "database" {
  name_prefix = "db-sg-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # Database access from web servers only
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "database-security-group"
    Type = "Database"
    SecurityLevel = "critical"
  }
}
```

### Step 5: Compliance and Governance

#### Tagging Strategy for Compliance
```hcl
# Standardized tagging
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    Owner         = var.owner
    CostCenter    = var.cost_center
    Compliance    = var.compliance_level
    DataClass     = var.data_classification
    Backup        = var.backup_required
    Monitoring    = var.monitoring_enabled
    SecurityLevel = var.security_level
  }
}

# Apply tags to all resources
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = "web-instance"
    Type = "Web Server"
  })
}
```

#### Compliance Monitoring
```hcl
# CloudTrail for audit logging
resource "aws_cloudtrail" "audit_trail" {
  name                          = "audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  tags = {
    Name = "audit-trail"
    Purpose = "compliance"
  }
}

# Config for compliance monitoring
resource "aws_config_configuration_recorder" "main" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}
```

### Step 6: Secrets Management

#### AWS Secrets Manager Integration
```hcl
# Store database password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "db-password"
  description             = "Database password for ${var.environment}"
  recovery_window_in_days = 7
  
  tags = {
    Name = "db-password"
    Environment = var.environment
    Type = "Secret"
  }
}

# Generate random password
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Use secret in RDS instance
resource "aws_db_instance" "main" {
  identifier = "secure-db"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  db_name  = "webapp"
  username = "admin"
  password = random_password.db_password.result
  
  # Use secret for password rotation
  manage_master_user_password = true
  
  tags = {
    Name = "secure-database"
    Type = "Database"
    SecurityLevel = "critical"
  }
}
```

#### Parameter Store for Configuration
```hcl
# Store configuration in Parameter Store
resource "aws_ssm_parameter" "app_config" {
  name  = "/${var.environment}/app/config"
  type  = "String"
  value = jsonencode({
    database_host = aws_db_instance.main.endpoint
    database_port = aws_db_instance.main.port
    database_name = aws_db_instance.main.db_name
    redis_host    = aws_elasticache_cluster.redis.cache_nodes[0].address
    redis_port    = aws_elasticache_cluster.redis.port
  })
  
  tags = {
    Name = "app-config"
    Environment = var.environment
    Type = "Configuration"
  }
}
```

### Step 7: Security Scanning and Validation

#### Security Scanning with tfsec
```bash
# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Run security scan
tfsec .

# Run with specific checks
tfsec . --include-checks aws-s3-enable-versioning,aws-s3-enable-server-side-encryption

# Generate report
tfsec . --format json --out tfsec-report.json
```

#### Compliance Testing with terraform-compliance
```bash
# Install terraform-compliance
pip install terraform-compliance

# Run compliance tests
terraform-compliance -p . -f compliance-tests/

# Run specific compliance tests
terraform-compliance -p . -f compliance-tests/ -t aws-s3-bucket-encryption
```

## Expected Deliverables

### 1. Security Configuration Examples
- Secure VPC and networking configuration
- Least privilege security groups
- Secure IAM roles and policies
- Encrypted storage and databases

### 2. State Security Implementation
- Remote state backend configuration
- State encryption and locking
- State access controls
- State backup and recovery

### 3. Provider Authentication
- Secure credential management
- IAM role-based authentication
- Environment variable configuration
- Credential rotation strategies

### 4. Compliance and Governance
- Standardized tagging strategy
- Compliance monitoring setup
- Audit logging configuration
- Governance policies

### 5. Secrets Management
- AWS Secrets Manager integration
- Parameter Store configuration
- Secret rotation strategies
- Secure secret access patterns

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are the key security principles for Terraform?**
   - Least privilege access
   - Defense in depth
   - Secure by default
   - Principle of separation
   - Audit and compliance

2. **How do you secure Terraform state?**
   - Use remote state backends
   - Enable encryption
   - Implement state locking
   - Control access to state

3. **What are the best practices for provider authentication?**
   - Use IAM roles instead of access keys
   - Implement least privilege policies
   - Use temporary credentials
   - Rotate credentials regularly

4. **How do you implement resource security?**
   - Use security groups with least privilege
   - Implement network segmentation
   - Enable encryption for sensitive data
   - Use private subnets for sensitive resources

5. **What are the strategies for compliance and governance?**
   - Implement standardized tagging
   - Enable audit logging
   - Use compliance monitoring tools
   - Create governance policies

6. **How do you handle secrets management?**
   - Use AWS Secrets Manager
   - Implement Parameter Store
   - Enable secret rotation
   - Control secret access

7. **What are the security scanning and validation techniques?**
   - Use tfsec for security scanning
   - Implement terraform-compliance
   - Run security tests in CI/CD
   - Monitor for security violations

## Troubleshooting

### Common Security Issues

#### 1. Exposed Credentials
```bash
# Error: Credentials exposed in state
# Solution: Use IAM roles and rotate credentials
```

#### 2. Insecure State
```bash
# Error: State file not encrypted
# Solution: Enable encryption in backend configuration
```

#### 3. Overly Permissive Policies
```bash
# Error: IAM policy too permissive
# Solution: Implement least privilege principle
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform security fundamentals
- Knowledge of secure state management
- Understanding of provider authentication
- Ability to implement resource security

Proceed to [Problem 19: Performance Optimization](../Problem-19-Performance-Optimization/) to learn about optimizing Terraform performance.
