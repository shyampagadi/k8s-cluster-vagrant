# Advanced Security - Complete Terraform Guide

## 🎯 Overview

AWS Advanced Security encompasses a comprehensive set of security services and features that provide enterprise-grade security capabilities, including GuardDuty, Inspector, Macie, Security Hub, and Config.

### **What is Advanced Security?**
Advanced Security in AWS provides a multi-layered security approach that includes threat detection, vulnerability assessment, data protection, compliance monitoring, and security posture management.

### **Key Concepts**
- **GuardDuty**: Threat detection service
- **Inspector**: Vulnerability assessment service
- **Macie**: Data security and privacy service
- **Security Hub**: Centralized security findings
- **Config**: Resource compliance monitoring
- **Detective**: Security incident investigation
- **Access Analyzer**: Access policy analysis
- **Audit Manager**: Compliance auditing
- **Control Tower**: Multi-account governance
- **Organizations**: Account management

### **When to Use Advanced Security**
- **Threat detection** - Detect malicious activity
- **Vulnerability assessment** - Identify security vulnerabilities
- **Data protection** - Protect sensitive data
- **Compliance monitoring** - Meet regulatory requirements
- **Security posture** - Maintain security best practices
- **Incident response** - Investigate security incidents
- **Access analysis** - Analyze access policies
- **Multi-account security** - Secure multiple AWS accounts

## 🏗️ Architecture Patterns

### **Basic Advanced Security Structure**
```
Advanced Security
├── GuardDuty (Threat Detection)
├── Inspector (Vulnerability Assessment)
├── Macie (Data Protection)
├── Security Hub (Centralized Findings)
├── Config (Compliance Monitoring)
└── Detective (Incident Investigation)
```

### **Security Monitoring Pattern**
```
Security Events
├── GuardDuty Findings → Security Hub
├── Inspector Findings → Security Hub
├── Macie Findings → Security Hub
├── Config Findings → Security Hub
└── Security Hub → Automated Response
```

## 📝 Terraform Implementation

### **GuardDuty Setup**
```hcl
# GuardDuty detector
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "Main GuardDuty Detector"
    Environment = "production"
  }
}

# GuardDuty member accounts
resource "aws_guardduty_member" "member" {
  count = length(var.member_accounts)

  account_id                 = var.member_accounts[count.index]
  detector_id                = aws_guardduty_detector.main.id
  email                      = "security@${var.member_accounts[count.index]}.com"
  invite                     = true
  disable_email_notification = false
}

# GuardDuty publishing destination
resource "aws_guardduty_publishing_destination" "main" {
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.guardduty_logs.arn
  kms_key_arn     = aws_kms_key.guardduty.arn
}

# S3 bucket for GuardDuty logs
resource "aws_s3_bucket" "guardduty_logs" {
  bucket = "guardduty-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "GuardDuty Logs Bucket"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# KMS key for GuardDuty
resource "aws_kms_key" "guardduty" {
  description             = "KMS key for GuardDuty"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "GuardDuty KMS Key"
    Environment = "production"
  }
}
```

### **Inspector Setup**
```hcl
# Inspector assessment target
resource "aws_inspector_assessment_target" "main" {
  name = "main-assessment-target"

  resource_group_arn = aws_inspector_resource_group.main.arn
}

# Inspector resource group
resource "aws_inspector_resource_group" "main" {
  tags = {
    Name        = "Main Inspector Resource Group"
    Environment = "production"
  }
}

# Inspector assessment template
resource "aws_inspector_assessment_template" "main" {
  name       = "main-assessment-template"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600

  rules_package_arns = [
    "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-9hgA516P",
    "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-H5hpSawc",
    "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-JJOtZiqQ",
    "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-vg5GGHSD"
  ]

  tags = {
    Name        = "Main Inspector Assessment Template"
    Environment = "production"
  }
}
```

### **Macie Setup**
```hcl
# Macie account
resource "aws_macie2_account" "main" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"

  tags = {
    Name        = "Main Macie Account"
    Environment = "production"
  }
}

# Macie classification job
resource "aws_macie2_classification_job" "main" {
  job_type = "ONE_TIME"
  name     = "main-classification-job"

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.main.bucket]
    }
  }

  tags = {
    Name        = "Main Macie Classification Job"
    Environment = "production"
  }
}

# S3 bucket for Macie
resource "aws_s3_bucket" "main" {
  bucket = "macie-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Macie Bucket"
    Environment = "production"
  }
}

data "aws_caller_identity" "current" {}
```

