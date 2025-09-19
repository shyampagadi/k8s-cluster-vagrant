# Problem 26: Advanced Loops - Complex Iteration Patterns
# This configuration demonstrates advanced loop patterns and complex iteration

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

# Generate random ID
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Complex nested data structure for advanced loops
locals {
  # Multi-level environment configuration
  environments = {
    dev = {
      instance_count = 2
      instance_type = "t3.micro"
      enable_monitoring = false
      storage_configs = {
        logs = { size = 10, encrypted = true, versioning = true }
        data = { size = 20, encrypted = true, versioning = false }
      }
    }
    staging = {
      instance_count = 3
      instance_type = "t3.small"
      enable_monitoring = true
      storage_configs = {
        logs = { size = 20, encrypted = true, versioning = true }
        data = { size = 50, encrypted = true, versioning = true }
        backup = { size = 100, encrypted = true, versioning = true }
      }
    }
    prod = {
      instance_count = 5
      instance_type = "t3.medium"
      enable_monitoring = true
      storage_configs = {
        logs = { size = 50, encrypted = true, versioning = true }
        data = { size = 100, encrypted = true, versioning = true }
        backup = { size = 200, encrypted = true, versioning = true }
        archive = { size = 500, encrypted = true, versioning = true }
      }
    }
  }

  # Flattened configuration for complex loops
  flattened_config = flatten([
    for env_name, env_config in local.environments : [
      for storage_name, storage_config in env_config.storage_configs : {
        env_name = env_name
        storage_name = storage_name
        instance_count = env_config.instance_count
        instance_type = env_config.instance_type
        enable_monitoring = env_config.enable_monitoring
        storage_size = storage_config.size
        storage_encrypted = storage_config.encrypted
        storage_versioning = storage_config.versioning
        key = "${env_name}-${storage_name}"
      }
    ]
  ])

  # Create a map from flattened config
  config_map = {
    for config in local.flattened_config : config.key => config
  }
}

# Create VPC for each environment
resource "aws_vpc" "environments" {
  for_each = local.environments

  cidr_block           = cidrsubnet("10.0.0.0/8", 8, index(keys(local.environments), each.key))
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${each.key}-vpc-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
  }
}

# Create subnets for each environment
resource "aws_subnet" "environments" {
  for_each = {
    for env_name, env_config in local.environments : env_name => env_config
  }

  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.environments[each.key].id
  cidr_block              = cidrsubnet(aws_vpc.environments[each.key].cidr_block, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${each.key}-subnet-${count.index + 1}-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
    SubnetIndex = count.index
  }
}

# Create Internet Gateway for each environment
resource "aws_internet_gateway" "environments" {
  for_each = local.environments

  vpc_id = aws_vpc.environments[each.key].id

  tags = {
    Name        = "${var.project_name}-${each.key}-igw-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
  }
}

# Create security groups for each environment
resource "aws_security_group" "environments" {
  for_each = local.environments

  name_prefix = "${var.project_name}-${each.key}-sg-${random_id.project_suffix.hex}"
  vpc_id      = aws_vpc.environments[each.key].id

  dynamic "ingress" {
    for_each = each.value.enable_monitoring ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = each.value.enable_monitoring ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = each.value.enable_monitoring ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-sg-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
  }
}

# Create EC2 instances for each environment with complex loops
resource "aws_instance" "environments" {
  for_each = {
    for env_name, env_config in local.environments : env_name => env_config
  }

  count = each.value.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.environments[each.key][count.index % length(aws_subnet.environments[each.key])].id
  vpc_security_group_ids = [aws_security_group.environments[each.key].id]

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = each.key
    instance_type = each.value.instance_type
    instance_index = count.index
  })

  tags = {
    Name        = "${var.project_name}-${each.key}-instance-${count.index + 1}-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
    InstanceIndex = count.index
  }
}

# Create S3 buckets with complex nested loops
resource "aws_s3_bucket" "storage" {
  for_each = local.config_map

  bucket = "${var.project_name}-${each.value.env_name}-${each.value.storage_name}-${random_id.project_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${each.value.env_name}-${each.value.storage_name}-${random_id.project_suffix.hex}"
    Environment = each.value.env_name
    Project     = var.project_name
    Module      = "advanced-loops"
    StorageType = each.value.storage_name
    Size        = each.value.storage_size
    Encrypted   = each.value.storage_encrypted
    Versioning  = each.value.storage_versioning
  }
}

# Enable versioning conditionally
resource "aws_s3_bucket_versioning" "storage" {
  for_each = {
    for k, v in local.config_map : k => v
    if v.storage_versioning == true
  }

  bucket = aws_s3_bucket.storage[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption conditionally
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  for_each = {
    for k, v in local.config_map : k => v
    if v.storage_encrypted == true
  }

  bucket = aws_s3_bucket.storage[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create CloudWatch log groups for monitoring-enabled environments
resource "aws_cloudwatch_log_group" "environments" {
  for_each = {
    for env_name, env_config in local.environments : env_name => env_config
    if env_config.enable_monitoring == true
  }

  name              = "/aws/ec2/${var.project_name}-${each.key}-${random_id.project_suffix.hex}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${each.key}-log-group-${random_id.project_suffix.hex}"
    Environment = each.key
    Project     = var.project_name
    Module      = "advanced-loops"
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
