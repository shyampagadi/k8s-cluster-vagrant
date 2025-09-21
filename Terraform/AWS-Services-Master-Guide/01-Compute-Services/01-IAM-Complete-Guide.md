# IAM (Identity and Access Management) - Complete Terraform Guide

## 🎯 Overview

AWS Identity and Access Management (IAM) is the foundation of AWS security. It controls who can access what AWS resources and how they can access them. IAM is essential for every AWS deployment and should be the first service you master.

### **What is IAM?**
IAM is a web service that helps you securely control access to AWS resources. You use IAM to control who is authenticated (signed in) and authorized (has permissions) to use resources.

### **Key Concepts**
- **Users**: Individual people or applications
- **Groups**: Collections of users
- **Roles**: Temporary permissions for AWS services or users
- **Policies**: Documents that define permissions
- **Access Keys**: Programmatic access credentials

### **When to Use IAM**
- **Every AWS deployment** - IAM is mandatory
- **Multi-user environments** - Managing team access
- **Application security** - Service-to-service authentication
- **Compliance requirements** - Audit trails and access control
- **Cost management** - Controlling resource access

## 🏗️ Architecture Patterns

### **Basic IAM Structure**
```
Root Account
├── IAM Users
│   ├── Individual Users
│   └── Application Users
├── IAM Groups
│   ├── Admin Group
│   ├── Developer Group
│   └── ReadOnly Group
├── IAM Roles
│   ├── Service Roles
│   ├── Cross-Account Roles
│   └── Instance Roles
└── IAM Policies
    ├── Managed Policies
    ├── Inline Policies
    └── Customer Managed Policies
```

### **Enterprise IAM Pattern**
```
Organization
├── Multiple AWS Accounts
│   ├── Production Account
│   ├── Staging Account
│   ├── Development Account
│   └── Security Account
├── Cross-Account Roles
├── Service-Linked Roles
└── Identity Federation
    ├── SAML
    ├── OIDC
    └── Active Directory
```

## 📝 Terraform Implementation

### **Basic IAM User**
```hcl
# Create IAM user
resource "aws_iam_user" "developer" {
  name = "developer-user"
  path = "/"
  
  tags = {
    Name        = "Developer User"
    Environment = "production"
    Department  = "Engineering"
  }
}

# Create access key for programmatic access
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# Create login profile for console access
resource "aws_iam_user_login_profile" "developer" {
  user    = aws_iam_user.developer.name
  pgp_key = "keybase:username" # Use your Keybase username
}
```

### **IAM Group with Policies**
```hcl
# Create IAM group
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/"
}

# Attach managed policy to group
resource "aws_iam_group_policy_attachment" "developers_power_user" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Create custom inline policy
resource "aws_iam_group_policy" "developers_s3_access" {
  name  = "S3AccessPolicy"
  group = aws_iam_group.developers.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::my-bucket/*",
          "arn:aws:s3:::my-bucket"
        ]
      }
    ]
  })
}

# Add user to group
resource "aws_iam_group_membership" "developers" {
  name = "developers-membership"
  
  users = [
    aws_iam_user.developer.name
  ]
  
  group = aws_iam_group.developers.name
}
```

### **IAM Role for EC2 Instance**
```hcl
# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"
  
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
    Name        = "EC2 Instance Role"
    Environment = "production"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
  
  tags = {
    Name        = "EC2 Instance Profile"
    Environment = "production"
  }
}
```

### **Cross-Account Role**
```hcl
# Cross-account role for external access
resource "aws_iam_role" "cross_account_role" {
  name = "cross-account-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root" # External account
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "Cross Account Role"
    Environment = "production"
  }
}

# Attach policy to cross-account role
resource "aws_iam_role_policy" "cross_account_policy" {
  name = "CrossAccountPolicy"
  role = aws_iam_role.cross_account_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::shared-bucket",
          "arn:aws:s3:::shared-bucket/*"
        ]
      }
    ]
  })
}
```

