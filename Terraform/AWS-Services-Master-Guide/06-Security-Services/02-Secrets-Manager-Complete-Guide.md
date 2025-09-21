# Secrets Manager - Complete Terraform Guide

## 🎯 Overview

AWS Secrets Manager is a service that helps you protect access to your applications, services, and IT resources. It enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle.

### **What is Secrets Manager?**
Secrets Manager is a secrets management service that helps you protect access to your applications, services, and IT resources without the upfront investment and on-going maintenance costs of operating your own infrastructure.

### **Key Concepts**
- **Secrets**: Encrypted key-value pairs stored in Secrets Manager
- **Secret Rotation**: Automatic rotation of secrets
- **Secret Versions**: Multiple versions of a secret
- **Resource Policies**: Control access to secrets
- **Cross-Region Replication**: Replicate secrets across regions
- **Lambda Rotation**: Custom rotation logic
- **Database Credentials**: Managed database credentials

### **When to Use Secrets Manager**
- **Database credentials** - Store and rotate database passwords
- **API keys** - Manage third-party API keys
- **Application secrets** - Store application configuration secrets
- **Compliance requirements** - Meet regulatory requirements
- **Secret rotation** - Automatically rotate secrets
- **Cross-account sharing** - Share secrets between accounts
- **Audit logging** - Track secret access

## 🏗️ Architecture Patterns

### **Basic Secrets Manager Structure**
```
Secrets Manager
├── Secrets (Database, API Keys, Certificates)
├── Secret Rotation (Automatic, Lambda-based)
├── Resource Policies (Access Control)
├── Cross-Region Replication
└── Audit Logging
```

### **Database Credentials Pattern**
```
Secrets Manager
├── RDS Database Credentials
├── Automatic Rotation
├── Lambda Rotation Function
└── RDS Integration
```

## 📝 Terraform Implementation

### **Basic Secrets Manager Setup**
```hcl
# KMS key for Secrets Manager
resource "aws_kms_key" "secrets_manager" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Secrets Manager KMS Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "secrets_manager" {
  name          = "alias/secrets-manager-key"
  target_key_id = aws_kms_key.secrets_manager.key_id
}

# Basic secret
resource "aws_secretsmanager_secret" "api_key" {
  name                    = "api-key"
  description             = "API key for external service"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "API Key Secret"
    Environment = "production"
  }
}

# Secret value
resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    api_key = "your-api-key-here"
    endpoint = "https://api.example.com"
  })
}
```

### **Database Credentials with Rotation**
```hcl
# RDS database credentials secret
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "rds-credentials"
  description             = "RDS database credentials"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  # Enable automatic rotation
  rotation_rules {
    automatically_after_days = 30
  }

  tags = {
    Name        = "RDS Credentials Secret"
    Environment = "production"
  }
}

# RDS database credentials version
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# Lambda function for rotation
resource "aws_lambda_function" "rotation_function" {
  filename         = "rotation_function.zip"
  function_name    = "rds-rotation-function"
  role            = aws_iam_role.rotation_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.rds_credentials.arn
    }
  }

  tags = {
    Name        = "RDS Rotation Function"
    Environment = "production"
  }
}

# IAM role for rotation function
resource "aws_iam_role" "rotation_role" {
  name = "rds-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_policy" {
  role       = aws_iam_role.rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSSecretsManagerRotationLambdaRole"
}

# Attach rotation function to secret
resource "aws_secretsmanager_secret_rotation" "rds_credentials" {
  secret_id           = aws_secretsmanager_secret.rds_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotation_function.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

### **Cross-Account Secret Sharing**
```hcl
# Cross-account secret
resource "aws_secretsmanager_secret" "cross_account" {
  name                    = "cross-account-secret"
  description             = "Cross-account shared secret"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "Cross Account Secret"
    Environment = "production"
  }
}

# Cross-account resource policy
resource "aws_secretsmanager_secret_policy" "cross_account" {
  secret_arn = aws_secretsmanager_secret.cross_account.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

# Cross-account secret version
resource "aws_secretsmanager_secret_version" "cross_account" {
  secret_id = aws_secretsmanager_secret.cross_account.id
  secret_string = jsonencode({
    shared_key = "shared-secret-value"
    endpoint   = "https://shared-api.example.com"
  })
}
```

### **Multi-Region Secret Replication**
```hcl
# Primary secret
resource "aws_secretsmanager_secret" "multi_region" {
  name                    = "multi-region-secret"
  description             = "Multi-region replicated secret"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "Multi Region Secret"
    Environment = "production"
  }
}

# Multi-region replication
resource "aws_secretsmanager_secret_replica" "multi_region" {
  provider = aws.us_west_2

  secret_id     = aws_secretsmanager_secret.multi_region.id
  kms_key_id    = aws_kms_key.secrets_manager.arn
  region        = "us-west-2"
}

