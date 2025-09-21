# Load Balancers - Complete Terraform Guide

## 🎯 Overview

AWS Load Balancers distribute incoming application traffic across multiple targets, such as EC2 instances, containers, and IP addresses, in multiple Availability Zones. This increases the availability and fault tolerance of your applications.

### **What are Load Balancers?**
Load balancers act as a single point of contact for clients, distributing incoming requests across multiple targets to ensure high availability and fault tolerance. AWS provides three types of load balancers: Application Load Balancer (ALB), Network Load Balancer (NLB), and Classic Load Balancer (CLB).

### **Key Concepts**
- **Load Balancer**: Distributes traffic across multiple targets
- **Target Groups**: Group of targets that receive traffic
- **Listeners**: Check for connection requests from clients
- **Health Checks**: Monitor the health of targets
- **Availability Zones**: Distribute load balancer across multiple AZs
- **Security Groups**: Control traffic to load balancer
- **SSL/TLS Termination**: Handle SSL/TLS encryption

### **When to Use Load Balancers**
- **High availability** - Distribute traffic across multiple targets
- **Scalability** - Handle increased traffic automatically
- **Fault tolerance** - Route traffic away from unhealthy targets
- **SSL termination** - Handle SSL/TLS encryption
- **Path-based routing** - Route traffic based on URL path
- **Host-based routing** - Route traffic based on host header
- **Microservices** - Route traffic to different services

## 🏗️ Architecture Patterns

### **Basic Load Balancer Structure**
```
Load Balancer
├── Listeners (Port 80, 443)
├── Target Groups
│   ├── Web Targets
│   ├── App Targets
│   └── Database Targets
├── Health Checks
├── Security Groups
└── Availability Zones
```

### **Multi-Tier Load Balancer Pattern**
```
Internet
├── Application Load Balancer (ALB)
│   ├── Web Tier Targets
│   └── App Tier Targets
├── Network Load Balancer (NLB)
│   └── Database Tier Targets
└── Internal Load Balancer
    └── Microservices Targets
```

### **Microservices Load Balancer Pattern**
```
Application Load Balancer
├── Frontend Service (Path: /frontend/*)
├── API Service (Path: /api/*)
├── User Service (Path: /users/*)
├── Product Service (Path: /products/*)
└── Order Service (Path: /orders/*)
```

## 📝 Terraform Implementation

### **Application Load Balancer (ALB)**
```hcl
# Security group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ALB Security Group"
    Environment = "production"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = true

  tags = {
    Name        = "Main ALB"
    Environment = "production"
  }
}

# Target group for web servers
resource "aws_lb_target_group" "web" {
  name     = "web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Web Target Group"
    Environment = "production"
  }
}

# HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# SSL certificate
resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com"
  ]

  tags = {
    Name        = "Main SSL Certificate"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### **Network Load Balancer (NLB)**
```hcl
# Security group for NLB
resource "aws_security_group" "nlb" {
  name_prefix = "nlb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TCP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "NLB Security Group"
    Environment = "production"
  }
}

# Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "main-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = true

  tags = {
    Name        = "Main NLB"
    Environment = "production"
  }
}

# Target group for NLB
resource "aws_lb_target_group" "nlb" {
  name     = "nlb-targets"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    protocol            = "TCP"
  }

  tags = {
    Name        = "NLB Target Group"
    Environment = "production"
  }
}

# TCP listener
resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb.arn
  }
}
```

### **Internal Load Balancer**
```hcl
# Internal Application Load Balancer
resource "aws_lb" "internal" {
  name               = "internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = aws_subnet.private[*].id

  enable_deletion_protection = true

  tags = {
    Name        = "Internal ALB"
    Environment = "production"
  }
}

# Security group for internal ALB
resource "aws_security_group" "internal_alb" {
  name_prefix = "internal-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [aws_vpc.main.cidr_block]
  }

  ingress {
    description     = "HTTPS from VPC"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Internal ALB Security Group"
    Environment = "production"
  }
}

# Target group for internal services
resource "aws_lb_target_group" "internal" {
  name     = "internal-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Internal Target Group"
    Environment = "production"
  }
}

# Internal HTTP listener
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }
}
```

### **Path-Based Routing**
```hcl
# Target group for API service
resource "aws_lb_target_group" "api" {
  name     = "api-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "API Target Group"
    Environment = "production"
  }
}

# Target group for frontend service
resource "aws_lb_target_group" "frontend" {
  name     = "frontend-targets"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Frontend Target Group"
    Environment = "production"
  }
}

# Path-based routing rules
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    path_pattern {
      values = ["/frontend/*"]
    }
  }
}
```

### **Host-Based Routing**
```hcl
# Target group for admin service
resource "aws_lb_target_group" "admin" {
  name     = "admin-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/admin/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Admin Target Group"
    Environment = "production"
  }
}

# Host-based routing rules
resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }

  condition {
    host_header {
      values = ["admin.example.com"]
    }
  }
}

