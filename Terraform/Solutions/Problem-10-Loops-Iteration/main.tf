# Loops and Iteration - Count and For Each - AWS Examples

# Configure Terraform and AWS Provider
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Loops Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for loop optimization
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Optimize count values
  instance_count = var.environment == "production" ? var.production_instance_count : var.development_instance_count
  subnet_count = length(var.availability_zones)
  
  # Transform for_each data
  server_configs = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size = config.disk_size * 1024  # Convert GB to MB
      monitoring = config.monitoring
      environment = config.environment
    }
  }
  
  # Filter for_each data
  production_configs = {
    for name, config in var.server_configs : name => config
    if config.environment == "production"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
  }
}

# Subnets using count
resource "aws_subnet" "public" {
  count = local.subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.availability_zones[count.index]
    Index = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = local.subnet_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = var.availability_zones[count.index]
    Index = count.index + 10
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
  }
}

# Route Table Associations using count
resource "aws_route_table_association" "public" {
  count = local.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups using for_each
resource "aws_security_group" "web" {
  for_each = toset(var.security_group_names)
  
  name_prefix = "${each.value}-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = {
    Name = each.value
    Type = "Security Group"
  }
}

# EC2 Instances using count
resource "aws_instance" "web" {
  count = local.instance_count
  
  ami           = var.ami_id
  instance_type = var.environment == "production" ? var.production_instance_type : var.development_instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web["web"].id]
  
  monitoring = var.enable_monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    instance_type = var.environment == "production" ? var.production_instance_type : var.development_instance_type
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Index = count.index + 1
    Environment = var.environment
  }
}

# EC2 Instances using for_each
resource "aws_instance" "app" {
  for_each = local.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  vpc_security_group_ids = [aws_security_group.web["app"].id]
  
  monitoring = each.value.monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name    = each.key
    environment = each.value.environment
    instance_type = each.value.instance_type
    disk_size = each.value.disk_size
  }))
  
  tags = merge(each.value.tags, {
    Name = "${local.resource_prefix}-${each.key}"
    Type = "App Server"
    ServerName = each.key
    InstanceType = each.value.instance_type
    DiskSize = each.value.disk_size
    Environment = each.value.environment
  })
}

# RDS Instance using count
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
  
  vpc_security_group_ids = [aws_security_group.web["database"].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
  }
}

# DB Subnet Group using count
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
  }
}

# S3 Buckets using for_each
resource "aws_s3_bucket" "main" {
  for_each = toset(var.bucket_names)
  
  bucket = "${local.resource_prefix}-${each.value}"
  
  tags = {
    Name = "${local.resource_prefix}-${each.value}"
    Type = "S3 Bucket"
    BucketName = each.value
  }
}

# S3 Bucket Versioning using for_each
resource "aws_s3_bucket_versioning" "main" {
  for_each = aws_s3_bucket.main
  
  bucket = each.value.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Encryption using for_each
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = var.enable_encryption ? aws_s3_bucket.main : {}
  
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block using for_each
resource "aws_s3_bucket_public_access_block" "main" {
  for_each = aws_s3_bucket.main
  
  bucket = each.value.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# S3 Objects using for_each
resource "aws_s3_object" "config" {
  for_each = aws_s3_bucket.main
  
  bucket = each.value.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    bucket_name = each.key
    instance_count = local.instance_count
  })
  
  content_type = "text/plain"
  
  tags = {
    Name = "${local.resource_prefix}-config-${each.key}"
    Type = "S3 Object"
    BucketName = each.key
  }
}

# CloudWatch Log Groups using for_each
resource "aws_cloudwatch_log_group" "main" {
  for_each = var.enable_monitoring ? toset(var.log_group_names) : toset([])
  
  name              = "/aws/ec2/${local.resource_prefix}-${each.value}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs-${each.value}"
    Type = "CloudWatch Log Group"
    LogGroupName = each.value
  }
}

# Data Sources
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
