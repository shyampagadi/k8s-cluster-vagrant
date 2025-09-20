# Terraform Lifecycle Rules - Complete Guide

## Overview

This comprehensive guide covers Terraform lifecycle rules, including create_before_destroy, prevent_destroy, ignore_changes, and advanced lifecycle management patterns for production environments.

## Lifecycle Rules Fundamentals

### Basic Lifecycle Block

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes       = []
  }
  
  tags = {
    Name = "web-server"
  }
}
```

## Create Before Destroy

### Basic Usage

```hcl
# Launch template that needs replacement
resource "aws_launch_template" "app" {
  name_prefix   = "app-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_version = var.app_version
  }))
  
  lifecycle {
    create_before_destroy = true
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-instance"
    }
  }
}

# Auto Scaling Group using the launch template
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  # Ensure new launch template is created before destroying old one
  lifecycle {
    create_before_destroy = true
  }
  
  tag {
    key                 = "Name"
    value               = "app-asg"
    propagate_at_launch = false
  }
}
```

### Advanced Create Before Destroy

```hcl
# Security group with create_before_destroy
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
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
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "web-security-group"
  }
}

# Load balancer target group with zero-downtime updates
resource "aws_lb_target_group" "app" {
  name_prefix = "app-tg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "app-target-group"
  }
}

# Database parameter group with safe updates
resource "aws_db_parameter_group" "app" {
  family      = "mysql8.0"
  name_prefix = "app-params-"
  
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
  
  parameter {
    name  = "max_connections"
    value = "1000"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "app-db-parameters"
  }
}
```

## Prevent Destroy

### Critical Resource Protection

```hcl
# Production database with destroy protection
resource "aws_db_instance" "production" {
  identifier = "production-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.xlarge"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "production"
  username = "admin"
  password = random_password.db_password.result
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "production-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
  
  tags = {
    Name        = "production-database"
    Environment = "production"
    Critical    = "true"
  }
}

# S3 bucket for critical data
resource "aws_s3_bucket" "critical_data" {
  bucket = "company-critical-data-${random_id.bucket_suffix.hex}"
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "critical-data-bucket"
    Environment = "production"
    DataClass   = "critical"
  }
}

# S3 bucket versioning (critical for data protection)
resource "aws_s3_bucket_versioning" "critical_data" {
  bucket = aws_s3_bucket.critical_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# KMS key for encryption
resource "aws_kms_key" "critical_data" {
  description             = "KMS key for critical data encryption"
  deletion_window_in_days = 30
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "critical-data-key"
  }
}
```

### Conditional Prevent Destroy

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-database"
  
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  
  db_name  = "application"
  username = "admin"
  password = random_password.db_password.result
  
  # Conditional lifecycle rules
  lifecycle {
    prevent_destroy = var.environment == "production" ? true : var.enable_deletion_protection
  }
  
  tags = {
    Name        = "${var.environment}-database"
    Environment = var.environment
  }
}
```

## Ignore Changes

### Ignoring Specific Attributes

```hcl
# Instance with ignored AMI changes (for auto-patching)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = var.subnet_id
  
  # Ignore AMI changes (managed by external patching process)
  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
  
  tags = {
    Name = "web-server"
  }
}

# Auto Scaling Group ignoring desired capacity
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  vpc_zone_identifier = var.subnet_ids
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  # Ignore desired capacity changes (managed by auto scaling policies)
  lifecycle {
    ignore_changes = [
      desired_capacity,
      target_group_arns  # May be modified by external load balancer management
    ]
  }
}

# RDS instance ignoring password changes
resource "aws_db_instance" "app" {
  identifier = "app-database"
  
  engine         = "mysql"
  instance_class = var.db_instance_class
  allocated_storage = var.db_storage_size
  
  db_name  = "application"
  username = "admin"
  password = var.db_password
  
  # Ignore password changes (managed by external rotation)
  lifecycle {
    ignore_changes = [
      password,
      latest_restorable_time  # This changes frequently
    ]
  }
  
  tags = {
    Name = "app-database"
  }
}
```

### Ignoring Tags

