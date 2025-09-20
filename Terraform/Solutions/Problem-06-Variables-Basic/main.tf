# Variables - Basic Types and Usage - AWS Examples

# Configure Terraform and AWS Provider
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
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Variables Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values demonstrating variable usage
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Conditional values based on variables
  instance_type = var.environment == "production" ? var.production_instance_type : var.development_instance_type
  instance_count = var.create_instances ? var.instance_count : 0
  
  # String interpolation with variables
  bucket_name = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  dns_name = "${var.subdomain}.${var.domain_name}"
  
  # Boolean logic with variables
  enable_monitoring = var.enable_monitoring && var.environment == "production"
  enable_encryption = var.enable_encryption || var.environment == "production"
  
  # Number calculations with variables
  total_cost = var.instance_count * var.hourly_rate
  backup_retention = var.environment == "production" ? var.backup_retention_production : var.backup_retention_development
}

# VPC demonstrating string variable usage
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    Region      = var.aws_region
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnets demonstrating number variable usage
resource "aws_subnet" "public" {
  count = var.subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    SubnetType  = "Public"
    Index       = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    SubnetType  = "Private"
    Index       = count.index + 1
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
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups demonstrating boolean variable usage
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Conditional ingress rules based on variables
  dynamic "ingress" {
    for_each = var.enable_http ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instances demonstrating comprehensive variable usage
resource "aws_instance" "web" {
  count = local.instance_count
  
  ami           = var.ami_id
  instance_type = local.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Conditional monitoring based on variables
  monitoring = local.enable_monitoring
  
  # User data with variable interpolation
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    enable_monitoring = local.enable_monitoring
    enable_encryption = local.enable_encryption
  }))
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    InstanceType = local.instance_type
    InstanceCount = var.instance_count
    EnableMonitoring = local.enable_monitoring
    EnableEncryption = local.enable_encryption
  }
}

# S3 Bucket demonstrating string variable usage
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name
  
  tags = {
    Name        = local.bucket_name
    Environment = var.environment
    Project     = var.project_name
    Domain      = local.dns_name
  }
}

# S3 Bucket Versioning with boolean variable
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Encryption with boolean variable
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = local.enable_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# RDS Instance demonstrating number and boolean variable usage
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${var.project_name}-${var.environment}-db"
  
  engine    = var.database_engine
  engine_version = var.database_version
  instance_class = var.database_instance_class
  
  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_allocated_storage * 2
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = local.backup_retention
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Project     = var.project_name
    Engine      = var.database_engine
    Version     = var.database_version
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  count = var.create_database ? 1 : 0
  
  name_prefix = "${var.project_name}-${var.environment}-db-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
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
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group with boolean variable
resource "aws_cloudwatch_log_group" "main" {
  count = local.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
    Project     = var.project_name
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