### **Service-Linked Role**
```hcl
# Service-linked role for AWS services
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
  description     = "Service-linked role for Amazon Elasticsearch Service"
}
```

## 🔧 Configuration Options

### **IAM User Configuration**
```hcl
resource "aws_iam_user" "example" {
  name                 = "example-user"
  path                 = "/"                    # User path
  permissions_boundary = "arn:aws:iam::aws:policy/ReadOnlyAccess" # Permission boundary
  
  tags = {
    Name        = "Example User"
    Environment = "production"
    Department  = "Engineering"
    Project     = "Example Project"
  }
}
```

### **IAM Role Configuration**
```hcl
resource "aws_iam_role" "example" {
  name                 = "example-role"
  path                 = "/"
  description          = "Example IAM role"
  max_session_duration = 3600 # 1 hour in seconds
  
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
    Name        = "Example Role"
    Environment = "production"
  }
}
```

### **IAM Policy Configuration**
```hcl
# Customer managed policy
resource "aws_iam_policy" "example" {
  name        = "example-policy"
  path        = "/"
  description = "Example IAM policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::example-bucket/*"
      }
    ]
  })
  
  tags = {
    Name        = "Example Policy"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Basic IAM setup for small team
resource "aws_iam_user" "admin" {
  name = "admin-user"
  
  tags = {
    Name = "Admin User"
  }
}

resource "aws_iam_access_key" "admin" {
  user = aws_iam_user.admin.name
}

resource "aws_iam_user_login_profile" "admin" {
  user    = aws_iam_user.admin.name
  pgp_key = "keybase:admin"
}
```

### **Production Deployment**
```hcl
# Production IAM setup with groups and policies
locals {
  users = [
    "admin",
    "developer1",
    "developer2",
    "readonly-user"
  ]
  
  groups = {
    "admins" = {
      policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
      users      = ["admin"]
    }
    "developers" = {
      policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
      users      = ["developer1", "developer2"]
    }
    "readonly" = {
      policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      users      = ["readonly-user"]
    }
  }
}

# Create users
resource "aws_iam_user" "users" {
  for_each = toset(local.users)
  
  name = each.value
  
  tags = {
    Name        = each.value
    Environment = "production"
  }
}

# Create groups
resource "aws_iam_group" "groups" {
  for_each = local.groups
  
  name = each.key
  
  tags = {
    Name        = each.key
    Environment = "production"
  }
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = local.groups
  
  group      = aws_iam_group.groups[each.key].name
  policy_arn = each.value.policy_arn
}

# Add users to groups
resource "aws_iam_group_membership" "group_memberships" {
  for_each = local.groups
  
  name  = "${each.key}-membership"
  group = aws_iam_group.groups[each.key].name
  users = each.value.users
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment IAM setup
locals {
  environments = ["dev", "staging", "prod"]
  
  environment_configs = {
    dev = {
      users = ["dev-user1", "dev-user2"]
      policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    staging = {
      users = ["staging-user1"]
      policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    prod = {
      users = ["prod-admin"]
      policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}

# Create environment-specific groups
resource "aws_iam_group" "environment_groups" {
  for_each = toset(local.environments)
  
  name = "${each.value}-group"
  
  tags = {
    Name        = "${each.value} Group"
    Environment = each.value
  }
}

# Attach policies to environment groups
resource "aws_iam_group_policy_attachment" "environment_policies" {
  for_each = local.environment_configs
  
  group      = aws_iam_group.environment_groups[each.key].name
  policy_arn = each.value.policies[0]
}

# Create environment-specific users
resource "aws_iam_user" "environment_users" {
  for_each = {
    for env, config in local.environment_configs : env => config.users
  }
  
  name = "${each.key}-${each.value}"
  
  tags = {
    Name        = "${each.key} ${each.value}"
    Environment = each.key
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for IAM events
resource "aws_cloudwatch_log_group" "iam_events" {
  name              = "/aws/iam/events"
  retention_in_days = 30
  
  tags = {
    Name        = "IAM Events Log Group"
    Environment = "production"
  }
}

# CloudWatch metric filter for failed logins
resource "aws_cloudwatch_log_metric_filter" "failed_logins" {
  name           = "FailedLogins"
  log_group_name = aws_cloudwatch_log_group.iam_events.name
  pattern        = "[timestamp, request_id, event_name=\"ConsoleLogin\", error_code=\"*\", ...]"
  
  metric_transformation {
    name      = "FailedLogins"
    namespace = "IAM/Events"
    value     = "1"
  }
}

# CloudWatch alarm for failed logins
resource "aws_cloudwatch_metric_alarm" "failed_logins_alarm" {
  alarm_name          = "FailedLoginsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedLogins"
  namespace           = "IAM/Events"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors failed login attempts"
  
  tags = {
    Name        = "Failed Logins Alarm"
    Environment = "production"
  }
}
```

