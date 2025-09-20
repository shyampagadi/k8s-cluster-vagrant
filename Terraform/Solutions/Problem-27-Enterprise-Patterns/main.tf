# Problem 27: Enterprise Patterns and Multi-Cloud Deployment
# Comprehensive enterprise-grade patterns and governance

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Multi-region provider configuration
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Data sources for enterprise governance
data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}

# Local values for enterprise patterns
locals {
  # Enterprise naming convention
  naming_convention = {
    prefix = "${var.organization}-${var.business_unit}-${var.application_name}"
    suffix = "${var.environment}-${var.region_code}"
  }
  
  # Compliance and governance tags
  mandatory_tags = {
    Organization     = var.organization
    BusinessUnit     = var.business_unit
    Application      = var.application_name
    Environment      = var.environment
    CostCenter       = var.cost_center
    Owner            = var.owner
    Compliance       = var.compliance_level
    DataClassification = var.data_classification
    BackupRequired   = var.backup_required
    ManagedBy        = "Terraform"
    CreatedDate      = timestamp()
  }
  
  # Multi-region configuration
  regions = {
    primary = {
      provider = "aws.primary"
      region   = var.primary_region
      priority = 1
    }
    secondary = {
      provider = "aws.secondary"
      region   = var.secondary_region
      priority = 2
    }
    dr = {
      provider = "aws.dr"
      region   = var.dr_region
      priority = 3
    }
  }
  
  # Enterprise security policies
  security_policies = {
    encryption_at_rest  = true
    encryption_in_transit = true
    mfa_required       = var.environment == "production"
    vpc_flow_logs      = true
    cloudtrail_enabled = true
    config_enabled     = true
  }
}

# Enterprise VPC with advanced networking
module "enterprise_vpc" {
  source = "./modules/enterprise-vpc"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  region      = each.value.region
  
  # Enterprise CIDR allocation
  vpc_cidr = var.vpc_cidrs[each.key]
  
  # Advanced networking features
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = true
  enable_vpn_gateway     = var.enable_vpn_gateway
  enable_flow_logs       = local.security_policies.vpc_flow_logs
  enable_network_acls    = true
  
  # Multi-AZ configuration
  availability_zones = var.availability_zones[each.key]
  
  # Subnet configuration
  public_subnets   = var.public_subnets[each.key]
  private_subnets  = var.private_subnets[each.key]
  database_subnets = var.database_subnets[each.key]
  
  # Enterprise security
  enable_default_security_group_rules = false
  
  tags = merge(local.mandatory_tags, {
    Region   = each.value.region
    Priority = each.value.priority
  })
}

# Enterprise security groups with standardized rules
module "enterprise_security_groups" {
  source = "./modules/enterprise-security-groups"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  vpc_id      = module.enterprise_vpc[each.key].vpc_id
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Standardized security group templates
  security_group_templates = {
    web_tier = {
      description = "Web tier security group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from internet"
        }
      ]
    }
    
    app_tier = {
      description = "Application tier security group"
      ingress_rules = [
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = "web_tier"
          description              = "App port from web tier"
        }
      ]
    }
    
    data_tier = {
      description = "Data tier security group"
      ingress_rules = [
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = "app_tier"
          description              = "MySQL from app tier"
        }
      ]
    }
  }
  
  tags = local.mandatory_tags
}

# Enterprise compute with standardized configurations
module "enterprise_compute" {
  source = "./modules/enterprise-compute"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Compute configuration
  vpc_id     = module.enterprise_vpc[each.key].vpc_id
  subnet_ids = module.enterprise_vpc[each.key].private_subnets
  
  # Enterprise instance configuration
  instance_configurations = {
    web = {
      instance_type          = var.instance_types.web
      min_size              = var.scaling_config.web.min_size
      max_size              = var.scaling_config.web.max_size
      desired_capacity      = var.scaling_config.web.desired_capacity
      security_group_ids    = [module.enterprise_security_groups[each.key].security_group_ids["web_tier"]]
      user_data_template    = "web_tier_user_data.sh"
      enable_detailed_monitoring = var.environment == "production"
    }
    
    app = {
      instance_type          = var.instance_types.app
      min_size              = var.scaling_config.app.min_size
      max_size              = var.scaling_config.app.max_size
      desired_capacity      = var.scaling_config.app.desired_capacity
      security_group_ids    = [module.enterprise_security_groups[each.key].security_group_ids["app_tier"]]
      user_data_template    = "app_tier_user_data.sh"
      enable_detailed_monitoring = var.environment == "production"
    }
  }
  
