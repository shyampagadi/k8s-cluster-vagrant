## Part 2: Enterprise Module Design Patterns

### 2.1 Module Versioning and Constraints

#### Semantic Versioning Strategy
```hcl
# Production module with version constraints
module "production_app" {
  source  = "git::https://github.com/company/terraform-modules.git//modules/application?ref=v2.1.0"
  
  # Version constraint for stability
  version = "~> 2.1.0"  # Allow patch updates only
  
  application_config = var.production_config
  environment        = "production"
}

# Development module with flexible versioning
module "development_app" {
  source  = "git::https://github.com/company/terraform-modules.git//modules/application?ref=v2.2.0-beta"
  
  # More flexible version constraint for development
  version = ">= 2.0.0, < 3.0.0"
  
  application_config = var.development_config
  environment        = "development"
}

# Local module for testing
module "test_app" {
  source = "../modules/application"
  
  application_config = var.test_config
  environment        = "test"
}
```

#### Module Registry Implementation
```hcl
# Using Terraform Registry modules
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  
  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr
  
  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  
  tags = var.tags
}

# Private registry modules
module "company_security" {
  source  = "company.registry.com/security/baseline/aws"
  version = "~> 1.5.0"
  
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  
  security_config = var.security_config
  
  tags = var.tags
}
```

### 2.2 Advanced Input/Output Patterns

#### Complex Variable Structures
```hcl
# modules/application/variables.tf
variable "application_config" {
  description = "Comprehensive application configuration"
  type = object({
    name    = string
    version = string
    
    # Compute configuration
    compute = object({
      instance_type    = string
      min_capacity     = number
      max_capacity     = number
      desired_capacity = number
      
      # Advanced compute options
      spot_instances = optional(object({
        enabled                = bool
        spot_allocation_strategy = string
        spot_instance_pools     = number
        spot_max_price         = string
      }), {
        enabled                = false
        spot_allocation_strategy = "diversified"
        spot_instance_pools     = 2
        spot_max_price         = null
      })
      
      # Launch template configuration
      launch_template = object({
        image_id      = string
        key_name      = optional(string)
        user_data     = optional(string)
        
        # Block device mappings
        block_device_mappings = optional(list(object({
          device_name = string
          ebs = object({
            volume_size = number
            volume_type = string
            encrypted   = bool
            iops        = optional(number)
          })
        })), [])
      })
    })
    
    # Database configuration
    database = optional(object({
      engine         = string
      engine_version = string
      instance_class = string
      
      # Storage configuration
      storage = object({
        allocated_storage     = number
        max_allocated_storage = optional(number)
        storage_type         = string
        storage_encrypted    = bool
        iops                 = optional(number)
      })
      
      # Backup configuration
      backup = object({
        backup_retention_period = number
        backup_window          = string
        maintenance_window     = string
        skip_final_snapshot    = bool
      })
      
      # Performance insights
      performance_insights = optional(object({
        enabled          = bool
        retention_period = number
      }), {
        enabled          = false
        retention_period = 7
      })
    }))
    
    # Load balancer configuration
    load_balancer = object({
      type               = string
      scheme             = string
      enable_deletion_protection = bool
      
      # Target group configuration
      target_groups = list(object({
        name     = string
        port     = number
        protocol = string
        
        health_check = object({
          enabled             = bool
          healthy_threshold   = number
          unhealthy_threshold = number
          timeout             = number
          interval            = number
          path                = string
          matcher             = string
        })
      }))
      
      # Listener configuration
      listeners = list(object({
        port     = number
        protocol = string
        
        # SSL configuration
        ssl_policy      = optional(string)
        certificate_arn = optional(string)
        
        # Default action
        default_action = object({
          type               = string
          target_group_index = number
        })
      }))
    })
    
    # Monitoring configuration
    monitoring = optional(object({
      enabled = bool
      
      # CloudWatch configuration
      cloudwatch = object({
        log_retention_days = number
        detailed_monitoring = bool
        
        # Custom metrics
        custom_metrics = optional(list(object({
          name      = string
          namespace = string
          value     = string
          unit      = string
        })), [])
      })
      
      # Alarms configuration
      alarms = optional(list(object({
        name               = string
        description        = string
        metric_name        = string
        namespace          = string
        statistic          = string
        period             = number
        evaluation_periods = number
        threshold          = number
        comparison_operator = string
        
        # Alarm actions
        alarm_actions = list(string)
        ok_actions    = list(string)
      })), [])
    }), {
      enabled = false
      cloudwatch = {
        log_retention_days  = 14
        detailed_monitoring = false
        custom_metrics      = []
      }
      alarms = []
    })
  })
  
  validation {
    condition = contains(["web", "api", "worker", "batch"], var.application_config.name)
    error_message = "Application name must be one of: web, api, worker, batch."
  }
  
  validation {
    condition = var.application_config.compute.min_capacity <= var.application_config.compute.desired_capacity
    error_message = "Minimum capacity must be less than or equal to desired capacity."
  }
  
  validation {
    condition = var.application_config.compute.desired_capacity <= var.application_config.compute.max_capacity
    error_message = "Desired capacity must be less than or equal to maximum capacity."
  }
}

variable "network_config" {
  description = "Network configuration from networking module"
  type = object({
    vpc_id             = string
    vpc_cidr           = string
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
    nat_gateway_ids    = list(string)
  })
}

variable "security_config" {
  description = "Security configuration from security module"
  type = object({
    kms_key_id          = string
    application_sg_id   = string
    database_sg_id      = string
    load_balancer_sg_id = string
  })
}
```

