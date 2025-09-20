# Variables - Complex Types and Validation - AWS Examples

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
    tags = merge(var.environment_tags, {
      ManagedBy = "Terraform"
      Purpose   = "Complex Variables Demo"
    })
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values demonstrating complex variable usage
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Transform list variables
  instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
  subnet_cidrs = [for i in range(length(var.availability_zones)) : cidrsubnet(var.vpc_cidr, 8, i)]
  
  # Transform map variables
  server_configs = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size     = config.disk_size * 1024  # Convert GB to MB
      monitoring    = config.monitoring
      environment   = config.environment
    }
  }
  
  # Filter and transform based on environment
  production_configs = {
    for name, config in var.server_configs : name => config
    if config.environment == "production"
  }
  
  # Transform object variables
  database_config = {
    engine    = var.database_config.engine
    version   = var.database_config.version
    instance_class = var.database_config.instance_class
    allocated_storage = var.database_config.allocated_storage
    backup_retention_period = var.database_config.backup_retention_period
    multi_az  = var.database_config.multi_az
    db_name   = var.database_config.db_name
    username  = var.database_config.username
  }
  
  # Transform tuple variables
  server_info = {
    name = var.server_info[0]
    count = var.server_info[1]
    enabled = var.server_info[2]
  }
  
  # Complex conditional logic
  enable_monitoring = var.enable_monitoring && var.environment == "production"
  enable_encryption = var.enable_encryption || var.environment == "production"
  
  # Complex calculations
  total_cost = var.instance_count * var.hourly_rate * 24 * 30  # Monthly cost
  backup_retention = var.environment == "production" ? var.backup_retention_production : var.backup_retention_development
}

# VPC demonstrating complex variable usage
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
  })
}

# Subnets demonstrating list variable usage
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.availability_zones[count.index]
    Index = count.index + 1
  })
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = var.availability_zones[count.index]
    Index = count.index + 10
  })
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups demonstrating complex variable usage
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules using list of objects
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress rules using list of objects
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
  })
}

resource "aws_security_group" "database" {
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
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
  })
}

# EC2 Instances demonstrating map variable usage
resource "aws_instance" "web" {
  for_each = local.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Conditional monitoring based on complex variables
  monitoring = each.value.monitoring && local.enable_monitoring
  
  # User data with complex variable interpolation
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    server_name = each.key
    server_config = each.value
    enable_monitoring = each.value.monitoring
    enable_encryption = local.enable_encryption
  }))
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-${each.key}"
    Type = "EC2 Instance"
    ServerName = each.key
    InstanceType = each.value.instance_type
    DiskSize = each.value.disk_size
    Monitoring = each.value.monitoring
    Environment = each.value.environment
  })
}

# RDS Instance demonstrating object variable usage
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.resource_prefix}-db"
  
  engine    = local.database_config.engine
  engine_version = local.database_config.version
  instance_class = local.database_config.instance_class
  
  allocated_storage     = local.database_config.allocated_storage
  max_allocated_storage = local.database_config.allocated_storage * 2
  
  db_name  = local.database_config.db_name
  username = local.database_config.username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = local.backup_retention
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = local.database_config.multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Engine = local.database_config.engine
    Version = local.database_config.version
    InstanceClass = local.database_config.instance_class
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
  })
}

# S3 Bucket demonstrating complex variable usage
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Encryption
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

# S3 Object demonstrating complex variable usage
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    server_configs = var.server_configs
    database_config = local.database_config
    enable_monitoring = local.enable_monitoring
    enable_encryption = local.enable_encryption
  })
  
  content_type = "text/plain"
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  count = local.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = merge(var.environment_tags, {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
  })
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