resource "aws_lb_listener_rule" "api_subdomain" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = ["api.example.com"]
    }
  }
}
```

## 🔧 Configuration Options

### **Load Balancer Configuration**
```hcl
resource "aws_lb" "custom" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnets

  # Access logs
  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }

  # Deletion protection
  enable_deletion_protection = var.enable_deletion_protection

  # Cross-zone load balancing
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # HTTP/2
  enable_http2 = var.enable_http2

  # WAF
  enable_waf_fail_open = var.enable_waf_fail_open

  tags = merge(var.common_tags, {
    Name = var.lb_name
  })
}
```

### **Target Group Configuration**
```hcl
resource "aws_lb_target_group" "custom" {
  name     = var.target_group_name
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = var.health_check_enabled
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = var.health_check_port
    protocol            = var.health_check_protocol
  }

  # Target group attributes
  target_type = var.target_type

  # Stickiness
  stickiness {
    type            = var.stickiness_type
    cookie_duration = var.cookie_duration
    enabled         = var.stickiness_enabled
  }

  # Deregistration delay
  deregistration_delay = var.deregistration_delay

  # Load balancing algorithm
  load_balancing_algorithm_type = var.load_balancing_algorithm_type

  tags = merge(var.common_tags, {
    Name = var.target_group_name
  })
}
```

### **Advanced Load Balancer Configuration**
```hcl
# Advanced ALB with WAF
resource "aws_lb" "advanced" {
  name               = "advanced-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  # Deletion protection
  enable_deletion_protection = true

  # HTTP/2
  enable_http2 = true

  # WAF
  enable_waf_fail_open = true

  tags = {
    Name        = "Advanced ALB"
    Environment = "production"
  }
}

# S3 bucket for ALB logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "alb-logs-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "ALB Logs Bucket"
    Environment = "production"
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "alb" {
  name  = "alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

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
    metric_name                = "ALBWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "ALB WAF"
    Environment = "production"
  }
}

# WAF association
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.advanced.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple ALB setup
resource "aws_lb" "simple" {
  name               = "simple-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "Simple ALB"
  }
}

resource "aws_lb_target_group" "simple" {
  name     = "simple-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "Simple Target Group"
  }
}

resource "aws_lb_listener" "simple" {
  load_balancer_arn = aws_lb.simple.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.simple.arn
  }
}
```

### **Production Deployment**
```hcl
# Production ALB setup
locals {
  alb_config = {
    name = "production-alb"
    internal = false
    load_balancer_type = "application"
    enable_deletion_protection = true
    enable_http2 = true
    enable_waf_fail_open = true
  }
}

