# Problem 29: Advanced Security Patterns - Complete Mastery Guide

## 🔒 Enterprise Security Architecture

### Zero Trust Security Model Implementation

#### Core Zero Trust Principles
1. **Never Trust, Always Verify**: Every request must be authenticated and authorized
2. **Least Privilege Access**: Minimal access rights for users and systems
3. **Assume Breach**: Design systems assuming compromise has occurred
4. **Verify Explicitly**: Use all available data points for access decisions

#### Zero Trust Network Architecture
```hcl
# Network segmentation with micro-perimeters
resource "aws_vpc" "zero_trust" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name           = "${var.project_name}-zero-trust-vpc"
    SecurityModel  = "ZeroTrust"
    ComplianceLevel = "High"
  })
}

# Isolated subnets for different security zones
resource "aws_subnet" "dmz" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.zero_trust.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-dmz-${count.index + 1}"
    SecurityZone = "DMZ"
    TrustLevel  = "Untrusted"
  })
}

resource "aws_subnet" "application" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.zero_trust.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-app-${count.index + 1}"
    SecurityZone = "Application"
    TrustLevel  = "Restricted"
  })
}

resource "aws_subnet" "data" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.zero_trust.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-data-${count.index + 1}"
    SecurityZone = "Data"
    TrustLevel  = "Highly-Restricted"
  })
}
```

### Advanced Identity and Access Management (IAM)

#### Attribute-Based Access Control (ABAC)
```hcl
# Dynamic IAM policy with ABAC patterns
data "aws_iam_policy_document" "abac_policy" {
  # Allow access based on resource tags matching user attributes
  statement {
    sid    = "ABACResourceAccess"
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/Department"
      values   = ["$${aws:PrincipalTag/Department}"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/Project"
      values   = ["$${aws:PrincipalTag/Project}"]
    }
    
    condition {
      test     = "StringLike"
      variable = "s3:ExistingObjectTag/Environment"
      values   = ["$${aws:PrincipalTag/AllowedEnvironments}"]
    }
  }
  
  # Time-based access restrictions
  statement {
    sid    = "TimeBasedAccess"
    effect = "Allow"
    
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "DateGreaterThan"
      variable = "aws:CurrentTime"
      values   = ["$${aws:TokenIssueTime}"]
    }
    
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = ["$${aws:TokenIssueTime + 3600}"] # 1 hour session
    }
    
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ip_ranges
    }
  }
  
  # MFA requirement for sensitive operations
  statement {
    sid    = "MFARequiredOperations"
    effect = "Allow"
    
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    
    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = ["3600"] # MFA within last hour
    }
  }
}

# Cross-account role with advanced conditions
resource "aws_iam_role" "cross_account_abac" {
  name = "${var.project_name}-cross-account-abac-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          StringLike = {
            "aws:userid" = var.allowed_user_patterns
          }
        }
      }
    ]
  })
  
  tags = merge(var.common_tags, {
    AccessModel = "ABAC"
    TrustLevel  = "CrossAccount"
  })
}
```

#### Just-In-Time (JIT) Access Implementation
```hcl
# Lambda function for JIT access provisioning
resource "aws_lambda_function" "jit_access" {
  filename         = "jit_access.zip"
  function_name    = "${var.project_name}-jit-access"
  role            = aws_iam_role.jit_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.access_requests.name
      SNS_TOPIC_ARN  = aws_sns_topic.access_notifications.arn
      MAX_ACCESS_DURATION = "3600" # 1 hour
    }
  }
  
  tags = var.common_tags
}

# DynamoDB table for access request tracking
resource "aws_dynamodb_table" "access_requests" {
  name           = "${var.project_name}-access-requests"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "request_id"
  
  attribute {
    name = "request_id"
    type = "S"
  }
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  attribute {
    name = "expiry_time"
    type = "N"
  }
  
  global_secondary_index {
    name     = "user-expiry-index"
    hash_key = "user_id"
    range_key = "expiry_time"
  }
  
  ttl {
    attribute_name = "expiry_time"
    enabled        = true
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_id  = aws_kms_key.access_requests.arn
  }
  
  tags = var.common_tags
}

# EventBridge rule for automatic access revocation
resource "aws_cloudwatch_event_rule" "access_expiry" {
  name        = "${var.project_name}-access-expiry"
  description = "Trigger access revocation on expiry"
  
  schedule_expression = "rate(5 minutes)"
  
  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "access_expiry_lambda" {
  rule      = aws_cloudwatch_event_rule.access_expiry.name
  target_id = "AccessExpiryLambdaTarget"
  arn       = aws_lambda_function.jit_access_cleanup.arn
}
```

