# Problem 11: Terraform Conditional Logic Mastery

## Conditional Logic Fundamentals

### What is Conditional Logic in Terraform?
Conditional logic allows you to make decisions in your Terraform configurations based on variables, resource attributes, or other conditions. This enables dynamic infrastructure creation that adapts to different environments and requirements.

### Types of Conditional Logic
1. **Ternary Operator** - Simple if/else conditions
2. **Count-based Conditionals** - Create or skip resources
3. **For_each Conditionals** - Dynamic resource sets
4. **Conditional Expressions** - Complex decision making

## Ternary Operator Patterns

### Basic Conditional Expressions
```hcl
# Environment-based instance type selection
variable "environment" {
  description = "Environment name"
  type        = string
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  tags = {
    Name = "web-server"
    Size = var.environment == "production" ? "large" : "small"
  }
}

# Multi-condition ternary
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.environment == "production" ? "db.r5.xlarge" : (
    var.environment == "staging" ? "db.t3.medium" : "db.t3.micro"
  )
  
  allocated_storage = var.environment == "production" ? 500 : (
    var.environment == "staging" ? 100 : 20
  )
  
  backup_retention_period = var.environment == "production" ? 30 : (
    var.environment == "staging" ? 7 : 1
  )
  
  multi_az = var.environment == "production" ? true : false
  
  tags = {
    Name = "${var.project_name}-database"
  }
}
```

### Complex Conditional Logic
```hcl
# Multiple condition evaluation
locals {
  # Determine if high availability is needed
  needs_high_availability = var.environment == "production" || var.critical_workload
  
  # Determine backup strategy
  backup_strategy = var.environment == "production" ? "comprehensive" : (
    var.environment == "staging" ? "standard" : "minimal"
  )
  
  # Calculate instance count based on multiple factors
  instance_count = var.environment == "production" ? (
    var.high_traffic ? 5 : 3
  ) : var.environment == "staging" ? 2 : 1
  
  # Determine storage type
  storage_type = var.performance_tier == "high" ? "io2" : (
    var.performance_tier == "medium" ? "gp3" : "gp2"
  )
}

resource "aws_instance" "web" {
  count = local.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.needs_high_availability ? "t3.large" : "t3.medium"
  
  monitoring = var.environment == "production" || var.enable_detailed_monitoring
  
  root_block_device {
    volume_type = local.storage_type
    volume_size = var.environment == "production" ? 100 : 20
    encrypted   = var.environment != "development"
  }
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
    HA   = local.needs_high_availability ? "enabled" : "disabled"
  }
}
```

## Count-Based Conditional Resources

### Conditional Resource Creation
```hcl
# Create monitoring resources only in production
resource "aws_cloudwatch_dashboard" "main" {
  count = var.environment == "production" ? 1 : 0
  
  dashboard_name = "${var.project_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web[0].id]
          ]
          period = 300
          stat   = "Average"
          region = "us-west-2"
          title  = "EC2 Instance CPU"
        }
      }
    ]
  })
}

# Create backup resources conditionally
resource "aws_backup_vault" "main" {
  count = var.enable_backup ? 1 : 0
  
  name        = "${var.project_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup[0].arn
  
  tags = {
    Name = "${var.project_name}-backup-vault"
  }
}

resource "aws_kms_key" "backup" {
  count = var.enable_backup ? 1 : 0
  
  description             = "KMS key for backup encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name = "${var.project_name}-backup-key"
  }
}

# Create NAT Gateway only if private subnets exist
resource "aws_nat_gateway" "main" {
  count = length(var.private_subnet_cidrs) > 0 ? length(var.public_subnet_cidrs) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs) > 0 ? length(var.public_subnet_cidrs) : 0
  
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}
```

