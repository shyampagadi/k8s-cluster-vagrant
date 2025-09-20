# Problem 33: Final Capstone Project - Comprehensive Hands-On Implementation

## 🎯 Capstone Project: Enterprise Multi-Tier Application Platform

### Project Overview
Build a complete enterprise-grade platform demonstrating all Terraform concepts learned across Problems 1-32.

## 🏗️ Phase 1: Foundation Infrastructure (3 hours)

### Multi-Region VPC Setup
```hcl
# main.tf - Primary region infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-capstone"
    key            = "capstone/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Secondary region provider
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Primary VPC with complete networking
module "primary_vpc" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.primary
  }
  
  name               = "${var.project_name}-primary"
  cidr_block         = "10.0.0.0/16"
  availability_zones = data.aws_availability_zones.primary.names
  
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnets = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_flow_logs   = true
  
  tags = local.common_tags
}

# Secondary VPC for disaster recovery
module "secondary_vpc" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.secondary
  }
  
  name               = "${var.project_name}-secondary"
  cidr_block         = "10.1.0.0/16"
  availability_zones = data.aws_availability_zones.secondary.names
  
  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets  = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
  database_subnets = ["10.1.100.0/24", "10.1.200.0/24", "10.1.300.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_flow_logs   = true
  
  tags = local.common_tags
}
```

### Security Foundation
```hcl
# security.tf - Comprehensive security setup
module "security_baseline" {
  source = "./modules/security"
  
  vpc_id = module.primary_vpc.vpc_id
  
  # WAF configuration
  waf_config = {
    enable_waf           = true
    rate_limit          = 2000
    blocked_countries   = ["CN", "RU"]
    enable_sql_injection = true
    enable_xss_protection = true
  }
  
  # Security groups
  security_groups = {
    web = {
      description = "Web tier security group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS"
        }
      ]
    }
    
    app = {
      description = "Application tier security group"
      ingress_rules = [
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = "web"
          description              = "App from Web"
        }
      ]
    }
    
    database = {
      description = "Database tier security group"
      ingress_rules = [
        {
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = "app"
          description              = "PostgreSQL from App"
        }
      ]
    }
  }
  
  tags = local.common_tags
}
```

## 🎯 Phase 2: Application Infrastructure (4 hours)

### Auto Scaling Web Tier
```hcl
# compute.tf - Multi-tier application setup
module "web_tier" {
  source = "./modules/compute"
  
  name = "${var.project_name}-web"
  
  # Launch template configuration
  launch_template = {
    image_id      = data.aws_ami.amazon_linux.id
    instance_type = var.web_instance_type
    key_name      = var.key_pair_name
    
    security_group_ids = [module.security_baseline.security_groups["web"].id]
    
    user_data = base64encode(templatefile("${path.module}/templates/web_user_data.sh", {
      app_version = var.app_version
      environment = var.environment
    }))
  }
  
  # Auto Scaling configuration
  autoscaling = {
    min_size         = var.environment == "production" ? 3 : 1
    max_size         = var.environment == "production" ? 10 : 3
    desired_capacity = var.environment == "production" ? 3 : 1
    
    target_group_arns = [module.load_balancer.target_group_arns["web"]]
    
    # Scaling policies
    scale_up_policy = {
      adjustment_type        = "ChangeInCapacity"
      scaling_adjustment     = 2
      cooldown              = 300
      metric_aggregation_type = "Average"
    }
    
    scale_down_policy = {
      adjustment_type        = "ChangeInCapacity"
      scaling_adjustment     = -1
      cooldown              = 300
      metric_aggregation_type = "Average"
    }
  }
  
  # CloudWatch alarms
  cloudwatch_alarms = {
    high_cpu = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = "2"
      metric_name        = "CPUUtilization"
      threshold          = "70"
      statistic          = "Average"
      period             = "300"
    }
    
    low_cpu = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = "2"
      metric_name        = "CPUUtilization"
      threshold          = "30"
      statistic          = "Average"
      period             = "300"
    }
  }
  
  subnet_ids = module.primary_vpc.private_subnets
  
  tags = local.common_tags
}
```

