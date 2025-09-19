# Problem 23: State Management - Remote State and Collaboration
# This configuration demonstrates advanced state management concepts

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

  # Remote backend configuration
  backend "s3" {
    # Backend configuration is provided via backend.tfvars
    # This allows for environment-specific backend configuration
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

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  cidr_block         = cidrsubnet(var.vpc_cr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create security group
resource "aws_security_group" "web_sg" {
  name_prefix = "${var.project_name}-web-sg-${random_id.project_suffix.hex}"
  vpc_id      = aws_vpc.main.id

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

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name        = "${var.project_name}-web-sg-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Create EC2 instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    instance_type = var.instance_type
  })

  tags = {
    Name        = "${var.project_name}-web-server-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Data source to get the latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create S3 bucket for application data
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-app-data-${random_id.project_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-app-data-${random_id.project_suffix.hex}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "state-management"
  }
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create application configuration file
resource "local_file" "app_config" {
  content = templatefile("${path.module}/templates/app.conf", {
    project_name = var.project_name
    environment  = var.environment
    vpc_id       = aws_vpc.main.id
    bucket_name  = aws_s3_bucket.app_data.id
  })
  filename = "${path.module}/config/app.conf"
}