#### Advanced Output Patterns
```hcl
# modules/application/outputs.tf
output "application_info" {
  description = "Comprehensive application information"
  value = {
    # Basic information
    name        = var.application_config.name
    version     = var.application_config.version
    environment = var.environment
    
    # Compute resources
    compute = {
      auto_scaling_group = {
        name = aws_autoscaling_group.app.name
        arn  = aws_autoscaling_group.app.arn
      }
      
      launch_template = {
        id      = aws_launch_template.app.id
        version = aws_launch_template.app.latest_version
      }
      
      instances = {
        count = aws_autoscaling_group.app.desired_capacity
        type  = var.application_config.compute.instance_type
      }
    }
    
    # Database resources (if enabled)
    database = var.application_config.database != null ? {
      identifier = aws_db_instance.app[0].identifier
      endpoint   = aws_db_instance.app[0].endpoint
      port       = aws_db_instance.app[0].port
      
      connection_info = {
        host     = aws_db_instance.app[0].address
        port     = aws_db_instance.app[0].port
        database = aws_db_instance.app[0].db_name
      }
    } : null
    
    # Load balancer resources
    load_balancer = {
      arn      = aws_lb.app.arn
      dns_name = aws_lb.app.dns_name
      zone_id  = aws_lb.app.zone_id
      
      target_groups = [
        for tg in aws_lb_target_group.app : {
          name = tg.name
          arn  = tg.arn
          port = tg.port
        }
      ]
      
      listeners = [
        for listener in aws_lb_listener.app : {
          arn  = listener.arn
          port = listener.port
        }
      ]
    }
    
    # Monitoring resources (if enabled)
    monitoring = var.application_config.monitoring.enabled ? {
      log_group = {
        name = aws_cloudwatch_log_group.app[0].name
        arn  = aws_cloudwatch_log_group.app[0].arn
      }
      
      alarms = [
        for alarm in aws_cloudwatch_metric_alarm.app : {
          name = alarm.alarm_name
          arn  = alarm.arn
        }
      ]
    } : null
    
    # Security information
    security = {
      security_groups = [
        aws_security_group.app.id,
        var.security_config.application_sg_id
      ]
      
      kms_key_id = var.security_config.kms_key_id
    }
    
    # Network information
    network = {
      vpc_id     = var.network_config.vpc_id
      subnet_ids = var.network_config.private_subnet_ids
    }
  }
}

# Specific outputs for common use cases
output "load_balancer_dns_name" {
  description = "Load balancer DNS name for external access"
  value       = aws_lb.app.dns_name
}

output "database_endpoint" {
  description = "Database endpoint for application connection"
  value       = var.application_config.database != null ? aws_db_instance.app[0].endpoint : null
  sensitive   = true
}

output "auto_scaling_group_name" {
  description = "Auto Scaling Group name for monitoring"
  value       = aws_autoscaling_group.app.name
}

output "security_group_ids" {
  description = "Security group IDs for additional configuration"
  value = [
    aws_security_group.app.id,
    var.security_config.application_sg_id
  ]
}

# Outputs for cross-module dependencies
output "application_endpoints" {
  description = "Application endpoints for service discovery"
  value = {
    public = {
      dns_name = aws_lb.app.dns_name
      port     = 80
      protocol = "HTTP"
    }
    
    private = var.application_config.database != null ? {
      host     = aws_db_instance.app[0].address
      port     = aws_db_instance.app[0].port
      protocol = "TCP"
    } : null
  }
}
```

