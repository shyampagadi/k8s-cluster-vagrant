# Conditional Logic and Dynamic Blocks - AWS Examples

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
      Purpose     = "Conditional Logic Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for conditional logic optimization
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Conditional values based on environment
  instance_count = var.environment == "production" ? var.production_instance_count : 
                  var.environment == "staging" ? var.staging_instance_count : 
                  var.development_instance_count
  
  instance_type = var.environment == "production" ? var.production_instance_type : 
                 var.environment == "staging" ? var.staging_instance_type : 
                 var.development_instance_type
  
  enable_monitoring = var.environment == "production" ? true : false
  enable_encryption = var.environment == "production" ? true : false
  enable_backup = var.environment == "production" ? true : false
  
  # Conditional database configuration
  database_config = {
    instance_class = var.environment == "production" ? "db.r5.large" : 
                    var.environment == "staging" ? "db.t3.medium" : "db.t3.micro"
    multi_az = var.environment == "production" ? true : false
    backup_retention = var.environment == "production" ? 30 : 7
    encryption = var.environment == "production" ? true : false
  }
  
  # Conditional security configuration
  security_config = {
    enable_waf = var.environment == "production" ? true : false
    enable_shield = var.environment == "production" ? true : false
    enable_guardduty = var.environment == "production" ? true : false
  }
  
  # Conditional feature flags
  feature_flags = {
    enable_monitoring = var.enable_monitoring && var.environment == "production"
    enable_encryption = var.enable_encryption || var.environment == "production"
    enable_backup = var.enable_backup && var.environment == "production"
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
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
  }
}

# Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.availability_zones[count.index]
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = var.availability_zones[count.index]
    Environment = var.environment
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
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups with Dynamic Blocks
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules based on environment
  dynamic "ingress" {
    for_each = var.environment == "production" ? var.production_ingress_rules : var.development_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.enable_egress ? var.egress_rules : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
    Environment = var.environment
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
  }
}

# EC2 Instances with Conditional Logic
resource "aws_instance" "web" {
  count = local.instance_count
  
  ami           = var.ami_id
  instance_type = local.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Conditional monitoring
  monitoring = local.enable_monitoring
  
  # Conditional user data
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    enable_monitoring = local.enable_monitoring
    enable_debug = var.environment == "development" ? true : false
    enable_ssl = var.environment == "production" ? true : false
  }))
  
  # Dynamic EBS volumes based on environment
  dynamic "ebs_block_device" {
    for_each = var.environment == "production" ? var.production_volumes : var.development_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
      encrypted   = local.enable_encryption
    }
  }
  
  # Dynamic root block device encryption
  dynamic "root_block_device" {
    for_each = local.enable_encryption ? [1] : []
    content {
      volume_size = var.root_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    InstanceType = local.instance_type
    Monitoring = local.enable_monitoring ? "Enabled" : "Disabled"
    SSL = var.environment == "production" ? "Enabled" : "Disabled"
  }
}

# RDS Instance with Conditional Logic
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.resource_prefix}-db"
  
  engine    = var.database_engine
  engine_version = var.database_version
  instance_class = local.database_config.instance_class
  
  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_allocated_storage * 2
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = local.database_config.backup_retention
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = local.database_config.multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    InstanceClass = local.database_config.instance_class
    MultiAZ = local.database_config.multi_az ? "Enabled" : "Disabled"
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
  }
}

# S3 Bucket with Conditional Logic
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
  }
}

# S3 Bucket Versioning with Conditional Logic
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = local.enable_backup ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Encryption with Conditional Logic
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = local.enable_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block with Conditional Logic
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.environment == "production" ? true : false
  block_public_policy     = var.environment == "production" ? true : false
  ignore_public_acls      = var.environment == "production" ? true : false
  restrict_public_buckets = var.environment == "production" ? true : false
}

# S3 Object with Conditional Logic
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    enable_monitoring = local.enable_monitoring
    enable_ssl = var.environment == "production" ? true : false
    enable_debug = var.environment == "development" ? true : false
  })
  
  content_type = "text/plain"
  
  tags = {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
    Environment = var.environment
  }
}

# CloudWatch Log Group with Conditional Logic
resource "aws_cloudwatch_log_group" "main" {
  count = local.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
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
