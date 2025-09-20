# Problem 33: Final Capstone Project - Complete Enterprise Platform
# Comprehensive enterprise-grade platform combining all learned concepts

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Multi-region providers
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Local values for enterprise platform
locals {
  # Enterprise naming convention
  name_prefix = "${var.organization}-${var.business_unit}-${var.application_name}-${var.environment}"
  
  # Comprehensive tagging strategy
  common_tags = {
    Organization       = var.organization
    BusinessUnit       = var.business_unit
    Application        = var.application_name
    Environment        = var.environment
    CostCenter         = var.cost_center
    Owner              = var.owner
    ManagedBy          = "Terraform"
    Project            = "FinalCapstone"
    Compliance         = var.compliance_level
    DataClassification = var.data_classification
    BackupRequired     = "true"
    MonitoringEnabled  = "true"
    SecurityLevel      = "high"
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
  }
}

# Enterprise VPC with advanced networking
module "enterprise_networking" {
  source = "./modules/enterprise-networking"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.name_prefix}-${each.key}"
  region      = each.value.region
  
  # Advanced VPC configuration
  vpc_cidr = var.vpc_cidrs[each.key]
  
  # Multi-AZ subnet configuration
  availability_zones = var.availability_zones[each.key]
  public_subnets     = var.public_subnets[each.key]
  private_subnets    = var.private_subnets[each.key]
  database_subnets   = var.database_subnets[each.key]
  
  # Enterprise networking features
  enable_nat_gateway     = true
  enable_vpn_gateway     = var.enable_vpn_gateway
  enable_flow_logs       = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # Security features
  enable_network_acls = true
  enable_default_security_group_rules = false
  
  tags = local.common_tags
}

# EKS Cluster for container orchestration
module "eks_cluster" {
  source = "./modules/eks-cluster"
  
  providers = {
    aws = aws.primary
  }
  
  cluster_name = "${local.name_prefix}-eks"
  
  # Cluster configuration
  kubernetes_version = var.kubernetes_version
  vpc_id            = module.enterprise_networking["primary"].vpc_id
  subnet_ids        = module.enterprise_networking["primary"].private_subnets
  
  # Node group configuration
  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size      = 2
      max_size      = 5
      desired_size  = 3
      capacity_type = "ON_DEMAND"
      
      labels = {
        role = "system"
      }
      
      taints = [
        {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    
    application = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size      = 3
      max_size      = 20
      desired_size  = 5
      capacity_type = "SPOT"
      
      labels = {
        role = "application"
      }
    }
  }
  
  # Advanced cluster features
  enable_irsa                    = true
  enable_cluster_autoscaler      = true
  enable_aws_load_balancer_controller = true
  enable_external_dns            = true
  enable_cert_manager            = true
  
  # Security configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  
  # Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  tags = local.common_tags
}

# Configure Kubernetes and Helm providers
data "aws_eks_cluster" "main" {
  provider = aws.primary
  name     = module.eks_cluster.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  provider = aws.primary
  name     = module.eks_cluster.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# Service Mesh with Istio
module "service_mesh" {
  source = "./modules/service-mesh"
  
  cluster_name = module.eks_cluster.cluster_name
  
  # Istio configuration
  istio_version = var.istio_version
  
  # Service mesh features
  enable_istio_ingress_gateway = true
  enable_istio_egress_gateway  = true
  enable_kiali                 = true
  enable_jaeger               = true
  enable_prometheus           = true
  enable_grafana              = true
  
  # Security policies
  enable_mtls = true
  enable_authorization_policies = true
  
  tags = local.common_tags
  
  depends_on = [module.eks_cluster]
}

# Comprehensive monitoring and observability
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name = module.eks_cluster.cluster_name
  
  # Monitoring stack
  enable_prometheus_operator = true
  enable_grafana             = true
  enable_alertmanager        = true
  enable_node_exporter       = true
  enable_kube_state_metrics  = true
  
  # Logging stack
  enable_fluentd    = true
  enable_elasticsearch = true
  enable_kibana     = true
  
  # Distributed tracing
  enable_jaeger = true
  
  # Custom dashboards
  grafana_dashboards = var.grafana_dashboards
  
  # Alert rules
  prometheus_rules = var.prometheus_rules
  
  # Notification channels
  alertmanager_config = var.alertmanager_config
  
  tags = local.common_tags
  
  depends_on = [module.eks_cluster]
}