### 2.3 Dynamic Module Configuration

#### Dynamic Block Patterns
```hcl
# Dynamic configuration based on input
resource "aws_launch_template" "app" {
  name_prefix   = "${var.application_config.name}-"
  image_id      = var.application_config.compute.launch_template.image_id
  instance_type = var.application_config.compute.instance_type
  key_name      = var.application_config.compute.launch_template.key_name
  
  vpc_security_group_ids = [
    aws_security_group.app.id,
    var.security_config.application_sg_id
  ]
  
  # Dynamic block device mappings
  dynamic "block_device_mappings" {
    for_each = var.application_config.compute.launch_template.block_device_mappings
    
    content {
      device_name = block_device_mappings.value.device_name
      
      ebs {
        volume_size = block_device_mappings.value.ebs.volume_size
        volume_type = block_device_mappings.value.ebs.volume_type
        encrypted   = block_device_mappings.value.ebs.encrypted
        iops        = block_device_mappings.value.ebs.iops
        
        delete_on_termination = true
      }
    }
  }
  
  # Dynamic IAM instance profile
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [1] : []
    
    content {
      name = var.iam_instance_profile
    }
  }
  
  # Dynamic monitoring
  dynamic "monitoring" {
    for_each = var.application_config.monitoring.enabled ? [1] : []
    
    content {
      enabled = true
    }
  }
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    application_name = var.application_config.name
    environment      = var.environment
    log_group_name   = var.application_config.monitoring.enabled ? aws_cloudwatch_log_group.app[0].name : ""
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.application_config.name}-instance"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic target groups for load balancer
resource "aws_lb_target_group" "app" {
  count = length(var.application_config.load_balancer.target_groups)
  
  name     = "${var.application_config.name}-${var.application_config.load_balancer.target_groups[count.index].name}"
  port     = var.application_config.load_balancer.target_groups[count.index].port
  protocol = var.application_config.load_balancer.target_groups[count.index].protocol
  vpc_id   = var.network_config.vpc_id
  
  health_check {
    enabled             = var.application_config.load_balancer.target_groups[count.index].health_check.enabled
    healthy_threshold   = var.application_config.load_balancer.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.application_config.load_balancer.target_groups[count.index].health_check.unhealthy_threshold
    timeout             = var.application_config.load_balancer.target_groups[count.index].health_check.timeout
    interval            = var.application_config.load_balancer.target_groups[count.index].health_check.interval
    path                = var.application_config.load_balancer.target_groups[count.index].health_check.path
    matcher             = var.application_config.load_balancer.target_groups[count.index].health_check.matcher
  }
  
  tags = merge(var.tags, {
    Name = "${var.application_config.name}-${var.application_config.load_balancer.target_groups[count.index].name}"
  })
}

# Dynamic listeners for load balancer
resource "aws_lb_listener" "app" {
  count = length(var.application_config.load_balancer.listeners)
  
  load_balancer_arn = aws_lb.app.arn
  port              = var.application_config.load_balancer.listeners[count.index].port
  protocol          = var.application_config.load_balancer.listeners[count.index].protocol
  
  # Dynamic SSL policy
  ssl_policy      = var.application_config.load_balancer.listeners[count.index].ssl_policy
  certificate_arn = var.application_config.load_balancer.listeners[count.index].certificate_arn
  
  default_action {
    type             = var.application_config.load_balancer.listeners[count.index].default_action.type
    target_group_arn = aws_lb_target_group.app[var.application_config.load_balancer.listeners[count.index].default_action.target_group_index].arn
  }
  
  tags = merge(var.tags, {
    Name = "${var.application_config.name}-listener-${var.application_config.load_balancer.listeners[count.index].port}"
  })
}
```

