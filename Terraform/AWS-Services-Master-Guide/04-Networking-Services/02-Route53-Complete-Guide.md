# Route 53 - Complete Terraform Guide

## 🎯 Overview

Amazon Route 53 is a highly available and scalable cloud Domain Name System (DNS) web service. It's designed to give developers and businesses an extremely reliable and cost-effective way to route end users to Internet applications by translating names like www.example.com into the numeric IP addresses like 192.0.2.1 that computers use to connect to each other.

### **What is Route 53?**
Route 53 is AWS's DNS service that provides reliable routing for your domain to AWS services or other web services. It offers a variety of routing policies and integrates seamlessly with other AWS services.

### **Key Concepts**
- **Hosted Zone**: Container for DNS records for a domain
- **DNS Records**: A, AAAA, CNAME, MX, TXT, etc.
- **Routing Policies**: Simple, Weighted, Latency-based, Failover, Geolocation
- **Health Checks**: Monitor the health of resources
- **Alias Records**: Route traffic to AWS resources
- **Private Hosted Zones**: DNS for VPC resources
- **Domain Registration**: Register new domains

### **When to Use Route 53**
- **Domain management** - Manage DNS for your domains
- **Load balancing** - Distribute traffic across multiple resources
- **Health monitoring** - Monitor resource health and failover
- **Geographic routing** - Route traffic based on user location
- **Cost optimization** - Route traffic to cost-effective resources
- **Disaster recovery** - Implement failover strategies
- **Microservices** - Route traffic to different services

## 🏗️ Architecture Patterns

### **Basic Route 53 Structure**
```
Route 53
├── Hosted Zone (example.com)
│   ├── A Records (www.example.com)
│   ├── CNAME Records (api.example.com)
│   ├── MX Records (mail.example.com)
│   └── TXT Records (verification)
├── Health Checks
├── Routing Policies
└── Alias Records
```

### **Multi-Region Routing Pattern**
```
Route 53
├── Primary Region (US-East-1)
│   ├── ALB (Primary)
│   └── Health Check
├── Secondary Region (EU-West-1)
│   ├── ALB (Secondary)
│   └── Health Check
└── Failover Routing Policy
```

### **Microservices Routing Pattern**
```
Route 53
├── Main Domain (example.com)
│   ├── Frontend Service (www.example.com)
│   ├── API Service (api.example.com)
│   ├── User Service (users.example.com)
│   ├── Product Service (products.example.com)
│   └── Order Service (orders.example.com)
└── Service Discovery
```

## 📝 Terraform Implementation

### **Basic Route 53 Setup**
```hcl
# Hosted zone for domain
resource "aws_route53_zone" "main" {
  name = "example.com"

  tags = {
    Name        = "Main Hosted Zone"
    Environment = "production"
  }
}

# A record for www subdomain
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# A record for root domain
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# CNAME record for API subdomain
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.api.dns_name]
}

# MX record for email
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mail.example.com"
  ]
}

# TXT record for domain verification
resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "TXT"
  ttl     = 300
  records = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}
```

### **Health Checks and Failover**
```hcl
# Health check for primary ALB
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "Primary Health Check"
    Environment = "production"
  }
}

# Health check for secondary ALB
resource "aws_route53_health_check" "secondary" {
  fqdn              = aws_lb.secondary.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "Secondary Health Check"
    Environment = "production"
  }
}

# Failover routing policy
resource "aws_route53_record" "failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
  health_check_id = aws_route53_health_check.secondary.id

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
}
```

### **Weighted Routing**
```hcl
# Weighted routing policy
resource "aws_route53_record" "weighted_1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "weighted.example.com"
  type    = "A"

  weighted_routing_policy {
    weight = 70
  }

  set_identifier = "version1"

  alias {
    name                   = aws_lb.version1.dns_name
    zone_id                = aws_lb.version1.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "weighted_2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "weighted.example.com"
  type    = "A"

  weighted_routing_policy {
    weight = 30
  }

  set_identifier = "version2"

  alias {
    name                   = aws_lb.version2.dns_name
    zone_id                = aws_lb.version2.zone_id
    evaluate_target_health = true
  }
}
```

### **Latency-Based Routing**
```hcl
# Latency-based routing policy
resource "aws_route53_record" "latency_us" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "latency.example.com"
  type    = "A"

  latency_routing_policy {
    region = "us-east-1"
  }

  set_identifier = "us-east-1"

  alias {
    name                   = aws_lb.us_east.dns_name
    zone_id                = aws_lb.us_east.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "latency_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "latency.example.com"
  type    = "A"

  latency_routing_policy {
    region = "eu-west-1"
  }

  set_identifier = "eu-west-1"

  alias {
    name                   = aws_lb.eu_west.dns_name
    zone_id                = aws_lb.eu_west.zone_id
    evaluate_target_health = true
  }
}
```

