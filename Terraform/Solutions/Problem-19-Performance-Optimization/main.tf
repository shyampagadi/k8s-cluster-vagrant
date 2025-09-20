# Performance Optimization - AWS Examples

# Configure Terraform and AWS Provider
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure AWS Provider with performance optimizations
provider "aws" {
  region = var.aws_region
  
  # Performance optimizations
  retry_mode = "adaptive"
  max_retries = 3
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Performance Demo"
    }
  }
}

# Generate random values efficiently
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for performance optimization
locals {
  # Resource naming with performance optimization
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Cached data for performance
  cached_ami_id = data.aws_ami.ubuntu.id
  cached_azs = data.aws_availability_zones.available.names
  
  # Pre-computed values for performance
  subnet_cidrs = {
    for i, az in local.cached_azs : az => cidrsubnet(var.vpc_cidr, 8, i)
  }
  
  # Environment-specific performance configurations
  performance_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = false
      enable_auto_scaling = false
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_auto_scaling = true
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_auto_scaling = true
    }
  }
  
  # Current performance configuration
  current_performance = local.performance_config[var.environment]
  
  # Optimized resource names
  resource_names = {
    vpc = "${local.resource_prefix}-vpc"
    subnet = "${local.resource_prefix}-subnet"
    instance = "${local.resource_prefix}-instance"
    security_group = "${local.resource_prefix}-sg"
    bucket = "${local.resource_prefix}-bucket"
  }
}

# Data sources with performance optimization
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC with performance optimization
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = local.resource_names.vpc
    Type = "VPC"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Subnets with parallel creation optimization
resource "aws_subnet" "public" {
  for_each = local.subnet_cidrs
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${each.key}"
    Type = "Public Subnet"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    AvailabilityZone = each.key
  }
}

resource "aws_subnet" "private" {
  for_each = local.subnet_cidrs
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(keys(local.subnet_cidrs), each.key) + 10)
  availability_zone = each.key
  
  tags = {
    Name = "${local.resource_prefix}-private-${each.key}"
    Type = "Private Subnet"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    AvailabilityZone = each.key
  }
}

# Route Table with performance optimization
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Route Table Associations with batch optimization
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${each.key}"
    Type = "Route Table Association"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Security Groups with performance optimization
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Batch ingress rules for performance
  dynamic "ingress" {
    for_each = var.web_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    SecurityGroupType = "Web"
  }
}

resource "aws_security_group" "database" {
  count = var.create_database ? 1 : 0
  
  name_prefix = "${local.resource_prefix}-db-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    SecurityGroupType = "Database"
  }
}

# Application Load Balancer for performance
resource "aws_lb" "main" {
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  
  enable_deletion_protection = var.environment == "prod"
  
  tags = {
    Name = "${local.resource_prefix}-alb"
    Type = "Application Load Balancer"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Target Group with performance optimization
resource "aws_lb_target_group" "web" {
  name     = "${local.resource_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
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
  
  tags = {
    Name = "${local.resource_prefix}-tg"
    Type = "Target Group"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
  
  tags = {
    Name = "${local.resource_prefix}-listener"
    Type = "Load Balancer Listener"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# EC2 Instances with performance optimization
resource "aws_instance" "web" {
  count = local.current_performance.instance_count
  
  ami           = local.cached_ami_id
  instance_type = local.current_performance.instance_type
  subnet_id     = values(aws_subnet.private)[count.index % length(aws_subnet.private)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.current_performance.enable_monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    project_name = var.project_name
    performance_optimized = "true"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    InstanceType = local.current_performance.instance_type
    Monitoring = local.current_performance.enable_monitoring ? "Enabled" : "Disabled"
  }
}

# Attach instances to target group with performance optimization
resource "aws_lb_target_group_attachment" "web" {
  count = local.current_performance.instance_count
  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# Auto Scaling Group for performance optimization
resource "aws_autoscaling_group" "web" {
  count = local.current_performance.enable_auto_scaling ? 1 : 0
  
  name                = "${local.resource_prefix}-asg"
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  target_group_arns  = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = local.current_performance.instance_count
  max_size         = local.current_performance.instance_count * 3
  desired_capacity = local.current_performance.instance_count
  
  launch_template {
    id      = aws_launch_template.web[0].id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${local.resource_prefix}-asg"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
  
  tag {
    key                 = "PerformanceOptimized"
    value               = "true"
    propagate_at_launch = true
  }
}

# Launch Template for Auto Scaling
resource "aws_launch_template" "web" {
  count = local.current_performance.enable_auto_scaling ? 1 : 0
  
  name_prefix   = "${local.resource_prefix}-lt-"
  image_id      = local.cached_ami_id
  instance_type = local.current_performance.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = "auto-scaled"
    project_name = var.project_name
    performance_optimized = "true"
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.resource_prefix}-lt"
      Type = "Launch Template"
      Environment = var.environment
      Project = var.project_name
      PerformanceOptimized = "true"
    }
  }
}

# RDS Instance with performance optimization
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.resource_prefix}-db"
  
  engine    = var.database_engine
  engine_version = var.database_version
  instance_class = var.database_instance_class
  
  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_allocated_storage * 2
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "prod"
  
  # Performance optimizations
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
    Engine = var.database_engine
    Version = var.database_version
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# S3 Bucket with performance optimization
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  tags = {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# CloudWatch Log Group with performance optimization
resource "aws_cloudwatch_log_group" "main" {
  count = local.current_performance.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

# CloudWatch Alarms for performance monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = local.current_performance.enable_monitoring ? local.current_performance.instance_count : 0
  
  alarm_name          = "${local.resource_prefix}-cpu-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = {
    Name = "${local.resource_prefix}-cpu-alarm-${count.index + 1}"
    Type = "CloudWatch Alarm"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  count = local.current_performance.enable_monitoring ? local.current_performance.instance_count : 0
  
  alarm_name          = "${local.resource_prefix}-disk-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors disk utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = {
    Name = "${local.resource_prefix}-disk-alarm-${count.index + 1}"
    Type = "CloudWatch Alarm"
    Environment = var.environment
    Project = var.project_name
    PerformanceOptimized = "true"
  }
}
