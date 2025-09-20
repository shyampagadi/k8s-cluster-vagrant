# Problem 31: Disaster Recovery and Business Continuity
# Comprehensive DR patterns and multi-region failover

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Multi-region providers
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Local values for DR configuration
locals {
  regions = {
    primary = {
      provider = "aws.primary"
      region   = var.primary_region
      priority = 1
    }
    dr = {
      provider = "aws.dr"
      region   = var.dr_region
      priority = 2
    }
  }
  
  common_tags = {
    Project    = var.project_name
    ManagedBy  = "Terraform"
    DR_Enabled = "true"
  }
}

# VPC in both regions
resource "aws_vpc" "main" {
  for_each = local.regions
  
  provider = each.value.provider
  
  cidr_block           = var.vpc_cidrs[each.key]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name   = "${var.project_name}-${each.key}-vpc"
    Region = each.value.region
  })
}

# Subnets in both regions
resource "aws_subnet" "private" {
  for_each = {
    for combo in flatten([
      for region_key, region_config in local.regions : [
        for i in range(2) : {
          key      = "${region_key}-private-${i}"
          region   = region_key
          provider = region_config.provider
          cidr     = cidrsubnet(var.vpc_cidrs[region_key], 8, i + 10)
          az_index = i
        }
      ]
    ]) : combo.key => combo
  }
  
  provider = each.value.provider
  
  vpc_id            = aws_vpc.main[each.value.region].id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available[each.value.region].names[each.value.az_index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}"
    Type = "Private"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for combo in flatten([
      for region_key, region_config in local.regions : [
        for i in range(2) : {
          key      = "${region_key}-public-${i}"
          region   = region_key
          provider = region_config.provider
          cidr     = cidrsubnet(var.vpc_cidrs[region_key], 8, i)
          az_index = i
        }
      ]
    ]) : combo.key => combo
  }
  
  provider = each.value.provider
  
  vpc_id                  = aws_vpc.main[each.value.region].id
  cidr_block              = each.value.cidr
  availability_zone       = data.aws_availability_zones.available[each.value.region].names[each.value.az_index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}"
    Type = "Public"
  })
}

data "aws_availability_zones" "available" {
  for_each = local.regions
  provider = each.value.provider
  state    = "available"
}

# RDS with cross-region automated backups
resource "aws_db_instance" "primary" {
  provider = aws.primary
  
  identifier = "${var.project_name}-primary-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.database["primary"].id]
  db_subnet_group_name   = aws_db_subnet_group.main["primary"].name

  # DR configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Enable automated backups for cross-region replication
  copy_tags_to_snapshot = true
  skip_final_snapshot   = false
  final_snapshot_identifier = "${var.project_name}-primary-final-snapshot"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-primary-db"
    Role = "Primary"
  })
}

# Read replica in DR region
resource "aws_db_instance" "dr_replica" {
  provider = aws.dr
  
  identifier = "${var.project_name}-dr-replica"

  # Replica configuration
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_instance_class
  
  # Can be promoted to standalone
  auto_minor_version_upgrade = false
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dr-replica"
    Role = "DR_Replica"
  })
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# DB subnet groups
resource "aws_db_subnet_group" "main" {
  for_each = local.regions
  provider = each.value.provider
  
  name       = "${var.project_name}-${each.key}-db-subnet-group"
  subnet_ids = [
    for k, v in aws_subnet.private : v.id 
    if startswith(k, each.key)
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-db-subnet-group"
  })
}

# Security groups
resource "aws_security_group" "database" {
  for_each = local.regions
  provider = each.value.provider
  
  name        = "${var.project_name}-${each.key}-db-sg"
  description = "Security group for database in ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-db-sg"
  })
}

# S3 bucket with cross-region replication
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-primary-bucket"
    Role = "Primary"
  })
}

resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = "${var.project_name}-dr-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dr-bucket"
    Role = "DR"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket replication
resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  provider   = aws.primary
  depends_on = [aws_s3_bucket_versioning.primary]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate_to_dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-s3-replication-policy"
  role     = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.dr.arn}/*"
      }
    ]
  })
}

# Route53 health checks and failover
resource "aws_route53_zone" "main" {
  count = var.domain_name != null ? 1 : 0
  name  = var.domain_name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-zone"
  })
}

resource "aws_route53_health_check" "primary" {
  count = var.domain_name != null ? 1 : 0
  
  fqdn                            = "primary.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_alarm_region         = var.primary_region
  cloudwatch_alarm_name           = "${var.project_name}-primary-health"
  insufficient_data_health_status = "Failure"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-primary-health-check"
  })
}

resource "aws_route53_record" "primary" {
  count = var.domain_name != null ? 1 : 0
  
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary[0].id
  records         = [aws_eip.primary.public_ip]
}

resource "aws_route53_record" "dr" {
  count = var.domain_name != null ? 1 : 0
  
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  set_identifier = "dr"
  
  failover_routing_policy {
    type = "SECONDARY"
  }

  records = [aws_eip.dr.public_ip]
}

# Elastic IPs for consistent endpoints
resource "aws_eip" "primary" {
  provider = aws.primary
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-primary-eip"
    Role = "Primary"
  })
}

resource "aws_eip" "dr" {
  provider = aws.dr
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dr-eip"
    Role = "DR"
  })
}

# AWS Backup for comprehensive backup strategy
resource "aws_backup_vault" "main" {
  for_each = local.regions
  provider = each.value.provider
  
  name        = "${var.project_name}-${each.key}-backup-vault"
  kms_key_arn = aws_kms_key.backup[each.key].arn

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-backup-vault"
  })
}

resource "aws_kms_key" "backup" {
  for_each = local.regions
  provider = each.value.provider
  
  description             = "KMS key for backup vault in ${each.key}"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-backup-key"
  })
}

resource "aws_backup_plan" "main" {
  for_each = local.regions
  provider = each.value.provider
  
  name = "${var.project_name}-${each.key}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[each.key].name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    copy_action {
      destination_vault_arn = each.key == "primary" ? aws_backup_vault.main["dr"].arn : aws_backup_vault.main["primary"].arn
      
      lifecycle {
        cold_storage_after = 30
        delete_after       = 120
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-backup-plan"
  })
}

# CloudWatch alarms for DR monitoring
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  provider = aws.primary
  
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-cpu-alarm"
  })
}

# SNS topics for DR notifications
resource "aws_sns_topic" "dr_notifications" {
  for_each = local.regions
  provider = each.value.provider
  
  name = "${var.project_name}-${each.key}-dr-notifications"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-dr-notifications"
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.notification_email != null ? local.regions : {}
  provider = each.value.provider
  
  topic_arn = aws_sns_topic.dr_notifications[each.key].arn
  protocol  = "email"
  endpoint  = var.notification_email
}