### **Geolocation Routing**
```hcl
# Geolocation routing policy
resource "aws_route53_record" "geo_us" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "geo.example.com"
  type    = "A"

  geolocation_routing_policy {
    continent = "NA"
  }

  set_identifier = "north-america"

  alias {
    name                   = aws_lb.us.dns_name
    zone_id                = aws_lb.us.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "geo_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "geo.example.com"
  type    = "A"

  geolocation_routing_policy {
    continent = "EU"
  }

  set_identifier = "europe"

  alias {
    name                   = aws_lb.eu.dns_name
    zone_id                = aws_lb.eu.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "geo_default" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "geo.example.com"
  type    = "A"

  geolocation_routing_policy {
    country = "*"
  }

  set_identifier = "default"

  alias {
    name                   = aws_lb.default.dns_name
    zone_id                = aws_lb.default.zone_id
    evaluate_target_health = true
  }
}
```

### **Private Hosted Zone**
```hcl
# Private hosted zone for VPC
resource "aws_route53_zone" "private" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name        = "Private Hosted Zone"
    Environment = "production"
  }
}

# A record in private hosted zone
resource "aws_route53_record" "private_db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.internal.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_db_instance.main.address]
}

# CNAME record in private hosted zone
resource "aws_route53_record" "private_api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.internal.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.internal.dns_name]
}
```

## 🔧 Configuration Options

### **Route 53 Zone Configuration**
```hcl
resource "aws_route53_zone" "custom" {
  name = var.domain_name

  # Comment for the hosted zone
  comment = var.zone_comment

  # VPC configuration for private hosted zone
  dynamic "vpc" {
    for_each = var.private_zone ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  # Tags
  tags = merge(var.common_tags, {
    Name = var.domain_name
  })
}
```

### **Route 53 Record Configuration**
```hcl
resource "aws_route53_record" "custom" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = var.record_type
  ttl     = var.ttl

  # Records for non-alias records
  records = var.records

  # Alias configuration
  dynamic "alias" {
    for_each = var.alias_target != null ? [var.alias_target] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Routing policy
  dynamic "weighted_routing_policy" {
    for_each = var.weighted_routing != null ? [var.weighted_routing] : []
    content {
      weight = weighted_routing.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = var.latency_routing != null ? [var.latency_routing] : []
    content {
      region = latency_routing.value.region
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = var.geolocation_routing != null ? [var.geolocation_routing] : []
    content {
      continent = geolocation_routing.value.continent
      country   = geolocation_routing.value.country
    }
  }

  dynamic "failover_routing_policy" {
    for_each = var.failover_routing != null ? [var.failover_routing] : []
    content {
      type = failover_routing.value.type
    }
  }

  set_identifier = var.set_identifier
  health_check_id = var.health_check_id
}
```

### **Advanced Route 53 Configuration**
```hcl
# Advanced hosted zone with delegation
resource "aws_route53_zone" "advanced" {
  name = "advanced.example.com"

  # Delegation set
  delegation_set_id = aws_route53_delegation_set.main.id

  tags = {
    Name        = "Advanced Hosted Zone"
    Environment = "production"
  }
}

# Delegation set
resource "aws_route53_delegation_set" "main" {
  reference_name = "main-delegation-set"
}

# Advanced health check
resource "aws_route53_health_check" "advanced" {
  fqdn              = "advanced.example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  measure_latency    = true
  enable_sni        = true

  tags = {
    Name        = "Advanced Health Check"
    Environment = "production"
  }
}

# Advanced record with multiple routing policies
resource "aws_route53_record" "advanced" {
  zone_id = aws_route53_zone.advanced.zone_id
  name    = "advanced.example.com"
  type    = "A"

  # Weighted routing with health check
  weighted_routing_policy {
    weight = 50
  }

  set_identifier = "advanced-set"
  health_check_id = aws_route53_health_check.advanced.id

  alias {
    name                   = aws_lb.advanced.dns_name
    zone_id                = aws_lb.advanced.zone_id
    evaluate_target_health = true
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple Route 53 setup
resource "aws_route53_zone" "simple" {
  name = "simple.example.com"

  tags = {
    Name = "Simple Hosted Zone"
  }
}

# Simple A record
resource "aws_route53_record" "simple" {
  zone_id = aws_route53_zone.simple.zone_id
  name    = "www.simple.example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}
```