```hcl
# Resource with externally managed tags
resource "aws_instance" "monitored" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  tags = {
    Name        = "monitored-instance"
    Environment = var.environment
    Project     = var.project_name
  }
  
  # Ignore tag changes made by external systems (monitoring, cost allocation, etc.)
  lifecycle {
    ignore_changes = [
      tags["LastPatched"],
      tags["MonitoringAgent"],
      tags["CostCenter"],
      tags["Owner"]
    ]
  }
}

# Alternative: Ignore all tag changes
resource "aws_s3_bucket" "logs" {
  bucket = "application-logs-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "application-logs"
    Environment = var.environment
  }
  
  # Ignore all tag changes
  lifecycle {
    ignore_changes = [tags]
  }
}
```

## Complex Lifecycle Scenarios

### Blue-Green Deployment Pattern

```hcl
variable "active_environment" {
  description = "Active environment (blue or green)"
  type        = string
  default     = "blue"
  
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be 'blue' or 'green'."
  }
}

# Blue environment
resource "aws_launch_template" "blue" {
  name_prefix   = "app-blue-"
  image_id      = var.blue_ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = "blue"
    app_version = var.blue_app_version
  }))
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "blue" {
  name                = "app-blue-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.active_environment == "blue" ? [aws_lb_target_group.app.arn] : []
  
  min_size         = var.active_environment == "blue" ? var.min_size : 0
  max_size         = var.active_environment == "blue" ? var.max_size : 0
  desired_capacity = var.active_environment == "blue" ? var.desired_capacity : 0
  
  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}

# Green environment
resource "aws_launch_template" "green" {
  name_prefix   = "app-green-"
  image_id      = var.green_ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = "green"
    app_version = var.green_app_version
  }))
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "app-green-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.active_environment == "green" ? [aws_lb_target_group.app.arn] : []
  
  min_size         = var.active_environment == "green" ? var.min_size : 0
  max_size         = var.active_environment == "green" ? var.max_size : 0
  desired_capacity = var.active_environment == "green" ? var.desired_capacity : 0
  
  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}
```

### Database Migration Pattern

```hcl
variable "database_migration_phase" {
  description = "Database migration phase"
  type        = string
  default     = "stable"
  
  validation {
    condition = contains([
      "stable", "preparation", "migration", "validation", "cleanup"
    ], var.database_migration_phase)
    error_message = "Invalid migration phase."
  }
}

# Current production database
resource "aws_db_instance" "current" {
  identifier = "production-db-current"
  
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.r5.xlarge"
  
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = "production"
  username = "admin"
  password = random_password.current_db_password.result
  
  backup_retention_period = 30
  
  lifecycle {
    prevent_destroy = var.database_migration_phase != "cleanup"
    ignore_changes = var.database_migration_phase == "migration" ? [
      backup_retention_period,
      backup_window,
      maintenance_window
    ] : []
  }
  
  tags = {
    Name = "production-db-current"
    Phase = var.database_migration_phase
  }
}

# New database for migration
resource "aws_db_instance" "new" {
  count = contains(["preparation", "migration", "validation"], var.database_migration_phase) ? 1 : 0
  
  identifier = "production-db-new"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.xlarge"
  
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = "production"
  username = "admin"
  password = random_password.new_db_password.result
  
  backup_retention_period = 30
  
  lifecycle {
    prevent_destroy = true
    create_before_destroy = true
  }
  
  tags = {
    Name = "production-db-new"
    Phase = var.database_migration_phase
  }
}
```

## Lifecycle Rules Best Practices

### Environment-Specific Lifecycle Rules

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

locals {
  # Environment-specific lifecycle settings
  lifecycle_settings = {
    development = {
      prevent_destroy       = false
      create_before_destroy = false
      ignore_changes       = []
    }
    staging = {
      prevent_destroy       = false
      create_before_destroy = true
      ignore_changes       = ["tags"]
    }
    production = {
      prevent_destroy       = true
      create_before_destroy = true
      ignore_changes       = ["tags", "user_data"]
    }
  }
  
  current_settings = local.lifecycle_settings[var.environment]
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  subnet_id              = var.subnet_id
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))
  
  # Dynamic lifecycle rules based on environment
  lifecycle {
    prevent_destroy       = local.current_settings.prevent_destroy
    create_before_destroy = local.current_settings.create_before_destroy
    ignore_changes       = local.current_settings.ignore_changes
  }
  
  tags = {
    Name        = "${var.environment}-app-instance"
    Environment = var.environment
  }
}
```

### Conditional Lifecycle Rules

```hcl
variable "enable_zero_downtime_updates" {
  description = "Enable zero-downtime updates"
  type        = bool
  default     = true
}