### Environment-Specific Resource Counts
```hcl
# Variable instance counts per environment
locals {
  environment_config = {
    development = {
      web_instances = 1
      app_instances = 1
      db_instances  = 1
      enable_cache  = false
      enable_cdn    = false
    }
    staging = {
      web_instances = 2
      app_instances = 2
      db_instances  = 1
      enable_cache  = true
      enable_cdn    = false
    }
    production = {
      web_instances = 3
      app_instances = 5
      db_instances  = 2
      enable_cache  = true
      enable_cdn    = true
    }
  }
  
  current_config = local.environment_config[var.environment]
}

# Web tier instances
resource "aws_instance" "web" {
  count = local.current_config.web_instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
    Tier = "web"
  }
}

# Application tier instances
resource "aws_instance" "app" {
  count = local.current_config.app_instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "production" ? "t3.large" : "t3.small"
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  
  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
    Tier = "application"
  }
}

# Cache cluster (conditional)
resource "aws_elasticache_cluster" "main" {
  count = local.current_config.enable_cache ? 1 : 0
  
  cluster_id           = "${var.project_name}-cache"
  engine               = "redis"
  node_type            = var.environment == "production" ? "cache.r6g.large" : "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main[0].name
  security_group_ids   = [aws_security_group.cache[0].id]
  
  tags = {
    Name = "${var.project_name}-cache"
  }
}
```

## For_Each Conditional Logic

### Dynamic Resource Sets
```hcl
# Conditional security group rules
variable "security_rules" {
  description = "Security group rules configuration"
  type = map(object({
    enabled     = bool
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  
  default = {
    http = {
      enabled     = true
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    }
    https = {
      enabled     = true
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
    ssh = {
      enabled     = false  # Only enabled in development
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH access"
    }
    rdp = {
      enabled     = false  # Only for Windows instances
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "RDP access"
    }
  }
}

# Filter enabled rules
locals {
  enabled_security_rules = {
    for rule_name, rule_config in var.security_rules :
    rule_name => rule_config
    if rule_config.enabled && (
      rule_name != "ssh" || var.environment == "development"
    ) && (
      rule_name != "rdp" || var.instance_os == "windows"
    )
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = local.enabled_security_rules
  
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.web.id
}
```

### Environment-Specific Resource Maps
```hcl
# Environment-specific subnet configurations
variable "subnet_configs" {
  description = "Subnet configurations per environment"
  type = map(map(object({
    cidr_block = string
    public     = bool
    az_index   = number
  })))
  
  default = {
    development = {
      public_1 = {
        cidr_block = "10.0.1.0/24"
        public     = true
        az_index   = 0
      }
      private_1 = {
        cidr_block = "10.0.11.0/24"
        public     = false
        az_index   = 0
      }
    }
    
    staging = {
      public_1 = {
        cidr_block = "10.0.1.0/24"
        public     = true
        az_index   = 0
      }
      public_2 = {
        cidr_block = "10.0.2.0/24"
        public     = true
        az_index   = 1
      }
      private_1 = {
        cidr_block = "10.0.11.0/24"
        public     = false
        az_index   = 0
      }
      private_2 = {
        cidr_block = "10.0.12.0/24"
        public     = false
        az_index   = 1
      }
    }
    
    production = {
      public_1 = {
        cidr_block = "10.0.1.0/24"
        public     = true
        az_index   = 0
      }
      public_2 = {
        cidr_block = "10.0.2.0/24"
        public     = true
        az_index   = 1
      }
      public_3 = {
        cidr_block = "10.0.3.0/24"
        public     = true
        az_index   = 2
      }
      private_1 = {
        cidr_block = "10.0.11.0/24"
        public     = false
        az_index   = 0
      }
      private_2 = {
        cidr_block = "10.0.12.0/24"
        public     = false
        az_index   = 1
      }
      private_3 = {
        cidr_block = "10.0.13.0/24"
        public     = false
        az_index   = 2
      }
    }
  }
}

# Create subnets based on environment
resource "aws_subnet" "main" {
  for_each = var.subnet_configs[var.environment]
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = each.value.public
  
  tags = {
    Name = "${var.project_name}-${each.key}"
    Type = each.value.public ? "public" : "private"
  }
}
```

## Advanced Conditional Patterns