# Primary secret version
resource "aws_secretsmanager_secret_version" "multi_region" {
  secret_id = aws_secretsmanager_secret.multi_region.id
  secret_string = jsonencode({
    primary_key = "primary-secret-value"
    region      = "us-east-1"
  })
}
```

## 🔧 Configuration Options

### **Secrets Manager Secret Configuration**
```hcl
resource "aws_secretsmanager_secret" "custom" {
  name                    = var.secret_name
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  # Rotation configuration
  dynamic "rotation_rules" {
    for_each = var.enable_rotation ? [1] : []
    content {
      automatically_after_days = var.rotation_days
    }
  }

  tags = merge(var.common_tags, {
    Name = var.secret_name
  })
}
```

### **Advanced Secrets Manager Configuration**
```hcl
# Advanced secret with custom rotation
resource "aws_secretsmanager_secret" "advanced" {
  name                    = "advanced-secret"
  description             = "Advanced secret with custom configuration"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  # Custom rotation rules
  rotation_rules {
    automatically_after_days = 30
  }

  tags = {
    Name        = "Advanced Secret"
    Environment = "production"
  }
}

# Advanced resource policy
resource "aws_secretsmanager_secret_policy" "advanced" {
  secret_arn = aws_secretsmanager_secret.advanced.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "secretsmanager:*"
        Resource = "*"
      },
      {
        Sid    = "AllowLambdaFunction"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple secret
resource "aws_secretsmanager_secret" "simple" {
  name                    = "simple-secret"
  description             = "Simple secret"
  recovery_window_in_days = 7

  tags = {
    Name = "Simple Secret"
  }
}

resource "aws_secretsmanager_secret_version" "simple" {
  secret_id = aws_secretsmanager_secret.simple.id
  secret_string = jsonencode({
    key = "value"
  })
}
```

### **Production Deployment**
```hcl
# Production Secrets Manager setup
locals {
  secrets_config = {
    recovery_window_in_days = 7
    enable_rotation = true
    rotation_days = 30
    secrets = ["api-key", "database-credentials", "jwt-secret", "encryption-key"]
  }
}

# Production secrets
resource "aws_secretsmanager_secret" "production" {
  for_each = toset(local.secrets_config.secrets)

  name                    = each.value
  description             = "Production secret for ${each.value}"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = local.secrets_config.recovery_window_in_days

  # Rotation configuration
  dynamic "rotation_rules" {
    for_each = local.secrets_config.enable_rotation ? [1] : []
    content {
      automatically_after_days = local.secrets_config.rotation_days
    }
  }

  tags = {
    Name        = "Production ${title(each.value)} Secret"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production secret versions
resource "aws_secretsmanager_secret_version" "production" {
  for_each = aws_secretsmanager_secret.production

  secret_id = each.value.id
  secret_string = jsonencode({
    value = "production-${each.key}-value"
    created_at = timestamp()
  })
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment Secrets Manager setup
locals {
  environments = {
    dev = {
      recovery_window_in_days = 7
      enable_rotation = false
    }
    staging = {
      recovery_window_in_days = 7
      enable_rotation = true
    }
    prod = {
      recovery_window_in_days = 30
      enable_rotation = true
    }
  }
}

# Environment-specific secrets
resource "aws_secretsmanager_secret" "environment" {
  for_each = local.environments

  name                    = "${each.key}-secret"
  description             = "${each.key} environment secret"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = each.value.recovery_window_in_days

  # Rotation configuration
  dynamic "rotation_rules" {
    for_each = each.value.enable_rotation ? [1] : []
    content {
      automatically_after_days = 30
    }
  }

  tags = {
    Name        = "${title(each.key)} Secret"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for Secrets Manager
resource "aws_cloudwatch_log_group" "secrets_manager_logs" {
  name              = "/aws/secretsmanager/audit-logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.secrets_manager.arn

  tags = {
    Name        = "Secrets Manager Audit Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for secret access
resource "aws_cloudwatch_log_metric_filter" "secret_access" {
  name           = "SecretAccess"
  log_group_name = aws_cloudwatch_log_group.secrets_manager_logs.name
  pattern        = "[timestamp, request_id, event_name=\"GetSecretValue\", ...]"

  metric_transformation {
    name      = "SecretAccess"
    namespace = "SecretsManager/Access"
    value     = "1"
  }
}

# CloudWatch alarm for secret access
resource "aws_cloudwatch_metric_alarm" "secret_access_alarm" {
  alarm_name          = "SecretAccessAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SecretAccess"
  namespace           = "SecretsManager/Access"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors secret access"

  tags = {
    Name        = "Secret Access Alarm"
    Environment = "production"
  }
}
```

### **CloudTrail Integration**
```hcl
# CloudTrail for Secrets Manager audit
resource "aws_cloudtrail" "secrets_manager_audit" {
  name                          = "secrets-manager-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true

  event_selector {
    read_write_type                 = "All"
    include_management_events      = true
    data_resource {
      type   = "AWS::SecretsManager::Secret"
      values = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]
    }
  }

  tags = {
    Name        = "Secrets Manager Audit Trail"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Resource Policies**
```hcl
# Secure resource policy
resource "aws_secretsmanager_secret_policy" "secure" {
  secret_arn = aws_secretsmanager_secret.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "secretsmanager:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSpecificServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
```

### **Encryption**
```hcl
# KMS key for Secrets Manager encryption
resource "aws_kms_key" "secrets_manager_encryption" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Secrets Manager Encryption Key"
    Environment = "production"
  }
}

# Encrypted secret
resource "aws_secretsmanager_secret" "encrypted" {
  name                    = "encrypted-secret"
  description             = "Encrypted secret"
  kms_key_id              = aws_kms_key.secrets_manager_encryption.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "Encrypted Secret"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for Secrets Manager access
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "SecretsManagerAccess"
  description = "Policy for Secrets Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Secret Lifecycle Management**
```hcl
# Cost-optimized secret
resource "aws_secretsmanager_secret" "cost_optimized" {
  name                    = "cost-optimized-secret"
  description             = "Cost-optimized secret"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  # Optimized rotation
  rotation_rules {
    automatically_after_days = 90
  }

  tags = {
    Name        = "Cost Optimized Secret"
    Environment = "production"
  }
}
```

### **Secret Version Management**
```hcl
# Secret with version management
resource "aws_secretsmanager_secret" "versioned" {
  name                    = "versioned-secret"
  description             = "Secret with version management"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "Versioned Secret"
    Environment = "production"
  }
}

# Multiple secret versions
resource "aws_secretsmanager_secret_version" "versioned" {
  count = 3

  secret_id = aws_secretsmanager_secret.versioned.id
  secret_string = jsonencode({
    version = count.index + 1
    value   = "version-${count.index + 1}-value"
  })
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Secret Access Denied**
```hcl
# Debug resource policy
resource "aws_secretsmanager_secret_policy" "debug" {
  secret_arn = aws_secretsmanager_secret.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAllPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "secretsmanager:*"
        Resource = "*"
      }
    ]
  })
}
```

#### **Issue: Rotation Problems**
```hcl
# Debug rotation function
resource "aws_lambda_function" "debug_rotation" {
  filename         = "debug_rotation.zip"
  function_name    = "debug-rotation-function"
  role            = aws_iam_role.rotation_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      DEBUG = "true"
    }
  }

  tags = {
    Name        = "Debug Rotation Function"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Secrets Setup**
```hcl
# E-commerce Secrets Manager setup
locals {
  ecommerce_config = {
    recovery_window_in_days = 30
    enable_rotation = true
    rotation_days = 30
    secrets = ["payment-api-key", "database-credentials", "jwt-secret", "encryption-key", "third-party-api-key"]
  }
}

# E-commerce secrets
resource "aws_secretsmanager_secret" "ecommerce" {
  for_each = toset(local.ecommerce_config.secrets)

  name                    = each.value
  description             = "E-commerce secret for ${each.value}"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = local.ecommerce_config.recovery_window_in_days

  # Rotation configuration
  dynamic "rotation_rules" {
    for_each = local.ecommerce_config.enable_rotation ? [1] : []
    content {
      automatically_after_days = local.ecommerce_config.rotation_days
    }
  }

  tags = {
    Name        = "E-commerce ${title(each.value)} Secret"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce secret versions
resource "aws_secretsmanager_secret_version" "ecommerce" {
  for_each = aws_secretsmanager_secret.ecommerce

  secret_id = each.value.id
  secret_string = jsonencode({
    value = "ecommerce-${each.key}-value"
    created_at = timestamp()
    environment = "production"
  })
}
```

### **Microservices Secrets Setup**
```hcl
# Microservices Secrets Manager setup
resource "aws_secretsmanager_secret" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name                    = "${each.value}-secrets"
  description             = "Microservices secrets for ${each.value}"
  kms_key_id              = aws_kms_key.secrets_manager.arn
  recovery_window_in_days = 7

  # Rotation configuration
  rotation_rules {
    automatically_after_days = 30
  }

  tags = {
    Name        = "Microservices ${title(each.value)} Secrets"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}

# Microservices secret versions
resource "aws_secretsmanager_secret_version" "microservices" {
  for_each = aws_secretsmanager_secret.microservices

  secret_id = each.value.id
  secret_string = jsonencode({
    service_name = each.key
    api_key = "microservices-${each.key}-api-key"
    database_url = "postgresql://user:pass@host:5432/${each.key}"
    created_at = timestamp()
  })
}
```

## 🔗 Related Services

### **Integration Patterns**
- **RDS**: Database credential management
- **Lambda**: Function secret access
- **ECS**: Container secret access
- **EKS**: Kubernetes secret access
- **KMS**: Secret encryption
- **CloudWatch**: Monitoring and logging
- **CloudTrail**: Audit logging
- **IAM**: Access control

### **Service Dependencies**
- **KMS**: Secret encryption
- **Lambda**: Rotation functions
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **CloudTrail**: Audit logging

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Secrets Manager examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Secrets Manager with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and CloudTrail
6. **Optimize**: Focus on cost and performance

**Your Secrets Manager Mastery Journey Continues with SNS!** 🚀

---

*This comprehensive Secrets Manager guide provides everything you need to master AWS Secrets Manager with Terraform. Each example is production-ready and follows security best practices.*
