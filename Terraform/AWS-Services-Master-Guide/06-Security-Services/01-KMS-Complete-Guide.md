# KMS (Key Management Service) - Complete Terraform Guide

## 🎯 Overview

AWS Key Management Service (KMS) is a managed service that makes it easy for you to create and control the encryption keys used to encrypt your data. KMS uses hardware security modules (HSMs) to protect your keys.

### **What is KMS?**
KMS is a managed service that enables you to easily encrypt your data and control the encryption keys used to encrypt and decrypt your data across AWS services and in your applications.

### **Key Concepts**
- **Customer Master Keys (CMKs)**: Encryption keys that can be used to encrypt/decrypt data
- **Key Policies**: Control access to CMKs
- **Key Rotation**: Automatic or manual key rotation
- **Aliases**: Friendly names for CMKs
- **Grants**: Temporary permissions for CMKs
- **Envelope Encryption**: Encrypting data encryption keys
- **Cross-Account Access**: Sharing keys across accounts

### **When to Use KMS**
- **Data encryption** - Encrypt data at rest and in transit
- **Compliance requirements** - Meet regulatory requirements
- **Key management** - Centralized key management
- **Access control** - Fine-grained access control
- **Audit logging** - Track key usage
- **Multi-service encryption** - Encrypt across AWS services
- **Cross-account sharing** - Share keys between accounts

## 🏗️ Architecture Patterns

### **Basic KMS Structure**
```
KMS
├── Customer Master Keys (CMKs)
│   ├── Key Policies
│   ├── Key Rotation
│   └── Aliases
├── Grants
├── Cross-Account Access
└── Audit Logging
```

### **Multi-Service Encryption Pattern**
```
KMS CMK
├── S3 Bucket Encryption
├── RDS Database Encryption
├── EBS Volume Encryption
├── Lambda Function Encryption
└── Secrets Manager Encryption
```

## 📝 Terraform Implementation

### **Basic KMS Setup**
```hcl
# KMS key
resource "aws_kms_key" "main" {
  description             = "Main KMS key for encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Main KMS Key"
    Environment = "production"
  }
}

# KMS alias
resource "aws_kms_alias" "main" {
  name          = "alias/main-encryption-key"
  target_key_id = aws_kms_key.main.key_id
}

# KMS key policy
resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id
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
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudwatch/logs"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

### **Multi-Purpose KMS Keys**
```hcl
# S3 encryption key
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "S3 Encryption Key"
    Environment = "production"
    Service     = "s3"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3.key_id
}

# RDS encryption key
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "RDS Encryption Key"
    Environment = "production"
    Service     = "rds"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds-encryption-key"
  target_key_id = aws_kms_key.rds.key_id
}

# EBS encryption key
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "EBS Encryption Key"
    Environment = "production"
    Service     = "ebs"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs-encryption-key"
  target_key_id = aws_kms_key.ebs.key_id
}
```

### **Cross-Account KMS Access**
```hcl
# Cross-account KMS key
resource "aws_kms_key" "cross_account" {
  description             = "Cross-account KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Cross Account KMS Key"
    Environment = "production"
  }
}

# Cross-account key policy
resource "aws_kms_key_policy" "cross_account" {
  key_id = aws_kms_key.cross_account.id
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
        Sid    = "Allow Cross-Account Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
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
}

# Cross-account grant
resource "aws_kms_grant" "cross_account" {
  name              = "cross-account-grant"
  key_id            = aws_kms_key.cross_account.key_id
  grantee_principal = "arn:aws:iam::123456789012:role/CrossAccountRole"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}
```

### **KMS with External Key Store**
```hcl
# External key store
resource "aws_kms_external_key_store" "main" {
  external_key_store_name = "external-key-store"
  xks_proxy_uri_endpoint  = "https://xks.example.com"
  xks_proxy_uri_path      = "/kms/xks/v1"
  xks_proxy_vpc_endpoint_service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-1234567890abcdef0"
  xks_proxy_authentication_credential_access_key_id = "AKIAIOSFODNN7EXAMPLE"
  xks_proxy_authentication_credential_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  xks_proxy_connectivity = "VPC_ENDPOINT_SERVICE"
}