### Application Load Balancer
```hcl
# load_balancer.tf
module "load_balancer" {
  source = "./modules/load-balancer"
  
  name = "${var.project_name}-alb"
  
  vpc_id     = module.primary_vpc.vpc_id
  subnet_ids = module.primary_vpc.public_subnets
  
  security_group_ids = [module.security_baseline.security_groups["web"].id]
  
  # Target groups
  target_groups = {
    web = {
      port             = 80
      protocol         = "HTTP"
      target_type      = "instance"
      
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      
      stickiness = {
        enabled = true
        type    = "lb_cookie"
        cookie_duration = 86400
      }
    }
  }
  
  # Listeners
  listeners = {
    web_http = {
      port     = 80
      protocol = "HTTP"
      
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    
    web_https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.ssl_certificate.certificate_arn
      
      default_action = {
        type             = "forward"
        target_group_arn = "web"
      }
    }
  }
  
  # Access logging
  access_logs = {
    enabled = true
    bucket  = module.logging.s3_bucket_name
    prefix  = "alb-access-logs"
  }
  
  tags = local.common_tags
}
```

## 🎯 Phase 3: Data Layer and Storage (2 hours)

### Multi-AZ Database Setup
```hcl
# database.tf
module "database" {
  source = "./modules/database"
  
  # Primary database
  primary = {
    identifier = "${var.project_name}-primary-db"
    
    engine         = "postgres"
    engine_version = "13.7"
    instance_class = var.db_instance_class
    
    allocated_storage     = 100
    max_allocated_storage = 1000
    storage_type         = "gp3"
    storage_encrypted    = true
    kms_key_id          = module.encryption.kms_key_arn
    
    db_name  = var.database_name
    username = var.database_username
    password = var.database_password
    
    vpc_security_group_ids = [module.security_baseline.security_groups["database"].id]
    db_subnet_group_name   = module.primary_vpc.database_subnet_group_name
    
    backup_retention_period = var.environment == "production" ? 30 : 7
    backup_window          = "03:00-04:00"
    maintenance_window     = "sun:04:00-sun:05:00"
    
    multi_az               = var.environment == "production"
    deletion_protection    = var.environment == "production"
    skip_final_snapshot    = var.environment != "production"
    
    performance_insights_enabled = true
    monitoring_interval         = 60
    
    tags = merge(local.common_tags, {
      Role = "primary"
    })
  }
  
  # Read replica in secondary region
  read_replica = var.environment == "production" ? {
    identifier = "${var.project_name}-replica-db"
    
    replicate_source_db = module.database.primary.identifier
    instance_class     = var.db_instance_class
    
    vpc_security_group_ids = [module.secondary_security.security_groups["database"].id]
    
    tags = merge(local.common_tags, {
      Role = "replica"
    })
  } : null
}
```

### Caching Layer
```hcl
# cache.tf
module "redis_cache" {
  source = "./modules/elasticache"
  
  cluster_id = "${var.project_name}-redis"
  
  engine         = "redis"
  engine_version = "6.2"
  node_type      = var.cache_node_type
  
  num_cache_nodes = var.environment == "production" ? 3 : 1
  
  subnet_group_name  = module.primary_vpc.cache_subnet_group_name
  security_group_ids = [module.security_baseline.security_groups["cache"].id]
  
  # Redis-specific configuration
  parameter_group_name = "default.redis6.x"
  
  # Backup configuration
  snapshot_retention_limit = var.environment == "production" ? 7 : 1
  snapshot_window         = "05:00-06:00"
  
  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                = var.redis_auth_token
  
  tags = local.common_tags
}
```

## 🎯 Phase 4: Monitoring and Observability (2 hours)