variable "protect_from_deletion" {
  description = "Protect resources from deletion"
  type        = bool
  default     = false
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  lifecycle {
    create_before_destroy = var.enable_zero_downtime_updates
    prevent_destroy       = var.protect_from_deletion
    
    ignore_changes = var.environment == "production" ? [
      "user_data",  # Managed by external configuration management
      "tags.LastUpdated"
    ] : []
  }
}
```

## Troubleshooting Lifecycle Rules

### Common Issues and Solutions

```hcl
# Issue 1: Dependency conflicts with create_before_destroy
resource "aws_security_group" "app" {
  name = "app-sg"  # Fixed name causes issues with create_before_destroy
  vpc_id = aws_vpc.main.id
  
  lifecycle {
    create_before_destroy = true
  }
}

# Solution: Use name_prefix instead
resource "aws_security_group" "app" {
  name_prefix = "app-sg-"  # Allows unique names
  vpc_id      = aws_vpc.main.id
  
  lifecycle {
    create_before_destroy = true
  }
}

# Issue 2: Prevent destroy blocking legitimate updates
resource "aws_db_instance" "main" {
  identifier = "main-db"
  
  engine         = "mysql"
  engine_version = "5.7"  # Want to upgrade to 8.0
  
  lifecycle {
    prevent_destroy = true  # Blocks engine version upgrade
  }
}

# Solution: Temporarily disable prevent_destroy for major updates
resource "aws_db_instance" "main" {
  identifier = "main-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  
  lifecycle {
    prevent_destroy = false  # Temporarily disabled for upgrade
    # Re-enable after upgrade: prevent_destroy = true
  }
}
```

### Debugging Lifecycle Issues

```bash
# Check for lifecycle-related errors
terraform plan -detailed-exitcode

# Validate configuration
terraform validate

# Force replacement (bypasses create_before_destroy)
terraform apply -replace="aws_instance.web"

# Import existing resources with lifecycle rules
terraform import aws_instance.web i-1234567890abcdef0
```

## Advanced Lifecycle Patterns

### Gradual Rollout Pattern

```hcl
variable "rollout_percentage" {
  description = "Percentage of instances to update"
  type        = number
  default     = 0
  
  validation {
    condition     = var.rollout_percentage >= 0 && var.rollout_percentage <= 100
    error_message = "Rollout percentage must be between 0 and 100."
  }
}

locals {
  total_instances = 10
  instances_to_update = floor(local.total_instances * var.rollout_percentage / 100)
}

# Old version instances
resource "aws_instance" "app_old" {
  count = local.total_instances - local.instances_to_update
  
  ami           = var.old_ami_id
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name    = "app-old-${count.index}"
    Version = "old"
  }
}

# New version instances
resource "aws_instance" "app_new" {
  count = local.instances_to_update
  
  ami           = var.new_ami_id
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name    = "app-new-${count.index}"
    Version = "new"
  }
}
```

## Best Practices Summary

### 1. Use create_before_destroy for Zero-Downtime Updates

```hcl
# Good: For resources that need zero-downtime replacement
resource "aws_launch_template" "app" {
  name_prefix = "app-"
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### 2. Apply prevent_destroy to Critical Resources

```hcl
# Good: Protect critical data
resource "aws_db_instance" "production" {
  identifier = "prod-db"
  
  lifecycle {
    prevent_destroy = true
  }
}
```

### 3. Use ignore_changes Judiciously

```hcl
# Good: Ignore externally managed attributes
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  
  lifecycle {
    ignore_changes = [
      ami,  # Managed by patching process
      tags["LastPatched"]  # Updated by external system
    ]
  }
}
```

### 4. Environment-Specific Lifecycle Rules

```hcl
# Good: Different rules for different environments
lifecycle {
  prevent_destroy = var.environment == "production"
  create_before_destroy = var.environment != "development"
}
```

## Conclusion

Lifecycle rules enable:
- **Zero-Downtime Updates**: Safe resource replacement
- **Data Protection**: Prevent accidental deletion
- **External Integration**: Ignore externally managed changes
- **Flexible Operations**: Environment-specific behaviors

Key takeaways:
- Use create_before_destroy for zero-downtime updates
- Apply prevent_destroy to critical resources
- Use ignore_changes for externally managed attributes
- Implement environment-specific lifecycle rules
- Test lifecycle rules in non-production environments
- Document complex lifecycle scenarios