### Advanced Encryption and Key Management

#### Envelope Encryption with Customer Managed Keys
```hcl
# Customer managed KMS key with advanced policies
resource "aws_kms_key" "envelope_encryption" {
  description             = "Customer managed key for envelope encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "rds.amazonaws.com",
            "secretsmanager.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "s3.${data.aws_region.current.name}.amazonaws.com",
              "rds.${data.aws_region.current.name}.amazonaws.com",
              "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "AllowApplicationAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.application_role_arns
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:Application" = var.application_name
            "kms:EncryptionContext:Environment" = var.environment
          }
        }
      }
    ]
  })
  
  tags = merge(var.common_tags, {
    KeyUsage = "EnvelopeEncryption"
    Compliance = "FIPS-140-2-Level-3"
  })
}

# KMS key alias for easier reference
resource "aws_kms_alias" "envelope_encryption" {
  name          = "alias/${var.project_name}-envelope-encryption"
  target_key_id = aws_kms_key.envelope_encryption.key_id
}

# S3 bucket with envelope encryption
resource "aws_s3_bucket" "encrypted_data" {
  bucket = "${var.project_name}-encrypted-data-${random_id.bucket_suffix.hex}"
  
  tags = var.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_data" {
  bucket = aws_s3_bucket.encrypted_data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.envelope_encryption.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# RDS with customer managed encryption
resource "aws_db_instance" "encrypted_database" {
  identifier = "${var.project_name}-encrypted-db"
  
  engine         = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type         = "gp3"
  storage_encrypted    = true
  kms_key_id          = aws_kms_key.envelope_encryption.arn
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = var.environment == "production"
  skip_final_snapshot = var.environment != "production"
  
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.envelope_encryption.arn
  
  tags = merge(var.common_tags, {
    DataClassification = "Sensitive"
    EncryptionType    = "CustomerManaged"
  })
}
```

### Advanced Network Security

#### Web Application Firewall (WAF) with Machine Learning
```hcl
# WAF Web ACL with comprehensive rules
resource "aws_wafv2_web_acl" "advanced_protection" {
  name  = "${var.project_name}-advanced-waf"
  scope = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  # AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        
        # Exclude specific rules if needed
        excluded_rule {
          name = "SizeRestrictions_BODY"
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 3
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5_minutes
        aggregate_key_type = "IP"
        
        scope_down_statement {
          geo_match_statement {
            country_codes = var.blocked_countries
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # Custom rule for SQL injection protection
  rule {
    name     = "CustomSQLInjectionRule"
    priority = 4
    
    action {
      block {}
    }
    
    statement {
      or_statement {
        statement {
          sqli_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        
        statement {
          sqli_match_statement {
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CustomSQLInjectionMetric"
      sampled_requests_enabled   = true
    }
  }
  
  tags = var.common_tags
}

# WAF logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "advanced_protection" {
  resource_arn            = aws_wafv2_web_acl.advanced_protection.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  
  redacted_field {
    single_header {
      name = "authorization"
    }
  }
  
  redacted_field {
    single_header {
      name = "cookie"
    }
  }
}

# CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/wafv2/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.envelope_encryption.arn
  
  tags = var.common_tags
}
```

### Security Monitoring and Incident Response

#### Advanced CloudTrail Configuration
```hcl
# CloudTrail with advanced security features
resource "aws_cloudtrail" "security_audit" {
  name           = "${var.project_name}-security-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  s3_key_prefix  = "cloudtrail-logs"
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  # Advanced event selectors for data events
  advanced_event_selector {
    name = "S3DataEvents"
    
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
    
    field_selector {
      field  = "resources.ARN"
      starts_with = [
        "${aws_s3_bucket.sensitive_data.arn}/",
        "${aws_s3_bucket.encrypted_data.arn}/"
      ]
    }
  }
  
  advanced_event_selector {
    name = "LambdaDataEvents"
    
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    
    field_selector {
      field  = "resources.type"
      equals = ["AWS::Lambda::Function"]
    }
  }
  
  # Insight selectors for anomaly detection
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }
  
  tags = var.common_tags
}

# CloudWatch alarms for security events
resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  alarm_name          = "${var.project_name}-root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountUsageCount"
  namespace           = "CloudWatchLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Root account usage detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project_name}-unauthorized-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICallsCount"
  namespace           = "CloudWatchLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Multiple unauthorized API calls detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  
  tags = var.common_tags
}
```

This comprehensive guide provides enterprise-grade security patterns for production environments with advanced threat protection, compliance, and monitoring capabilities.