# External key
resource "aws_kms_external_key" "main" {
  description             = "External KMS key"
  deletion_window_in_days = 7
  external_key_store_id   = aws_kms_external_key_store.main.id
  key_material_base64     = "your-key-material-base64"

  tags = {
    Name        = "External KMS Key"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **KMS Key Configuration**
```hcl
resource "aws_kms_key" "custom" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  key_usage               = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  tags = merge(var.common_tags, {
    Name = var.key_name
  })
}
```

### **Advanced KMS Configuration**
```hcl
# Advanced KMS key with custom key spec
resource "aws_kms_key" "advanced" {
  description             = "Advanced KMS key with custom configuration"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "RSA_2048"

  tags = {
    Name        = "Advanced KMS Key"
    Environment = "production"
  }
}

# Advanced key policy
resource "aws_kms_key_policy" "advanced" {
  key_id = aws_kms_key.advanced.id
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
        Sid    = "Allow Lambda Function"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "lambda.${data.aws_region.current.name}.amazonaws.com"
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
# Simple KMS key
resource "aws_kms_key" "simple" {
  description             = "Simple KMS key"
  deletion_window_in_days = 7

  tags = {
    Name = "Simple KMS Key"
  }
}

resource "aws_kms_alias" "simple" {
  name          = "alias/simple-key"
  target_key_id = aws_kms_key.simple.key_id
}
```

### **Production Deployment**
```hcl
# Production KMS setup
locals {
  kms_config = {
    deletion_window_in_days = 7
    enable_key_rotation = true
    key_usage = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "SYMMETRIC_DEFAULT"
  }
}

# Production KMS keys
resource "aws_kms_key" "production" {
  for_each = toset([
    "s3",
    "rds",
    "ebs",
    "lambda",
    "secrets-manager"
  ])

  description             = "Production KMS key for ${each.value}"
  deletion_window_in_days = local.kms_config.deletion_window_in_days
  enable_key_rotation     = local.kms_config.enable_key_rotation
  key_usage               = local.kms_config.key_usage
  customer_master_key_spec = local.kms_config.customer_master_key_spec

  tags = {
    Name        = "Production ${title(each.value)} Key"
    Environment = "production"
    Service     = each.value
  }
}

# Production KMS aliases
resource "aws_kms_alias" "production" {
  for_each = aws_kms_key.production

  name          = "alias/production-${each.key}-key"
  target_key_id = each.value.key_id
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment KMS setup
locals {
  environments = {
    dev = {
      deletion_window_in_days = 7
      enable_key_rotation = false
    }
    staging = {
      deletion_window_in_days = 7
      enable_key_rotation = true
    }
    prod = {
      deletion_window_in_days = 30
      enable_key_rotation = true
    }
  }
}

# Environment-specific KMS keys
resource "aws_kms_key" "environment" {
  for_each = local.environments

  description             = "${each.key} KMS key"
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = each.value.enable_key_rotation

  tags = {
    Name        = "${title(each.key)} KMS Key"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific KMS aliases
resource "aws_kms_alias" "environment" {
  for_each = aws_kms_key.environment

  name          = "alias/${each.key}-key"
  target_key_id = each.value.key_id
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for KMS
resource "aws_cloudwatch_log_group" "kms_logs" {
  name              = "/aws/kms/audit-logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name        = "KMS Audit Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for KMS usage
resource "aws_cloudwatch_log_metric_filter" "kms_usage" {
  name           = "KMSUsage"
  log_group_name = aws_cloudwatch_log_group.kms_logs.name
  pattern        = "[timestamp, request_id, event_name=\"GenerateDataKey\", ...]"

  metric_transformation {
    name      = "KMSUsage"
    namespace = "KMS/Usage"
    value     = "1"
  }
}

# CloudWatch alarm for KMS usage
resource "aws_cloudwatch_metric_alarm" "kms_usage_alarm" {
  alarm_name          = "KMSUsageAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "KMSUsage"
  namespace           = "KMS/Usage"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors KMS usage"

  tags = {
    Name        = "KMS Usage Alarm"
    Environment = "production"
  }
}
```

### **CloudTrail Integration**
```hcl
# CloudTrail for KMS audit
resource "aws_cloudtrail" "kms_audit" {
  name                          = "kms-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true

  event_selector {
    read_write_type                 = "All"
    include_management_events      = true
    data_resource {
      type   = "AWS::KMS::Key"
      values = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
    }
  }

  tags = {
    Name        = "KMS Audit Trail"
    Environment = "production"
  }
}

# S3 bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "kms-cloudtrail-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "KMS CloudTrail Bucket"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

## 🛡️ Security Best Practices

### **Key Policies**
```hcl
# Secure key policy
resource "aws_kms_key_policy" "secure" {
  key_id = aws_kms_key.main.id
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
        Sid    = "Allow Specific Services"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "rds.amazonaws.com",
            "lambda.amazonaws.com"
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
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "s3.${data.aws_region.current.name}.amazonaws.com",
              "rds.${data.aws_region.current.name}.amazonaws.com",
              "lambda.${data.aws_region.current.name}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}
```

### **Key Rotation**
```hcl
# KMS key with automatic rotation
resource "aws_kms_key" "rotating" {
  description             = "KMS key with automatic rotation"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Rotating KMS Key"
    Environment = "production"
  }
}

# Manual key rotation
resource "aws_kms_key" "manual_rotation" {
  description             = "KMS key with manual rotation"
  deletion_window_in_days = 7
  enable_key_rotation     = false

  tags = {
    Name        = "Manual Rotation KMS Key"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for KMS access
resource "aws_iam_policy" "kms_access" {
  name        = "KMSAccess"
  description = "Policy for KMS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:ListKeys",
          "kms:ListAliases"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Key Usage Optimization**
```hcl
# Cost-optimized KMS key
resource "aws_kms_key" "cost_optimized" {
  description             = "Cost-optimized KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = {
    Name        = "Cost Optimized KMS Key"
    Environment = "production"
  }
}
```

### **Multi-Region Key Management**
```hcl
# Multi-region KMS key
resource "aws_kms_key" "multi_region" {
  provider = aws.us_east_1

  description             = "Multi-region KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  multi_region            = true

  tags = {
    Name        = "Multi Region KMS Key"
    Environment = "production"
  }
}

# Multi-region replica
resource "aws_kms_replica_key" "multi_region" {
  provider = aws.us_west_2

  description             = "Multi-region KMS key replica"
  deletion_window_in_days = 7
  primary_key_arn         = aws_kms_key.multi_region.arn

  tags = {
    Name        = "Multi Region KMS Key Replica"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Key Access Denied**
```hcl
# Debug key policy
resource "aws_kms_key_policy" "debug" {
  key_id = aws_kms_key.main.id
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
      }
    ]
  })
}
```

#### **Issue: Key Rotation Problems**
```hcl
# Debug key rotation
resource "aws_kms_key" "debug_rotation" {
  description             = "Debug key rotation"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Debug Rotation KMS Key"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce KMS Setup**
```hcl
# E-commerce KMS setup
locals {
  ecommerce_config = {
    deletion_window_in_days = 30
    enable_key_rotation = true
    services = ["s3", "rds", "ebs", "lambda", "secrets-manager"]
  }
}

# E-commerce KMS keys
resource "aws_kms_key" "ecommerce" {
  for_each = toset(local.ecommerce_config.services)

  description             = "E-commerce KMS key for ${each.value}"
  deletion_window_in_days = local.ecommerce_config.deletion_window_in_days
  enable_key_rotation     = local.ecommerce_config.enable_key_rotation

  tags = {
    Name        = "E-commerce ${title(each.value)} Key"
    Environment = "production"
    Project     = "ecommerce"
    Service     = each.value
  }
}

# E-commerce KMS aliases
resource "aws_kms_alias" "ecommerce" {
  for_each = aws_kms_key.ecommerce

  name          = "alias/ecommerce-${each.key}-key"
  target_key_id = each.value.key_id
}
```

### **Microservices KMS Setup**
```hcl
# Microservices KMS setup
resource "aws_kms_key" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  description             = "Microservices KMS key for ${each.value}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "Microservices ${title(each.value)} Key"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}

# Microservices KMS aliases
resource "aws_kms_alias" "microservices" {
  for_each = aws_kms_key.microservices

  name          = "alias/microservices-${each.key}-key"
  target_key_id = each.value.key_id
}
```

## 🔗 Related Services

### **Integration Patterns**
- **S3**: Bucket encryption
- **RDS**: Database encryption
- **EBS**: Volume encryption
- **Lambda**: Function encryption
- **Secrets Manager**: Secret encryption
- **CloudWatch**: Log encryption
- **SNS**: Topic encryption
- **SQS**: Queue encryption

### **Service Dependencies**
- **IAM**: Access control
- **CloudTrail**: Audit logging
- **CloudWatch**: Monitoring
- **S3**: Key storage

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic KMS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect KMS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and CloudTrail
6. **Optimize**: Focus on cost and performance

**Your KMS Mastery Journey Continues with Secrets Manager!** 🚀

---

*This comprehensive KMS guide provides everything you need to master AWS Key Management Service with Terraform. Each example is production-ready and follows security best practices.*
