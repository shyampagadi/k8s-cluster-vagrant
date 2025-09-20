# Problem 5: Terraform Resource Lifecycle Mastery

## Resource Lifecycle Fundamentals

### What is Resource Lifecycle?
Resource lifecycle in Terraform refers to how resources are created, updated, and destroyed throughout their existence. Understanding lifecycle management is crucial for maintaining stable infrastructure.

### Terraform Resource Lifecycle Phases
1. **Create** - Resource is provisioned for the first time
2. **Read** - Terraform refreshes resource state from the provider
3. **Update** - Resource is modified in place or replaced
4. **Delete** - Resource is destroyed and removed

## Basic Lifecycle Management

### Standard Resource Lifecycle
```hcl
# Basic resource creation
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server"
  }
}

# Lifecycle phases:
# 1. terraform plan  -> Shows resource will be created
# 2. terraform apply -> Creates the resource
# 3. Modify configuration -> Shows resource will be updated
# 4. terraform apply -> Updates the resource
# 5. terraform destroy -> Destroys the resource
```

### Resource Dependencies
```hcl
# Implicit dependencies (automatic)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "web-subnet"
  }
}

resource "aws_instance" "web" {
  ami       = "ami-0c02fb55956c7d316"
  subnet_id = aws_subnet.web.id  # Implicit dependency on subnet
  
  tags = {
    Name = "web-server"
  }
}

# Explicit dependencies (manual)
resource "aws_instance" "app" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  # Explicit dependency - ensures web server is created first
  depends_on = [aws_instance.web]
  
  tags = {
    Name = "app-server"
  }
}
```

## Lifecycle Rules and Meta-Arguments

### create_before_destroy
```hcl
# Problem: Default behavior destroys old resource before creating new one
# This can cause downtime for critical resources

resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  # Ensure new launch template is created before old one is destroyed
  lifecycle {
    create_before_destroy = true
  }
}

# Use case: Auto Scaling Groups
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # Critical for zero-downtime deployments
  lifecycle {
    create_before_destroy = true
  }
  
  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}
```

### prevent_destroy
```hcl
# Protect critical resources from accidental destruction
resource "aws_s3_bucket" "critical_data" {
  bucket = "${var.project_name}-critical-data"
  
  # Prevents terraform destroy from deleting this bucket
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Critical Data Bucket"
    Environment = "production"
  }
}

# Production database protection
resource "aws_db_instance" "production" {
  identifier = "${var.project_name}-prod-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.medium"
  
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Prevent accidental deletion of production database
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Production Database"
    Environment = "production"
  }
}
```

### ignore_changes
```hcl
# Ignore changes to specific attributes
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # User data might be modified by configuration management tools
  user_data = file("${path.module}/user-data.sh")
  
  lifecycle {
    # Ignore changes to AMI and user_data after initial creation
    ignore_changes = [
      ami,
      user_data,
    ]
  }
  
  tags = {
    Name = "web-server"
  }
}

# Ignore all tag changes (useful when tags are managed externally)
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-app-data"
  
  lifecycle {
    ignore_changes = [tags]
  }
}

# Ignore changes to auto-scaling capacity (managed by auto-scaling policies)
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = var.subnet_ids
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  lifecycle {
    # Let auto-scaling policies manage capacity
    ignore_changes = [desired_capacity]
  }
}
```

### replace_triggered_by
```hcl
# Force replacement when specific resources change
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Replace instance when launch template changes
  lifecycle {
    replace_triggered_by = [
      aws_launch_template.web
    ]
  }
  
  tags = {
    Name = "web-server"
  }
}

# Replace instances when configuration changes
resource "random_id" "config_hash" {
  byte_length = 8
  
  keepers = {
    config_file = filemd5("${path.module}/app-config.json")
  }
}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  lifecycle {
    replace_triggered_by = [
      random_id.config_hash
    ]
  }
  
  tags = {
    Name        = "app-server"
    ConfigHash  = random_id.config_hash.hex
  }
}
```

## Advanced Lifecycle Patterns

### Blue-Green Deployments
```hcl
# Blue-Green deployment pattern
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
resource "aws_instance" "blue" {
  count = var.active_environment == "blue" ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name        = "${var.project_name}-blue-${count.index + 1}"
    Environment = "blue"
  }
}

# Green environment
resource "aws_instance" "green" {
  count = var.active_environment == "green" ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name        = "${var.project_name}-green-${count.index + 1}"
    Environment = "green"
  }
}

# Load balancer targets active environment
resource "aws_lb_target_group_attachment" "active" {
  count = var.instance_count
  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = var.active_environment == "blue" ? aws_instance.blue[count.index].id : aws_instance.green[count.index].id
  port             = 80
}
```