### **Security Hub Setup**
```hcl
# Security Hub
resource "aws_securityhub_account" "main" {
  enable_default_standards = true

  tags = {
    Name        = "Main Security Hub"
    Environment = "production"
  }
}

# Security Hub standards subscription
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [aws_securityhub_account.main]
}

# Security Hub standards subscription for PCI DSS
resource "aws_securityhub_standards_subscription" "pci" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"

  depends_on = [aws_securityhub_account.main]
}

# Security Hub action target
resource "aws_securityhub_action_target" "main" {
  name        = "main-action-target"
  description = "Main action target for Security Hub"
  identifier  = "MainActionTarget"

  tags = {
    Name        = "Main Security Hub Action Target"
    Environment = "production"
  }
}

data "aws_region" "current" {}
```

### **Config Setup**
```hcl
# Config configuration recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "main-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.main]
}

# Config delivery channel
resource "aws_config_delivery_channel" "main" {
  name           = "main-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.main]
}

# IAM role for Config
resource "aws_iam_role" "config_role" {
  name = "config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# S3 bucket for Config logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "config-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Config Logs Bucket"
    Environment = "production"
  }
}

# Config rule
resource "aws_config_config_rule" "main" {
  name = "main-config-rule"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
```

### **Detective Setup**
```hcl
# Detective graph
resource "aws_detective_graph" "main" {
  tags = {
    Name        = "Main Detective Graph"
    Environment = "production"
  }
}

# Detective member
resource "aws_detective_member" "main" {
  account_id  = data.aws_caller_identity.current.account_id
  email       = "security@example.com"
  graph_arn   = aws_detective_graph.main.arn
  message     = "Please accept the invitation to join the Detective graph"
  disable_email_notification = false
}

# Detective invitation
resource "aws_detective_invitation_accepter" "main" {
  graph_arn = aws_detective_graph.main.arn
}
```

### **Access Analyzer Setup**
```hcl
# Access Analyzer analyzer
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "main-analyzer"
  type          = "ACCOUNT"

  tags = {
    Name        = "Main Access Analyzer"
    Environment = "production"
  }
}

# Access Analyzer archive rule
resource "aws_accessanalyzer_archive_rule" "main" {
  analyzer_name = aws_accessanalyzer_analyzer.main.analyzer_name
  rule_name     = "main-archive-rule"

  filter {
    criteria = "isPublic:true"
  }

  filter {
    criteria = "principal:arn:aws:iam::123456789012:root"
  }
}
```

## 🔧 Configuration Options

### **Advanced Security Configuration**
```hcl
# GuardDuty detector configuration
resource "aws_guardduty_detector" "custom" {
  enable = var.enable_guardduty

  datasources {
    s3_logs {
      enable = var.enable_s3_logs
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_audit_logs
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name = "Custom GuardDuty Detector"
  })
}
```

### **Advanced Security Configuration**
```hcl
# Advanced Security Hub setup
resource "aws_securityhub_account" "advanced" {
  enable_default_standards = true

  tags = {
    Name        = "Advanced Security Hub"
    Environment = "production"
  }
}

# Advanced Security Hub standards subscription
resource "aws_securityhub_standards_subscription" "advanced" {
  for_each = toset([
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0",
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1",
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  ])

  standards_arn = each.value

  depends_on = [aws_securityhub_account.advanced]
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple GuardDuty detector
resource "aws_guardduty_detector" "simple" {
  enable = true

  tags = {
    Name = "Simple GuardDuty Detector"
  }
}

# Simple Security Hub
resource "aws_securityhub_account" "simple" {
  enable_default_standards = true

  tags = {
    Name = "Simple Security Hub"
  }
}
```

### **Production Deployment**
```hcl
# Production Advanced Security setup
locals {
  security_config = {
    enable_guardduty = true
    enable_inspector = true
    enable_macie = true
    enable_security_hub = true
    enable_config = true
    enable_detective = true
  }
}

# Production GuardDuty detector
resource "aws_guardduty_detector" "production" {
  count = local.security_config.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "Production GuardDuty Detector"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production Security Hub
resource "aws_securityhub_account" "production" {
  count = local.security_config.enable_security_hub ? 1 : 0

  enable_default_standards = true

  tags = {
    Name        = "Production Security Hub"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment Advanced Security setup
locals {
  environments = {
    dev = {
      enable_guardduty = false
      enable_inspector = false
      enable_macie = false
      enable_security_hub = false
    }
    staging = {
      enable_guardduty = true
      enable_inspector = true
      enable_macie = false
      enable_security_hub = true
    }
    prod = {
      enable_guardduty = true
      enable_inspector = true
      enable_macie = true
      enable_security_hub = true
    }
  }
}

# Environment-specific GuardDuty detectors
resource "aws_guardduty_detector" "environment" {
  for_each = {
    for env, config in local.environments : env => config
    if config.enable_guardduty
  }

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "${title(each.key)} GuardDuty Detector"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for Security Hub
resource "aws_cloudwatch_log_group" "security_hub_logs" {
  name              = "/aws/securityhub/findings"
  retention_in_days = 30

  tags = {
    Name        = "Security Hub Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for Security Hub
resource "aws_cloudwatch_log_metric_filter" "security_hub_findings" {
  name           = "SecurityHubFindings"
  log_group_name = aws_cloudwatch_log_group.security_hub_logs.name
  pattern        = "[timestamp, request_id, event_name=\"BatchImportFindings\", ...]"

  metric_transformation {
    name      = "SecurityHubFindings"
    namespace = "Security Hub/Findings"
    value     = "1"
  }
}

# CloudWatch alarm for Security Hub findings
resource "aws_cloudwatch_metric_alarm" "security_hub_findings" {
  alarm_name          = "SecurityHubFindingsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SecurityHubFindings"
  namespace           = "Security Hub/Findings"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Security Hub findings"

  tags = {
    Name        = "Security Hub Findings Alarm"
    Environment = "production"
  }
}
```