### Comprehensive Monitoring Stack
```hcl
# monitoring.tf
module "monitoring" {
  source = "./modules/monitoring"
  
  # CloudWatch dashboards
  dashboards = {
    application = {
      name = "${var.project_name}-application-dashboard"
      
      widgets = [
        {
          type   = "metric"
          title  = "Application Performance"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.load_balancer.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.load_balancer.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", module.load_balancer.arn_suffix]
          ]
        },
        {
          type   = "metric"
          title  = "Database Performance"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", module.database.primary.identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", module.database.primary.identifier],
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", module.database.primary.identifier]
          ]
        }
      ]
    }
  }
  
  # CloudWatch alarms
  alarms = {
    high_error_rate = {
      alarm_name          = "${var.project_name}-high-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = "2"
      metric_name         = "HTTPCode_Target_5XX_Count"
      namespace           = "AWS/ApplicationELB"
      period              = "300"
      statistic           = "Sum"
      threshold           = "10"
      alarm_description   = "High error rate detected"
      alarm_actions       = [module.notifications.sns_topic_arn]
      
      dimensions = {
        LoadBalancer = module.load_balancer.arn_suffix
      }
    }
    
    database_cpu_high = {
      alarm_name          = "${var.project_name}-database-cpu-high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = "2"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/RDS"
      period              = "300"
      statistic           = "Average"
      threshold           = "80"
      alarm_description   = "Database CPU utilization is high"
      alarm_actions       = [module.notifications.sns_topic_arn]
      
      dimensions = {
        DBInstanceIdentifier = module.database.primary.identifier
      }
    }
  }
  
  tags = local.common_tags
}
```

## 🎯 Phase 5: Security and Compliance (2 hours)

### Security Automation
```hcl
# security_automation.tf
module "security_automation" {
  source = "./modules/security-automation"
  
  # AWS Config rules
  config_rules = {
    s3_bucket_encryption = {
      name                = "s3-bucket-server-side-encryption-enabled"
      source_identifier   = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
      description         = "Checks if S3 buckets have encryption enabled"
    }
    
    rds_encryption = {
      name                = "rds-storage-encrypted"
      source_identifier   = "RDS_STORAGE_ENCRYPTED"
      description         = "Checks if RDS instances have encryption enabled"
    }
    
    security_group_ssh = {
      name                = "incoming-ssh-disabled"
      source_identifier   = "INCOMING_SSH_DISABLED"
      description         = "Checks if security groups allow SSH from 0.0.0.0/0"
    }
  }
  
  # Remediation actions
  remediation_configurations = {
    encrypt_s3_bucket = {
      config_rule_name = "s3-bucket-server-side-encryption-enabled"
      resource_type    = "AWS::S3::Bucket"
      target_type      = "SSM_DOCUMENT"
      target_id        = "AWSConfigRemediation-EnableS3BucketEncryption"
      automatic        = true
    }
  }
  
  # Security Hub
  security_hub = {
    enable_default_standards = true
    
    custom_insights = [
      {
        name    = "High Severity Findings"
        filters = {
          severity_label = ["HIGH", "CRITICAL"]
        }
      }
    ]
  }
  
  tags = local.common_tags
}
```

## 📊 Success Validation and Testing

### Automated Testing Suite
```bash
#!/bin/bash
# test-capstone.sh

echo "🧪 Running Capstone Project Tests..."

# Infrastructure validation
echo "1. Validating Terraform configuration..."
terraform validate

# Security scanning
echo "2. Running security scans..."
tfsec .
checkov -d . --framework terraform

# Cost estimation
echo "3. Estimating costs..."
infracost breakdown --path .

# Integration tests
echo "4. Running integration tests..."
cd tests
go test -v ./...

# Load testing
echo "5. Running load tests..."
artillery run load-test.yml

# Security testing
echo "6. Running security tests..."
nmap -sS -O target-host
nikto -h https://your-domain.com

echo "✅ All tests completed!"
```

### Performance Benchmarks
```yaml
# load-test.yml - Artillery load testing
config:
  target: 'https://your-domain.com'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 120
      arrivalRate: 50
    - duration: 60
      arrivalRate: 100

scenarios:
  - name: "Homepage Load Test"
    requests:
      - get:
          url: "/"
      - get:
          url: "/api/health"
      - post:
          url: "/api/users"
          json:
            name: "Test User"
            email: "test@example.com"
```

## 🏆 Project Deliverables

### Required Outputs
- [ ] Multi-region infrastructure deployment
- [ ] Auto-scaling web application tier
- [ ] Highly available database with read replicas
- [ ] Comprehensive monitoring and alerting
- [ ] Security automation and compliance
- [ ] Disaster recovery procedures
- [ ] Cost optimization implementation
- [ ] Complete documentation and runbooks

### Portfolio Artifacts
- Infrastructure architecture diagrams
- Security assessment reports
- Performance testing results
- Cost analysis and optimization recommendations
- Disaster recovery test documentation
- Compliance audit reports

This capstone project demonstrates mastery of all Terraform concepts and provides a portfolio-ready enterprise implementation.
