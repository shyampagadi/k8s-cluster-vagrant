# Advanced Security Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for advanced Terraform security implementations, zero-trust architecture issues, compliance automation problems, and enterprise security management challenges.

## 📋 Table of Contents

1. [Zero-Trust Architecture Issues](#zero-trust-architecture-issues)
2. [Advanced Threat Protection Problems](#advanced-threat-protection-problems)
3. [Compliance Automation Challenges](#compliance-automation-challenges)
4. [Security Monitoring and Response Issues](#security-monitoring-and-response-issues)
5. [Identity and Access Management Problems](#identity-and-access-management-problems)
6. [Data Protection and Encryption Issues](#data-protection-and-encryption-issues)
7. [Security Governance Challenges](#security-governance-challenges)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 🔒 Zero-Trust Architecture Issues

### Problem: Zero-Trust Implementation Failures

**Symptoms:**
```
Error: Zero-trust policy violation: unauthorized access detected
```

**Root Causes:**
- Missing zero-trust policies
- Incorrect network segmentation
- Insufficient access controls
- Missing continuous verification

**Solutions:**

#### Solution 1: Implement Comprehensive Zero-Trust Policies
```hcl
# ✅ Comprehensive zero-trust policy implementation
locals {
  zero_trust_policies = {
    # Network segmentation policies
    network_segmentation = {
      enable_micro_segmentation = true
      enable_network_isolation = true
      enable_traffic_inspection = true
      enable_zero_trust_networking = true
    }
    
    # Access control policies
    access_control = {
      enable_least_privilege = true
      enable_just_in_time_access = true
      enable_continuous_verification = true
      enable_multi_factor_authentication = true
    }
    
    # Data protection policies
    data_protection = {
      enable_encryption_at_rest = true
      enable_encryption_in_transit = true
      enable_data_classification = true
      enable_data_loss_prevention = true
    }
    
    # Monitoring policies
    monitoring = {
      enable_continuous_monitoring = true
      enable_threat_detection = true
      enable_incident_response = true
      enable_security_orchestration = true
    }
  }
  
  # Generate zero-trust network policies
  zero_trust_network_policies = {
    for segment in var.network_segments : segment.name => {
      # Micro-segmentation rules
      micro_segmentation = {
        enable_segment_isolation = true
        enable_traffic_inspection = true
        enable_access_control = true
      }
      
      # Access control rules
      access_control = {
        enable_least_privilege = true
        enable_continuous_verification = true
        enable_multi_factor_authentication = true
      }
      
      # Monitoring rules
      monitoring = {
        enable_continuous_monitoring = true
        enable_threat_detection = true
        enable_incident_response = true
      }
    }
  }
}

# Implement zero-trust VPC
resource "aws_vpc" "zero_trust" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "zero-trust-vpc"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}

# Implement micro-segmentation
resource "aws_subnet" "zero_trust" {
  for_each = var.network_segments
  
  vpc_id            = aws_vpc.zero_trust.id
  cidr_block         = each.value.cidr_block
  availability_zone  = each.value.availability_zone
  
  tags = {
    Name = "${each.key}-subnet"
    SecurityLevel = "zero-trust"
    Segment = each.key
    Compliance = "required"
  }
}

# Implement zero-trust security groups
resource "aws_security_group" "zero_trust" {
  for_each = var.security_groups
  
  name_prefix = "${each.key}-zero-trust-"
  vpc_id      = aws_vpc.zero_trust.id
  
  # Zero-trust ingress rules
  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = ingress.value.security_groups
      cidr_blocks     = ingress.value.cidr_blocks
      description     = ingress.value.description
    }
  }
  
  # Zero-trust egress rules
  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      security_groups = egress.value.security_groups
      cidr_blocks     = egress.value.cidr_blocks
      description     = egress.value.description
    }
  }
  
  tags = {
    Name = "${each.key}-zero-trust-sg"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}
```

#### Solution 2: Implement Continuous Verification
```hcl
# ✅ Continuous verification implementation
resource "aws_iam_role" "zero_trust" {
  name = "zero-trust-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          StringLike = {
            "aws:userid" = "*:${var.allowed_user_pattern}"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "zero-trust-role"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}

# Implement continuous verification policies
resource "aws_iam_policy" "zero_trust" {
  name = "zero-trust-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "zero-trust-policy"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}
```

---

## 🛡️ Advanced Threat Protection Problems

### Problem: Threat Detection Failures

**Symptoms:**
```
Error: Threat detection system failure: unable to detect threats
```

**Root Causes:**
- Missing threat detection configuration
- Incorrect threat intelligence integration
- Insufficient monitoring coverage
- Missing incident response automation

**Solutions:**

#### Solution 1: Implement Comprehensive Threat Detection
```hcl
# ✅ Comprehensive threat detection implementation
locals {
  threat_detection_config = {
    # GuardDuty configuration
    guardduty = {
      enable_guardduty = true
      enable_s3_protection = true
      enable_dns_protection = true
      enable_kubernetes_protection = true
      enable_malware_protection = true
    }
    
    # Security Hub configuration
    security_hub = {
      enable_security_hub = true
      enable_standards = ["cis-aws-foundations-benchmark", "pci-dss", "nist-800-53"]
      enable_controls = ["all"]
      enable_findings_aggregation = true
    }
    
    # WAF configuration
    waf = {
      enable_waf = true
      enable_rate_limiting = true
      enable_geo_blocking = true
      enable_bot_protection = true
      enable_sql_injection_protection = true
    }
    
    # Inspector configuration
    inspector = {
      enable_inspector = true
      enable_vulnerability_assessment = true
      enable_compliance_assessment = true
      enable_network_reachability = true
    }
  }
}

# Implement GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = local.threat_detection_config.guardduty.enable_guardduty
  
  datasources {
    s3_logs {
      enable = local.threat_detection_config.guardduty.enable_s3_protection
    }
    dns_logs {
      enable = local.threat_detection_config.guardduty.enable_dns_protection
    }
    kubernetes {
      audit_logs {
        enable = local.threat_detection_config.guardduty.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = local.threat_detection_config.guardduty.enable_malware_protection
        }
      }
    }
  }
  
  tags = {
    Name = "guardduty-detector"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement Security Hub
resource "aws_securityhub_account" "main" {
  enable_default_standards = local.threat_detection_config.security_hub.enable_security_hub
}

resource "aws_securityhub_standards_subscription" "standards" {
  for_each = toset(local.threat_protection_config.security_hub.enable_standards)
  
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/${each.key}"
  
  depends_on = [aws_securityhub_account.main]
}

# Implement WAF
resource "aws_wafv2_web_acl" "main" {
  name  = "threat-protection-waf"
  scope = "REGIONAL"
  
  default_action {
    block {}
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
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  # Geo blocking rule
  rule {
    name     = "GeoBlockingRule"
    priority = 2
    
    action {
      block {}
    }
    
    statement {
      geo_match_statement {
        country_codes = ["CN", "RU", "KP"]
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockingRule"
      sampled_requests_enabled   = true
    }
  }
  
  # Bot protection rule
  rule {
    name     = "BotProtectionRule"
    priority = 3
    
    action {
      block {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BotProtectionRule"
      sampled_requests_enabled   = true
    }
  }
  
  tags = {
    Name = "threat-protection-waf"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}
```

#### Solution 2: Implement Incident Response Automation
```hcl
# ✅ Incident response automation
resource "aws_cloudwatch_event_rule" "security_incident" {
  name        = "security-incident-rule"
  description = "Trigger security incident response"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty", "aws.securityhub"]
    detail-type = ["GuardDuty Finding", "Security Hub Findings - Imported"]
    detail = {
      severity = ["HIGH", "CRITICAL"]
    }
  })
  
  tags = {
    Name = "security-incident-rule"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

resource "aws_cloudwatch_event_target" "security_incident" {
  rule      = aws_cloudwatch_event_rule.security_incident.name
  target_id = "SecurityIncidentTarget"
  arn       = aws_lambda_function.security_incident_response.arn
}

# Implement security incident response Lambda
resource "aws_lambda_function" "security_incident_response" {
  filename         = "security_incident_response.zip"
  function_name    = "security-incident-response"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      SLACK_WEBHOOK = var.slack_webhook_url
    }
  }
  
  tags = {
    Name = "security-incident-response"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement security alerts
resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
  
  tags = {
    Name = "security-alerts"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

resource "aws_sns_topic_subscription" "security_alerts" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_team_email
}
```

---

## 📋 Compliance Automation Challenges

### Problem: Compliance Automation Failures

**Symptoms:**
```
Error: Compliance check failed: policy violation detected
```

**Root Causes:**
- Missing compliance policies
- Incorrect compliance rules
- Insufficient compliance monitoring
- Missing compliance reporting

**Solutions:**

#### Solution 1: Implement Comprehensive Compliance Automation
```hcl
# ✅ Comprehensive compliance automation
locals {
  compliance_config = {
    # Config rules
    config_rules = {
      enable_config = true
      enable_compliance_rules = true
      enable_remediation = true
      enable_continuous_compliance = true
    }
    
    # CloudTrail configuration
    cloudtrail = {
      enable_cloudtrail = true
      enable_log_file_validation = true
      enable_cloudwatch_logs = true
      enable_s3_logging = true
    }
    
    # Compliance frameworks
    frameworks = {
      enable_cis = true
      enable_pci = true
      enable_sox = true
      enable_hipaa = true
      enable_gdpr = true
    }
  }
  
  # Generate compliance rules
  compliance_rules = {
    "s3-bucket-encryption" = {
      source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
      description = "S3 bucket encryption enabled"
      remediation = "s3-bucket-encryption-remediation"
    }
    "rds-encryption" = {
      source_identifier = "RDS_STORAGE_ENCRYPTED"
      description = "RDS storage encryption enabled"
      remediation = "rds-encryption-remediation"
    }
    "ebs-encryption" = {
      source_identifier = "EBS_ENCRYPTED_VOLUMES"
      description = "EBS volume encryption enabled"
      remediation = "ebs-encryption-remediation"
    }
    "cloudtrail-enabled" = {
      source_identifier = "CLOUD_TRAIL_ENABLED"
      description = "CloudTrail enabled"
      remediation = "cloudtrail-enabled-remediation"
    }
    "config-enabled" = {
      source_identifier = "CONFIG_ENABLED"
      description = "Config enabled"
      remediation = "config-enabled-remediation"
    }
  }
}

# Implement Config
resource "aws_config_configuration_recorder" "main" {
  name     = "compliance-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
  
  tags = {
    Name = "compliance-recorder"
    Compliance = "enabled"
  }
}

# Implement compliance rules
resource "aws_config_rule" "compliance_rules" {
  for_each = local.compliance_rules
  
  name = each.key
  
  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }
  
  tags = {
    Name = each.key
    Compliance = "enabled"
  }
}

# Implement compliance remediation
resource "aws_config_remediation_configuration" "compliance_remediation" {
  for_each = local.compliance_rules
  
  config_rule_name = aws_config_rule.compliance_rules[each.key].name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-${each.value.remediation}"
  target_version   = "1"
  
  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_remediation_role.arn
  }
}
```

#### Solution 2: Implement Compliance Reporting
```hcl
# ✅ Compliance reporting implementation
resource "aws_cloudwatch_dashboard" "compliance" {
  dashboard_name = "compliance-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Config", "ComplianceCheckPassed"],
            ["AWS/Config", "ComplianceCheckFailed"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Compliance Check Results"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          query   = "SOURCE '/aws/config/compliance' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Compliance Logs"
        }
      }
    ]
  })
}

# Implement compliance alerts
resource "aws_cloudwatch_metric_alarm" "compliance_failure" {
  alarm_name          = "compliance-check-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ComplianceCheckFailed"
  namespace           = "AWS/Config"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Compliance check failure detected"
  
  alarm_actions = [aws_sns_topic.compliance_alerts.arn]
  
  tags = {
    Name = "compliance-check-failure"
    Compliance = "enabled"
  }
}

# Implement compliance reporting
resource "aws_lambda_function" "compliance_reporting" {
  filename         = "compliance_reporting.zip"
  function_name    = "compliance-reporting"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.compliance_alerts.arn
      S3_BUCKET = aws_s3_bucket.compliance_reports.bucket
    }
  }
  
  tags = {
    Name = "compliance-reporting"
    Compliance = "enabled"
  }
}
```

---

## 📊 Security Monitoring and Response Issues

### Problem: Security Monitoring Failures

**Symptoms:**
```
Error: Security monitoring system failure: unable to monitor security events
```

**Root Causes:**
- Missing security monitoring configuration
- Incorrect log aggregation
- Insufficient monitoring coverage
- Missing alerting mechanisms

**Solutions:**

#### Solution 1: Implement Comprehensive Security Monitoring
```hcl
# ✅ Comprehensive security monitoring
locals {
  security_monitoring_config = {
    # CloudTrail configuration
    cloudtrail = {
      enable_cloudtrail = true
      enable_log_file_validation = true
      enable_cloudwatch_logs = true
      enable_s3_logging = true
    }
    
    # CloudWatch configuration
    cloudwatch = {
      enable_log_groups = true
      enable_metrics = true
      enable_alarms = true
      enable_dashboards = true
    }
    
    # Security monitoring
    monitoring = {
      enable_security_monitoring = true
      enable_threat_detection = true
      enable_incident_response = true
      enable_forensics = true
    }
  }
}

# Implement CloudTrail
resource "aws_cloudtrail" "security_monitoring" {
  name                          = "security-monitoring-trail"
  s3_bucket_name                = aws_s3_bucket.security_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }
  
  tags = {
    Name = "security-monitoring-trail"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement CloudWatch log groups
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/security/events"
  retention_in_days = 365
  
  tags = {
    Name = "security-logs"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement security monitoring dashboard
resource "aws_cloudwatch_dashboard" "security_monitoring" {
  dashboard_name = "security-monitoring-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/GuardDuty", "FindingCount"],
            ["AWS/SecurityHub", "FindingCount"],
            ["AWS/Config", "ComplianceCheckFailed"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Security Metrics"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          query   = "SOURCE '/aws/security/events' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Security Events"
        }
      }
    ]
  })
}
```

#### Solution 2: Implement Security Incident Response
```hcl
# ✅ Security incident response
resource "aws_cloudwatch_event_rule" "security_incident" {
  name        = "security-incident-rule"
  description = "Trigger security incident response"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty", "aws.securityhub"]
    detail-type = ["GuardDuty Finding", "Security Hub Findings - Imported"]
    detail = {
      severity = ["HIGH", "CRITICAL"]
    }
  })
  
  tags = {
    Name = "security-incident-rule"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

resource "aws_cloudwatch_event_target" "security_incident" {
  rule      = aws_cloudwatch_event_rule.security_incident.name
  target_id = "SecurityIncidentTarget"
  arn       = aws_lambda_function.security_incident_response.arn
}

# Implement security incident response Lambda
resource "aws_lambda_function" "security_incident_response" {
  filename         = "security_incident_response.zip"
  function_name    = "security-incident-response"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      SLACK_WEBHOOK = var.slack_webhook_url
    }
  }
  
  tags = {
    Name = "security-incident-response"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}
```

---

## 🔐 Identity and Access Management Problems

### Problem: IAM Configuration Failures

**Symptoms:**
```
Error: IAM policy violation: insufficient permissions
```

**Root Causes:**
- Missing IAM policies
- Incorrect permission configuration
- Insufficient access controls
- Missing MFA requirements

**Solutions:**

#### Solution 1: Implement Comprehensive IAM Policies
```hcl
# ✅ Comprehensive IAM policies
locals {
  iam_policies = {
    # Zero-trust IAM policies
    zero_trust = {
      enable_least_privilege = true
      enable_mfa_required = true
      enable_session_duration = true
      enable_conditional_access = true
    }
    
    # Role-based access control
    rbac = {
      enable_roles = true
      enable_groups = true
      enable_users = false
      enable_policies = true
    }
    
    # Access control
    access_control = {
      enable_ip_restrictions = true
      enable_time_restrictions = true
      enable_location_restrictions = true
      enable_device_restrictions = true
    }
  }
}

# Implement zero-trust IAM role
resource "aws_iam_role" "zero_trust" {
  name = "zero-trust-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          StringLike = {
            "aws:userid" = "*:${var.allowed_user_pattern}"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "zero-trust-role"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}

# Implement zero-trust IAM policy
resource "aws_iam_policy" "zero_trust" {
  name = "zero-trust-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "zero-trust-policy"
    SecurityLevel = "zero-trust"
    Compliance = "required"
  }
}
```

#### Solution 2: Implement MFA Requirements
```hcl
# ✅ MFA requirements implementation
resource "aws_iam_policy" "mfa_required" {
  name = "mfa-required-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "mfa-required-policy"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement MFA policy attachment
resource "aws_iam_user_policy_attachment" "mfa_required" {
  for_each = toset(var.users)
  
  user       = each.value
  policy_arn = aws_iam_policy.mfa_required.arn
}
```

---

## 🔒 Data Protection and Encryption Issues

### Problem: Data Protection Failures

**Symptoms:**
```
Error: Data protection violation: encryption not enabled
```

**Root Causes:**
- Missing encryption configuration
- Incorrect key management
- Insufficient data protection
- Missing data classification

**Solutions:**

#### Solution 1: Implement Comprehensive Data Protection
```hcl
# ✅ Comprehensive data protection
locals {
  data_protection_config = {
    # Encryption configuration
    encryption = {
      enable_encryption_at_rest = true
      enable_encryption_in_transit = true
      enable_key_rotation = true
      enable_key_management = true
    }
    
    # Data classification
    data_classification = {
      enable_data_classification = true
      enable_data_labeling = true
      enable_data_retention = true
      enable_data_purge = true
    }
    
    # Data loss prevention
    data_loss_prevention = {
      enable_dlp = true
      enable_data_monitoring = true
      enable_data_alerting = true
      enable_data_blocking = true
    }
  }
}

# Implement KMS key
resource "aws_kms_key" "data_protection" {
  description             = "Data protection key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = {
    Name = "data-protection-key"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

# Implement KMS alias
resource "aws_kms_alias" "data_protection" {
  name          = "alias/data-protection"
  target_key_id = aws_kms_key.data_protection.key_id
}

# Implement encrypted S3 bucket
resource "aws_s3_bucket" "data_protection" {
  bucket = "${var.project_name}-data-protection"
  
  tags = {
    Name = "data-protection-bucket"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_protection" {
  bucket = aws_s3_bucket.data_protection.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_protection.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Implement encrypted EBS volume
resource "aws_ebs_volume" "data_protection" {
  availability_zone = var.availability_zone
  size              = var.volume_size
  encrypted         = true
  kms_key_id        = aws_kms_key.data_protection.arn
  
  tags = {
    Name = "data-protection-volume"
    SecurityLevel = "advanced"
    Compliance = "required"
  }
}
```

#### Solution 2: Implement Data Classification
```hcl
# ✅ Data classification implementation
resource "aws_s3_bucket" "classified_data" {
  for_each = var.data_classifications
  
  bucket = "${var.project_name}-${each.key}-data"
  
  tags = merge({
    Name = "${each.key}-data-bucket"
    SecurityLevel = "advanced"
    Compliance = "required"
  }, each.value.tags)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "classified_data" {
  for_each = aws_s3_bucket.classified_data
  
  bucket = each.value.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_protection.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Implement data retention policies
resource "aws_s3_bucket_lifecycle_configuration" "classified_data" {
  for_each = aws_s3_bucket.classified_data
  
  bucket = each.value.id
  
  rule {
    id     = "data_retention"
    status = "Enabled"
    
    expiration {
      days = var.data_classifications[each.key].retention_days
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Security State Inspection
```bash
# ✅ Inspect security state
terraform console
> local.security_config
> local.zero_trust_policies
> local.threat_detection_config
```

### Technique 2: Security Debug Outputs
```hcl
# ✅ Add security debug outputs
output "security_debug" {
  description = "Security configuration debug information"
  value = {
    zero_trust_enabled = local.zero_trust_policies.network_segmentation.enable_micro_segmentation
    threat_detection_enabled = local.threat_detection_config.guardduty.enable_guardduty
    compliance_enabled = local.compliance_config.config_rules.enable_config
    monitoring_enabled = local.security_monitoring_config.cloudtrail.enable_cloudtrail
  }
}
```

### Technique 3: Security Validation
```hcl
# ✅ Add security validation
locals {
  security_validation = {
    # Validate zero-trust configuration
    zero_trust_valid = (
      local.zero_trust_policies.network_segmentation.enable_micro_segmentation &&
      local.zero_trust_policies.access_control.enable_least_privilege &&
      local.zero_trust_policies.monitoring.enable_continuous_monitoring
    )
    
    # Validate threat detection
    threat_detection_valid = (
      local.threat_detection_config.guardduty.enable_guardduty &&
      local.threat_detection_config.security_hub.enable_security_hub &&
      local.threat_detection_config.waf.enable_waf
    )
    
    # Validate compliance
    compliance_valid = (
      local.compliance_config.config_rules.enable_config &&
      local.compliance_config.cloudtrail.enable_cloudtrail &&
      local.compliance_config.frameworks.enable_cis
    )
    
    # Overall validation
    overall_valid = (
      local.security_validation.zero_trust_valid &&
      local.security_validation.threat_detection_valid &&
      local.security_validation.compliance_valid
    )
  }
}
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Security Testing
```hcl
# ✅ Test security in isolation
# tests/test_security.tf
resource "aws_instance" "security_test" {
  ami           = data.aws_ami.example.id
  instance_type = "t3.micro"
  
  tags = {
    Name = "security-test-instance"
    Test = "true"
  }
}
```

### Strategy 2: Security Monitoring
```bash
# ✅ Monitor security performance
time terraform plan
time terraform apply

# ✅ Monitor security metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/GuardDuty \
  --metric-name FindingCount \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Strategy 3: Security Documentation
```markdown
# ✅ Document security patterns
## Security Pattern: Zero-Trust Architecture

### Purpose
Implements zero-trust security principles.

### Configuration
```hcl
locals {
  zero_trust_config = {
    enable_micro_segmentation = true
    enable_least_privilege = true
    enable_continuous_monitoring = true
  }
}
```

### Usage
```hcl
resource "aws_security_group" "zero_trust" {
  # Security group configuration...
}
```
```

---

## 📞 Getting Help

### Internal Resources
- Review security documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [AWS Security Best Practices](https://aws.amazon.com/security/security-resources/)
- [Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)
- [CIS Controls](https://www.cisecurity.org/controls/)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review security documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Implement Zero-Trust**: Apply zero-trust security principles
- **Detect Threats**: Implement comprehensive threat detection
- **Automate Compliance**: Automate compliance processes
- **Monitor Security**: Implement continuous security monitoring
- **Protect Data**: Implement comprehensive data protection
- **Manage Access**: Implement robust access controls
- **Govern Security**: Implement security governance
- **Test Security**: Test security implementations

Remember: Advanced security requires careful planning, comprehensive implementation, and continuous monitoring. Proper implementation ensures robust protection against evolving threats.
