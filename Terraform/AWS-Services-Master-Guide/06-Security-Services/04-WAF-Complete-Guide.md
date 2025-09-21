# WAF (Web Application Firewall) - Complete Terraform Guide

## 🎯 Overview

AWS WAF is a web application firewall that helps protect your web applications or APIs against common web exploits and bots that may affect availability, compromise security, or consume excessive resources.

### **What is WAF?**
WAF is a service that lets you monitor, control, and block HTTP and HTTPS requests to your web applications or APIs based on conditions that you define, such as the IP addresses that requests originate from or values in the request.

### **Key Concepts**
- **Web ACLs**: Collections of rules that define how to inspect and control web requests
- **Rules**: Individual conditions and actions for web requests
- **Rule Groups**: Reusable collections of rules
- **Conditions**: Criteria for matching requests
- **Actions**: What to do when conditions are met
- **IP Sets**: Collections of IP addresses
- **Regex Pattern Sets**: Collections of regular expressions
- **Rate-based Rules**: Rules based on request rates
- **Geo Match**: Rules based on geographic location
- **Managed Rule Groups**: Pre-configured rule groups from AWS and partners

### **When to Use WAF**
- **Web application protection** - Protect against common web attacks
- **API security** - Secure API endpoints
- **Bot protection** - Block malicious bots
- **DDoS protection** - Mitigate DDoS attacks
- **Rate limiting** - Control request rates
- **Geographic restrictions** - Block requests from specific countries
- **SQL injection protection** - Prevent SQL injection attacks
- **XSS protection** - Prevent cross-site scripting attacks

## 🏗️ Architecture Patterns

### **Basic WAF Structure**
```
WAF Web ACL
├── Rules (Custom Rules)
├── Rule Groups (Managed Rule Groups)
├── IP Sets (IP Address Collections)
├── Regex Pattern Sets (Pattern Collections)
├── Rate-based Rules (Rate Limiting)
└── Geo Match Rules (Geographic Rules)
```

### **WAF Protection Pattern**
```
Internet
├── WAF Web ACL (Protection Layer)
├── CloudFront (CDN)
├── Load Balancer (Traffic Distribution)
└── Application (Protected Resource)
```

## 📝 Terraform Implementation

### **Basic WAF Setup**
```hcl
# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "main-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Main Web ACL"
    Environment = "production"
  }
}

# WAF IP Set
resource "aws_wafv2_ip_set" "main" {
  name               = "main-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "192.168.0.0/16",
    "10.0.0.0/8"
  ]

  tags = {
    Name        = "Main IP Set"
    Environment = "production"
  }
}

# WAF Rule
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

### **WAF with Managed Rule Groups**
```hcl
# WAF Web ACL with managed rule groups
resource "aws_wafv2_web_acl" "managed_rules" {
  name  = "managed-rules-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Group - Known Bad Inputs
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

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ManagedRulesWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Managed Rules Web ACL"
    Environment = "production"
  }
}
```

### **WAF with Custom Rules**
```hcl
# WAF Web ACL with custom rules
resource "aws_wafv2_web_acl" "custom_rules" {
  name  = "custom-rules-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Custom Rule - Block specific IPs
  rule {
    name     = "BlockSpecificIPs"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockSpecificIPsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Custom Rule - Rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 2

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
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CustomRulesWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Custom Rules Web ACL"
    Environment = "production"
  }
}

# IP Set for blocked IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "1.2.3.4/32",
    "5.6.7.8/32"
  ]

  tags = {
    Name        = "Blocked IPs"
    Environment = "production"
  }
}
```

### **WAF with Geographic Rules**
```hcl
# WAF Web ACL with geographic rules
resource "aws_wafv2_web_acl" "geo_rules" {
  name  = "geo-rules-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Geographic Rule - Block specific countries
  rule {
    name     = "BlockSpecificCountries"
    priority = 1

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
      metric_name                = "BlockSpecificCountriesMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GeoRulesWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Geo Rules Web ACL"
    Environment = "production"
  }
}
```

### **WAF with Regex Pattern Sets**
```hcl
# WAF Regex Pattern Set
resource "aws_wafv2_regex_pattern_set" "main" {
  name  = "main-regex-pattern-set"
  scope = "REGIONAL"

  regular_expression {
    regex_string = ".*\\.php$"
  }

  regular_expression {
    regex_string = ".*\\.asp$"
  }

  tags = {
    Name        = "Main Regex Pattern Set"
    Environment = "production"
  }
}