# Database infrastructure with high availability
module "database" {
  source = "./modules/database"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.name_prefix}-${each.key}"
  
  # Database configuration
  vpc_id     = module.enterprise_networking[each.key].vpc_id
  subnet_ids = module.enterprise_networking[each.key].database_subnets
  
  # Primary database configuration
  databases = {
    primary = {
      engine               = var.database_config.engine
      engine_version       = var.database_config.engine_version
      instance_class       = var.database_config.instance_class
      allocated_storage    = var.database_config.allocated_storage
      max_allocated_storage = var.database_config.max_allocated_storage
      
      # High availability
      multi_az                = each.key == "primary"
      backup_retention_period = var.database_config.backup_retention_period
      backup_window          = var.database_config.backup_window
      maintenance_window     = var.database_config.maintenance_window
      
      # Security
      storage_encrypted = true
      kms_key_id       = module.security[each.key].kms_key_arn
      
      # Monitoring
      monitoring_interval = 60
      performance_insights_enabled = true
      
      # Read replicas
      read_replicas = each.key == "primary" ? var.database_config.read_replicas : {}
    }
  }
  
  tags = local.common_tags
}

# Comprehensive security implementation
module "security" {
  source = "./modules/security"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.name_prefix}-${each.key}"
  
  # KMS configuration
  create_kms_key = true
  kms_key_description = "Enterprise KMS key for ${local.name_prefix} in ${each.value.region}"
  
  # Secrets management
  secrets = var.secrets_config
  
  # Security services
  enable_guardduty    = true
  enable_security_hub = true
  enable_config       = true
  enable_cloudtrail   = true
  enable_inspector    = true
  
  # WAF configuration
  enable_waf = each.key == "primary"
  waf_rules  = var.waf_rules
  
  # Network security
  security_group_rules = var.security_group_rules
  
  tags = local.common_tags
}

# CI/CD pipeline integration
module "cicd" {
  source = "./modules/cicd"
  
  providers = {
    aws = aws.primary
  }
  
  name_prefix = local.name_prefix
  
  # Repository configuration
  repository_name = "${local.name_prefix}-repo"
  
  # Pipeline configuration
  pipeline_stages = [
    {
      name = "Source"
      actions = [
        {
          name     = "SourceAction"
          category = "Source"
          provider = "CodeCommit"
          configuration = {
            RepositoryName = "${local.name_prefix}-repo"
            BranchName     = var.source_branch
          }
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name     = "BuildAction"
          category = "Build"
          provider = "CodeBuild"
          configuration = {
            ProjectName = "${local.name_prefix}-build"
          }
        }
      ]
    },
    {
      name = "Deploy"
      actions = [
        {
          name     = "DeployAction"
          category = "Deploy"
          provider = "EKS"
          configuration = {
            ClusterName = module.eks_cluster.cluster_name
            ServiceName = "application"
          }
        }
      ]
    }
  ]
  
  # Build configuration
  build_projects = {
    build = {
      environment = {
        compute_type = "BUILD_GENERAL1_MEDIUM"
        image       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
        type        = "LINUX_CONTAINER"
      }
      
      source = {
        type      = "CODEPIPELINE"
        buildspec = "buildspec.yml"
      }
    }
  }
  
  tags = local.common_tags
}

# Backup and disaster recovery
module "backup" {
  source = "./modules/backup"
  
  for_each = local.regions
  
  providers = {
    aws = each.value.provider
  }
  
  name_prefix = "${local.name_prefix}-${each.key}"
  
  # Backup vault configuration
  backup_vault_name = "${local.name_prefix}-${each.key}-vault"
  kms_key_arn      = module.security[each.key].kms_key_arn
  
  # Backup plans
  backup_plans = var.backup_plans
  
  # Resources to backup
  backup_resources = {
    rds_instances = [for db in module.database[each.key].database_arns : db]
    ebs_volumes   = module.eks_cluster.ebs_volume_arns
  }
  
