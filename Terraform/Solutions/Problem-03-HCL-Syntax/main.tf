# HCL Syntax Deep Dive - Comprehensive Examples

# Configure Terraform and Providers
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
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_string" "password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Local values demonstrating HCL expressions
locals {
  # String expressions
  formatted_name = format("%s-%s-%s", var.project_name, var.environment, random_id.suffix.hex)
  upper_name     = upper(var.project_name)
  lower_name     = lower(var.project_name)
  clean_name     = replace(var.project_name, "_", "-")
  
  # Numeric expressions
  total_instances = var.web_count + var.db_count
  half_instances  = var.total_count / 2
  remaining_count = var.total_count % 3
  
  # Boolean expressions
  is_production = var.environment == "production"
  has_enough_instances = var.instance_count >= 3
  enable_monitoring = var.environment == "production" && var.monitoring_enabled
  
  # Complex expressions
  instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
  
  # Conditional expressions
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  monitoring_config = var.monitoring_enabled ? {
    enabled = true
    retention_days = 30
    alert_threshold = 80.0
  } : {
    enabled = false
    retention_days = 0
    alert_threshold = 0.0
  }
  
  # Common tags using merge function
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
  
  # Dynamic tags based on conditions
  dynamic_tags = merge(local.common_tags, {
    Monitoring = var.monitoring_enabled ? "enabled" : "disabled"
    InstanceType = local.instance_type
    TotalInstances = var.instance_count
  })
}

# Data sources demonstrating HCL expressions
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

# VPC demonstrating complex HCL expressions
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = local.formatted_name
    Type = "Main VPC"
  })
}

# Subnets demonstrating for expressions
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone        = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-igw"
    Type = "Internet Gateway"
  })
}

# Route Table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-public-rt"
    Type = "Public Route Table"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups demonstrating dynamic blocks
resource "aws_security_group" "web" {
  name_prefix = "${local.formatted_name}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-web-sg"
    Type = "Web Security Group"
  })
}

# EC2 Instances demonstrating complex HCL expressions
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # User data with templatefile function
  user_data = templatefile("${path.module}/templates/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    monitoring  = var.monitoring_enabled
  })
  
  # Conditional monitoring
  monitoring = var.monitoring_enabled
  
  tags = merge(local.dynamic_tags, {
    Name = "${local.formatted_name}-web-${count.index + 1}"
    Type = "Web Server"
    InstanceIndex = count.index + 1
  })
}

# S3 Bucket demonstrating string interpolation
resource "aws_s3_bucket" "main" {
  bucket = "${local.lower_name}-${var.environment}-${random_id.suffix.hex}"
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-bucket"
    Type = "S3 Bucket"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.environment == "production" ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Object demonstrating file functions
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    instance_count = var.instance_count
    monitoring_enabled = var.monitoring_enabled
  })
  
  content_type = "text/plain"
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-config"
    Type = "Configuration File"
  })
}

# RDS Instance demonstrating complex object expressions
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.formatted_name}-db"
  
  engine    = var.database_config.engine
  engine_version = var.database_config.version
  instance_class = var.database_config.instance_class
  
  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.allocated_storage * 2
  
  db_name  = var.database_config.db_name
  username = var.database_config.username
  password = random_string.password.result
  
  vpc_security_group_ids = [aws_security_group.web.id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.database_config.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  
  multi_az = var.environment == "production" ? true : false
  
  skip_final_snapshot = var.environment != "production"
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-db"
    Type = "Database Instance"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.formatted_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-db-subnet-group"
    Type = "DB Subnet Group"
  })
}

# CloudWatch Log Group demonstrating conditional creation
resource "aws_cloudwatch_log_group" "main" {
  count = var.monitoring_enabled ? 1 : 0
  
  name              = "/aws/ec2/${local.formatted_name}"
  retention_in_days = local.monitoring_config.retention_days
  
  tags = merge(local.common_tags, {
    Name = "${local.formatted_name}-logs"
    Type = "CloudWatch Log Group"
  })
}
