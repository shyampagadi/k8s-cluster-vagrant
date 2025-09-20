# Problem 23: Advanced State Management and Team Collaboration
# Comprehensive state management patterns and remote backend configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote backend configuration
  backend "s3" {
    # These values should be provided via backend config file or CLI
    # bucket         = "terraform-state-bucket"
    # key            = "environments/production/terraform.tfstate"
    # region         = "us-west-2"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
    # 
    # Example usage:
    # terraform init -backend-config="backend.hcl"
  }
}

provider "aws" {
  region = var.aws_region
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      StateBackend  = "S3"
      WorkspaceName = terraform.workspace
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for state management
locals {
  # Workspace-specific configurations
  workspace_configs = {
    default = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
    
    development = {
      instance_type = "t3.small"
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
    
    staging = {
      instance_type = "t3.medium"
      min_size     = 2
      max_size     = 5
      desired_size = 3
    }
    
    production = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
      desired_size = 5
    }
  }
  
  # Current workspace configuration
  current_config = local.workspace_configs[terraform.workspace]
  
  # Environment-specific naming
  name_prefix = "${var.project_name}-${terraform.workspace}"
  
  # State management tags
  state_tags = {
    StateFile     = "${var.project_name}/${terraform.workspace}/terraform.tfstate"
    LastModified  = timestamp()
    TerraformVersion = "~> 1.0"
  }
}

# State backend infrastructure (for bootstrapping)
module "state_backend" {
  source = "./modules/state-backend"
  count  = var.create_state_backend ? 1 : 0

  bucket_name        = var.state_bucket_name
  dynamodb_table_name = var.state_lock_table_name
  
  # Enable versioning and encryption
  enable_versioning = true
  enable_encryption = true
  
  # Lifecycle policies for state files
  lifecycle_rules = [
    {
      id     = "state_file_lifecycle"
      status = "Enabled"
      
      noncurrent_version_expiration = {
        days = 90
      }
      
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]
  
  # Cross-region replication for disaster recovery
  enable_replication = var.enable_state_replication
  replication_region = var.state_replication_region
  
  tags = merge(var.tags, local.state_tags)
}

# VPC with workspace-specific configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${local.name_prefix}-vpc"
    Workspace = terraform.workspace
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${local.name_prefix}-igw"
    Workspace = terraform.workspace
  }
}

# Subnets with workspace-aware sizing
resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${local.name_prefix}-public-${count.index + 1}"
    Workspace = terraform.workspace
    Type      = "Public"
  }
}

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name      = "${local.name_prefix}-private-${count.index + 1}"
    Workspace = terraform.workspace
    Type      = "Private"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "${local.name_prefix}-public-rt"
    Workspace = terraform.workspace
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group with workspace-specific rules
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers in ${terraform.workspace}"
  vpc_id      = aws_vpc.main.id

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (restricted in production)
  dynamic "ingress" {
    for_each = terraform.workspace == "production" ? [] : [1]
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${local.name_prefix}-web-sg"
    Workspace = terraform.workspace
  }
}

# Launch template with workspace-specific configuration
resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = var.ami_id
  instance_type = local.current_config.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = terraform.workspace
    project     = var.project_name
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = terraform.workspace == "production" ? 20 : 10
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${local.name_prefix}-web"
      Workspace = terraform.workspace
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group with workspace-specific sizing
resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = local.current_config.min_size
  max_size         = local.current_config.max_size
  desired_capacity = local.current_config.desired_size

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Workspace"
    value               = terraform.workspace
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = terraform.workspace == "production" ? true : false

  tags = {
    Name      = "${local.name_prefix}-alb"
    Workspace = terraform.workspace
  }
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${local.name_prefix}-web-tg"
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

  tags = {
    Name      = "${local.name_prefix}-web-tg"
    Workspace = terraform.workspace
  }
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name      = "${local.name_prefix}-db-subnet-group"
    Workspace = terraform.workspace
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  count = var.create_database ? 1 : 0
  
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS in ${terraform.workspace}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name      = "${local.name_prefix}-rds-sg"
    Workspace = terraform.workspace
  }
}

# RDS Instance with workspace-specific configuration
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.name_prefix}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = terraform.workspace == "production" ? "db.t3.medium" : "db.t3.micro"

  allocated_storage     = terraform.workspace == "production" ? 100 : 20
  max_allocated_storage = terraform.workspace == "production" ? 1000 : 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name

  backup_retention_period = terraform.workspace == "production" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = terraform.workspace != "production"
  final_snapshot_identifier = terraform.workspace == "production" ? "${local.name_prefix}-final-snapshot" : null

  # Multi-AZ only for production
  multi_az = terraform.workspace == "production" ? true : false

  # Enhanced monitoring for production
  monitoring_interval = terraform.workspace == "production" ? 60 : 0

  tags = {
    Name      = "${local.name_prefix}-db"
    Workspace = terraform.workspace
  }
}

# S3 bucket for application data with workspace isolation
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${terraform.workspace}-app-data-${random_id.bucket_suffix.hex}"

  tags = {
    Name      = "${local.name_prefix}-app-data"
    Workspace = terraform.workspace
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${local.name_prefix}"
  retention_in_days = terraform.workspace == "production" ? 30 : 7

  tags = {
    Name      = "${local.name_prefix}-logs"
    Workspace = terraform.workspace
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = terraform.workspace == "production" ? "70" : "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name      = "${local.name_prefix}-high-cpu-alarm"
    Workspace = terraform.workspace
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization for scaling up"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization for scaling down"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
