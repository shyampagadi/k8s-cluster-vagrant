# Troubleshooting - AWS Examples

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

# Configure AWS Provider with troubleshooting features
provider "aws" {
  region = var.aws_region
  
  # Retry configuration for troubleshooting
  retry_mode = "adaptive"
  max_retries = 3
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Troubleshooting Demo"
    }
  }
}

# Generate random values for troubleshooting
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for troubleshooting
locals {
  # Resource naming with troubleshooting prefix
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Troubleshooting configuration
  troubleshooting_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = true
      enable_debugging = true
      enable_validation = true
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_debugging = true
      enable_validation = true
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_debugging = false
      enable_validation = true
    }
  }
  
  # Current troubleshooting configuration
  current_troubleshooting = local.troubleshooting_config[var.environment]
  
  # Troubleshooting resource names
  resource_names = {
    vpc = "${local.resource_prefix}-vpc"
    subnet = "${local.resource_prefix}-subnet"
    instance = "${local.resource_prefix}-instance"
    security_group = "${local.resource_prefix}-sg"
    bucket = "${local.resource_prefix}-bucket"
  }
}

# Data sources for troubleshooting
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

# VPC with troubleshooting features
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = local.resource_names.vpc
    Type = "VPC"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
  }
}

# Subnets with troubleshooting features
resource "aws_subnet" "public" {
  count = var.subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
    SubnetType = "Public"
    Index = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
    SubnetType = "Private"
    Index = count.index + 1
  }
}

# Route Table with troubleshooting features
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
    TroubleshootingEnabled = "true"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
  }
}

# Security Groups with troubleshooting features
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
    SecurityGroupType = "Database"
  }
}

# Application Load Balancer for troubleshooting
resource "aws_lb" "main" {
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = var.environment == "prod"
  
  tags = {
    Name = "${local.resource_prefix}-alb"
    Type = "Application Load Balancer"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
  }
}

# Target Group with troubleshooting features
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
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
  }
}

# EC2 Instances with troubleshooting features
resource "aws_instance" "web" {
  count = local.current_troubleshooting.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_troubleshooting.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.current_troubleshooting.enable_monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    project_name = var.project_name
    troubleshooting_enabled = "true"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
    InstanceType = local.current_troubleshooting.instance_type
    Monitoring = local.current_troubleshooting.enable_monitoring ? "Enabled" : "Disabled"
  }
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "web" {
  count = local.current_troubleshooting.instance_count
  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# RDS Instance with troubleshooting features
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
  
  # Troubleshooting features
  performance_insights_enabled = local.current_troubleshooting.enable_monitoring
  performance_insights_retention_period = 7
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
    Engine = var.database_engine
    Version = var.database_version
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
  }
}

# S3 Bucket with troubleshooting features
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
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
    TroubleshootingEnabled = "true"
  }
}

# CloudWatch Log Group with troubleshooting features
resource "aws_cloudwatch_log_group" "main" {
  count = local.current_troubleshooting.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
  }
}

# CloudWatch Alarms for troubleshooting
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = local.current_troubleshooting.enable_monitoring ? local.current_troubleshooting.instance_count : 0
  
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
    TroubleshootingEnabled = "true"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  count = local.current_troubleshooting.enable_monitoring ? local.current_troubleshooting.instance_count : 0
  
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
    TroubleshootingEnabled = "true"
  }
}

# CloudWatch Alarms for troubleshooting
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  count = local.current_troubleshooting.enable_monitoring ? local.current_troubleshooting.instance_count : 0
  
  alarm_name          = "${local.resource_prefix}-memory-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors memory utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = {
    Name = "${local.resource_prefix}-memory-alarm-${count.index + 1}"
    Type = "CloudWatch Alarm"
    Environment = var.environment
    Project = var.project_name
    TroubleshootingEnabled = "true"
  }
}