  # Cross-region backup
  enable_cross_region_backup = each.key == "primary"
  destination_region        = each.key == "primary" ? var.secondary_region : var.primary_region
  
  tags = local.common_tags
}

# Cost management and optimization
module "cost_management" {
  source = "./modules/cost-management"
  
  providers = {
    aws = aws.primary
  }
  
  name_prefix = local.name_prefix
  
  # Budget configuration
  budgets = var.budgets
  
  # Cost allocation tags
  cost_allocation_tags = keys(local.common_tags)
  
  # Cost anomaly detection
  enable_cost_anomaly_detection = true
  cost_anomaly_threshold       = var.cost_anomaly_threshold
  
  # Savings plans and reserved instances
  enable_savings_plans_recommendations = true
  enable_ri_recommendations           = true
  
  tags = local.common_tags
}

# Application deployment
module "applications" {
  source = "./modules/applications"
  
  cluster_name = module.eks_cluster.cluster_name
  
  # Application configurations
  applications = {
    frontend = {
      namespace = "frontend"
      image     = var.application_images.frontend
      replicas  = var.application_replicas.frontend
      
      service = {
        type = "ClusterIP"
        port = 80
      }
      
      ingress = {
        enabled = true
        host    = var.frontend_domain
        paths   = ["/"]
      }
      
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }
    
    backend = {
      namespace = "backend"
      image     = var.application_images.backend
      replicas  = var.application_replicas.backend
      
      service = {
        type = "ClusterIP"
        port = 8080
      }
      
      ingress = {
        enabled = true
        host    = var.backend_domain
        paths   = ["/api"]
      }
      
      resources = {
        requests = {
          cpu    = "200m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }
      
      # Database connection
      env = [
        {
          name  = "DATABASE_URL"
          value = module.database["primary"].database_endpoints["primary"]
        }
      ]
      
      # Secrets
      env_from = [
        {
          secret_ref = {
            name = "database-credentials"
          }
        }
      ]
    }
  }
  
  # Horizontal Pod Autoscaler
  hpa_configs = {
    frontend = {
      min_replicas = 3
      max_replicas = 20
      target_cpu_utilization = 70
    }
    
    backend = {
      min_replicas = 5
      max_replicas = 50
      target_cpu_utilization = 70
      target_memory_utilization = 80
    }
  }
  
  tags = local.common_tags
  
  depends_on = [
    module.eks_cluster,
    module.service_mesh,
    module.monitoring
  ]
}

# DNS and SSL certificate management
module "dns" {
  source = "./modules/dns"
  
  providers = {
    aws = aws.primary
  }
  
  domain_name = var.domain_name
  
  # Hosted zone configuration
  create_hosted_zone = var.create_hosted_zone
  
  # DNS records
  records = {
    frontend = {
      name = var.frontend_subdomain
      type = "A"
      alias = {
        name                   = module.applications.ingress_dns_names["frontend"]
        zone_id               = module.applications.ingress_zone_ids["frontend"]
        evaluate_target_health = true
      }
    }
    
    backend = {
      name = var.backend_subdomain
      type = "A"
      alias = {
        name                   = module.applications.ingress_dns_names["backend"]
        zone_id               = module.applications.ingress_zone_ids["backend"]
        evaluate_target_health = true
      }
    }
  }
  
  # SSL certificates
  certificates = {
    main = {
      domain_name = var.domain_name
      subject_alternative_names = [
        "*.${var.domain_name}"
      ]
    }
  }
  
  # Health checks
  health_checks = var.health_checks
  
  tags = local.common_tags
}

# Compliance and governance
module "compliance" {
  source = "./modules/compliance"
  
  providers = {
    aws = aws.primary
  }
  
  name_prefix = local.name_prefix
  
  # Compliance framework
  compliance_framework = var.compliance_framework
  
  # Config rules
  config_rules = var.config_rules
  
  # Security standards
  security_standards = var.security_standards
  
  # Audit configuration
  enable_audit_logging = true
  audit_log_retention = 2555  # 7 years
  
  # Compliance reporting
  enable_compliance_reporting = true
  compliance_report_frequency = "DAILY"
  
  tags = local.common_tags
}
