# Problem 22: Modules - Advanced Features and Patterns
# This configuration demonstrates advanced module usage patterns

# Configure the AWS Provider
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

# Generate random ID for unique naming
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Networking Module - Always created
module "networking" {
  source = "./modules/networking"

  project_name     = var.project_name
  environment      = var.environment
  project_suffix   = random_id.project_suffix.hex
  vpc_cidr         = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
}

# Compute Module - Conditionally created based on environment
module "compute" {
  count  = var.create_compute_resources ? 1 : 0
  source = "./modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  project_suffix      = random_id.project_suffix.hex
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  security_group_ids  = module.networking.security_group_ids
  instance_type       = var.instance_type
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  enable_auto_scaling = var.enable_auto_scaling
}

# Storage Module - Multiple instances using for_each
module "storage" {
  for_each = var.storage_configurations
  source   = "./modules/storage"

  project_name   = var.project_name
  environment    = var.environment
  project_suffix = random_id.project_suffix.hex
  storage_type   = each.key
  storage_config = each.value
  vpc_id         = module.networking.vpc_id
}

# Conditional monitoring module
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project_name   = var.project_name
  environment    = var.environment
  project_suffix = random_id.project_suffix.hex
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
}

# Create application configuration
resource "local_file" "app_config" {
  content = templatefile("${path.module}/templates/app.conf", {
    project_name = var.project_name
    environment  = var.environment
    vpc_id       = module.networking.vpc_id
    storage_buckets = {
      for k, v in module.storage : k => v.bucket_name
    }
    compute_enabled = var.create_compute_resources
    monitoring_enabled = var.enable_monitoring
  })
  filename = "${path.module}/config/app.conf"
}
