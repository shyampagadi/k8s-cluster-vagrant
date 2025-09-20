# Production Environment - Final Project
# This file demonstrates environment-specific configuration

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

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Local values for production environment
locals {
  environment = "production"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  tags              = local.common_tags
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "MySQL from web tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-sg"
  })
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name      = var.project_name
  environment       = local.environment
  instance_type     = var.prod_instance_type
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = aws_security_group.web.id
  min_size          = var.prod_min_size
  max_size          = var.prod_max_size
  desired_capacity  = var.prod_desired_capacity
  tags              = local.common_tags
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  project_name           = var.project_name
  environment            = local.environment
  subnet_ids             = module.networking.private_subnet_ids
  db_security_group_id   = aws_security_group.database.id
  db_instance_class      = var.prod_db_instance_class
  db_allocated_storage   = var.prod_db_allocated_storage
  db_max_allocated_storage = var.prod_db_max_allocated_storage
  db_backup_retention_period = var.prod_db_backup_retention_period
  db_password            = random_password.db_password.result
  tags                   = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name       = var.project_name
  aws_region        = var.aws_region
  log_retention_days = var.prod_log_retention_days
  tags               = local.common_tags
}