# Production ALB
resource "aws_lb" "production" {
  name               = local.alb_config.name
  internal           = local.alb_config.internal
  load_balancer_type = local.alb_config.load_balancer_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  # Deletion protection
  enable_deletion_protection = local.alb_config.enable_deletion_protection

  # HTTP/2
  enable_http2 = local.alb_config.enable_http2

  # WAF
  enable_waf_fail_open = local.alb_config.enable_waf_fail_open

  tags = {
    Name        = "Production ALB"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production target group
resource "aws_lb_target_group" "production" {
  name     = "production-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Stickiness
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name        = "Production Target Group"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment ALB setup
locals {
  environments = {
    dev = {
      name = "dev-alb"
      internal = false
      enable_deletion_protection = false
    }
    staging = {
      name = "staging-alb"
      internal = false
      enable_deletion_protection = false
    }
    prod = {
      name = "prod-alb"
      internal = false
      enable_deletion_protection = true
    }
  }
}

# Environment-specific ALBs
resource "aws_lb" "environment" {
  for_each = local.environments

  name               = each.value.name
  internal           = each.value.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Deletion protection
  enable_deletion_protection = each.value.enable_deletion_protection

  tags = {
    Name        = each.value.name
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific target groups
resource "aws_lb_target_group" "environment" {
  for_each = local.environments

  name     = "${each.key}-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${each.key} Target Group"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for ALB logs
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/aws/applicationloadbalancer/alb"
  retention_in_days = 30

  tags = {
    Name        = "ALB Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for ALB errors
resource "aws_cloudwatch_log_metric_filter" "alb_errors" {
  name           = "ALBErrors"
  log_group_name = aws_cloudwatch_log_group.alb_logs.name
  pattern        = "[timestamp, request_id, error_code=\"*\", ...]"

  metric_transformation {
    name      = "ALBErrors"
    namespace = "ALB/Errors"
    value     = "1"
  }
}

# CloudWatch alarm for ALB errors
resource "aws_cloudwatch_metric_alarm" "alb_errors_alarm" {
  alarm_name          = "ALBErrorsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ALBErrors"
  namespace           = "ALB/Errors"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB errors"

  tags = {
    Name        = "ALB Errors Alarm"
    Environment = "production"
  }
}

# CloudWatch alarm for target response time
resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "TargetResponseTime"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors target response time"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "Target Response Time Alarm"
    Environment = "production"
  }
}
```

### **Access Logs**
```hcl
# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_access_logs" {
  bucket = "alb-access-logs-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "ALB Access Logs Bucket"
    Environment = "production"
  }
}

# ALB with access logs
resource "aws_lb" "with_logs" {
  name               = "alb-with-logs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name        = "ALB with Logs"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Security Groups**
```hcl
# Restrictive security group for ALB
resource "aws_security_group" "alb_restrictive" {
  name_prefix = "alb-restrictive-"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from specific IP ranges
  ingress {
    description = "HTTP from office"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }

  # Allow HTTPS from specific IP ranges
  ingress {
    description = "HTTPS from office"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ALB Restrictive Security Group"
    Environment = "production"
  }
}
```

### **WAF Integration**
```hcl
# WAF Web ACL for ALB
resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

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
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ALBWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "ALB WAF"
    Environment = "production"
  }
}

# WAF association with ALB
resource "aws_wafv2_web_acl_association" "alb_waf" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}
```

### **SSL/TLS Configuration**
```hcl
# SSL certificate for ALB
resource "aws_acm_certificate" "alb_ssl" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com",
    "api.example.com"
  ]

  tags = {
    Name        = "ALB SSL Certificate"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB with SSL termination
resource "aws_lb" "ssl_termination" {
  name               = "ssl-termination-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "SSL Termination ALB"
    Environment = "production"
  }
}

# HTTPS listener with SSL
resource "aws_lb_listener" "ssl_https" {
  load_balancer_arn = aws_lb.ssl_termination.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.alb_ssl.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

## 💰 Cost Optimization

### **Target Group Optimization**
```hcl
# Optimized target group
resource "aws_lb_target_group" "optimized" {
  name     = "optimized-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Optimized health check
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Optimized stickiness
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = true
  }

  # Optimized deregistration delay
  deregistration_delay = 30

  tags = {
    Name        = "Optimized Target Group"
    Environment = "production"
  }
}
```

### **Load Balancer Optimization**
```hcl
# Optimized ALB
resource "aws_lb" "optimized" {
  name               = "optimized-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Optimized settings
  enable_deletion_protection = false
  enable_http2 = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "Optimized ALB"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Target Health Check Failures**
```hcl
# Debug target group
resource "aws_lb_target_group" "debug" {
  name     = "debug-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Debug health check
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Debug Target Group"
    Environment = "production"
  }
}
```

#### **Issue: SSL Certificate Problems**
```hcl
# Debug SSL certificate
resource "aws_acm_certificate" "debug" {
  domain_name       = "debug.example.com"
  validation_method = "DNS"

  tags = {
    Name        = "Debug SSL Certificate"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Debug HTTPS listener
resource "aws_lb_listener" "debug_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.debug.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.debug.arn
  }
}
```

#### **Issue: Routing Problems**
```hcl
# Debug routing rules
resource "aws_lb_listener_rule" "debug" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1000

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.debug.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Load Balancer**
```hcl
# E-commerce ALB setup
locals {
  ecommerce_config = {
    name = "ecommerce-alb"
    internal = false
    enable_deletion_protection = true
    enable_http2 = true
  }
}

# E-commerce ALB
resource "aws_lb" "ecommerce" {
  name               = local.ecommerce_config.name
  internal           = local.ecommerce_config.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "ecommerce-logs"
    enabled = true
  }

  # Deletion protection
  enable_deletion_protection = local.ecommerce_config.enable_deletion_protection

  # HTTP/2
  enable_http2 = local.ecommerce_config.enable_http2

  tags = {
    Name        = "E-commerce ALB"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce target groups
resource "aws_lb_target_group" "ecommerce_web" {
  name     = "ecommerce-web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "E-commerce Web Target Group"
    Environment = "production"
    Project     = "ecommerce"
  }
}

resource "aws_lb_target_group" "ecommerce_api" {
  name     = "ecommerce-api-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "E-commerce API Target Group"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Load Balancer**
```hcl
# Microservices ALB setup
resource "aws_lb" "microservices" {
  name               = "microservices-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = aws_subnet.private[*].id

  tags = {
    Name        = "Microservices ALB"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices target groups
resource "aws_lb_target_group" "user_service" {
  name     = "user-service-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/users/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "User Service Target Group"
    Environment = "production"
    Project     = "microservices"
  }
}

resource "aws_lb_target_group" "product_service" {
  name     = "product-service-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/products/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "Product Service Target Group"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **EC2**: Target instances
- **ECS**: Target containers
- **EKS**: Target pods
- **Lambda**: Target functions
- **VPC**: Network placement
- **Security Groups**: Network security
- **Route 53**: DNS routing
- **CloudFront**: CDN integration
- **WAF**: Web application firewall
- **Certificate Manager**: SSL certificates

### **Service Dependencies**
- **Target Groups**: Traffic distribution
- **Listeners**: Traffic routing
- **Security Groups**: Network security
- **Subnets**: Network placement
- **IAM Roles**: Service permissions

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic load balancer examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect load balancers with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and access logs
6. **Optimize**: Focus on cost and performance

**Your Load Balancer Mastery Journey Continues with Route 53!** 🚀

---

*This comprehensive Load Balancer guide provides everything you need to master AWS Load Balancers with Terraform. Each example is production-ready and follows security best practices.*
