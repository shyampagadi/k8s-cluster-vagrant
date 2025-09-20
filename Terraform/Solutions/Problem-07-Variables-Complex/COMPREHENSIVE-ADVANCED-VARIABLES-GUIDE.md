# Problem 7: Advanced Terraform Variables - Complex Patterns and Structures

## Advanced Variable Types

### Complex Object Variables
```hcl
# Multi-tier application configuration
variable "application_architecture" {
  description = "Complete application architecture configuration"
  type = object({
    name    = string
    version = string
    
    web_tier = object({
      instance_type     = string
      min_instances     = number
      max_instances     = number
      desired_instances = number
      
      load_balancer = object({
        type                = string
        scheme              = string
        deletion_protection = bool
        ports = list(object({
          port     = number
          protocol = string
          ssl_cert = optional(string)
        }))
      })
      
      auto_scaling = object({
        scale_up_threshold   = number
        scale_down_threshold = number
        scale_up_cooldown    = number
        scale_down_cooldown  = number
      })
    })
    
    app_tier = object({
      instance_type     = string
      min_instances     = number
      max_instances     = number
      desired_instances = number
      
      database_connections = object({
        max_connections     = number
        connection_timeout  = number
        pool_size          = number
      })
    })
    
    data_tier = object({
      primary_database = object({
        engine              = string
        version             = string
        instance_class      = string
        allocated_storage   = number
        max_allocated_storage = number
        backup_retention    = number
        multi_az           = bool
        encryption_enabled = bool
      })
      
      cache = object({
        node_type          = string
        num_cache_nodes    = number
        parameter_group    = string
        engine_version     = string
      })
      
      read_replicas = list(object({
        instance_class    = string
        region           = string
        backup_retention = number
      }))
    })
    
    monitoring = object({
      enabled           = bool
      retention_days    = number
      detailed_monitoring = bool
      
      alerts = list(object({
        name        = string
        metric      = string
        threshold   = number
        comparison  = string
        period      = number
        statistic   = string
        actions     = list(string)
      }))
    })
    
    security = object({
      encryption_at_rest  = bool
      encryption_in_transit = bool
      
      network_acls = list(object({
        rule_number = number
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = optional(number)
        to_port     = optional(number)
      }))
      
      security_groups = map(object({
        description = string
        ingress_rules = list(object({
          from_port   = number
          to_port     = number
          protocol    = string
          cidr_blocks = list(string)
          description = string
        }))
        egress_rules = list(object({
          from_port   = number
          to_port     = number
          protocol    = string
          cidr_blocks = list(string)
          description = string
        }))
      }))
    })
  })
  
  # Complex default configuration
  default = {
    name    = "enterprise-app"
    version = "2.0.0"
    
    web_tier = {
      instance_type     = "t3.medium"
      min_instances     = 2
      max_instances     = 10
      desired_instances = 3
      
      load_balancer = {
        type                = "application"
        scheme              = "internet-facing"
        deletion_protection = true
        ports = [
          {
            port     = 80
            protocol = "HTTP"
            ssl_cert = null
          },
          {
            port     = 443
            protocol = "HTTPS"
            ssl_cert = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
          }
        ]
      }
      
      auto_scaling = {
        scale_up_threshold   = 70
        scale_down_threshold = 30
        scale_up_cooldown    = 300
        scale_down_cooldown  = 300
      }
    }
    
    app_tier = {
      instance_type     = "t3.large"
      min_instances     = 2
      max_instances     = 8
      desired_instances = 4
      
      database_connections = {
        max_connections    = 100
        connection_timeout = 30
        pool_size         = 20
      }
    }
    
    data_tier = {
      primary_database = {
        engine                = "mysql"
        version              = "8.0"
        instance_class       = "db.r5.xlarge"
        allocated_storage    = 500
        max_allocated_storage = 1000
        backup_retention     = 30
        multi_az            = true
        encryption_enabled  = true
      }
      
      cache = {
        node_type       = "cache.r6g.large"
        num_cache_nodes = 3
        parameter_group = "default.redis7"
        engine_version  = "7.0"
      }
      
      read_replicas = [
        {
          instance_class   = "db.r5.large"
          region          = "us-east-1"
          backup_retention = 7
        },
        {
          instance_class   = "db.r5.large"
          region          = "eu-west-1"
          backup_retention = 7
        }
      ]
    }
    
    monitoring = {
      enabled             = true
      retention_days      = 90
      detailed_monitoring = true
      
      alerts = [
        {
          name       = "High CPU Usage"
          metric     = "CPUUtilization"
          threshold  = 80
          comparison = "GreaterThanThreshold"
          period     = 300
          statistic  = "Average"
          actions    = ["arn:aws:sns:us-west-2:123456789012:alerts"]
        },
        {
          name       = "High Memory Usage"
          metric     = "MemoryUtilization"
          threshold  = 85
          comparison = "GreaterThanThreshold"
          period     = 300
          statistic  = "Average"
          actions    = ["arn:aws:sns:us-west-2:123456789012:alerts"]
        }
      ]
    }
    
    security = {
      encryption_at_rest     = true
      encryption_in_transit  = true
      
      network_acls = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/8"
          from_port   = 80
          to_port     = 80
        },
        {
          rule_number = 110
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/8"
          from_port   = 443
          to_port     = 443
        }
      ]
      
      security_groups = {
        web = {
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
          egress_rules = [
            {
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
              description = "All outbound traffic"
            }
          ]
        }
        
        app = {
          description = "Application tier security group"
          ingress_rules = [
            {
              from_port   = 8080
              to_port     = 8080
              protocol    = "tcp"
              cidr_blocks = ["10.0.0.0/8"]
              description = "Application port from web tier"
            }
          ]
          egress_rules = [
            {
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
              description = "All outbound traffic"
            }
          ]
        }
      }
    }
  }
}
```

