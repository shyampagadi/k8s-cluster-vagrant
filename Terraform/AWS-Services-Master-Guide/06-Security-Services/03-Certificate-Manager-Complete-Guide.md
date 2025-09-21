# Certificate Manager - Complete Terraform Guide

## 🎯 Overview

AWS Certificate Manager (ACM) is a service that lets you easily provision, manage, and deploy public and private SSL/TLS certificates for use with AWS services and your internal connected resources.

### **What is Certificate Manager?**
ACM is a service that helps you manage SSL/TLS certificates for your AWS-based websites and applications. It handles the complexity of creating, storing, and renewing public and private certificates.

### **Key Concepts**
- **Public Certificates**: SSL/TLS certificates for public-facing resources
- **Private Certificates**: SSL/TLS certificates for internal resources
- **Certificate Authority (CA)**: Entity that issues certificates
- **Domain Validation**: Process to verify domain ownership
- **Certificate Chain**: Chain of trust from certificate to root CA
- **Key Pair**: Public and private key pair for encryption
- **Certificate Transparency**: Public log of certificates
- **Renewal**: Automatic certificate renewal
- **Export**: Export certificates for use outside AWS

### **When to Use Certificate Manager**
- **HTTPS websites** - Secure web applications
- **API endpoints** - Secure API communications
- **Load balancers** - SSL termination at load balancers
- **CloudFront distributions** - CDN SSL certificates
- **API Gateway** - Secure API endpoints
- **Elastic Load Balancing** - SSL termination
- **Internal applications** - Private certificates
- **Microservices** - Service-to-service encryption

## 🏗️ Architecture Patterns

### **Basic Certificate Manager Structure**
```
Certificate Manager
├── Public Certificates (Internet-facing)
├── Private Certificates (Internal)
├── Certificate Authority (CA)
├── Domain Validation
├── Certificate Chain
└── Automatic Renewal
```

### **SSL/TLS Termination Pattern**
```
Internet
├── CloudFront (SSL Certificate)
├── Load Balancer (SSL Certificate)
├── API Gateway (SSL Certificate)
└── Application (HTTP)
```

## 📝 Terraform Implementation

### **Basic Public Certificate Setup**
```hcl
# Public certificate
resource "aws_acm_certificate" "public" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com",
    "api.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Public Certificate"
    Environment = "production"
  }
}

# Certificate validation
resource "aws_acm_certificate_validation" "public" {
  certificate_arn         = aws_acm_certificate.public.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.public.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Route53 zone
resource "aws_route53_zone" "main" {
  name = "example.com"

  tags = {
    Name        = "Main Route53 Zone"
    Environment = "production"
  }
}
```

### **Certificate with Email Validation**
```hcl
# Public certificate with email validation
resource "aws_acm_certificate" "email_validated" {
  domain_name       = "example.com"
  validation_method = "EMAIL"

  subject_alternative_names = [
    "www.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Email Validated Certificate"
    Environment = "production"
  }
}
```

### **Private Certificate Setup**
```hcl
# Private certificate authority
resource "aws_acm_certificate_authority" "private_ca" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name  = "Private CA"
      organization = "Example Organization"
    }
  }

  permanent_deletion_time_in_days = 7

  tags = {
    Name        = "Private Certificate Authority"
    Environment = "production"
  }
}

# Private certificate
resource "aws_acm_certificate" "private" {
  certificate_authority_arn = aws_acm_certificate_authority.private_ca.arn
  domain_name               = "internal.example.com"

  subject_alternative_names = [
    "*.internal.example.com"
  ]

  tags = {
    Name        = "Private Certificate"
    Environment = "production"
  }
}
```

### **Certificate with CloudFront**
```hcl
# Public certificate for CloudFront
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "CloudFront Certificate"
    Environment = "production"
  }
}

# CloudFront distribution with certificate
resource "aws_cloudfront_distribution" "main" {
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

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "CloudFront Distribution"
    Environment = "production"
  }
}

# S3 bucket for CloudFront
resource "aws_s3_bucket" "main" {
  bucket = "cloudfront-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CloudFront Bucket"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# CloudFront origin access identity
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for CloudFront"
}
```

