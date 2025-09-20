# Staging Environment Configuration
# This file demonstrates environment-specific configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Local values for staging environment
locals {
  environment = "staging"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  tags              = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  tags         = local.common_tags
}

# Instances Module
module "instances" {
  source = "../../modules/instances"

  project_name      = var.project_name
  instance_count    = var.staging_instance_count
  instance_type     = var.staging_instance_type
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.web_security_group_id
  tags              = local.common_tags
}
