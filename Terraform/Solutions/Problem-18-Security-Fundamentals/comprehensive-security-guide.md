# Terraform Security Fundamentals - Complete Guide

## Overview

This comprehensive guide covers Terraform security fundamentals, including secure configuration practices, secrets management, access control, and enterprise-grade security patterns for infrastructure as code.

## Security Principles

### Defense in Depth

```hcl
# Multi-layered security approach
resource "aws_vpc" "secure" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "secure-vpc"
    Security = "high"
  }
}

# Network ACLs (Layer 1)
resource "aws_network_acl" "secure" {
  vpc_id = aws_vpc.secure.id
  
  # Deny all by default, explicit allow rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  tags = {
    Name = "secure-nacl"
  }
}

# Security Groups (Layer 2)
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.secure.id
  description = "Security group for web servers"
  
  # Minimal required access
  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # No direct SSH access
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "web-security-group"
  }
}

# Application-level security (Layer 3)
resource "aws_instance" "web" {
  ami           = data.aws_ami.hardened.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Encrypted storage
  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_key.instance.arn
    volume_type = "gp3"
    volume_size = 20
  }
  
  # Instance metadata security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }
  
  tags = {
    Name = "secure-web-server"
  }
}
```

### Least Privilege Access

```hcl
# IAM role with minimal permissions
resource "aws_iam_role" "app_role" {
  name = "app-execution-role"
  
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
    Name = "app-execution-role"
  }
}

# Specific permissions only
resource "aws_iam_role_policy" "app_policy" {
  name = "app-policy"
  role = aws_iam_role.app_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_data.arn}/config/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.app_secrets.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/app:*"
        ]
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "app_profile" {
  name = "app-instance-profile"
  role = aws_iam_role.app_role.name
}
```

## Secrets Management

### AWS Secrets Manager Integration

```hcl
# Secure secret storage
resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "prod/database/credentials"
  description             = "Database credentials for production"
  recovery_window_in_days = 30
  
  replica {
    region = "us-east-1"
  }
  
  tags = {
    Environment = "production"
    Type        = "database-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# Secure password generation
resource "random_password" "db_password" {
  length  = 32
  special = true
  
  # Avoid characters that might cause issues
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Use secrets in resources
data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)
}

resource "aws_db_instance" "main" {
  identifier = "secure-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.database.arn
  
  db_name  = "application"
  username = local.db_creds.username
  password = local.db_creds.password
  
  # Security configurations
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Prevent accidental deletion
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "secure-database-final-snapshot"
  
  # Enable logging
  enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]
  
  tags = {
    Name = "secure-database"
  }
}
```

### KMS Key Management

```hcl
# Customer-managed KMS keys
resource "aws_kms_key" "database" {
  description             = "KMS key for database encryption"
  deletion_window_in_days = 30
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
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "database-encryption-key"
  }
}

resource "aws_kms_alias" "database" {
  name          = "alias/database-encryption"
  target_key_id = aws_kms_key.database.key_id
}

# Separate key for different purposes
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30
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
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "s3-encryption-key"
  }
}
```

## Network Security

### VPC Security Configuration

```hcl
# Secure VPC with flow logs
resource "aws_vpc" "secure" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "secure-vpc"
  }
}

# VPC Flow Logs for monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.secure.id
  
  tags = {
    Name = "vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
  
  tags = {
    Name = "vpc-flow-logs"
  }
}

# Private subnets only
resource "aws_subnet" "private" {
  count = 3
  
  vpc_id            = aws_vpc.secure.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # No public IP assignment
  map_public_ip_on_launch = false
  
  tags = {
    Name = "private-subnet-${count.index + 1}"
    Type = "private"
  }
}

# NAT Gateway for outbound internet access
resource "aws_eip" "nat" {
  count = 3
  
  domain = "vpc"
  
  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = 3
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
}

# Restrictive security groups
resource "aws_security_group" "database" {
  name_prefix = "database-sg-"
  vpc_id      = aws_vpc.secure.id
  description = "Security group for database servers"
  
  # Only allow access from application servers
  ingress {
    description     = "MySQL from app servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  # No outbound internet access
  egress {
    description = "Internal communication only"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.secure.cidr_block]
  }
  
  tags = {
    Name = "database-security-group"
  }
}
```

### WAF Protection

```hcl
# Web Application Firewall
resource "aws_wafv2_web_acl" "main" {
  name  = "main-web-acl"
  scope = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # SQL injection protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainWebACL"
    sampled_requests_enabled   = true
  }
  
  tags = {
    Name = "main-web-acl"
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

## Data Protection

### S3 Security Configuration

```hcl
# Secure S3 bucket
resource "aws_s3_bucket" "secure_data" {
  bucket = "secure-data-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "secure-data-bucket"
    Environment = "production"
    DataClass   = "sensitive"
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
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  rule {
    id     = "security_lifecycle"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket policy
resource "aws_s3_bucket_policy" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
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
        Sid    = "AllowApplicationAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.app_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.secure_data.arn}/*"
      }
    ]
  })
}

# Logging
resource "aws_s3_bucket_logging" "secure_data" {
  bucket = aws_s3_bucket.secure_data.id
  
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}
```

## Monitoring and Compliance

### Security Monitoring

```hcl
# CloudTrail for API logging
resource "aws_cloudtrail" "security" {
  name           = "security-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  s3_key_prefix  = "cloudtrail-logs"
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  kms_key_id = aws_kms_key.cloudtrail.arn
  
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
    Name = "security-cloudtrail"
  }
}

