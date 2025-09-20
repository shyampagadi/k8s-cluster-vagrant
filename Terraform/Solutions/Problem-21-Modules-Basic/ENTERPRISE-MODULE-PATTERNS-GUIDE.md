# Enterprise Module Development Patterns - Complete Guide

## 🏢 Enterprise Module Architecture

### Module Hierarchy and Governance

#### Enterprise Module Structure
```
enterprise-modules/
├── foundation/                    # Core infrastructure modules
│   ├── networking/               # VPC, subnets, routing
│   ├── security/                 # Security groups, NACLs, WAF
│   ├── identity/                 # IAM roles, policies, OIDC
│   └── monitoring/               # CloudWatch, logging, alerting
├── platform/                     # Platform services modules
│   ├── compute/                  # EC2, ASG, ECS, EKS
│   ├── storage/                  # S3, EFS, EBS, FSx
│   ├── database/                 # RDS, DynamoDB, ElastiCache
│   └── messaging/                # SQS, SNS, EventBridge
├── application/                   # Application-specific modules
│   ├── web-tier/                 # Load balancers, CDN
│   ├── api-gateway/              # API Gateway, Lambda
│   ├── microservices/            # Container orchestration
│   └── data-pipeline/            # ETL, analytics, ML
└── governance/                    # Compliance and policy modules
    ├── compliance/               # SOC2, PCI-DSS, HIPAA
    ├── cost-management/          # Budgets, cost allocation
    ├── backup-recovery/          # Backup strategies, DR
    └── security-scanning/        # Vulnerability assessment
```

### Enterprise Module Design Principles

#### 1. Single Responsibility Principle
```hcl
# ✅ Good: Focused VPC module
module "vpc" {
  source = "git::https://github.com/company/terraform-modules//vpc?ref=v2.1.0"
  
  name               = var.vpc_name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  
  # VPC-specific configuration only
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.environment == "production"
  
  tags = local.common_tags
}

# ❌ Bad: Monolithic module doing everything
module "infrastructure" {
  source = "./modules/everything"
  
  # Too many responsibilities
  vpc_config      = var.vpc_config
  ec2_config      = var.ec2_config
  rds_config      = var.rds_config
  s3_config       = var.s3_config
  iam_config      = var.iam_config
  # ... 50+ more configurations
}
```

#### 2. Interface Segregation
```hcl
# ✅ Good: Clean, focused interfaces
module "database" {
  source = "./modules/rds"
  
  # Database-specific inputs
  engine         = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.medium"
  
  # Network integration
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.database_subnet_ids
  security_group_ids   = [module.database_sg.security_group_id]
  
  # Backup and maintenance
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  tags = local.common_tags
}

# Module outputs only what's needed
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = false
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
  sensitive   = false
}

# Don't expose internal implementation details
# output "database_password" {  # ❌ Never expose secrets
#   value = aws_db_instance.main.password
# }
```

#### 3. Dependency Inversion
```hcl
# ✅ Good: Depend on abstractions, not concretions
module "application" {
  source = "./modules/application"
  
  # Abstract dependencies - module doesn't care about implementation
  vpc_id             = var.vpc_id              # Could be from any VPC module
  subnet_ids         = var.subnet_ids          # Could be from any subnet source
  security_group_ids = var.security_group_ids  # Could be from any SG module
  database_endpoint  = var.database_endpoint   # Could be RDS, Aurora, etc.
  
  # Application-specific configuration
  application_config = var.application_config
}

# ❌ Bad: Tight coupling to specific implementations
module "application" {
  source = "./modules/application"
  
  # Tightly coupled to specific module implementations
  vpc_id            = module.company_vpc_v2.vpc_id
  subnet_ids        = module.company_subnets_v1.private_subnet_ids
  database_endpoint = module.company_postgres_v3.primary_endpoint
}
```

## 🔒 Enterprise Security Patterns

### Security-First Module Design

