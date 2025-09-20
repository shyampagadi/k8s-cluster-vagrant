# Terraform Conditional Logic and Dynamic Blocks - Complete Guide

## Overview

This comprehensive guide covers Terraform's conditional logic, dynamic blocks, and advanced control flow patterns for creating flexible, environment-aware infrastructure configurations.

## Conditional Logic Fundamentals

### Ternary Operator

```hcl
# Basic ternary syntax: condition ? true_value : false_value

variable "environment" {
  description = "Environment name"
  type        = string
}

# Simple conditional
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  monitoring = var.environment == "production" ? true : false
  
  tags = {
    Name = var.environment == "production" ? "prod-web-server" : "dev-web-server"
  }
}

# Nested conditionals
locals {
  instance_type = var.environment == "production" ? "t3.large" : (
    var.environment == "staging" ? "t3.medium" : "t3.micro"
  )
}
```

### Count-Based Conditionals

```hcl
variable "create_database" {
  description = "Whether to create database"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Conditional resource creation
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier     = "main-database"
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
}

# Environment-based conditional creation
resource "aws_db_instance" "replica" {
  count = var.environment == "production" ? 1 : 0
  
  identifier             = "main-database-replica"
  replicate_source_db    = aws_db_instance.main[0].id
  instance_class         = "db.t3.micro"
}

# Multiple conditions
resource "aws_cloudwatch_log_group" "app" {
  count = var.environment == "production" && var.enable_logging ? 1 : 0
  
  name              = "/aws/application/${var.app_name}"
  retention_in_days = 30
}
```

### For_each Conditionals

```hcl
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    create_monitoring = bool
    instance_type     = string
    backup_enabled    = bool
  }))
  
  default = {
    dev = {
      create_monitoring = false
      instance_type     = "t3.micro"
      backup_enabled    = false
    }
    prod = {
      create_monitoring = true
      instance_type     = "t3.large"
      backup_enabled    = true
    }
  }
}

# Conditional for_each based on environment settings
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = {
    for env, config in var.environments : env => config
    if config.create_monitoring
  }
  
  alarm_name          = "${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
}
```

## Advanced Conditional Patterns

### Complex Boolean Logic

```hcl
variable "environment" {
  type = string
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "instance_count" {
  type    = number
  default = 1
}

locals {
  # Complex conditional logic
  is_production = var.environment == "production"
  is_high_availability = var.instance_count > 1
  needs_monitoring = var.enable_monitoring || local.is_production
  
  # Multi-condition logic
  enable_backup = (
    local.is_production ||
    (var.environment == "staging" && local.is_high_availability)
  )
  
  # Conditional with validation
  instance_type = (
    local.is_production && local.is_high_availability ? "t3.xlarge" :
    local.is_production ? "t3.large" :
    var.environment == "staging" ? "t3.medium" :
    "t3.micro"
  )
}

resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  monitoring    = local.needs_monitoring
  
  # Conditional block
  dynamic "ebs_block_device" {
    for_each = local.enable_backup ? [1] : []
    content {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 100
      encrypted   = true
    }
  }
}
```

### Conditional Resource Configuration

