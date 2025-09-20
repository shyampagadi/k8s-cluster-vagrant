# Problem 30: Production Deployment - Blue-Green and Canary
# This configuration demonstrates production deployment patterns

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

# Generate deployment project ID
resource "random_id" "deployment_id" {
  byte_length = 6
}

# VPC for production deployment
resource "aws_vpc" "production" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-production-vpc-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

# Public subnets for load balancers
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.production.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_region.current.name
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Type        = "public"
  }
}

# Private subnets for application instances
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.production.id
  cidr_block         = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_region.current.name

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Type        = "private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "production" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name        = "${var.project_name}-igw-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

resource "aws_nat_gateway" "production" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-sg-${random_id.deployment_id.hex}"
  vpc_id      = aws_vpc.production.id

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
    Name        = "${var.project_name}-alb-sg-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-sg-${random_id.deployment_id.hex}"
  vpc_id      = aws_vpc.production.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-app-sg-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

# Application Load Balancer
resource "aws_lb" "production" {
  name               = "${var.project_name}-alb-${random_id.deployment_id.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
  }
}

# Target Groups for Blue-Green deployment
resource "aws_lb_target_group" "blue" {
  name     = "${var.project_name}-blue-tg-${random_id.deployment_id.hex}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.production.id

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
    Name        = "${var.project_name}-blue-tg-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Color       = "blue"
  }
}

resource "aws_lb_target_group" "green" {
  name     = "${var.project_name}-green-tg-${random_id.deployment_id.hex}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.production.id

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
    Name        = "${var.project_name}-green-tg-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Color       = "green"
  }
}

# Launch Templates for Blue-Green deployment
resource "aws_launch_template" "blue" {
  name_prefix   = "${var.project_name}-blue-lt-${random_id.deployment_id.hex}"
  image_id       = data.aws_ami.amazon_linux.id
  instance_type  = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    deployment_color = "blue"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-blue-instance-${random_id.deployment_id.hex}"
      Environment = var.environment
      Project     = var.project_name
      Module      = "production-deployment"
      Color       = "blue"
    }
  }

  tags = {
    Name        = "${var.project_name}-blue-lt-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Color       = "blue"
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "${var.project_name}-green-lt-${random_id.deployment_id.hex}"
  image_id       = data.aws_ami.amazon_linux.id
  instance_type  = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    deployment_color = "green"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-green-instance-${random_id.deployment_id.hex}"
      Environment = var.environment
      Project     = var.project_name
      Module      = "production-deployment"
      Color       = "green"
    }
  }

  tags = {
    Name        = "${var.project_name}-green-lt-${random_id.deployment_id.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "production-deployment"
    Color       = "green"
  }
}

# Auto Scaling Groups for Blue-Green deployment
resource "aws_autoscaling_group" "blue" {
  name                = "${var.project_name}-blue-asg-${random_id.deployment_id.hex}"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.blue.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-blue-asg-${random_id.deployment_id.hex}"
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
    key                 = "Color"
    value               = "blue"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "${var.project_name}-green-asg-${random_id.deployment_id.hex}"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.green.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 0
  max_size         = var.max_instances
  desired_capacity = 0

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-green-asg-${random_id.deployment_id.hex}"
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
    key                 = "Color"
    value               = "green"
    propagate_at_launch = true
  }
}

# ALB Listener
resource "aws_lb_listener" "production" {
  load_balancer_arn = aws_lb.production.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
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