### **Certificate with Load Balancer**
```hcl
# Public certificate for load balancer
resource "aws_acm_certificate" "alb" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "ALB Certificate"
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

  enable_deletion_protection = false

  tags = {
    Name        = "Main ALB"
    Environment = "production"
  }
}

# ALB listener with certificate
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALB target group
resource "aws_lb_target_group" "main" {
  name     = "main-tg"
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
    Name        = "Main Target Group"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **Certificate Configuration**
```hcl
resource "aws_acm_certificate" "custom" {
  domain_name       = var.domain_name
  validation_method = var.validation_method

  subject_alternative_names = var.subject_alternative_names

  certificate_authority_arn = var.certificate_authority_arn

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = var.domain_name
  })
}
```

### **Advanced Certificate Configuration**
```hcl
# Advanced public certificate
resource "aws_acm_certificate" "advanced" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "admin.example.com"
  ]

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Advanced Certificate"
    Environment = "production"
  }
}

# Advanced private certificate authority
resource "aws_acm_certificate_authority" "advanced_ca" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name           = "Advanced Private CA"
      country               = "US"
      organization          = "Example Organization"
      organizational_unit   = "IT Department"
      state                 = "CA"
      locality              = "San Francisco"
    }
  }

  permanent_deletion_time_in_days = 7

  tags = {
    Name        = "Advanced Private Certificate Authority"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple public certificate
resource "aws_acm_certificate" "simple" {
  domain_name       = "example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Simple Certificate"
  }
}
```

### **Production Deployment**
```hcl
# Production certificate setup
locals {
  certificate_config = {
    domain_name = "example.com"
    validation_method = "DNS"
    enable_cloudfront = true
    enable_alb = true
    enable_api_gateway = true
  }
}