#### 1. Encryption by Default
```hcl
# S3 Module with enterprise security
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  
  tags = var.tags
}

# Encryption is mandatory, not optional
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# Public access blocked by default
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning enabled for data protection
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle management for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_rules != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}
```

#### 2. Least Privilege IAM Patterns
```hcl
# IAM Role Module with least privilege
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = var.trusted_services
    }
    
    actions = ["sts:AssumeRole"]
    
    dynamic "condition" {
      for_each = var.assume_role_conditions
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "main" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
  # Prevent privilege escalation
  permissions_boundary = var.permissions_boundary_arn
  
  tags = var.tags
}

# Custom policy with minimal permissions
data "aws_iam_policy_document" "main" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      
      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "main" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main.json
}
```

### 3. Network Security Patterns
```hcl
# Security Group Module with enterprise patterns
resource "aws_security_group" "main" {
  name_prefix = "${var.name}-"
  description = var.description
  vpc_id      = var.vpc_id

  # Default deny all - explicit allow required
  tags = merge(var.tags, {
    Name = var.name
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rules with detailed logging
resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress_rules)
  
  type              = "ingress"
  security_group_id = aws_security_group.main.id
  
  from_port   = var.ingress_rules[count.index].from_port
  to_port     = var.ingress_rules[count.index].to_port
  protocol    = var.ingress_rules[count.index].protocol
  
  # Prefer security group references over CIDR blocks
  source_security_group_id = lookup(var.ingress_rules[count.index], "source_security_group_id", null)
  cidr_blocks             = lookup(var.ingress_rules[count.index], "cidr_blocks", null)
  
  description = var.ingress_rules[count.index].description
}

# Egress rules - explicit allow only
resource "aws_security_group_rule" "egress" {
  count = length(var.egress_rules)
  
  type              = "egress"
  security_group_id = aws_security_group.main.id
  
  from_port   = var.egress_rules[count.index].from_port
  to_port     = var.egress_rules[count.index].to_port
  protocol    = var.egress_rules[count.index].protocol
  
  cidr_blocks = var.egress_rules[count.index].cidr_blocks
  description = var.egress_rules[count.index].description
}
```

## 🏗️ Enterprise Module Composition Patterns

### 1. Layered Architecture Pattern
```hcl
# Foundation Layer - Core infrastructure
module "foundation" {
  source = "./modules/foundation"
  
  environment = var.environment
  region      = var.aws_region
  
  # Network configuration
  vpc_config = {
    cidr_block         = var.vpc_cidr
    availability_zones = var.availability_zones
    enable_flow_logs   = var.environment == "production"
  }
  
  # Security baseline
  security_config = {
    enable_guardduty     = true
    enable_security_hub  = true
    enable_config        = true
    enable_cloudtrail    = true
  }
  
  tags = local.common_tags
}

# Platform Layer - Shared services
module "platform" {
  source = "./modules/platform"
  
  # Dependencies from foundation
  vpc_id             = module.foundation.vpc_id
  private_subnet_ids = module.foundation.private_subnet_ids
  public_subnet_ids  = module.foundation.public_subnet_ids
  
  # Platform services configuration
  compute_config = {
    enable_ecs_cluster = true
    enable_eks_cluster = var.environment == "production"
    enable_lambda      = true
  }
  
  storage_config = {
    enable_efs = true
    enable_fsx = var.environment == "production"
  }
  
  depends_on = [module.foundation]
  tags       = local.common_tags
}

# Application Layer - Business logic
module "applications" {
  source = "./modules/applications"
  
  # Dependencies from platform
  ecs_cluster_id     = module.platform.ecs_cluster_id
  eks_cluster_name   = module.platform.eks_cluster_name
  lambda_subnet_ids  = module.platform.lambda_subnet_ids
  
  # Application configurations
  applications = var.applications
  
  depends_on = [module.platform]
  tags       = local.common_tags
}
```