# Security monitoring alarms
resource "aws_cloudwatch_metric_alarm" "root_access" {
  alarm_name          = "root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountUsage"
  namespace           = "CloudWatchLogMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Root account usage detected"
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]
  
  tags = {
    Name = "root-access-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "unauthorized-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CloudWatchLogMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Unauthorized API calls detected"
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]
  
  tags = {
    Name = "unauthorized-api-calls-alarm"
  }
}

# Security notifications
resource "aws_sns_topic" "security_alerts" {
  name              = "security-alerts"
  kms_master_key_id = aws_kms_key.sns.arn
  
  tags = {
    Name = "security-alerts"
  }
}
```

### Config Rules for Compliance

```hcl
# AWS Config for compliance monitoring
resource "aws_config_configuration_recorder" "security" {
  name     = "security-recorder"
  role_arn = aws_iam_role.config.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "security" {
  name           = "security-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.id
  s3_key_prefix  = "config"
}

# Config rules for security compliance
resource "aws_config_config_rule" "s3_bucket_public_access_prohibited" {
  name = "s3-bucket-public-access-prohibited"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.security]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.security]
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"
  
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  
  depends_on = [aws_config_configuration_recorder.security]
}
```

## Security Scanning and Validation

### Automated Security Scanning

```bash
#!/bin/bash
# security-scan.sh

echo "Running security scans..."

# Checkov scan
echo "1. Running Checkov security scan..."
checkov -d . --framework terraform --output cli --quiet

# TFSec scan
echo -e "\n2. Running TFSec security scan..."
tfsec . --no-color

# Terrascan
echo -e "\n3. Running Terrascan..."
terrascan scan -t terraform -d .

# Custom security checks
echo -e "\n4. Running custom security checks..."

# Check for hardcoded secrets
echo "Checking for hardcoded secrets..."
if grep -r "password\|secret\|key" --include="*.tf" . | grep -v "variable\|data\|random_password"; then
    echo "⚠️  Potential hardcoded secrets found"
else
    echo "✅ No hardcoded secrets detected"
fi

# Check for public access
echo "Checking for public access configurations..."
if grep -r "0.0.0.0/0" --include="*.tf" .; then
    echo "⚠️  Public access (0.0.0.0/0) configurations found"
else
    echo "✅ No public access configurations detected"
fi

# Check for encryption
echo "Checking for encryption configurations..."
if grep -r "encrypted.*=.*true" --include="*.tf" . > /dev/null; then
    echo "✅ Encryption configurations found"
else
    echo "⚠️  No encryption configurations detected"
fi

echo -e "\nSecurity scan completed."
```

### Security Testing

```hcl
# security-test.tf
locals {
  security_tests = {
    # Test encryption requirements
    s3_encryption_test = {
      resource_type = "aws_s3_bucket_server_side_encryption_configuration"
      required      = true
      description   = "S3 buckets must have encryption enabled"
    }
    
    # Test public access blocks
    s3_public_access_test = {
      resource_type = "aws_s3_bucket_public_access_block"
      required      = true
      description   = "S3 buckets must block public access"
    }
    
    # Test VPC flow logs
    vpc_flow_logs_test = {
      resource_type = "aws_flow_log"
      required      = true
      description   = "VPCs must have flow logs enabled"
    }
  }
  
  # Validate security configurations
  security_validation = {
    for test_name, test_config in local.security_tests :
    test_name => {
      test_passed = length([
        for resource_key, resource in data.terraform_remote_state.current.outputs :
        resource if can(regex(test_config.resource_type, resource_key))
      ]) > 0
      description = test_config.description
    }
  }
}

output "security_test_results" {
  description = "Security test results"
  value = {
    for test_name, result in local.security_validation :
    test_name => {
      status      = result.test_passed ? "PASS" : "FAIL"
      description = result.description
    }
  }
}
```

## Best Practices

### 1. Secure by Default

```hcl
# Always configure security from the start
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

# Immediately configure security settings
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 2. Principle of Least Privilege

```hcl
# Grant minimal required permissions
resource "aws_iam_role_policy" "minimal" {
  name = "minimal-policy"
  role = aws_iam_role.app.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"  # Only specific action needed
        ]
        Resource = [
          "${aws_s3_bucket.app.arn}/config/*"  # Only specific path
        ]
      }
    ]
  })
}
```

### 3. Defense in Depth

```hcl
# Multiple layers of security
resource "aws_instance" "secure" {
  # Layer 1: Network isolation
  subnet_id = aws_subnet.private.id
  
  # Layer 2: Security groups
  vpc_security_group_ids = [aws_security_group.restrictive.id]
  
  # Layer 3: Encryption
  root_block_device {
    encrypted = true
  }
  
  # Layer 4: Instance hardening
  user_data = base64encode(file("hardening-script.sh"))
}
```

### 4. Continuous Monitoring

```hcl
# Enable comprehensive logging
resource "aws_cloudtrail" "audit" {
  name           = "audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
}
```

## Conclusion

Security fundamentals enable:
- **Risk Mitigation**: Reduce security vulnerabilities
- **Compliance**: Meet regulatory requirements
- **Data Protection**: Secure sensitive information
- **Access Control**: Implement proper authorization
- **Monitoring**: Detect and respond to threats

Key takeaways:
- Implement security by default
- Use principle of least privilege
- Apply defense in depth
- Manage secrets securely
- Enable comprehensive monitoring
- Automate security scanning
- Follow compliance frameworks
