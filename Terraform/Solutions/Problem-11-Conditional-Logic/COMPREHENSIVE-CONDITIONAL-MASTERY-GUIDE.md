# Conditional Logic Mastery - Complete Enterprise Guide

## 🧠 Advanced Conditional Patterns

### Multi-Condition Logic
```hcl
# Complex conditional resource creation
resource "aws_instance" "web" {
  count = var.environment == "production" && var.enable_web_tier ? var.web_instance_count : 0
  
  ami           = local.ami_id
  instance_type = var.environment == "production" ? "m5.large" : "t3.micro"
  
  # Conditional security groups
  vpc_security_group_ids = concat(
    [aws_security_group.web.id],
    var.enable_waf ? [aws_security_group.waf.id] : [],
    var.environment == "production" ? [aws_security_group.prod_monitoring.id] : []
  )
  
  # Environment-specific user data
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = var.environment
    enable_monitoring = var.environment == "production"
    log_level = var.environment == "production" ? "INFO" : "DEBUG"
  }))
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
    Tier = "web"
  })
}

# Conditional module usage
module "monitoring" {
  count = var.environment == "production" ? 1 : 0
  
  source = "./modules/monitoring"
  
  cluster_name = var.cluster_name
  alert_email  = var.alert_email
  
  tags = local.common_tags
}

# Dynamic conditional blocks
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = var.vpc_id
  
  # Conditional ingress rules
  dynamic "ingress" {
    for_each = var.environment == "production" ? var.production_ingress_rules : var.dev_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  # Always allow HTTPS in production
  dynamic "ingress" {
    for_each = var.environment == "production" ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  }
  
  tags = local.common_tags
}
```

### Advanced Ternary Operations
```hcl
# Complex ternary expressions
locals {
  # Multi-level conditional logic
  instance_type = (
    var.environment == "production" ? (
      var.high_performance ? "c5.4xlarge" : "m5.xlarge"
    ) : (
      var.environment == "staging" ? "t3.medium" : "t3.micro"
    )
  )
  
  # Conditional resource naming
  resource_suffix = var.multi_region ? "${var.aws_region}-${var.environment}" : var.environment
  
  # Environment-specific configurations
  database_config = {
    instance_class = var.environment == "production" ? "db.r5.xlarge" : "db.t3.medium"
    multi_az      = var.environment == "production" ? true : false
    backup_retention = var.environment == "production" ? 30 : 7
    storage_encrypted = var.environment != "development"
  }
  
  # Conditional feature flags
  features = {
    enable_monitoring = var.environment == "production"
    enable_backup    = var.environment != "development"
    enable_ssl       = var.environment != "development"
    enable_waf       = var.environment == "production"
  }
}
```

## 🔄 Environment-Specific Patterns

### Workspace-Based Conditionals
```hcl
# Workspace-aware configurations
locals {
  workspace_config = {
    development = {
      instance_count = 1
      instance_type  = "t3.micro"
      enable_monitoring = false
      backup_retention = 1
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      enable_monitoring = true
      backup_retention = 7
    }
    production = {
      instance_count = 5
      instance_type  = "m5.large"
      enable_monitoring = true
      backup_retention = 30
    }
  }
  
  current_config = local.workspace_config[terraform.workspace]
}

resource "aws_instance" "app" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  tags = {
    Name = "${terraform.workspace}-app-${count.index + 1}"
    Workspace = terraform.workspace
  }
}

# Conditional monitoring based on workspace
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.current_config.enable_monitoring ? local.current_config.instance_count : 0
  
  alarm_name          = "${terraform.workspace}-high-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = terraform.workspace == "production" ? "70" : "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }
}
```

### Feature Flag Implementation
```hcl
# Feature flag system
variable "feature_flags" {
  description = "Feature flags for conditional functionality"
  type = object({
    enable_auto_scaling     = bool
    enable_load_balancer   = bool
    enable_database_backup = bool
    enable_ssl_termination = bool
    enable_waf_protection  = bool
  })
  default = {
    enable_auto_scaling     = false
    enable_load_balancer   = false
    enable_database_backup = false
    enable_ssl_termination = false
    enable_waf_protection  = false
  }
}

# Auto Scaling Group (conditional)
resource "aws_autoscaling_group" "app" {
  count = var.feature_flags.enable_auto_scaling ? 1 : 0
  
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.feature_flags.enable_load_balancer ? [aws_lb_target_group.app[0].arn] : []
  health_check_type   = var.feature_flags.enable_load_balancer ? "ELB" : "EC2"
  
  min_size         = var.environment == "production" ? 2 : 1
  max_size         = var.environment == "production" ? 10 : 3
  desired_capacity = var.environment == "production" ? 3 : 1
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}

# Load Balancer (conditional)
resource "aws_lb" "app" {
  count = var.feature_flags.enable_load_balancer ? 1 : 0
  
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets           = var.public_subnet_ids
  
  enable_deletion_protection = var.environment == "production"
  
  tags = local.common_tags
}

# WAF (conditional)
resource "aws_wafv2_web_acl" "app" {
  count = var.feature_flags.enable_waf_protection ? 1 : 0
  
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = var.environment == "production" ? 2000 : 10000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  tags = local.common_tags
}
```

This comprehensive guide provides enterprise-grade conditional logic patterns for production Terraform deployments.