### **Security Monitoring**
```hcl
# CloudWatch alarm for GuardDuty findings
resource "aws_cloudwatch_metric_alarm" "guardduty_findings" {
  alarm_name          = "GuardDutyFindingsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TotalFindingCount"
  namespace           = "AWS/GuardDuty"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors GuardDuty findings"

  dimensions = {
    DetectorId = aws_guardduty_detector.main.id
  }

  tags = {
    Name        = "GuardDuty Findings Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Security Configuration**
```hcl
# Secure GuardDuty detector
resource "aws_guardduty_detector" "secure" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "Secure GuardDuty Detector"
    Environment = "production"
  }
}

# Secure Security Hub
resource "aws_securityhub_account" "secure" {
  enable_default_standards = true

  tags = {
    Name        = "Secure Security Hub"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for Advanced Security access
resource "aws_iam_policy" "advanced_security_access" {
  name        = "AdvancedSecurityAccess"
  description = "Policy for Advanced Security access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "guardduty:GetDetector",
          "guardduty:ListDetectors",
          "securityhub:GetFindings",
          "securityhub:ListFindings",
          "inspector:DescribeFindings",
          "inspector:ListFindings"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Security Optimization**
```hcl
# Cost-optimized GuardDuty detector
resource "aws_guardduty_detector" "cost_optimized" {
  enable = true

  datasources {
    s3_logs {
      enable = false
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = false
        }
      }
    }
  }

  tags = {
    Name        = "Cost Optimized GuardDuty Detector"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: GuardDuty Not Detecting Threats**
```hcl
# Debug GuardDuty detector
resource "aws_guardduty_detector" "debug" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "Debug GuardDuty Detector"
    Environment = "production"
  }
}
```

#### **Issue: Security Hub Not Aggregating Findings**
```hcl
# Debug Security Hub
resource "aws_securityhub_account" "debug" {
  enable_default_standards = true

  tags = {
    Name        = "Debug Security Hub"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Advanced Security Setup**
```hcl
# E-commerce Advanced Security setup
locals {
  ecommerce_config = {
    enable_guardduty = true
    enable_inspector = true
    enable_macie = true
    enable_security_hub = true
    enable_config = true
  }
}

# E-commerce GuardDuty detector
resource "aws_guardduty_detector" "ecommerce" {
  count = local.ecommerce_config.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "E-commerce GuardDuty Detector"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce Security Hub
resource "aws_securityhub_account" "ecommerce" {
  count = local.ecommerce_config.enable_security_hub ? 1 : 0

  enable_default_standards = true

  tags = {
    Name        = "E-commerce Security Hub"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Advanced Security Setup**
```hcl
# Microservices Advanced Security setup
resource "aws_guardduty_detector" "microservices" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "Microservices GuardDuty Detector"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices Security Hub
resource "aws_securityhub_account" "microservices" {
  enable_default_standards = true

  tags = {
    Name        = "Microservices Security Hub"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **CloudWatch**: Monitoring and logging
- **SNS**: Notifications
- **SQS**: Message queuing
- **Lambda**: Automated response
- **IAM**: Access control
- **KMS**: Encryption
- **S3**: Log storage
- **VPC**: Network security

### **Service Dependencies**
- **CloudWatch**: Monitoring
- **SNS**: Notifications
- **SQS**: Message queuing
- **Lambda**: Automated response
- **IAM**: Access control

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Advanced Security examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Advanced Security with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your Advanced Security Mastery Journey Continues with Master Services!** 🚀

---

*This comprehensive Advanced Security guide provides everything you need to master AWS Advanced Security with Terraform. Each example is production-ready and follows security best practices.*
