# Problem 32: Cost Optimization and FinOps
# Comprehensive cost optimization patterns and financial operations

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local values for cost optimization
locals {
  # Cost allocation tags
  cost_tags = {
    Project     = var.project_name
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    Application = var.application_name
    ManagedBy   = "Terraform"
  }
  
  # Instance type mapping for cost optimization
  instance_types = {
    dev = {
      web = "t3.micro"
      app = "t3.small"
      db  = "db.t3.micro"
    }
    staging = {
      web = "t3.small"
      app = "t3.medium"
      db  = "db.t3.small"
    }
    production = {
      web = "t3.medium"
      app = "t3.large"
      db  = "db.t3.medium"
    }
  }
  
  # Spot instance configuration
  spot_config = {
    max_price = var.spot_max_price
    instance_interruption_behavior = "terminate"
    spot_instance_type = "one-time"
  }
}

# Cost budgets for monitoring
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters {
    tag {
      key    = "Project"
      values = [var.project_name]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  tags = local.cost_tags
}

# VPC with cost-optimized configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Subnets with minimal configuration
resource "aws_subnet" "public" {
  count = var.environment == "production" ? 3 : 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = var.environment == "production" ? 3 : 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Cost-optimized NAT Gateway (single for non-prod)
resource "aws_nat_gateway" "main" {
  count = var.environment == "production" ? length(aws_subnet.public) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-nat-${count.index + 1}"
  })
}

resource "aws_eip" "nat" {
  count  = var.environment == "production" ? length(aws_subnet.public) : 1
  domain = "vpc"

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

# Launch template with mixed instance types and spot instances
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.instance_types[var.environment].web
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web.id]

  # Instance metadata service v2 (free)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Cost-optimized storage
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.environment == "production" ? 20 : 10
      volume_type = "gp3"  # More cost-effective than gp2
      encrypted   = true
      throughput  = 125    # Baseline throughput
      iops        = 3000   # Baseline IOPS
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.cost_tags, {
      Name = "${var.project_name}-web"
      Tier = "Web"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Auto Scaling Group with mixed instances and spot
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = var.scaling_config.min_size
  max_size         = var.scaling_config.max_size
  desired_capacity = var.scaling_config.desired_capacity

  # Mixed instances policy for cost optimization
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web.id
        version           = "$Latest"
      }

      # Multiple instance types for better spot availability
      override {
        instance_type = local.instance_types[var.environment].web
      }
      
      override {
        instance_type = var.environment == "production" ? "t3.small" : "t3.nano"
      }
    }

    # Spot instances for cost savings
    instances_distribution {
      on_demand_base_capacity                  = var.environment == "production" ? 1 : 0
      on_demand_percentage_above_base_capacity = var.environment == "production" ? 25 : 0
      spot_allocation_strategy                 = "diversified"
      spot_instance_pools                      = 3
      spot_max_price                          = var.spot_max_price
    }
  }

  # Instance refresh for cost optimization
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.cost_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Application Load Balancer (cost-optimized)
resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  # Disable deletion protection for non-prod to save costs
  enable_deletion_protection = var.environment == "production"

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
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

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-web-tg"
  })
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# RDS with cost optimization
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = local.instance_types[var.environment].db

  # Cost-optimized storage
  allocated_storage     = var.environment == "production" ? 100 : 20
  max_allocated_storage = var.environment == "production" ? 1000 : 100
  storage_type          = "gp3"  # More cost-effective
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Backup configuration based on environment
  backup_retention_period = var.environment == "production" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Multi-AZ only for production
  multi_az = var.environment == "production"

  # Performance Insights only for production
  performance_insights_enabled = var.environment == "production"
  monitoring_interval         = var.environment == "production" ? 60 : 0

  skip_final_snapshot = var.environment != "production"

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-db"
  })
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Security groups
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-db-sg"
  })
}

# S3 bucket with lifecycle policies for cost optimization
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-bucket"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete old versions
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CloudWatch with cost-optimized retention
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-logs"
  })
}

# Cost anomaly detection
resource "aws_ce_anomaly_detector" "main" {
  name         = "${var.project_name}-cost-anomaly-detector"
  monitor_type = "DIMENSIONAL"

  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["EC2-Instance", "Amazon Relational Database Service", "Amazon Simple Storage Service"]
  })

  tags = local.cost_tags
}

resource "aws_ce_anomaly_subscription" "main" {
  name      = "${var.project_name}-cost-anomaly-subscription"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.main.arn
  ]
  
  subscriber {
    type    = "EMAIL"
    address = var.cost_anomaly_email
  }

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = [tostring(var.cost_anomaly_threshold)]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }

  tags = local.cost_tags
}

# Savings Plans recommendation (informational)
data "aws_ce_cost_category" "savings_plans" {
  cost_category_arn = "arn:aws:ce::${data.aws_caller_identity.current.account_id}:costcategory/SavingsPlans"
}

data "aws_caller_identity" "current" {}

# Reserved Instance recommendations via Cost Explorer
resource "aws_ce_cost_category" "project" {
  name         = "${var.project_name}-cost-category"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = var.project_name
    rule {
      dimension {
        key           = "TAG"
        values        = ["Project$${var.project_name}"]
        match_options = ["EQUALS"]
      }
    }
  }

  tags = local.cost_tags
}