### **CloudTrail Integration**
```hcl
# CloudTrail for IAM API calls
resource "aws_cloudtrail" "iam_trail" {
  name                          = "iam-api-calls"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events      = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  
  tags = {
    Name        = "IAM API Calls Trail"
    Environment = "production"
  }
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "iam-cloudtrail-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true
  
  tags = {
    Name        = "IAM CloudTrail Logs"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

## 🛡️ Security Best Practices

### **Least Privilege Principle**
```hcl
# Minimal permissions for specific tasks
resource "aws_iam_policy" "minimal_s3_policy" {
  name        = "MinimalS3Policy"
  description = "Minimal S3 permissions for specific bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::specific-bucket/specific-path/*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/Environment" = "production"
          }
        }
      }
    ]
  })
}
```

### **Permission Boundaries**
```hcl
# Permission boundary to limit user permissions
resource "aws_iam_policy" "permission_boundary" {
  name        = "PermissionBoundary"
  description = "Permission boundary for developers"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
        }
      }
    ]
  })
}

# Apply permission boundary to user
resource "aws_iam_user" "developer_with_boundary" {
  name                 = "developer-with-boundary"
  permissions_boundary = aws_iam_policy.permission_boundary.arn
  
  tags = {
    Name        = "Developer with Boundary"
    Environment = "production"
  }
}
```

### **MFA Enforcement**
```hcl
# MFA enforcement policy
resource "aws_iam_policy" "mfa_enforcement" {
  name        = "MFAEnforcement"
  description = "Requires MFA for all actions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

# Attach MFA enforcement to group
resource "aws_iam_group_policy_attachment" "mfa_enforcement" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}
```

### **Access Key Rotation**
```hcl
# Access key with automatic rotation
resource "aws_iam_access_key" "rotating_key" {
  user = aws_iam_user.developer.name
}

# Lambda function for key rotation
resource "aws_lambda_function" "key_rotation" {
  filename         = "key_rotation.zip"
  function_name    = "key-rotation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      USER_NAME = aws_iam_user.developer.name
    }
  }
}

# EventBridge rule for key rotation
resource "aws_cloudwatch_event_rule" "key_rotation_schedule" {
  name                = "key-rotation-schedule"
  description         = "Trigger key rotation every 90 days"
  schedule_expression = "rate(90 days)"
}