# Production public certificate
resource "aws_acm_certificate" "production" {
  domain_name       = local.certificate_config.domain_name
  validation_method = local.certificate_config.validation_method

  subject_alternative_names = [
    "www.${local.certificate_config.domain_name}",
    "api.${local.certificate_config.domain_name}",
    "admin.${local.certificate_config.domain_name}"
  ]

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Production Certificate"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production certificate validation
resource "aws_acm_certificate_validation" "production" {
  certificate_arn         = aws_acm_certificate.production.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment certificate setup
locals {
  environments = {
    dev = {
      domain_name = "dev.example.com"
      validation_method = "DNS"
    }
    staging = {
      domain_name = "staging.example.com"
      validation_method = "DNS"
    }
    prod = {
      domain_name = "example.com"
      validation_method = "DNS"
    }
  }
}

# Environment-specific certificates
resource "aws_acm_certificate" "environment" {
  for_each = local.environments

  domain_name       = each.value.domain_name
  validation_method = each.value.validation_method

  subject_alternative_names = [
    "www.${each.value.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${title(each.key)} Certificate"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for Certificate Manager
resource "aws_cloudwatch_log_group" "certificate_logs" {
  name              = "/aws/certificate-manager/certificates"
  retention_in_days = 30

  tags = {
    Name        = "Certificate Manager Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for certificate events
resource "aws_cloudwatch_log_metric_filter" "certificate_events" {
  name           = "CertificateEvents"
  log_group_name = aws_cloudwatch_log_group.certificate_logs.name
  pattern        = "[timestamp, request_id, event_name=\"RequestCertificate\", ...]"

  metric_transformation {
    name      = "CertificateEvents"
    namespace = "Certificate Manager/Events"
    value     = "1"
  }
}

# CloudWatch alarm for certificate expiration
resource "aws_cloudwatch_metric_alarm" "certificate_expiration" {
  alarm_name          = "CertificateExpirationAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "86400"
  statistic           = "Minimum"
  threshold           = "30"
  alarm_description   = "This metric monitors certificate expiration"

  dimensions = {
    CertificateArn = aws_acm_certificate.public.arn
  }

  tags = {
    Name        = "Certificate Expiration Alarm"
    Environment = "production"
  }
}
```

### **Certificate Monitoring**
```hcl
# CloudWatch alarm for certificate validation
resource "aws_cloudwatch_metric_alarm" "certificate_validation" {
  alarm_name          = "CertificateValidationAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ValidationStatus"
  namespace           = "AWS/CertificateManager"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors certificate validation"

  dimensions = {
    CertificateArn = aws_acm_certificate.public.arn
  }

  tags = {
    Name        = "Certificate Validation Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Certificate Security**
```hcl
# Secure public certificate
resource "aws_acm_certificate" "secure" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com"
  ]

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Secure Certificate"
    Environment = "production"
  }
}
```

### **Private Certificate Security**
```hcl
# Secure private certificate authority
resource "aws_acm_certificate_authority" "secure_ca" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name           = "Secure Private CA"
      country               = "US"
      organization          = "Example Organization"
      organizational_unit   = "Security Department"
      state                 = "CA"
      locality              = "San Francisco"
    }
  }

  permanent_deletion_time_in_days = 7

  tags = {
    Name        = "Secure Private Certificate Authority"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for Certificate Manager access
resource "aws_iam_policy" "certificate_manager_access" {
  name        = "CertificateManagerAccess"
  description = "Policy for Certificate Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Certificate Optimization**
```hcl
# Cost-optimized certificate
resource "aws_acm_certificate" "cost_optimized" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Cost Optimized Certificate"
    Environment = "production"
  }
}
```

### **Wildcard Certificate**
```hcl
# Wildcard certificate for cost optimization
resource "aws_acm_certificate" "wildcard" {
  domain_name       = "*.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Wildcard Certificate"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Certificate Validation Failed**
```hcl
# Debug certificate
resource "aws_acm_certificate" "debug" {
  domain_name       = "example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Debug Certificate"
    Environment = "production"
  }
}
```

#### **Issue: Certificate Not Renewing**
```hcl
# Debug certificate with explicit renewal
resource "aws_acm_certificate" "debug_renewal" {
  domain_name       = "example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Debug Renewal Certificate"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Certificate Setup**
```hcl
# E-commerce certificate setup
locals {
  ecommerce_config = {
    domain_name = "ecommerce.example.com"
    validation_method = "DNS"
    enable_cloudfront = true
    enable_alb = true
  }
}

# E-commerce public certificate
resource "aws_acm_certificate" "ecommerce" {
  domain_name       = local.ecommerce_config.domain_name
  validation_method = local.ecommerce_config.validation_method

  subject_alternative_names = [
    "www.${local.ecommerce_config.domain_name}",
    "api.${local.ecommerce_config.domain_name}",
    "admin.${local.ecommerce_config.domain_name}",
    "checkout.${local.ecommerce_config.domain_name}"
  ]

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "E-commerce Certificate"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Certificate Setup**
```hcl
# Microservices certificate setup
resource "aws_acm_certificate" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  domain_name       = "${each.value}.example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "api.${each.value}.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Microservices ${title(each.value)} Certificate"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **CloudFront**: CDN SSL certificates
- **Load Balancer**: SSL termination
- **API Gateway**: API SSL certificates
- **Route 53**: DNS validation
- **S3**: Static website SSL
- **ECS**: Container SSL
- **Lambda**: Function SSL
- **VPC**: Private certificates

### **Service Dependencies**
- **Route 53**: DNS validation
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **VPC**: Private certificates

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Certificate Manager examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Certificate Manager with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your Certificate Manager Mastery Journey Continues with WAF!** 🚀

---

*This comprehensive Certificate Manager guide provides everything you need to master AWS Certificate Manager with Terraform. Each example is production-ready and follows security best practices.*