  # Enterprise AMI selection
  ami_filters = var.enterprise_ami_filters
  
  # Compliance requirements
  enable_encryption = local.security_policies.encryption_at_rest
  kms_key_id       = module.enterprise_kms[each.key].key_id
  
  # Instance metadata service configuration
  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }
  
  tags = local.mandatory_tags
}

# Enterprise load balancing with advanced features
module "enterprise_load_balancer" {
  source = "./modules/enterprise-load-balancer"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Load balancer configuration
  vpc_id     = module.enterprise_vpc[each.key].vpc_id
  subnet_ids = module.enterprise_vpc[each.key].public_subnets
  
  # Security configuration
  security_group_ids = [module.enterprise_security_groups[each.key].security_group_ids["web_tier"]]
  
  # SSL/TLS configuration
  certificate_arn = module.enterprise_acm[each.key].certificate_arn
  ssl_policy     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  
  # Advanced features
  enable_deletion_protection = var.environment == "production"
  enable_cross_zone_load_balancing = true
  enable_http2 = true
  
  # Access logging
  access_logs = {
    bucket  = module.enterprise_logging[each.key].access_logs_bucket
    prefix  = "alb-access-logs"
    enabled = true
  }
  
  # Target groups
  target_groups = {
    web = {
      port                = 80
      protocol            = "HTTP"
      health_check_path   = "/health"
      health_check_matcher = "200"
      targets             = module.enterprise_compute[each.key].instance_ids["web"]
    }
    
    app = {
      port                = 8080
      protocol            = "HTTP"
      health_check_path   = "/api/health"
      health_check_matcher = "200"
      targets             = module.enterprise_compute[each.key].instance_ids["app"]
    }
  }
  
  tags = local.mandatory_tags
}

# Enterprise database with high availability
module "enterprise_database" {
  source = "./modules/enterprise-database"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Database configuration
  vpc_id     = module.enterprise_vpc[each.key].vpc_id
  subnet_ids = module.enterprise_vpc[each.key].database_subnets
  
  # Engine configuration
  engine               = var.database_config.engine
  engine_version       = var.database_config.engine_version
  instance_class       = var.database_config.instance_class
  allocated_storage    = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.max_allocated_storage
  
  # High availability
  multi_az                = var.environment == "production"
  backup_retention_period = var.database_config.backup_retention_period
  backup_window          = var.database_config.backup_window
  maintenance_window     = var.database_config.maintenance_window
  
  # Security
  storage_encrypted    = local.security_policies.encryption_at_rest
  kms_key_id          = module.enterprise_kms[each.key].key_id
  security_group_ids  = [module.enterprise_security_groups[each.key].security_group_ids["data_tier"]]
  
  # Monitoring
  monitoring_interval = var.environment == "production" ? 60 : 0
  performance_insights_enabled = var.environment == "production"
  
  # Read replicas for production
  read_replicas = var.environment == "production" ? var.database_config.read_replicas : {}
  
  tags = local.mandatory_tags
}

# Enterprise KMS for encryption
module "enterprise_kms" {
  source = "./modules/enterprise-kms"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Key configuration
  key_description = "Enterprise KMS key for ${local.naming_convention.prefix} in ${each.value.region}"
  key_usage      = "ENCRYPT_DECRYPT"
  
  # Key policy
  key_administrators = var.kms_key_administrators
  key_users         = var.kms_key_users
  
  # Compliance
  enable_key_rotation = true
  deletion_window    = var.environment == "production" ? 30 : 7
  
  tags = local.mandatory_tags
}

# Enterprise ACM for SSL certificates
module "enterprise_acm" {
  source = "./modules/enterprise-acm"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  domain_name = var.domain_name
  
  # Subject Alternative Names
  subject_alternative_names = var.subject_alternative_names
  
  # Validation
  validation_method = "DNS"
  
  # Certificate transparency logging
  certificate_transparency_logging_preference = "ENABLED"
  
  tags = local.mandatory_tags
}

# Enterprise monitoring and observability
module "enterprise_monitoring" {
  source = "./modules/enterprise-monitoring"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # CloudWatch configuration
  create_dashboards = true
  dashboard_body = templatefile("${path.module}/templates/enterprise_dashboard.json", {
    region      = each.value.region
    name_prefix = "${local.naming_convention.prefix}-${each.key}"
  })
  
