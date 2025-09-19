# Resource Lifecycle and State Management - AWS Examples

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
  
  # Remote state backend configuration
  backend "s3" {
    # Configure these values in backend configuration
    # bucket         = "my-terraform-state"
    # key            = "path/to/my/key"
    # region         = "us-west-2"
    # dynamodb_table = "terraform-locks"
    # encrypt        = true
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
      Purpose     = "Resource Lifecycle Demo"
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

# Local values for common configurations
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "Resource Lifecycle Demo"
  }
}

# VPC - Demonstrates basic resource lifecycle
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = var.prevent_destroy
    ignore_changes        = [tags["LastModified"]]
  }
}

# Internet Gateway - Demonstrates dependency management
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# Subnets - Demonstrates resource creation and dependency
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.availability_zones[count.index]
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = var.availability_zones[count.index]
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# Route Table - Demonstrates resource relationships
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-private-rt"
    Type = "Private Route Table"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# Route Table Associations - Demonstrates explicit dependencies
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  # Explicit dependency demonstration
  depends_on = [aws_route_table.public, aws_subnet.public]
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
  
  # Explicit dependency demonstration
  depends_on = [aws_route_table.private, aws_subnet.private]
}

# Security Groups - Demonstrates resource updates
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
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
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${local.resource_prefix}-db-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instances - Demonstrates resource lifecycle and state management
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # User data for demonstration
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name    = var.app_name
    environment = var.environment
    instance_id = count.index + 1
  }))
  
  # Conditional monitoring
  monitoring = var.enable_monitoring
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Role = "Web Server"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = var.prevent_destroy
    ignore_changes        = [tags["LastModified"], user_data]
  }
}

# RDS Instance - Demonstrates complex resource lifecycle
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.resource_prefix}-db"
  
  engine    = var.database_config.engine
  engine_version = var.database_config.engine_version
  instance_class = var.database_config.instance_class
  
  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.allocated_storage * 2
  
  db_name  = var.database_config.db_name
  username = var.database_config.username
  password = random_string.password.result
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.database_config.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  
  multi_az = var.environment == "production" ? true : false
  
  skip_final_snapshot = var.environment != "production"
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Role = "Database"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = var.prevent_destroy
    ignore_changes        = [password, tags["LastModified"]]
  }
}

# DB Subnet Group - Demonstrates resource dependencies
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# S3 Bucket - Demonstrates resource state management
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes  = [tags["LastModified"]]
  }
}

# S3 Bucket Versioning - Demonstrates resource updates
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.environment == "production" ? "Enabled" : "Suspended"
  }
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
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
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# S3 Object - Demonstrates resource creation and updates
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    instance_count = var.instance_count
    database_endpoint = var.create_database ? aws_db_instance.main[0].endpoint : "localhost:3306"
  })
  
  content_type = "text/plain"
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group - Demonstrates conditional resource creation
resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.monitoring_config.retention_days
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
  })
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}

# Data Sources - Demonstrates data source lifecycle
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

# Null Resource - Demonstrates resource lifecycle without cloud resources
resource "null_resource" "example" {
  count = var.create_example_resource ? 1 : 0
  
  # Triggers for resource recreation
  triggers = {
    app_name = var.app_name
    environment = var.environment
    timestamp = timestamp()
  }
  
  # Provisioner demonstration
  provisioner "local-exec" {
    command = "echo 'Resource lifecycle demo completed'"
  }
  
  # Lifecycle rules demonstration
  lifecycle {
    create_before_destroy = true
  }
}