```hcl
variable "ssl_certificate_arn" {
  description = "SSL certificate ARN (optional)"
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Enable WAF protection"
  type        = bool
  default     = false
}

resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  
  # Conditional security groups
  security_groups = concat(
    [aws_security_group.alb.id],
    var.enable_waf ? [aws_security_group.waf[0].id] : []
  )
  
  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.ssl_certificate_arn != null ? "443" : "80"
  protocol          = var.ssl_certificate_arn != null ? "HTTPS" : "HTTP"
  
  # Conditional SSL configuration
  ssl_policy      = var.ssl_certificate_arn != null ? "ELBSecurityPolicy-TLS-1-2-2017-01" : null
  certificate_arn = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Conditional WAF security group
resource "aws_security_group" "waf" {
  count = var.enable_waf ? 1 : 0
  
  name_prefix = "waf-sg-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Dynamic Blocks

### Basic Dynamic Blocks

```hcl
variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  
  default = [
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

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = var.vpc_id
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Conditional Dynamic Blocks

```hcl
variable "environment" {
  type = string
}

variable "enable_ssh_access" {
  type    = bool
  default = false
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-sg-"
  vpc_id      = var.vpc_id
  
  # Always allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Conditional SSH access
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "SSH access"
    }
  }
  
  # Production-only HTTPS
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
}
```

### Nested Dynamic Blocks

```hcl
variable "load_balancer_config" {
  description = "Load balancer configuration"
  type = object({
    listeners = list(object({
      port     = number
      protocol = string
      rules = list(object({
        priority = number
        conditions = list(object({
          field  = string
          values = list(string)
        }))
        actions = list(object({
          type               = string
          target_group_arn   = string
          redirect_config    = optional(object({
            status_code = string
            host        = string
            path        = string
          }))
        }))
      }))
    }))
  })
}

resource "aws_lb_listener" "app" {
  for_each = {
    for idx, listener in var.load_balancer_config.listeners : idx => listener
  }
  
  load_balancer_arn = aws_lb.main.arn
  port              = each.value.port
  protocol          = each.value.protocol
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
  
  # Dynamic listener rules
  dynamic "rule" {
    for_each = each.value.rules
    content {
      priority = rule.value.priority
      
      # Dynamic conditions
      dynamic "condition" {
        for_each = rule.value.conditions
        content {
          field  = condition.value.field
          values = condition.value.values
        }
      }
      
      # Dynamic actions
      dynamic "action" {
        for_each = rule.value.actions
        content {
          type             = action.value.type
          target_group_arn = action.value.target_group_arn
          
          # Conditional redirect configuration
          dynamic "redirect" {
            for_each = action.value.redirect_config != null ? [action.value.redirect_config] : []
            content {
              status_code = redirect.value.status_code
              host        = redirect.value.host
              path        = redirect.value.path
            }
          }
        }
      }
    }
  }
}
```

### Dynamic Blocks with Complex Logic

```hcl
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine                = string
    instance_class        = string
    allocated_storage     = number
    backup_retention_period = number
    
    # Optional configurations
    read_replicas = optional(list(object({
      identifier      = string
      instance_class  = string
      region         = optional(string)
    })), [])
    
    parameter_groups = optional(list(object({
      name = string
      parameters = list(object({
        name  = string
        value = string
      }))
    })), [])
  })
}

resource "aws_db_instance" "main" {
  identifier     = "main-database"
  engine         = var.database_config.engine
  instance_class = var.database_config.instance_class
  allocated_storage = var.database_config.allocated_storage
  backup_retention_period = var.database_config.backup_retention_period
}

# Dynamic read replicas
resource "aws_db_instance" "replica" {
  for_each = {
    for replica in var.database_config.read_replicas : replica.identifier => replica
  }
  
  identifier             = each.value.identifier
  replicate_source_db    = aws_db_instance.main.id
  instance_class         = each.value.instance_class
  
  # Conditional cross-region replica
  provider = each.value.region != null ? aws.replica_region : aws
}

# Dynamic parameter groups
resource "aws_db_parameter_group" "custom" {
  for_each = {
    for pg in var.database_config.parameter_groups : pg.name => pg
  }
  
  family = "${var.database_config.engine}8.0"
  name   = each.value.name
  
  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}
```

## Environment-Specific Conditionals

### Multi-Environment Configuration

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains([
      "development", "staging", "production"
    ], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

locals {
  # Environment-specific configurations
  env_config = {
    development = {
      instance_type         = "t3.micro"
      instance_count        = 1
      enable_monitoring     = false
      backup_retention      = 1
      multi_az             = false
      deletion_protection   = false
      enable_logging       = false
      log_retention_days   = 7
    }
    
    staging = {
      instance_type         = "t3.small"
      instance_count        = 2
      enable_monitoring     = true
      backup_retention      = 7
      multi_az             = false
      deletion_protection   = false
      enable_logging       = true
      log_retention_days   = 14
    }
    
    production = {
      instance_type         = "t3.large"
      instance_count        = 3
      enable_monitoring     = true
      backup_retention      = 30
      multi_az             = true
      deletion_protection   = true
      enable_logging       = true
      log_retention_days   = 90
    }
  }
  
  current_config = local.env_config[var.environment]
}

# Environment-aware resources
resource "aws_instance" "app" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_config.instance_type
  monitoring    = local.current_config.enable_monitoring
  
  tags = {
    Name        = "${var.environment}-app-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-database"
  engine         = "mysql"
  instance_class = "db.t3.micro"
  
  backup_retention_period = local.current_config.backup_retention
  multi_az               = local.current_config.multi_az
  deletion_protection    = local.current_config.deletion_protection
  
  tags = {
    Environment = var.environment
  }
}

# Conditional logging
resource "aws_cloudwatch_log_group" "app" {
  count = local.current_config.enable_logging ? 1 : 0
  
  name              = "/aws/${var.environment}/application"
  retention_in_days = local.current_config.log_retention_days
}
```

### Feature Flags

```hcl
variable "feature_flags" {
  description = "Feature flags configuration"
  type = object({
    enable_caching      = bool
    enable_cdn          = bool
    enable_auto_scaling = bool
    enable_ssl          = bool
    enable_waf          = bool
  })
  
  default = {
    enable_caching      = false
    enable_cdn          = false
    enable_auto_scaling = false
    enable_ssl          = false
    enable_waf          = false
  }
}

# Conditional caching
resource "aws_elasticache_cluster" "redis" {
  count = var.feature_flags.enable_caching ? 1 : 0
  
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
}

# Conditional CDN
resource "aws_cloudfront_distribution" "main" {
  count = var.feature_flags.enable_cdn ? 1 : 0
  
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${aws_lb.main.name}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled = true
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-${aws_lb.main.name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Conditional auto scaling
resource "aws_autoscaling_group" "app" {
  count = var.feature_flags.enable_auto_scaling ? 1 : 0
  
  name                = "${var.environment}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

## Error Handling and Validation

### Conditional Validation

```hcl
variable "ssl_config" {
  description = "SSL configuration"
  type = object({
    enabled         = bool
    certificate_arn = optional(string)
    domain_name     = optional(string)
  })
  
  validation {
    condition = (
      !var.ssl_config.enabled ||
      (var.ssl_config.enabled && var.ssl_config.certificate_arn != null)
    )
    error_message = "Certificate ARN is required when SSL is enabled."
  }
  
  validation {
    condition = (
      !var.ssl_config.enabled ||
      (var.ssl_config.enabled && var.ssl_config.domain_name != null)
    )
    error_message = "Domain name is required when SSL is enabled."
  }
}
```

### Safe Conditionals with Try

```hcl
variable "optional_config" {
  description = "Optional configuration"
  type = object({
    database = optional(object({
      engine = string
      size   = string
    }))
    cache = optional(object({
      engine = string
      size   = string
    }))
  })
  default = {}
}

locals {
  # Safe access to optional nested values
  database_engine = try(var.optional_config.database.engine, "mysql")
  database_size   = try(var.optional_config.database.size, "db.t3.micro")
  
  cache_engine = try(var.optional_config.cache.engine, "redis")
  cache_size   = try(var.optional_config.cache.size, "cache.t3.micro")
  
  # Conditional resource creation with safe access
  create_database = try(var.optional_config.database != null, false)
  create_cache    = try(var.optional_config.cache != null, false)
}

resource "aws_db_instance" "main" {
  count = local.create_database ? 1 : 0
  
  identifier     = "main-database"
  engine         = local.database_engine
  instance_class = local.database_size
}

resource "aws_elasticache_cluster" "main" {
  count = local.create_cache ? 1 : 0
  
  cluster_id  = "main-cache"
  engine      = local.cache_engine
  node_type   = local.cache_size
}
```

## Testing Conditional Logic

### Test Scenarios

```hcl
# test-conditionals.tf
variable "test_scenarios" {
  description = "Test scenarios for conditional logic"
  type = map(object({
    environment     = string
    feature_flags   = map(bool)
    expected_resources = map(number)
  }))
  
  default = {
    development = {
      environment = "development"
      feature_flags = {
        enable_monitoring = false
        enable_backup     = false
        enable_ssl        = false
      }
      expected_resources = {
        instances    = 1
        databases    = 0
        load_balancers = 0
      }
    }
    
    production = {
      environment = "production"
      feature_flags = {
        enable_monitoring = true
        enable_backup     = true
        enable_ssl        = true
      }
      expected_resources = {
        instances    = 3
        databases    = 1
        load_balancers = 1
      }
    }
  }
}
```

### Testing Script

```bash
#!/bin/bash
# test-conditional-logic.sh

echo "Testing conditional logic..."

scenarios=("development" "staging" "production")

for scenario in "${scenarios[@]}"; do
    echo "Testing scenario: $scenario"
    
    # Apply configuration
    terraform apply -auto-approve -var="environment=$scenario"
    
    # Validate expected resources
    instance_count=$(terraform state list | grep aws_instance | wc -l)
    database_count=$(terraform state list | grep aws_db_instance | wc -l)
    
    echo "Instances created: $instance_count"
    echo "Databases created: $database_count"
    
    # Cleanup
    terraform destroy -auto-approve -var="environment=$scenario"
done

echo "All conditional logic tests completed!"
```

## Best Practices

### 1. Readable Conditionals

```hcl
# Good: Clear and readable
locals {
  is_production = var.environment == "production"
  needs_high_availability = local.is_production && var.instance_count > 1
  
  instance_type = local.needs_high_availability ? "t3.large" : "t3.micro"
}

# Avoid: Complex nested conditionals
locals {
  instance_type = var.environment == "production" ? (var.instance_count > 1 ? "t3.large" : "t3.medium") : (var.environment == "staging" ? "t3.small" : "t3.micro")
}
```

### 2. Consistent Patterns

```hcl
# Use consistent conditional patterns
resource "aws_instance" "web" {
  count = var.create_web_servers ? var.web_server_count : 0
  # ... configuration
}

resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  # ... configuration
}

resource "aws_elasticache_cluster" "redis" {
  count = var.create_cache ? 1 : 0
  # ... configuration
}
```

### 3. Environment Validation

```hcl
# Validate environment-specific requirements
locals {
  # Ensure production has proper configuration
  production_validation = var.environment == "production" ? (
    var.backup_enabled && var.monitoring_enabled && var.multi_az_enabled
  ) : true
  
  validation_check = local.production_validation ? null : file("ERROR: Production environment requires backup, monitoring, and multi-AZ")
}
```

## Conclusion

Conditional logic and dynamic blocks enable:
- **Flexible Configurations**: Adapt infrastructure based on conditions
- **Environment Awareness**: Different behavior per environment
- **Feature Flags**: Enable/disable features dynamically
- **Resource Optimization**: Create only needed resources

Key takeaways:
- Use ternary operators for simple conditionals
- Leverage count and for_each for conditional resource creation
- Implement dynamic blocks for variable resource configurations
- Structure environment-specific logic clearly
- Validate conditional requirements
- Test conditional scenarios thoroughly