### Environment-Specific Configurations
```hcl
# Environment-specific variable patterns
variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    # Infrastructure sizing
    web_tier = object({
      instance_type     = string
      min_instances     = number
      max_instances     = number
      desired_instances = number
    })
    
    app_tier = object({
      instance_type     = string
      min_instances     = number
      max_instances     = number
      desired_instances = number
    })
    
    database = object({
      instance_class       = string
      allocated_storage    = number
      backup_retention     = number
      multi_az            = bool
      deletion_protection = bool
    })
    
    # Feature flags
    features = object({
      monitoring_enabled    = bool
      logging_enabled      = bool
      backup_enabled       = bool
      auto_scaling_enabled = bool
      cdn_enabled         = bool
    })
    
    # Security settings
    security = object({
      encryption_required = bool
      mfa_required       = bool
      vpc_flow_logs      = bool
      cloudtrail_enabled = bool
    })
    
    # Cost optimization
    cost_optimization = object({
      use_spot_instances    = bool
      use_reserved_instances = bool
      lifecycle_policies    = bool
      auto_shutdown        = bool
    })
  }))
  
  default = {
    development = {
      web_tier = {
        instance_type     = "t3.micro"
        min_instances     = 1
        max_instances     = 2
        desired_instances = 1
      }
      
      app_tier = {
        instance_type     = "t3.small"
        min_instances     = 1
        max_instances     = 2
        desired_instances = 1
      }
      
      database = {
        instance_class      = "db.t3.micro"
        allocated_storage   = 20
        backup_retention    = 1
        multi_az           = false
        deletion_protection = false
      }
      
      features = {
        monitoring_enabled    = false
        logging_enabled      = true
        backup_enabled       = false
        auto_scaling_enabled = false
        cdn_enabled         = false
      }
      
      security = {
        encryption_required = false
        mfa_required       = false
        vpc_flow_logs      = false
        cloudtrail_enabled = false
      }
      
      cost_optimization = {
        use_spot_instances     = true
        use_reserved_instances = false
        lifecycle_policies     = false
        auto_shutdown         = true
      }
    }
    
    staging = {
      web_tier = {
        instance_type     = "t3.small"
        min_instances     = 2
        max_instances     = 4
        desired_instances = 2
      }
      
      app_tier = {
        instance_type     = "t3.medium"
        min_instances     = 2
        max_instances     = 4
        desired_instances = 2
      }
      
      database = {
        instance_class      = "db.t3.small"
        allocated_storage   = 100
        backup_retention    = 7
        multi_az           = true
        deletion_protection = true
      }
      
      features = {
        monitoring_enabled    = true
        logging_enabled      = true
        backup_enabled       = true
        auto_scaling_enabled = true
        cdn_enabled         = false
      }
      
      security = {
        encryption_required = true
        mfa_required       = false
        vpc_flow_logs      = true
        cloudtrail_enabled = true
      }
      
      cost_optimization = {
        use_spot_instances     = false
        use_reserved_instances = false
        lifecycle_policies     = true
        auto_shutdown         = false
      }
    }
    
    production = {
      web_tier = {
        instance_type     = "t3.large"
        min_instances     = 3
        max_instances     = 15
        desired_instances = 5
      }
      
      app_tier = {
        instance_type     = "t3.xlarge"
        min_instances     = 3
        max_instances     = 12
        desired_instances = 6
      }
      
      database = {
        instance_class      = "db.r5.xlarge"
        allocated_storage   = 500
        backup_retention    = 30
        multi_az           = true
        deletion_protection = true
      }
      
      features = {
        monitoring_enabled    = true
        logging_enabled      = true
        backup_enabled       = true
        auto_scaling_enabled = true
        cdn_enabled         = true
      }
      
      security = {
        encryption_required = true
        mfa_required       = true
        vpc_flow_logs      = true
        cloudtrail_enabled = true
      }
      
      cost_optimization = {
        use_spot_instances     = false
        use_reserved_instances = true
        lifecycle_policies     = true
        auto_shutdown         = false
      }
    }
  }
}
```