### 2. Microservice Module Pattern
```hcl
# Microservice module with complete lifecycle
module "user_service" {
  source = "./modules/microservice"
  
  # Service identification
  service_name = "user-service"
  service_port = 8080
  
  # Container configuration
  container_config = {
    image_uri    = "${var.ecr_repository_url}/user-service:${var.image_tag}"
    cpu          = 256
    memory       = 512
    environment_variables = {
      DATABASE_URL = module.user_database.connection_string
      REDIS_URL    = module.user_cache.endpoint
      LOG_LEVEL    = var.environment == "production" ? "INFO" : "DEBUG"
    }
  }
  
  # Infrastructure dependencies
  vpc_id             = module.foundation.vpc_id
  subnet_ids         = module.foundation.private_subnet_ids
  security_group_ids = [module.microservice_sg.security_group_id]
  
  # Load balancer integration
  load_balancer_config = {
    target_group_arn = module.alb.target_group_arns["user-service"]
    health_check_path = "/health"
  }
  
  # Auto-scaling configuration
  autoscaling_config = {
    min_capacity = var.environment == "production" ? 2 : 1
    max_capacity = var.environment == "production" ? 10 : 3
    target_cpu_utilization = 70
  }
  
  # Monitoring and alerting
  monitoring_config = {
    enable_detailed_monitoring = var.environment == "production"
    log_retention_days        = var.environment == "production" ? 30 : 7
    enable_xray_tracing       = true
  }
  
  tags = local.common_tags
}
```

## 📊 Enterprise Monitoring and Observability

### Comprehensive Monitoring Module
```hcl
# Monitoring module for enterprise observability
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.service_name}-dashboard"

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
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.service_name],
            [".", "MemoryUtilization", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/ecs/${var.service_name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarms for proactive monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.service_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = var.service_name
  }

  tags = var.tags
}

# SNS Topic for alert notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.service_name}-alerts"
  
  tags = var.tags
}

# SNS Topic Subscription for email alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.alert_email_addresses)
  
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}
```

## 🔄 Enterprise CI/CD Integration Patterns

### Module Testing and Validation
```hcl
# Module validation with comprehensive testing
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

# Input validation with enterprise constraints
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "m5.large", "m5.xlarge", "m5.2xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be from approved enterprise list."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# Cost control validation
variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_instance_count <= 50
    error_message = "Maximum instance count cannot exceed 50 for cost control."
  }
}
```

### Module Versioning and Release Strategy
```hcl
# Module source with semantic versioning
module "vpc" {
  source = "git::https://github.com/company/terraform-modules//vpc?ref=v2.1.0"
  
  # Pin to specific version for production
  # Use latest for development: ref=main
  
  name               = var.vpc_name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

# Module registry usage with version constraints
module "database" {
  source  = "company/rds/aws"
  version = "~> 3.2.0"  # Allow patch updates, not minor
  
  engine         = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.medium"
  
  tags = local.common_tags
}
```

## 🎯 Enterprise Module Success Metrics

### Key Performance Indicators (KPIs)
1. **Module Reusability**: > 80% of infrastructure uses shared modules
2. **Deployment Speed**: < 15 minutes for standard environments
3. **Error Rate**: < 2% deployment failures
4. **Security Compliance**: 100% compliance with security baselines
5. **Cost Optimization**: 20% reduction in infrastructure costs
6. **Developer Productivity**: 50% faster infrastructure provisioning

### Module Quality Gates
```hcl
# Quality gates enforced in CI/CD pipeline
# 1. Terraform validation
# 2. Security scanning (tfsec, checkov)
# 3. Cost estimation (infracost)
# 4. Integration testing
# 5. Documentation validation
# 6. Performance benchmarking

# Example: Cost control check
resource "test_assertions" "cost_control" {
  component = "cost_validation"

  check "monthly_cost_limit" {
    assertion = data.infracost_breakdown.main.total_monthly_cost < var.max_monthly_cost
    error_message = "Estimated monthly cost exceeds budget limit"
  }
}
```

This enterprise guide provides the advanced patterns and practices needed for production-ready module development in large organizations.