# WAF Web ACL with regex rules
resource "aws_wafv2_web_acl" "regex_rules" {
  name  = "regex-rules-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Regex Rule - Block specific file extensions
  rule {
    name     = "BlockFileExtensions"
    priority = 1

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.main.arn

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockFileExtensionsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RegexRulesWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Regex Rules Web ACL"
    Environment = "production"
  }
}
```

### **WAF with CloudFront**
```hcl
# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1

  name  = "cloudfront-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudFrontWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "CloudFront Web ACL"
    Environment = "production"
  }
}

# CloudFront distribution with WAF
resource "aws_cloudfront_distribution" "waf_protected" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.main.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.main.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  tags = {
    Name        = "WAF Protected CloudFront Distribution"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **WAF Web ACL Configuration**
```hcl
resource "aws_wafv2_web_acl" "custom" {
  name  = var.web_acl_name
  scope = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  # Rules
  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.managed_rule_group != null ? [rule.value.managed_rule_group] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${rule.value.name}Metric"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.web_acl_name
    sampled_requests_enabled   = true
  }

  tags = merge(var.common_tags, {
    Name = var.web_acl_name
  })
}
```

### **Advanced WAF Configuration**
```hcl
# Advanced WAF Web ACL
resource "aws_wafv2_web_acl" "advanced" {
  name  = "advanced-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Advanced Rule - SQL Injection Protection
  rule {
    name     = "SQLInjectionProtection"
    priority = 1

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = "union"
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }

        statement {
          byte_match_statement {
            search_string         = "select"
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionProtectionMetric"
      sampled_requests_enabled   = true
    }
  }

  # Advanced Rule - XSS Protection
  rule {
    name     = "XSSProtection"
    priority = 2

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {}
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }

        text_transformation {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSProtectionMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AdvancedWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Advanced Web ACL"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple WAF Web ACL
resource "aws_wafv2_web_acl" "simple" {
  name  = "simple-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SimpleWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "Simple Web ACL"
  }
}
```

### **Production Deployment**
```hcl
# Production WAF setup
locals {
  waf_config = {
    web_acl_name = "production-web-acl"
    scope = "REGIONAL"
    enable_managed_rules = true
    enable_custom_rules = true
    enable_rate_limiting = true
    enable_geo_blocking = true
  }
}

# Production WAF Web ACL
resource "aws_wafv2_web_acl" "production" {
  name  = local.waf_config.web_acl_name
  scope = local.waf_config.scope

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 2

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
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ProductionWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Production Web ACL"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment WAF setup
locals {
  environments = {
    dev = {
      web_acl_name = "dev-web-acl"
      scope = "REGIONAL"
      enable_managed_rules = false
    }
    staging = {
      web_acl_name = "staging-web-acl"
      scope = "REGIONAL"
      enable_managed_rules = true
    }
    prod = {
      web_acl_name = "prod-web-acl"
      scope = "REGIONAL"
      enable_managed_rules = true
    }
  }
}

# Environment-specific WAF Web ACLs
resource "aws_wafv2_web_acl" "environment" {
  for_each = local.environments

  name  = each.value.web_acl_name
  scope = each.value.scope

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
  dynamic "rule" {
    for_each = each.value.enable_managed_rules ? [1] : []
    content {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1

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
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = each.value.web_acl_name
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${title(each.key)} Web ACL"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for WAF
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/web-acl"
  retention_in_days = 30

  tags = {
    Name        = "WAF Logs"
    Environment = "production"
  }
}

# WAF Web ACL with logging
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn = aws_wafv2_web_acl.main.arn

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# CloudWatch metric filter for WAF
resource "aws_cloudwatch_log_metric_filter" "waf_blocks" {
  name           = "WAFBlocks"
  log_group_name = aws_cloudwatch_log_group.waf_logs.name
  pattern        = "[timestamp, request_id, action=\"BLOCK\", ...]"

  metric_transformation {
    name      = "WAFBlocks"
    namespace = "WAF/Blocks"
    value     = "1"
  }
}

# CloudWatch alarm for WAF blocks
resource "aws_cloudwatch_metric_alarm" "waf_blocks" {
  alarm_name          = "WAFBlocksAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WAFBlocks"
  namespace           = "WAF/Blocks"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors WAF blocks"

  tags = {
    Name        = "WAF Blocks Alarm"
    Environment = "production"
  }
}
```

### **WAF Metrics**
```hcl
# CloudWatch alarm for WAF requests
resource "aws_cloudwatch_metric_alarm" "waf_requests" {
  alarm_name          = "WAFRequestsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Count"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors WAF requests"

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = data.aws_region.current.name
  }

  tags = {
    Name        = "WAF Requests Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **WAF Security Configuration**
```hcl
# Secure WAF Web ACL
resource "aws_wafv2_web_acl" "secure" {
  name  = "secure-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Group - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

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
    metric_name                = "SecureWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Secure Web ACL"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for WAF access
resource "aws_iam_policy" "waf_access" {
  name        = "WAFAccess"
  description = "Policy for WAF access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetWebACL",
          "wafv2:ListWebACLs",
          "wafv2:GetLoggingConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **WAF Optimization**
```hcl
# Cost-optimized WAF Web ACL
resource "aws_wafv2_web_acl" "cost_optimized" {
  name  = "cost-optimized-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Only essential managed rule groups
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CostOptimizedWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Cost Optimized Web ACL"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: WAF Not Blocking Requests**
```hcl
# Debug WAF Web ACL
resource "aws_wafv2_web_acl" "debug" {
  name  = "debug-web-acl"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "DebugWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Debug Web ACL"
    Environment = "production"
  }
}
```

#### **Issue: WAF Rules Not Working**
```hcl
# Debug WAF Web ACL with simple rule
resource "aws_wafv2_web_acl" "debug_rules" {
  name  = "debug-rules-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Simple rule for debugging
  rule {
    name     = "DebugRule"
    priority = 1

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string         = "test"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "DebugRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "DebugRulesWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Debug Rules Web ACL"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce WAF Setup**
```hcl
# E-commerce WAF setup
locals {
  ecommerce_config = {
    web_acl_name = "ecommerce-web-acl"
    scope = "REGIONAL"
    enable_managed_rules = true
    enable_rate_limiting = true
    enable_geo_blocking = true
  }
}

# E-commerce WAF Web ACL
resource "aws_wafv2_web_acl" "ecommerce" {
  name  = local.ecommerce_config.web_acl_name
  scope = local.ecommerce_config.scope

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 2

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
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "EcommerceWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "E-commerce Web ACL"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices WAF Setup**
```hcl
# Microservices WAF setup
resource "aws_wafv2_web_acl" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name  = "${each.value}-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule Group - Core Rule Set
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${each.value}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Microservices ${title(each.value)} Web ACL"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **CloudFront**: CDN protection
- **Load Balancer**: ALB/NLB protection
- **API Gateway**: API protection
- **CloudWatch**: Monitoring and logging
- **Route 53**: DNS protection
- **S3**: Static website protection
- **ECS**: Container protection
- **Lambda**: Function protection

### **Service Dependencies**
- **CloudWatch**: Monitoring and logging
- **IAM**: Access control
- **VPC**: Network protection
- **Route 53**: DNS protection

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic WAF examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect WAF with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your WAF Mastery Journey Continues with Advanced Security!** 🚀

---

*This comprehensive WAF guide provides everything you need to master AWS WAF with Terraform. Each example is production-ready and follows security best practices.*
