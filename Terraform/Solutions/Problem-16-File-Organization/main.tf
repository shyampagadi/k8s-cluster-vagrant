# File Organization and Project Structure - AWS Examples

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
      Purpose     = "File Organization Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for file organization
locals {
  # Resource naming patterns
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Environment-specific configurations
  environment_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = false
      enable_encryption = false
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_encryption = true
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_encryption = true
    }
  }
  
  # Current environment configuration
  current_config = local.environment_config[var.environment]
  
  # File organization patterns
  naming_patterns = {
    vpc = "${local.resource_prefix}-vpc"
    subnet = "${local.resource_prefix}-subnet"
    instance = "${local.resource_prefix}-instance"
    security_group = "${local.resource_prefix}-sg"
    bucket = "${local.resource_prefix}-bucket"
  }
}

# VPC demonstrating file organization patterns
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = {
    Name = local.naming_patterns.vpc
    Type = "VPC"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# Subnets demonstrating resource organization
resource "aws_subnet" "public" {
  count = var.subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
    SubnetType = "Public"
    Index = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
    SubnetType = "Private"
    Index = count.index + 1
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
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# Security Groups demonstrating file organization
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
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
    Project = var.project_name
    FileOrganization = "main.tf"
    SecurityGroupType = "Web"
  }
}

resource "aws_security_group" "database" {
  count = var.create_database ? 1 : 0
  
  name_prefix = "${local.resource_prefix}-db-"
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
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
    SecurityGroupType = "Database"
  }
}

# EC2 Instances demonstrating file organization patterns
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = var.ami_id
  instance_type = local.current_config.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.current_config.enable_monitoring
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    project_name = var.project_name
    file_organization = "main.tf"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
    InstanceType = local.current_config.instance_type
    Monitoring = local.current_config.enable_monitoring ? "Enabled" : "Disabled"
  }
}

# RDS Instance demonstrating file organization
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
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "prod"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
    Engine = var.database_engine
    Version = var.database_version
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# S3 Bucket demonstrating file organization
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = local.current_config.enable_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
  
  tags = {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# CloudWatch Log Group demonstrating file organization
resource "aws_cloudwatch_log_group" "main" {
  count = local.current_config.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    Project = var.project_name
    FileOrganization = "main.tf"
  }
}

# Data Sources demonstrating file organization
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