#### Conditional Resource Creation
```hcl
# Conditional database creation
resource "aws_db_instance" "app" {
  count = var.application_config.database != null ? 1 : 0
  
  identifier = "${var.application_config.name}-${var.environment}"
  
  engine         = var.application_config.database.engine
  engine_version = var.application_config.database.engine_version
  instance_class = var.application_config.database.instance_class
  
  allocated_storage     = var.application_config.database.storage.allocated_storage
  max_allocated_storage = var.application_config.database.storage.max_allocated_storage
  storage_type         = var.application_config.database.storage.storage_type
  storage_encrypted    = var.application_config.database.storage.storage_encrypted
  iops                 = var.application_config.database.storage.iops
  
  db_name  = var.application_config.name
  username = "admin"
  password = random_password.db_password[0].result
  
  vpc_security_group_ids = [var.security_config.database_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.app[0].name
  
  backup_retention_period = var.application_config.database.backup.backup_retention_period
  backup_window          = var.application_config.database.backup.backup_window
  maintenance_window     = var.application_config.database.backup.maintenance_window
  skip_final_snapshot    = var.application_config.database.backup.skip_final_snapshot
  
  # Conditional performance insights
  performance_insights_enabled          = var.application_config.database.performance_insights.enabled
  performance_insights_retention_period = var.application_config.database.performance_insights.retention_period
  
  kms_key_id = var.security_config.kms_key_id
  
  tags = merge(var.tags, {
    Name = "${var.application_config.name}-database"
  })
}

# Conditional monitoring resources
resource "aws_cloudwatch_log_group" "app" {
  count = var.application_config.monitoring.enabled ? 1 : 0
  
  name              = "/aws/application/${var.application_config.name}"
  retention_in_days = var.application_config.monitoring.cloudwatch.log_retention_days
  
  kms_key_id = var.security_config.kms_key_id
  
  tags = merge(var.tags, {
    Name = "${var.application_config.name}-logs"
  })
}

# Conditional CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "app" {
  count = var.application_config.monitoring.enabled ? length(var.application_config.monitoring.alarms) : 0
  
  alarm_name          = "${var.application_config.name}-${var.application_config.monitoring.alarms[count.index].name}"
  alarm_description   = var.application_config.monitoring.alarms[count.index].description
  
  metric_name         = var.application_config.monitoring.alarms[count.index].metric_name
  namespace           = var.application_config.monitoring.alarms[count.index].namespace
  statistic           = var.application_config.monitoring.alarms[count.index].statistic
  period              = var.application_config.monitoring.alarms[count.index].period
  evaluation_periods  = var.application_config.monitoring.alarms[count.index].evaluation_periods
  threshold           = var.application_config.monitoring.alarms[count.index].threshold
  comparison_operator = var.application_config.monitoring.alarms[count.index].comparison_operator
  
  alarm_actions = var.application_config.monitoring.alarms[count.index].alarm_actions
  ok_actions    = var.application_config.monitoring.alarms[count.index].ok_actions
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  tags = merge(var.tags, {
    Name = "${var.application_config.name}-${var.application_config.monitoring.alarms[count.index].name}"
  })
}
```
