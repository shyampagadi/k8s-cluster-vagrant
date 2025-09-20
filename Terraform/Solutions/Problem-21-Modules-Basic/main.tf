# Problem 21: Modules - Basic Usage and Structure
# Comprehensive module implementation and usage examples

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

# Get latest Amazon Linux 2 AMI if not specified
data "aws_ami" "amazon_linux" {
  count       = var.web_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values for common tags and naming
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
  web_ami_id  = var.web_ami_id != "" ? var.web_ami_id : data.aws_ami.amazon_linux[0].id
}

# VPC Module Usage
module "vpc" {
  source = "./modules/vpc"

  name               = "${local.name_prefix}-vpc"
  cidr               = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = local.common_tags
}

# Security Group Module Usage
module "web_security_group" {
  source = "./modules/security-group"

  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "SSH from VPC"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound traffic"
    }
  ]

  tags = local.common_tags
}

# EC2 Instance Module Usage
module "web_servers" {
  source = "./modules/ec2"

  name           = "${local.name_prefix}-web"
  instance_count = var.web_instance_count
  
  ami                    = local.web_ami_id
  instance_type          = var.web_instance_type
  key_name              = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [module.web_security_group.security_group_id]
  subnet_ids            = module.vpc.public_subnets
  
  associate_public_ip_address = true
  
  user_data = base64encode(templatefile("${path.module}/templates/web_user_data.sh", {
    environment = var.environment
    project     = var.project_name
  }))

  root_block_device = {
    volume_type = "gp3"
    volume_size = var.web_root_volume_size
    encrypted   = true
  }

  tags = local.common_tags
}

# Application Load Balancer Module Usage
module "alb" {
  source = "./modules/alb"

  name = "${local.name_prefix}-alb"
  
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.web_security_group.security_group_id]
  
  target_groups = [
    {
      name             = "${local.name_prefix}-web-tg"
      port             = 80
      protocol         = "HTTP"
      target_type      = "instance"
      health_check = {
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
      targets = module.web_servers.instance_ids
    }
  ]
  
  listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "forward"
      target_group_index = 0
    }
  ]
  
  tags = local.common_tags
}

# S3 Module Usage for static assets
module "static_assets" {
  source = "./modules/s3"

  bucket_name = "${local.name_prefix}-static-assets-${random_id.bucket_suffix.hex}"
  
  versioning_enabled = true
  
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  
  tags = local.common_tags
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
