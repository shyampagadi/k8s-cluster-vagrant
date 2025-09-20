# Enterprise Terraform Patterns - Comprehensive Guide

## Overview
This guide covers enterprise-grade Terraform patterns including large-scale infrastructure management, organizational patterns, governance frameworks, and production-ready architectures.

## Enterprise Architecture Patterns

### Multi-Environment Architecture
```hcl
# Enterprise multi-environment structure
locals {
  environments = {
    development = {
      instance_count = 1
      instance_type  = "t3.micro"
      enable_monitoring = false
      backup_retention = 1
      vpc_cidr = "10.0.0.0/16"
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      enable_monitoring = true
      backup_retention = 7
      vpc_cidr = "10.1.0.0/16"
    }
    production = {
      instance_count = 5
      instance_type  = "t3.medium"
      enable_monitoring = true
      backup_retention = 30
      vpc_cidr = "10.2.0.0/16"
    }
  }
  
  # Environment-specific configurations
  current_environment = local.environments[var.environment]
}

# Environment-specific VPC
resource "aws_vpc" "environment" {
  cidr_block           = local.current_environment.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.team_name
    CostCenter  = var.cost_center
  }
}
```

### Organizational Structure
```hcl
# Enterprise organizational structure
locals {
  # Organizational hierarchy
  organization = {
    company_name = "Acme Corp"
    business_unit = "Engineering"
    department    = "Platform Engineering"
    team          = "DevOps"
  }
  
  # Compliance and governance
  compliance_tags = {
    DataClassification = "Confidential"
    ComplianceFramework = "SOC2"
    BackupRequired     = "true"
    EncryptionRequired  = "true"
    MonitoringRequired  = "true"
    AuditRequired      = "true"
  }
  
  # Cost allocation
  cost_allocation_tags = {
    CostCenter    = var.cost_center
    Project       = var.project_name
    Environment   = var.environment
    BusinessUnit  = local.organization.business_unit
    Department    = local.organization.department
    Team          = local.organization.team
  }
  
  # Security tags
  security_tags = {
    SecurityLevel    = var.environment == "production" ? "high" : "medium"
    DataSensitivity = "confidential"
    AccessLevel     = "restricted"
    EncryptionKey   = aws_kms_key.main.arn
  }
  
  # Combine all tags
  common_tags = merge(
    local.compliance_tags,
    local.cost_allocation_tags,
    local.security_tags,
    {
      ManagedBy    = "terraform"
      TerraformVersion = "1.5.0"
      LastModified = timestamp()
    }
  )
}
```

## Large-Scale Infrastructure Patterns

### Modular Infrastructure Architecture
```hcl
# Core infrastructure modules
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr           = local.current_environment.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  
  tags = local.common_tags
}

module "security" {
  source = "./modules/security"
  
  vpc_id = module.networking.vpc_id
  environment = var.environment
  
  tags = local.common_tags
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id              = module.networking.vpc_id
  subnet_ids          = module.networking.private_subnet_ids
  security_group_ids  = module.security.security_group_ids
  instance_count      = local.current_environment.instance_count
  instance_type       = local.current_environment.instance_type
  
  tags = local.common_tags
}

module "storage" {
  source = "./modules/storage"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  environment = var.environment
  
  tags = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"
  
  vpc_id              = module.networking.vpc_id
  instance_ids        = module.compute.instance_ids
  database_endpoint   = module.storage.database_endpoint
  environment         = var.environment
  
  tags = local.common_tags
}
```

### Multi-Region Architecture
```hcl
# Multi-region configuration
locals {
  regions = ["us-west-2", "us-east-1", "eu-west-1"]
  
  # Region-specific configurations
  region_configs = {
    us-west-2 = {
      primary = true
      instance_count = 3
      database_multi_az = true
    }
    us-east-1 = {
      primary = false
      instance_count = 2
      database_multi_az = false
    }
    eu-west-1 = {
      primary = false
      instance_count = 2
      database_multi_az = false
    }
  }
}

# Create resources in multiple regions
resource "aws_vpc" "multi_region" {
  for_each = local.region_configs
  
  provider = aws.regional[each.key]
  
  cidr_block           = "10.${index(local.regions, each.key)}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name     = "${each.key}-vpc"
    Region   = each.key
    Primary  = each.value.primary
  })
}
```

## Governance and Compliance Patterns

### Policy as Code
```hcl
# Sentinel policies for governance
# sentinel/policies/require-tags.sentinel
import "tfplan"

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.actions is not ["delete"] implies
    all rc.change.after as _, resource {
      resource.tags is not null and
      "Environment" in resource.tags and
      "Project" in resource.tags and
      "Owner" in resource.tags
    }
  }
}

# Sentinel policies for cost control
# sentinel/policies/cost-control.sentinel
import "tfplan"

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is "aws_instance" implies
    rc.change.after.instance_type in ["t3.micro", "t3.small", "t3.medium"]
  }
}
```