### **Production Deployment**
```hcl
# Production Route 53 setup
locals {
  route53_config = {
    domain_name = "production.example.com"
    enable_failover = true
    enable_health_checks = true
    enable_ssl = true
  }
}

# Production hosted zone
resource "aws_route53_zone" "production" {
  name = local.route53_config.domain_name

  tags = {
    Name        = "Production Hosted Zone"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production health check
resource "aws_route53_health_check" "production" {
  fqdn              = "www.${local.route53_config.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  measure_latency    = true
  enable_sni        = true

  tags = {
    Name        = "Production Health Check"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production A record with alias
resource "aws_route53_record" "production" {
  zone_id = aws_route53_zone.production.zone_id
  name    = "www.${local.route53_config.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.production.dns_name
    zone_id                = aws_lb.production.zone_id
    evaluate_target_health = true
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment Route 53 setup
locals {
  environments = {
    dev = {
      domain_name = "dev.example.com"
      enable_health_checks = false
    }
    staging = {
      domain_name = "staging.example.com"
      enable_health_checks = true
    }
    prod = {
      domain_name = "prod.example.com"
      enable_health_checks = true
    }
  }
}

# Environment-specific hosted zones
resource "aws_route53_zone" "environment" {
  for_each = local.environments

  name = each.value.domain_name

  tags = {
    Name        = "${each.key} Hosted Zone"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific health checks
resource "aws_route53_health_check" "environment" {
  for_each = {
    for env, config in local.environments : env => config
    if config.enable_health_checks
  }

  fqdn              = "www.${each.value.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "${each.key} Health Check"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for Route 53 logs
resource "aws_cloudwatch_log_group" "route53_logs" {
  name              = "/aws/route53/query-logs"
  retention_in_days = 30

  tags = {
    Name        = "Route 53 Query Logs"
    Environment = "production"
  }
}

# Route 53 query logging
resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_group.route53_logs]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_logs.arn
  zone_id                  = aws_route53_zone.main.zone_id
}

# CloudWatch metric filter for DNS queries
resource "aws_cloudwatch_log_metric_filter" "dns_queries" {
  name           = "DNSQueries"
  log_group_name = aws_cloudwatch_log_group.route53_logs.name
  pattern        = "[timestamp, request_id, query_name, query_type, response_code]"

  metric_transformation {
    name      = "DNSQueries"
    namespace = "Route53/Queries"
    value     = "1"
  }
}

# CloudWatch alarm for DNS query volume
resource "aws_cloudwatch_metric_alarm" "dns_query_volume" {
  alarm_name          = "DNSQueryVolume"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DNSQueries"
  namespace           = "Route53/Queries"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors DNS query volume"

  tags = {
    Name        = "DNS Query Volume Alarm"
    Environment = "production"
  }
}
```

### **Health Check Monitoring**
```hcl
# CloudWatch alarm for health check failures
resource "aws_cloudwatch_metric_alarm" "health_check_failures" {
  alarm_name          = "HealthCheckFailures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors health check failures"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  tags = {
    Name        = "Health Check Failures Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **DNS Security**
```hcl
# DNSSEC configuration
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "main-ksk"
  status                     = "ACTIVE"
}

# KMS key for DNSSEC
resource "aws_kms_key" "dnssec" {
  description             = "KMS key for DNSSEC"
  deletion_window_in_days = 7

  tags = {
    Name        = "DNSSEC KMS Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "dnssec" {
  name          = "alias/dnssec-key"
  target_key_id = aws_kms_key.dnssec.key_id
}

# DNSSEC signing configuration
resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on = [aws_route53_key_signing_key.main]
  hosted_zone_id = aws_route53_zone.main.zone_id
}
```

### **Private Hosted Zone Security**
```hcl
# Private hosted zone with VPC association
resource "aws_route53_zone" "private_secure" {
  name = "secure.internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name        = "Secure Private Hosted Zone"
    Environment = "production"
  }
}

# VPC association for private hosted zone
resource "aws_route53_zone_association" "private" {
  zone_id = aws_route53_zone.private_secure.zone_id
  vpc_id  = aws_vpc.main.id
}
```

### **Access Control**
```hcl
# IAM policy for Route 53 access
resource "aws_iam_policy" "route53_access" {
  name        = "Route53Access"
  description = "Policy for Route 53 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${aws_route53_zone.main.zone_id}"
      }
    ]
  })
}

