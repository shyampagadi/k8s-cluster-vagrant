# Problem 14: Terraform Lifecycle Rules Mastery

## Lifecycle Rules Overview

### Available Lifecycle Rules
1. **create_before_destroy** - Create replacement before destroying original
2. **prevent_destroy** - Prevent resource destruction
3. **ignore_changes** - Ignore changes to specific attributes
4. **replace_triggered_by** - Force replacement when other resources change

## Create Before Destroy

### Basic Usage
```hcl
# Launch template with create_before_destroy
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Ensure new template is created before old one is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server"
    }
  }
}

# Auto Scaling Group using the template
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  
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

### Advanced Create Before Destroy
```hcl
# Security group with create_before_destroy
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
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
```

## Prevent Destroy

### Critical Resource Protection
```hcl
# Production database with prevent_destroy
resource "aws_db_instance" "production" {
  identifier = "production-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.xlarge"
  
  allocated_storage     = 500
  max_allocated_storage = 1000
  storage_encrypted     = true
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = true
  
  # Prevent accidental destruction via Terraform
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Production Database"
    Environment = "production"
    Critical    = "true"
  }
}

# Critical S3 bucket protection
resource "aws_s3_bucket" "critical_data" {
  bucket = "${var.project_name}-critical-data-${random_id.bucket_suffix.hex}"
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Critical Data Bucket"
    Environment = "production"
    DataClass   = "critical"
  }
}

resource "aws_s3_bucket_versioning" "critical_data" {
  bucket = aws_s3_bucket.critical_data.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

## Ignore Changes

### Ignoring External Modifications
```hcl
# Instance with ignore_changes for externally managed attributes
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # User data might be modified by configuration management
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
  }))
  
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

# Auto Scaling Group ignoring capacity changes
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
    ignore_changes = [
      desired_capacity,
      target_group_arns,
    ]
  }
  
  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}
```

### Ignoring Tag Changes
```hcl
# Resource with externally managed tags
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-app-data"
  
  lifecycle {
    # Ignore all tag changes (managed by external system)
    ignore_changes = [tags, tags_all]
  }
  
  tags = {
    Name        = "Application Data"
    Environment = var.environment
  }
}

# Selective tag ignoring
resource "aws_instance" "monitored" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  lifecycle {
    # Ignore specific tags that are managed externally
    ignore_changes = [
      tags["LastPatched"],
      tags["MonitoringAgent"],
      tags["BackupStatus"],
    ]
  }
  
  tags = {
    Name         = "monitored-server"
    Environment  = var.environment
    LastPatched  = "managed-externally"
  }
}
```

## Replace Triggered By

### Forced Replacement Patterns
```hcl
# Configuration hash for triggering replacements
resource "random_id" "config_hash" {
  byte_length = 8
  
  keepers = {
    config_file = filemd5("${path.module}/app-config.json")
    script_file = filemd5("${path.module}/deploy-script.sh")
  }
}

# Instance that gets replaced when configuration changes
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    config_hash = random_id.config_hash.hex
  }))
  
  lifecycle {
    replace_triggered_by = [
      random_id.config_hash
    ]
  }
  
  tags = {
    Name       = "app-server"
    ConfigHash = random_id.config_hash.hex
  }
}
```

### Complex Replacement Triggers
```hcl
# Multiple trigger sources
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  lifecycle {
    replace_triggered_by = [
      aws_launch_template.web,
      random_id.deployment_id,
    ]
  }
  
  tags = {
    Name = "web-server"
  }
}

# Deployment tracking
resource "random_id" "deployment_id" {
  byte_length = 4
  
  keepers = {
    ami_id      = var.ami_id
    app_version = var.app_version
    timestamp   = var.force_deployment ? timestamp() : "static"
  }
}
```

This comprehensive guide covers all Terraform lifecycle rules with practical examples for production infrastructure management.