## Advanced Validation Patterns

### Complex Validation Rules
```hcl
# Multi-condition validation
variable "database_config" {
  description = "Database configuration with complex validation"
  type = object({
    engine         = string
    version        = string
    instance_class = string
    storage_gb     = number
    iops          = optional(number)
    storage_type  = string
  })
  
  validation {
    # Validate engine and version combinations
    condition = (
      (var.database_config.engine == "mysql" && contains(["5.7", "8.0"], var.database_config.version)) ||
      (var.database_config.engine == "postgres" && contains(["12", "13", "14", "15"], var.database_config.version)) ||
      (var.database_config.engine == "oracle-ee" && contains(["19.0.0.0.ru-2021-10.rur-2021-10.r1"], var.database_config.version))
    )
    error_message = "Invalid engine and version combination."
  }
  
  validation {
    # Validate instance class for engine
    condition = (
      var.database_config.engine == "mysql" ? can(regex("^db\\.(t3|r5|m5)", var.database_config.instance_class)) :
      var.database_config.engine == "postgres" ? can(regex("^db\\.(t3|r5|m5)", var.database_config.instance_class)) :
      var.database_config.engine == "oracle-ee" ? can(regex("^db\\.(r5|m5)", var.database_config.instance_class)) :
      false
    )
    error_message = "Instance class not supported for the selected database engine."
  }
  
  validation {
    # Validate storage configuration
    condition = (
      var.database_config.storage_type == "gp2" ? (
        var.database_config.storage_gb >= 20 && var.database_config.storage_gb <= 65536
      ) : var.database_config.storage_type == "gp3" ? (
        var.database_config.storage_gb >= 20 && var.database_config.storage_gb <= 65536
      ) : var.database_config.storage_type == "io1" ? (
        var.database_config.storage_gb >= 100 && var.database_config.storage_gb <= 65536 &&
        var.database_config.iops != null && var.database_config.iops >= 1000
      ) : false
    )
    error_message = "Invalid storage configuration for the selected storage type."
  }
}

# Cross-variable validation
variable "cluster_config" {
  description = "Cluster configuration"
  type = object({
    node_count    = number
    node_type     = string
    storage_size  = number
    backup_enabled = bool
  })
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Validation that depends on multiple variables
locals {
  # Production environments must have specific minimums
  production_requirements_met = var.environment == "production" ? (
    var.cluster_config.node_count >= 3 &&
    var.cluster_config.storage_size >= 100 &&
    var.cluster_config.backup_enabled == true
  ) : true
}

# Custom validation function
variable "network_config" {
  description = "Network configuration with CIDR validation"
  type = object({
    vpc_cidr     = string
    subnet_cidrs = list(string)
  })
  
  validation {
    # Validate VPC CIDR
    condition     = can(cidrhost(var.network_config.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
  
  validation {
    # Validate all subnet CIDRs are within VPC CIDR
    condition = alltrue([
      for subnet_cidr in var.network_config.subnet_cidrs :
      can(cidrsubnet(var.network_config.vpc_cidr, 0, 0)) &&
      can(cidrhost(subnet_cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid and within the VPC CIDR range."
  }
  
  validation {
    # Validate no overlapping subnets
    condition = length(var.network_config.subnet_cidrs) == length(toset(var.network_config.subnet_cidrs))
    error_message = "Subnet CIDRs must not overlap."
  }
}
```

### Dynamic Validation Based on Environment
```hcl
# Environment-aware validation
variable "instance_config" {
  description = "Instance configuration"
  type = object({
    type  = string
    count = number
  })
  
  validation {
    # Different rules for different environments
    condition = var.environment == "production" ? (
      contains(["t3.large", "t3.xlarge", "m5.large", "m5.xlarge"], var.instance_config.type) &&
      var.instance_config.count >= 2
    ) : var.environment == "staging" ? (
      contains(["t3.small", "t3.medium", "t3.large"], var.instance_config.type) &&
      var.instance_config.count >= 1
    ) : (
      contains(["t3.micro", "t3.small"], var.instance_config.type) &&
      var.instance_config.count >= 1
    )
    error_message = "Instance configuration does not meet environment requirements."
  }
}
```

## Variable Processing and Transformation