### Feature Flag Implementation
```hcl
# Feature flags for different capabilities
variable "feature_flags" {
  description = "Feature flags for enabling/disabling functionality"
  type = object({
    enable_monitoring     = bool
    enable_logging       = bool
    enable_backup        = bool
    enable_auto_scaling  = bool
    enable_load_balancer = bool
    enable_cdn          = bool
    enable_waf          = bool
  })
  
  default = {
    enable_monitoring     = true
    enable_logging       = true
    enable_backup        = false
    enable_auto_scaling  = false
    enable_load_balancer = false
    enable_cdn          = false
    enable_waf          = false
  }
}

# Environment-specific feature overrides
locals {
  environment_features = {
    development = merge(var.feature_flags, {
      enable_backup        = false
      enable_auto_scaling  = false
      enable_load_balancer = false
      enable_cdn          = false
      enable_waf          = false
    })
    
    staging = merge(var.feature_flags, {
      enable_backup        = true
      enable_auto_scaling  = true
      enable_load_balancer = true
      enable_cdn          = false
      enable_waf          = false
    })
    
    production = merge(var.feature_flags, {
      enable_backup        = true
      enable_auto_scaling  = true
      enable_load_balancer = true
      enable_cdn          = true
      enable_waf          = true
    })
  }
  
  active_features = local.environment_features[var.environment]
}

# Conditional resources based on feature flags
resource "aws_cloudwatch_log_group" "app" {
  count = local.active_features.enable_logging ? 1 : 0
  
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = var.environment == "production" ? 90 : 30
  
  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_lb" "main" {
  count = local.active_features.enable_load_balancer ? 1 : 0
  
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.main : subnet.id if subnet.map_public_ip_on_launch]
  
  enable_deletion_protection = var.environment == "production"
  
  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_autoscaling_group" "web" {
  count = local.active_features.enable_auto_scaling ? 1 : 0
  
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = [for subnet in aws_subnet.main : subnet.id if !subnet.map_public_ip_on_launch]
  target_group_arns   = local.active_features.enable_load_balancer ? [aws_lb_target_group.web[0].arn] : []
  
  min_size         = var.environment == "production" ? 2 : 1
  max_size         = var.environment == "production" ? 10 : 3
  desired_capacity = var.environment == "production" ? 3 : 2
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }
}
```

### Conditional Validation and Error Handling
```hcl
# Conditional validation based on environment
variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class      = string
    allocated_storage   = number
    backup_retention    = number
    multi_az           = bool
    deletion_protection = bool
  })
  
  validation {
    # Production databases must meet minimum requirements
    condition = var.environment != "production" || (
      var.database_config.allocated_storage >= 100 &&
      var.database_config.backup_retention >= 7 &&
      var.database_config.multi_az == true &&
      var.database_config.deletion_protection == true
    )
    error_message = "Production databases must have at least 100GB storage, 7-day backup retention, multi-AZ enabled, and deletion protection enabled."
  }
  
  validation {
    # Staging databases should have reasonable settings
    condition = var.environment != "staging" || (
      var.database_config.allocated_storage >= 20 &&
      var.database_config.backup_retention >= 1
    )
    error_message = "Staging databases must have at least 20GB storage and 1-day backup retention."
  }
}

# Conditional locals with error checking
locals {
  # Validate environment-specific requirements
  production_requirements_met = var.environment == "production" ? (
    length([for subnet in aws_subnet.main : subnet.id if !subnet.map_public_ip_on_launch]) >= 2 &&
    local.active_features.enable_backup &&
    local.active_features.enable_monitoring
  ) : true
  
  # Error if production requirements not met
  validation_error = local.production_requirements_met ? null : "Production environment requirements not met"
}

# Use validation in resource creation
resource "aws_db_instance" "main" {
  count = local.production_requirements_met ? 1 : 0
  
  identifier = "${var.project_name}-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.database_config.instance_class
  
  allocated_storage   = var.database_config.allocated_storage
  backup_retention_period = var.database_config.backup_retention
  multi_az           = var.database_config.multi_az
  deletion_protection = var.database_config.deletion_protection
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  tags = {
    Name = "${var.project_name}-database"
  }
}
```

This comprehensive guide demonstrates all aspects of conditional logic in Terraform, from simple ternary operators to complex feature flag implementations and environment-specific resource creation patterns.
