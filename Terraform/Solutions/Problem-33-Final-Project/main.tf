# Problem 33: Final Project - Complete Infrastructure Solution
# This configuration demonstrates a comprehensive Terraform solution

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
data "aws_availability_zones" "available" {
  state = "available"
}

# Generate final project ID
resource "random_id" "final_project_id" {
  byte_length = 8
}

# VPC for final project
resource "aws_vpc" "final_project" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
    Purpose     = "comprehensive-solution"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.final_project.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
    Type        = "public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.final_project.id
  cidr_block         = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
    Type        = "private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "final_project" {
  vpc_id = aws_vpc.final_project.id

  tags = {
    Name        = "${var.project_name}-igw-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

resource "aws_nat_gateway" "final_project" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.final_project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.final_project.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.final_project.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.final_project.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-sg-${random_id.final_project_id.hex}"
  vpc_id      = aws_vpc.final_project.id

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
    Name        = "${var.project_name}-web-sg-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-sg-${random_id.final_project_id.hex}"
  vpc_id      = aws_vpc.final_project.id

  ingress {
    from_port       = 3306
    to_port         = 3306
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
    Name        = "${var.project_name}-db-sg-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Application Load Balancer
resource "aws_lb" "final_project" {
  name               = "${var.project_name}-alb-${random_id.final_project_id.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Target Group
resource "aws_lb_target_group" "final_project" {
  name     = "${var.project_name}-tg-${random_id.final_project_id.hex}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.final_project.id

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
    Name        = "${var.project_name}-tg-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Launch Template
resource "aws_launch_template" "final_project" {
  name_prefix   = "${var.project_name}-lt-${random_id.final_project_id.hex}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    final_project = true
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-instance-${random_id.final_project_id.hex}"
      Environment = var.environment
      Project     = var.project_name
      Module      = "final-project"
    }
  }

  tags = {
    Name        = "${var.project_name}-lt-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "final_project" {
  name                = "${var.project_name}-asg-${random_id.final_project_id.hex}"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.final_project.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.final_project.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-${random_id.final_project_id.hex}"
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
}

# ALB Listener
resource "aws_lb_listener" "final_project" {
  load_balancer_arn = aws_lb.final_project.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.final_project.arn
  }
}

# S3 Buckets
resource "aws_s3_bucket" "final_project_data" {
  bucket = "${var.project_name}-data-${random_id.final_project_id.hex}"

  tags = {
    Name        = "${var.project_name}-data-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

resource "aws_s3_bucket" "final_project_logs" {
  bucket = "${var.project_name}-logs-${random_id.final_project_id.hex}"

  tags = {
    Name        = "${var.project_name}-logs-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "final_project" {
  name              = "/aws/ec2/${var.project_name}-${random_id.final_project_id.hex}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-log-group-${random_id.final_project_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "final-project"
  }
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