### Compliance Monitoring
```hcl
# Compliance monitoring configuration
resource "aws_config_configuration_recorder" "compliance" {
  name     = "compliance-recorder"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_rule" "required_tags" {
  name = "required-tags"
  
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  
  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = "production"
    tag2Key   = "Project"
    tag2Value = "platform"
  })
  
  depends_on = [aws_config_configuration_recorder.compliance]
}
```

## Security Patterns

### Zero Trust Architecture
```hcl
# Zero trust security implementation
resource "aws_security_group" "zero_trust" {
  name_prefix = "${var.project_name}-zero-trust-"
  vpc_id      = aws_vpc.main.id
  
  # No default ingress rules
  ingress = []
  
  # Restrictive egress rules
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-zero-trust-sg"
    SecurityLevel = "high"
  })
}

# Network segmentation
resource "aws_security_group" "web_tier" {
  name_prefix = "${var.project_name}-web-tier-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }
  
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
    description     = "HTTP to app tier"
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-tier-sg"
    Tier = "web"
  })
}

resource "aws_security_group" "app_tier" {
  name_prefix = "${var.project_name}-app-tier-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
    description     = "HTTP from web tier"
  }
  
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.database_tier.id]
    description     = "MySQL to database tier"
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-tier-sg"
    Tier = "application"
  })
}

resource "aws_security_group" "database_tier" {
  name_prefix = "${var.project_name}-database-tier-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
    description     = "MySQL from app tier"
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-database-tier-sg"
    Tier = "database"
  })
}
```

## Monitoring and Observability

### Comprehensive Monitoring
```hcl
# CloudWatch monitoring configuration
resource "aws_cloudwatch_dashboard" "enterprise" {
  dashboard_name = "${var.project_name}-enterprise-dashboard"
  
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
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Instance Metrics"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          query   = "SOURCE '/aws/ec2/${var.project_name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Application Logs"
        }
      }
    ]
  })
}

# Custom metrics
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = local.common_tags
}
```

## Disaster Recovery Patterns

### Multi-Region Backup
```hcl
# Cross-region backup configuration
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-backup-${random_id.bucket_suffix.hex}"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-backup"
    Purpose = "disaster-recovery"
  })
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  role   = aws_iam_role.replication.arn
  
  rule {
    id     = "replicate-to-secondary-region"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.backup_secondary.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# Cross-region snapshot replication
resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-primary-db"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Enable cross-region backup
  replicate_source_db = aws_db_instance.primary.id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-primary-db"
    Role = "primary"
  })
}
```

## Cost Optimization Patterns

### Resource Optimization
```hcl
# Auto Scaling for cost optimization
resource "aws_autoscaling_group" "cost_optimized" {
  name                = "${var.project_name}-cost-optimized-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  health_check_type   = "EC2"
  
  min_size         = 1
  max_size         = 10
  desired_capacity = 2
  
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cost_optimized.id
        version           = "$Latest"
      }
      
      override {
        instance_type = "t3.small"
      }
      
      override {
        instance_type = "t3.medium"
      }
    }
    
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "diversified"
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-cost-optimized-instance"
    propagate_at_launch = true
  }
}

# Cost monitoring
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "1000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = ["Project:${var.project_name}"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

## Automation and CI/CD Patterns

### Infrastructure as Code Pipeline
```hcl
# GitHub Actions workflow for Terraform
# .github/workflows/terraform.yml
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id
  
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
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_state_lock.arn
      }
    ]
  })
}
```

## Best Practices

### Enterprise Best Practices
- **Governance**: Implement comprehensive governance frameworks
- **Security**: Follow zero-trust security principles
- **Compliance**: Ensure regulatory compliance
- **Monitoring**: Implement comprehensive monitoring
- **Documentation**: Maintain detailed documentation

### Operational Best Practices
- **Automation**: Automate all operational processes
- **Testing**: Implement comprehensive testing strategies
- **Backup**: Implement robust backup and recovery
- **Cost Management**: Optimize costs continuously
- **Team Collaboration**: Enable effective team collaboration

## Conclusion

Enterprise Terraform patterns enable the management of large-scale, complex infrastructure with proper governance, security, and compliance. By implementing these patterns, organizations can achieve enterprise-grade infrastructure management capabilities.

Regular review and updates of enterprise patterns ensure continued effectiveness and adaptation to evolving business requirements and technology landscapes.
