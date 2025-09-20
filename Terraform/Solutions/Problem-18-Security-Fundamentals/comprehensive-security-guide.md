# Problem 18: Terraform Security Fundamentals

## Security Principles in Terraform

### Core Security Concepts
1. **Least Privilege Access** - Grant minimum necessary permissions
2. **Defense in Depth** - Multiple layers of security controls
3. **Encryption Everywhere** - Data at rest and in transit
4. **Network Segmentation** - Isolate resources and traffic
5. **Audit and Monitoring** - Track all changes and access

## Credential and Secret Management

### AWS Provider Authentication
```hcl
# SECURE: Use IAM roles (recommended)
provider "aws" {
  region = var.aws_region
  # Automatically uses IAM role attached to EC2/ECS/Lambda
}

# SECURE: Use assume role for cross-account access
provider "aws" {
  region = var.aws_region
  
  assume_role {
    role_arn     = "arn:aws:iam::${var.target_account_id}:role/TerraformRole"
    session_name = "terraform-deployment"
    external_id  = var.external_id
  }
}

# AVOID: Hardcoded credentials (never do this)
# provider "aws" {
#   access_key = "AKIAIOSFODNN7EXAMPLE"  # DON'T DO THIS
#   secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # DON'T DO THIS
# }
```

### Sensitive Variable Handling
```hcl
# Mark sensitive variables
variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.database_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "api_keys" {
  description = "API keys for external services"
  type = map(string)
  sensitive = true
  default = {}
}

# Use random passwords
resource "random_password" "database_password" {
  length  = 16
  special = true
  
  # Store in AWS Secrets Manager
  lifecycle {
    ignore_changes = [length, special]
  }
}

resource "aws_secretsmanager_secret" "database_password" {
  name                    = "${var.project_name}-db-password"
  description             = "Database master password"
  recovery_window_in_days = 7
  
  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = random_password.database_password.result
}
```

### KMS Encryption Implementation
```hcl
# Customer-managed KMS key
resource "aws_kms_key" "main" {
  description             = "${var.project_name} encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.ec2_role.arn,
            aws_iam_role.lambda_role.arn
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-kms-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.main.key_id
}

# Use KMS key for encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

## Network Security

### VPC Security Configuration
```hcl
# Secure VPC with private subnets
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Enable VPC Flow Logs for security monitoring
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn
  
  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

# Private subnets for sensitive resources
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  # No public IP assignment
  map_public_ip_on_launch = false
  
  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "private"
  }
}
```

### Security Group Best Practices
```hcl
# Restrictive security groups with specific rules
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for web servers"
  
  # No default rules - define explicitly
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Separate rules for better management
resource "aws_security_group_rule" "web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet"
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "web_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS from internet"
  security_group_id = aws_security_group.web.id
}

# Database security group - only allow access from application tier
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for database servers"
  
  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_security_group_rule" "database_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "MySQL from application tier"
  security_group_id        = aws_security_group.database.id
}
```

### Network ACLs for Additional Security
```hcl
# Network ACL for database subnets
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id
  
  # Allow inbound MySQL from application subnets
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 3306
    to_port    = 3306
  }
  
  # Allow outbound responses
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Deny all other traffic
  ingress {
    rule_no    = 200
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }
  
  egress {
    rule_no    = 200
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }
  
  tags = {
    Name = "${var.project_name}-database-nacl"
  }
}
```

## IAM Security

### Least Privilege IAM Policies
```hcl
# EC2 instance role with minimal permissions
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  
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
  
  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Custom policy with specific permissions
resource "aws_iam_policy" "ec2_policy" {
  name        = "${var.project_name}-ec2-policy"
  description = "Policy for EC2 instances"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.database_password.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.main.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

### Cross-Account Access Security
```hcl
# Cross-account role with conditions
resource "aws_iam_role" "cross_account_role" {
  name = "${var.project_name}-cross-account-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
          IpAddress = {
            "aws:SourceIp" = var.allowed_ip_ranges
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
        }
      }
    ]
  })
  
  max_session_duration = 3600  # 1 hour maximum
  
  tags = {
    Name = "${var.project_name}-cross-account-role"
  }
}
```

## Data Protection

### S3 Security Configuration
```hcl
# Secure S3 bucket configuration
resource "aws_s3_bucket" "secure_data" {
  bucket = "${var.project_name}-secure-data-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "${var.project_name}-secure-data"
    DataClass   = "sensitive"
    Environment = var.environment
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

# Enable versioning
resource "aws_s3_bucket_versioning" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle configuration for security
resource "aws_s3_bucket_lifecycle_configuration" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  rule {
    id     = "security_lifecycle"
    status = "Enabled"
    
    # Delete incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    
    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    # Archive after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    # Delete after 7 years (compliance requirement)
    expiration {
      days = 2555
    }
  }
}

# Bucket policy for additional security
resource "aws_s3_bucket_policy" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.secure_data.arn,
          "${aws_s3_bucket.secure_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.secure_data.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}
```

## Security Monitoring and Compliance

### CloudTrail for Audit Logging
```hcl
# CloudTrail for API logging
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  s3_key_prefix  = "cloudtrail-logs"
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  kms_key_id = aws_kms_key.main.arn
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.secure_data.arn}/*"]
    }
  }
  
  tags = {
    Name = "${var.project_name}-cloudtrail"
  }
}

# CloudTrail S3 bucket
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-cloudtrail-${random_id.bucket_suffix.hex}"
  force_destroy = false
  
  tags = {
    Name = "${var.project_name}-cloudtrail"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
```

### AWS Config for Compliance
```hcl
# AWS Config for compliance monitoring
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config.bucket
  s3_key_prefix  = "config"
}

# Config rules for security compliance
resource "aws_config_config_rule" "s3_bucket_public_access_prohibited" {
  name = "s3-bucket-public-access-prohibited"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}
```

This comprehensive security guide provides enterprise-grade security patterns and best practices for Terraform infrastructure deployments.