# IAM role for Route 53 access
resource "aws_iam_role" "route53_role" {
  name = "route53-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "route53_policy" {
  role       = aws_iam_role.route53_role.name
  policy_arn = aws_iam_policy.route53_access.arn
}
```

## 💰 Cost Optimization

### **Cost-Effective Routing**
```hcl
# Cost-effective weighted routing
resource "aws_route53_record" "cost_effective_1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cost.example.com"
  type    = "A"

  weighted_routing_policy {
    weight = 80
  }

  set_identifier = "cheap-resource"

  alias {
    name                   = aws_lb.cheap.dns_name
    zone_id                = aws_lb.cheap.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cost_effective_2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cost.example.com"
  type    = "A"

  weighted_routing_policy {
    weight = 20
  }

  set_identifier = "expensive-resource"

  alias {
    name                   = aws_lb.expensive.dns_name
    zone_id                = aws_lb.expensive.zone_id
    evaluate_target_health = true
  }
}
```

### **Health Check Optimization**
```hcl
# Optimized health check
resource "aws_route53_health_check" "optimized" {
  fqdn              = "optimized.example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  measure_latency   = true

  # Optimized settings
  enable_sni = false
  insufficient_data_health_status = "Healthy"

  tags = {
    Name        = "Optimized Health Check"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: DNS Resolution Problems**
```hcl
# Debug DNS record
resource "aws_route53_record" "debug" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "debug.example.com"
  type    = "A"
  ttl     = 60
  records = ["192.0.2.1"]
}
```

#### **Issue: Health Check Failures**
```hcl
# Debug health check
resource "aws_route53_health_check" "debug" {
  fqdn              = "debug.example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "10"

  tags = {
    Name        = "Debug Health Check"
    Environment = "production"
  }
}
```

#### **Issue: Routing Policy Problems**
```hcl
# Debug routing policy
resource "aws_route53_record" "debug_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "debug-routing.example.com"
  type    = "A"

  # Simple routing for debugging
  ttl     = 300
  records = ["192.0.2.1"]
}
```

## 📚 Real-World Examples

### **E-Commerce DNS Setup**
```hcl
# E-commerce Route 53 setup
locals {
  ecommerce_config = {
    domain_name = "ecommerce.example.com"
    enable_ssl = true
    enable_cdn = true
  }
}

# E-commerce hosted zone
resource "aws_route53_zone" "ecommerce" {
  name = local.ecommerce_config.domain_name

  tags = {
    Name        = "E-commerce Hosted Zone"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce health check
resource "aws_route53_health_check" "ecommerce" {
  fqdn              = "www.${local.ecommerce_config.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  measure_latency    = true
  enable_sni        = true

  tags = {
    Name        = "E-commerce Health Check"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce A record
resource "aws_route53_record" "ecommerce" {
  zone_id = aws_route53_zone.ecommerce.zone_id
  name    = "www.${local.ecommerce_config.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.ecommerce.dns_name
    zone_id                = aws_lb.ecommerce.zone_id
    evaluate_target_health = true
  }
}

# E-commerce API record
resource "aws_route53_record" "ecommerce_api" {
  zone_id = aws_route53_zone.ecommerce.zone_id
  name    = "api.${local.ecommerce_config.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.ecommerce_api.dns_name
    zone_id                = aws_lb.ecommerce_api.zone_id
    evaluate_target_health = true
  }
}
```

### **Microservices DNS Setup**
```hcl
# Microservices Route 53 setup
resource "aws_route53_zone" "microservices" {
  name = "microservices.example.com"

  tags = {
    Name        = "Microservices Hosted Zone"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices service records
resource "aws_route53_record" "user_service" {
  zone_id = aws_route53_zone.microservices.zone_id
  name    = "users.microservices.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.user_service.dns_name
    zone_id                = aws_lb.user_service.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "product_service" {
  zone_id = aws_route53_zone.microservices.zone_id
  name    = "products.microservices.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.product_service.dns_name
    zone_id                = aws_lb.product_service.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "order_service" {
  zone_id = aws_route53_zone.microservices.zone_id
  name    = "orders.microservices.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.order_service.dns_name
    zone_id                = aws_lb.order_service.zone_id
    evaluate_target_health = true
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **Load Balancers**: Traffic distribution
- **CloudFront**: CDN integration
- **S3**: Static website hosting
- **EC2**: Instance routing
- **ECS**: Container routing
- **EKS**: Kubernetes routing
- **Lambda**: Function routing
- **Certificate Manager**: SSL certificates
- **WAF**: Web application firewall

### **Service Dependencies**
- **Hosted Zones**: DNS management
- **Health Checks**: Resource monitoring
- **IAM**: Access control
- **CloudWatch**: Monitoring and logging
- **KMS**: DNSSEC key management

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Route 53 examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Route 53 with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and query logging
6. **Optimize**: Focus on cost and performance

**Your Route 53 Mastery Journey Continues with CloudFront!** 🚀

---

*This comprehensive Route 53 guide provides everything you need to master AWS Route 53 with Terraform. Each example is production-ready and follows security best practices.*