### Using Locals for Complex Processing
```hcl
# Process complex variables with locals
locals {
  # Extract environment-specific configuration
  current_env_config = var.environment_configs[var.environment]
  
  # Calculate derived values
  total_min_instances = (
    local.current_env_config.web_tier.min_instances +
    local.current_env_config.app_tier.min_instances
  )
  
  total_max_instances = (
    local.current_env_config.web_tier.max_instances +
    local.current_env_config.app_tier.max_instances
  )
  
  # Process security groups
  security_group_rules = flatten([
    for sg_name, sg_config in var.application_architecture.security.security_groups : [
      for rule in sg_config.ingress_rules : {
        sg_name     = sg_name
        type        = "ingress"
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
        cidr_blocks = rule.cidr_blocks
        description = rule.description
      }
    ]
  ])
  
  # Create subnet configurations
  subnet_configs = {
    for i, cidr in var.network_config.subnet_cidrs : 
    "subnet-${i + 1}" => {
      cidr_block        = cidr
      availability_zone = data.aws_availability_zones.available.names[i % length(data.aws_availability_zones.available.names)]
      public           = i < var.public_subnet_count
      tags = {
        Name = "${var.project_name}-subnet-${i + 1}"
        Type = i < var.public_subnet_count ? "public" : "private"
        Tier = i < var.public_subnet_count ? "web" : (
          i < var.public_subnet_count + var.app_subnet_count ? "app" : "data"
        )
      }
    }
  }
  
  # Process monitoring alerts
  monitoring_alerts = {
    for alert in var.application_architecture.monitoring.alerts :
    alert.name => {
      metric_name         = alert.metric
      threshold          = alert.threshold
      comparison_operator = alert.comparison
      evaluation_periods = 2
      period             = alert.period
      statistic          = alert.statistic
      alarm_actions      = alert.actions
      treat_missing_data = "notBreaching"
    }
  }
  
  # Generate tags
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      CreatedAt   = timestamp()
    },
    var.additional_tags
  )
  
  # Environment-specific tags
  environment_tags = var.environment == "production" ? {
    Backup      = "required"
    Monitoring  = "enhanced"
    Compliance  = "required"
  } : var.environment == "staging" ? {
    Backup      = "optional"
    Monitoring  = "standard"
    Compliance  = "testing"
  } : {
    Backup      = "none"
    Monitoring  = "basic"
    Compliance  = "none"
  }
  
  # Final merged tags
  final_tags = merge(local.common_tags, local.environment_tags)
}
```

### Variable Transformation Functions
```hcl
# Transform and normalize variable data
locals {
  # Normalize instance types to families
  instance_families = {
    for tier_name, tier_config in {
      web = local.current_env_config.web_tier
      app = local.current_env_config.app_tier
    } : tier_name => {
      family = split(".", tier_config.instance_type)[0]
      size   = split(".", tier_config.instance_type)[1]
      type   = tier_config.instance_type
    }
  }
  
  # Calculate resource requirements
  resource_requirements = {
    for tier_name, tier_config in {
      web = local.current_env_config.web_tier
      app = local.current_env_config.app_tier
    } : tier_name => {
      min_cpu = tier_config.min_instances * (
        contains(["micro"], local.instance_families[tier_name].size) ? 1 :
        contains(["small"], local.instance_families[tier_name].size) ? 1 :
        contains(["medium"], local.instance_families[tier_name].size) ? 2 :
        contains(["large"], local.instance_families[tier_name].size) ? 2 :
        contains(["xlarge"], local.instance_families[tier_name].size) ? 4 : 8
      )
      
      max_cpu = tier_config.max_instances * (
        contains(["micro"], local.instance_families[tier_name].size) ? 1 :
        contains(["small"], local.instance_families[tier_name].size) ? 1 :
        contains(["medium"], local.instance_families[tier_name].size) ? 2 :
        contains(["large"], local.instance_families[tier_name].size) ? 2 :
        contains(["xlarge"], local.instance_families[tier_name].size) ? 4 : 8
      )
    }
  }
  
  # Generate configuration files
  application_config = {
    database = {
      host     = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      name     = aws_db_instance.main.db_name
      username = aws_db_instance.main.username
    }
    
    cache = {
      host = aws_elasticache_cluster.main.cache_nodes[0].address
      port = aws_elasticache_cluster.main.cache_nodes[0].port
    }
    
    features = local.current_env_config.features
    
    scaling = {
      web_tier = local.current_env_config.web_tier
      app_tier = local.current_env_config.app_tier
    }
  }
}
```

This comprehensive guide demonstrates advanced variable patterns, complex object structures, sophisticated validation rules, and powerful transformation techniques for managing complex Terraform configurations.