### Rolling Updates
```hcl
# Rolling update pattern with instance refresh
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    app_version = var.app_version
  }))
  
  lifecycle {
    create_before_destroy = true
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # Enable instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
    triggers = ["tag"]
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Version"
    value               = var.app_version
    propagate_at_launch = true
  }
}
```

### Canary Deployments
```hcl
# Canary deployment with weighted routing
variable "canary_percentage" {
  description = "Percentage of traffic to route to canary"
  type        = number
  default     = 0
  
  validation {
    condition     = var.canary_percentage >= 0 && var.canary_percentage <= 100
    error_message = "Canary percentage must be between 0 and 100."
  }
}

# Production instances
resource "aws_instance" "production" {
  count = var.production_instance_count
  
  ami           = var.production_ami_id
  instance_type = var.instance_type
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "${var.project_name}-prod-${count.index + 1}"
    Type = "production"
  }
}

# Canary instances (only created if canary_percentage > 0)
resource "aws_instance" "canary" {
  count = var.canary_percentage > 0 ? var.canary_instance_count : 0
  
  ami           = var.canary_ami_id
  instance_type = var.instance_type
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "${var.project_name}-canary-${count.index + 1}"
    Type = "canary"
  }
}

# Weighted target groups
resource "aws_lb_target_group" "production" {
  name     = "${var.project_name}-prod-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "canary" {
  count = var.canary_percentage > 0 ? 1 : 0
  
  name     = "${var.project_name}-canary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

# Weighted routing
resource "aws_lb_listener_rule" "canary" {
  count = var.canary_percentage > 0 ? 1 : 0
  
  listener_arn = aws_lb_listener.web.arn
  priority     = 100
  
  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.production.arn
        weight = 100 - var.canary_percentage
      }
      
      target_group {
        arn    = aws_lb_target_group.canary[0].arn
        weight = var.canary_percentage
      }
    }
  }
  
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

## Resource State Management

### State Refresh and Drift Detection
```hcl
# Terraform automatically refreshes state during plan/apply
# Manual refresh: terraform refresh

# Detect configuration drift
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # If someone manually changes the instance type in AWS console,
  # Terraform will detect the drift and show it in the plan
  
  tags = {
    Name = "web-server"
  }
}

# Use data sources to detect external changes
data "aws_instance" "web" {
  instance_id = aws_instance.web.id
}

# Compare actual vs expected state
locals {
  instance_type_drift = data.aws_instance.web.instance_type != var.instance_type
}

output "drift_detected" {
  value = local.instance_type_drift ? "Instance type has drifted!" : "No drift detected"
}
```

### Resource Import and Adoption
```bash
# Import existing resources into Terraform state
terraform import aws_instance.web i-1234567890abcdef0

# Import with for_each
terraform import 'aws_instance.web["web-1"]' i-1234567890abcdef0
terraform import 'aws_instance.web["web-2"]' i-0987654321fedcba0
```

```hcl
# Configuration for imported resources
resource "aws_instance" "web" {
  for_each = {
    "web-1" = "i-1234567890abcdef0"
    "web-2" = "i-0987654321fedcba0"
  }
  
  # Configuration must match existing resources
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = each.key
  }
  
  lifecycle {
    # Ignore changes during initial import
    ignore_changes = [ami, user_data]
  }
}
```

### Resource Replacement Strategies
```hcl
# Force resource replacement
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Change this value to force replacement
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    timestamp = timestamp()  # Forces replacement on every apply
  }))
  
  tags = {
    Name = "web-server"
  }
}

# Controlled replacement with keepers
resource "random_id" "instance_id" {
  byte_length = 8
  
  keepers = {
    ami_id        = var.ami_id
    instance_type = var.instance_type
    config_hash   = filemd5("${path.module}/config.json")
  }
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Instance will be replaced when keepers change
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    instance_id = random_id.instance_id.hex
  }))
  
  tags = {
    Name       = "web-server"
    InstanceId = random_id.instance_id.hex
  }
}
```

## Lifecycle Best Practices

### Production-Ready Lifecycle Configuration
```hcl
# Production database with comprehensive lifecycle management
resource "aws_db_instance" "production" {
  identifier = "${var.project_name}-prod-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.xlarge"
  
  allocated_storage     = 500
  max_allocated_storage = 1000
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.database.arn
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-prod-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      password,  # Password managed externally
      final_snapshot_identifier  # Avoid conflicts with timestamp
    ]
  }
  
  tags = {
    Name        = "Production Database"
    Environment = "production"
    Backup      = "required"
  }
}
```

This comprehensive guide covers all aspects of Terraform resource lifecycle management, from basic concepts to advanced deployment patterns and production best practices.
