# Resource Dependencies - AWS Examples

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
      Purpose     = "Resource Dependencies Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for dependency optimization
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Pre-compute dependency lists
  web_dependencies = [
    aws_security_group.web,
    aws_route_table_association.public
  ]
  
  database_dependencies = [
    aws_db_subnet_group.main,
    aws_security_group.database
  ]
  
  # Conditional dependency lists
  conditional_dependencies = var.create_database ? 
    concat(local.web_dependencies, local.database_dependencies) : 
    local.web_dependencies
}

# VPC (Level 1 - No dependencies)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
    Environment = var.environment
    DependencyLevel = "1"
  }
}

# Internet Gateway (Level 2 - Depends on VPC)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_vpc.main"
  }
}

# Subnets (Level 2 - Depends on VPC)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.availability_zones[count.index]
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_vpc.main"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = var.availability_zones[count.index]
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_vpc.main"
  }
}

# Route Table (Level 3 - Depends on VPC and IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Implicit dependency on IGW
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
    Environment = var.environment
    DependencyLevel = "3"
    DependsOn = "aws_vpc.main, aws_internet_gateway.main"
  }
}

# DB Subnet Group (Level 3 - Depends on VPC and Private Subnets)
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id  # Implicit dependency on private subnets
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Environment = var.environment
    DependencyLevel = "3"
    DependsOn = "aws_vpc.main, aws_subnet.private"
  }
}

# Route Table Association (Level 4 - Depends on Route Table and Subnets)
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id  # Implicit dependency on subnet
  route_table_id = aws_route_table.public.id  # Implicit dependency on route table
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
    Environment = var.environment
    DependencyLevel = "4"
    DependsOn = "aws_subnet.public, aws_route_table.public"
  }
}

# Security Groups (Level 3 - Depends on VPC)
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id  # Implicit dependency on VPC
  
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
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
    Environment = var.environment
    DependencyLevel = "3"
    DependsOn = "aws_vpc.main"
  }
}

resource "aws_security_group" "database" {
  count = var.create_database ? 1 : 0
  
  name_prefix = "${local.resource_prefix}-db-"
  vpc_id      = aws_vpc.main.id  # Implicit dependency on VPC
  
  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]  # Implicit dependency on web SG
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
    Environment = var.environment
    DependencyLevel = "3"
    DependsOn = "aws_vpc.main, aws_security_group.web"
  }
}

# EC2 Instances (Level 5 - Depends on Subnets, Security Groups, Route Table Associations)
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id  # Implicit dependency on subnet
  
  vpc_security_group_ids = [aws_security_group.web.id]  # Implicit dependency on security group
  
  # Explicit dependencies for complex scenarios
  depends_on = [
    aws_security_group.web,      # Security group must exist
    aws_route_table_association.public,  # Route table must be associated
    aws_db_instance.main         # Database must be ready (if created)
  ]
  
  monitoring = var.enable_monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    database_endpoint = var.create_database ? aws_db_instance.main[0].endpoint : "none"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    DependencyLevel = "5"
    DependsOn = "aws_subnet.public, aws_security_group.web, aws_route_table_association.public"
  }
}

# RDS Instance (Level 4 - Depends on DB Subnet Group and Security Group)
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
  
  vpc_security_group_ids = [aws_security_group.database[0].id]  # Implicit dependency on security group
  db_subnet_group_name   = aws_db_subnet_group.main[0].name  # Implicit dependency on subnet group
  
  # Explicit dependency on subnet group
  depends_on = [aws_db_subnet_group.main]
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    DependencyLevel = "4"
    DependsOn = "aws_db_subnet_group.main, aws_security_group.database"
  }
}

# S3 Bucket (Level 1 - No dependencies)
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    DependencyLevel = "1"
  }
}

# S3 Bucket Versioning (Level 2 - Depends on S3 Bucket)
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id  # Implicit dependency on S3 bucket
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_s3_bucket.main"
  }
}

# S3 Bucket Encryption (Level 2 - Depends on S3 Bucket)
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id  # Implicit dependency on S3 bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_s3_bucket.main"
  }
}

# S3 Bucket Public Access Block (Level 2 - Depends on S3 Bucket)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id  # Implicit dependency on S3 bucket

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
  
  tags = {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_s3_bucket.main"
  }
}

# S3 Object (Level 3 - Depends on S3 Bucket and EC2 Instances)
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id  # Implicit dependency on S3 bucket
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    instance_count = var.instance_count
    database_endpoint = var.create_database ? aws_db_instance.main[0].endpoint : "none"
  })
  
  content_type = "text/plain"
  
  # Explicit dependency on instances for configuration
  depends_on = [aws_instance.web]
  
  tags = {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
    Environment = var.environment
    DependencyLevel = "3"
    DependsOn = "aws_s3_bucket.main, aws_instance.web"
  }
}

# CloudWatch Log Group (Level 2 - Depends on VPC)
resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    DependencyLevel = "2"
    DependsOn = "aws_vpc.main"
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