  # Alarms configuration
  alarm_configurations = var.alarm_configurations
  
  # SNS topics for notifications
  notification_endpoints = var.notification_endpoints
  
  # Log groups
  log_groups = {
    application = {
      name              = "/aws/ec2/${local.naming_convention.prefix}-${each.key}"
      retention_in_days = var.log_retention_days
      kms_key_id       = module.enterprise_kms[each.key].key_arn
    }
    
    load_balancer = {
      name              = "/aws/elasticloadbalancing/${local.naming_convention.prefix}-${each.key}"
      retention_in_days = var.log_retention_days
      kms_key_id       = module.enterprise_kms[each.key].key_arn
    }
  }
  
  tags = local.mandatory_tags
}

# Enterprise logging and audit
module "enterprise_logging" {
  source = "./modules/enterprise-logging"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # S3 bucket for logs
  create_access_logs_bucket = true
  access_logs_bucket_name   = "${local.naming_convention.prefix}-${each.key}-access-logs"
  
  # CloudTrail configuration
  enable_cloudtrail = local.security_policies.cloudtrail_enabled
  cloudtrail_config = {
    include_global_service_events = true
    is_multi_region_trail        = false
    enable_logging               = true
    kms_key_id                  = module.enterprise_kms[each.key].key_arn
    
    event_selector = [
      {
        read_write_type                 = "All"
        include_management_events       = true
        exclude_management_event_sources = []
        
        data_resource = [
          {
            type   = "AWS::S3::Object"
            values = ["arn:aws:s3:::${local.naming_convention.prefix}-${each.key}-*/*"]
          }
        ]
      }
    ]
  }
  
  # VPC Flow Logs
  enable_vpc_flow_logs = local.security_policies.vpc_flow_logs
  vpc_id              = module.enterprise_vpc[each.key].vpc_id
  
  # Config service
  enable_config = local.security_policies.config_enabled
  config_rules = var.config_rules
  
  tags = local.mandatory_tags
}

# Enterprise backup and disaster recovery
module "enterprise_backup" {
  source = "./modules/enterprise-backup"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.naming_convention.prefix}-${each.key}"
  
  # Backup vault configuration
  backup_vault_name = "${local.naming_convention.prefix}-${each.key}-backup-vault"
  kms_key_arn      = module.enterprise_kms[each.key].key_arn
  
  # Backup plans
  backup_plans = var.backup_plans
  
  # Resources to backup
  backup_resources = {
    ec2_instances = module.enterprise_compute[each.key].instance_arns
    rds_instances = [module.enterprise_database[each.key].db_instance_arn]
    ebs_volumes   = module.enterprise_compute[each.key].ebs_volume_arns
  }
  
  # Cross-region backup for production
  enable_cross_region_backup = var.environment == "production"
  destination_region        = each.key == "primary" ? var.secondary_region : var.primary_region
  
  tags = local.mandatory_tags
}

# Enterprise IAM roles and policies
module "enterprise_iam" {
  source = "./modules/enterprise-iam"
  
  name_prefix = local.naming_convention.prefix
  
  # Service roles
  service_roles = {
    ec2_role = {
      assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
      managed_policies = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      inline_policies = {
        s3_access = data.aws_iam_policy_document.s3_access.json
        kms_access = data.aws_iam_policy_document.kms_access.json
      }
    }
  }
  
  # Cross-account roles for enterprise governance
  cross_account_roles = var.cross_account_roles
  
  tags = local.mandatory_tags
}

# IAM policy documents
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    
    resources = [
      "arn:aws:s3:::${local.naming_convention.prefix}-*/*"
    ]
  }
}

data "aws_iam_policy_document" "kms_access" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    
    resources = [
      for region_key, region_config in local.regions :
      module.enterprise_kms[region_key].key_arn
    ]
  }
}

# Enterprise cost management
module "enterprise_cost_management" {
  source = "./modules/enterprise-cost-management"
  
  name_prefix = local.naming_convention.prefix
  
  # Budget configuration
  budgets = var.budgets
  
  # Cost allocation tags
  cost_allocation_tags = keys(local.mandatory_tags)
  
  # Cost anomaly detection
  enable_cost_anomaly_detection = var.environment == "production"
  
  tags = local.mandatory_tags
}
