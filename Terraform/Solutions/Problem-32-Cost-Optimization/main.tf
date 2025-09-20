# Problem 32: Cost Optimization - Resource Efficiency and Monitoring
# This configuration demonstrates cost optimization patterns

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

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate cost optimization project ID
resource "random_id" "cost_id" {
  byte_length = 6
}

# VPC for cost-optimized infrastructure
resource "aws_vpc" "cost_optimized" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-cost-vpc-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# Subnets for cost-optimized infrastructure
resource "aws_subnet" "cost_optimized" {
  count = 2

  vpc_id                  = aws_vpc.cost_optimized.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_region.current.name
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-cost-subnet-${count.index + 1}-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cost_optimized" {
  vpc_id = aws_vpc.cost_optimized.id

  tags = {
    Name        = "${var.project_name}-cost-igw-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# Security Group for cost-optimized instances
resource "aws_security_group" "cost_optimized" {
  name_prefix = "${var.project_name}-cost-sg-${random_id.cost_id.hex}"
  vpc_id      = aws_vpc.cost_optimized.id

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

  tags = {
    Name        = "${var.project_name}-cost-sg-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# Launch Template with cost optimization
resource "aws_launch_template" "cost_optimized" {
  name_prefix   = "${var.project_name}-cost-lt-${random_id.cost_id.hex}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.cost_optimized.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    cost_optimized = true
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-cost-instance-${random_id.cost_id.hex}"
      Environment = var.environment
      Project     = var.project_name
      Module      = "cost-optimization"
      CostCenter  = "engineering"
    }
  }

  tags = {
    Name        = "${var.project_name}-cost-lt-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# Auto Scaling Group with cost optimization
resource "aws_autoscaling_group" "cost_optimized" {
  name                = "${var.project_name}-cost-asg-${random_id.cost_id.hex}"
  vpc_zone_identifier = aws_subnet.cost_optimized[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.cost_optimized.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-cost-asg-${random_id.cost_id.hex}"
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
    key                 = "CostCenter"
    value               = "engineering"
    propagate_at_launch = true
  }
}

# Cost-optimized S3 bucket
resource "aws_s3_bucket" "cost_optimized" {
  bucket = "${var.project_name}-cost-data-${random_id.cost_id.hex}"

  tags = {
    Name        = "${var.project_name}-cost-data-${random_id.cost_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "cost-optimization"
    CostCenter  = "engineering"
  }
}

# S3 lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimized" {
  bucket = aws_s3_bucket.cost_optimized.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Cost monitoring CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.project_name}-cost-dashboard-${random_id.cost_id.hex}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Estimated Charges"
          period  = 86400
        }
      }
    ]
  })
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