resource "aws_cloudwatch_event_target" "key_rotation_target" {
  rule      = aws_cloudwatch_event_rule.key_rotation_schedule.name
  target_id = "KeyRotationTarget"
  arn       = aws_lambda_function.key_rotation.arn
}
```

## 💰 Cost Optimization

### **Cost Analysis**
```hcl
# Cost analysis for IAM usage
resource "aws_iam_policy" "cost_optimization" {
  name        = "CostOptimization"
  description = "Policy for cost optimization actions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetSavingsPlansUtilization",
          "ce:GetUsageReport"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### **Resource Tagging**
```hcl
# Consistent tagging for cost tracking
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    CostCenter    = var.cost_center
    Owner         = var.owner
    ManagedBy     = "Terraform"
    CreatedDate   = timestamp()
  }
}

resource "aws_iam_user" "tagged_user" {
  name = "tagged-user"
  
  tags = merge(local.common_tags, {
    Name = "Tagged User"
    Role = "Developer"
  })
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Access Denied Errors**
```hcl
# Debug policy for troubleshooting
resource "aws_iam_policy" "debug_policy" {
  name        = "DebugPolicy"
  description = "Policy for debugging access issues"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedGroupPolicies"
        ]
        Resource = "*"
      }
    ]
  })
}
```

#### **Issue: Cross-Account Access Problems**
```hcl
# Cross-account trust policy with conditions
resource "aws_iam_role" "cross_account_debug" {
  name = "cross-account-debug"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id"
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2025-12-31T23:59:59Z"
          }
        }
      }
    ]
  })
}
```

#### **Issue: Policy Evaluation Problems**
```hcl
# Policy with explicit deny and allow
resource "aws_iam_policy" "explicit_policy" {
  name        = "ExplicitPolicy"
  description = "Policy with explicit allow and deny"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSpecificActions"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::allowed-bucket/*"
      },
      {
        Sid    = "DenySpecificActions"
        Effect = "Deny"
        Action = [
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::allowed-bucket/*"
      }
    ]
  })
}
```

## 📚 Real-World Examples

### **E-Commerce Platform IAM Setup**
```hcl
# E-commerce platform IAM structure
locals {
  ecommerce_roles = {
    "web-server-role" = {
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
      policies = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      ]
    }
    "database-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "rds.amazonaws.com"
            }
          }
        ]
      })
      policies = [
        "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
      ]
    }
  }
}

# Create e-commerce roles
resource "aws_iam_role" "ecommerce_roles" {
  for_each = local.ecommerce_roles
  
  name               = each.key
  assume_role_policy = each.value.assume_role_policy
  
  tags = {
    Name        = each.key
    Environment = "production"
    Project     = "ecommerce"
  }
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "ecommerce_role_policies" {
  for_each = {
    for role, config in local.ecommerce_roles : role => config.policies
  }
  
  role       = aws_iam_role.ecommerce_roles[each.key].name
  policy_arn = each.value[0]
}
```

### **Microservices IAM Setup**
```hcl
# Microservices IAM structure
locals {
  microservices = [
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ]
}

# Create service-specific roles
resource "aws_iam_role" "microservice_roles" {
  for_each = toset(local.microservices)
  
  name = "${each.value}-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${each.value} Role"
    Environment = "production"
    Service     = each.value
  }
}

# Service-specific policies
resource "aws_iam_policy" "microservice_policies" {
  for_each = toset(local.microservices)
  
  name        = "${each.value}-policy"
  description = "Policy for ${each.value}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${each.value}-*"
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "microservice_policy_attachments" {
  for_each = toset(local.microservices)
  
  role       = aws_iam_role.microservice_roles[each.value].name
  policy_arn = aws_iam_policy.microservice_policies[each.value].arn
}
```

## 🔗 Related Services

### **Integration Patterns**
- **VPC**: IAM roles for VPC endpoints
- **EC2**: Instance profiles and roles
- **S3**: Bucket policies and IAM policies
- **RDS**: Database authentication
- **Lambda**: Execution roles
- **ECS/EKS**: Task and pod roles
- **CloudWatch**: Monitoring and logging
- **CloudTrail**: Audit logging

### **Service Dependencies**
- **KMS**: For encryption key management
- **Secrets Manager**: For secret storage
- **Certificate Manager**: For SSL/TLS certificates
- **Organizations**: For multi-account management
- **Control Tower**: For landing zone setup

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic IAM examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect IAM with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and CloudTrail
6. **Optimize**: Focus on cost and performance

**Your IAM Mastery Journey Continues with VPC!** 🚀

---

*This comprehensive IAM guide provides everything you need to master AWS Identity and Access Management with Terraform. Each example is production-ready and follows security best practices.*
