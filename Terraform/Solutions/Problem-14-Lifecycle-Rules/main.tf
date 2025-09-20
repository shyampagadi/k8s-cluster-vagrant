# Lifecycle Rules - AWS Examples

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
      Purpose     = "Lifecycle Rules Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for lifecycle optimization
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Environment-specific lifecycle configurations
  is_production = var.environment == "production"
  is_staging = var.environment == "staging"
  is_development = var.environment == "development"
  
  # Environment-specific configurations
  instance_config = {
    count = local.is_production ? 3 : (local.is_staging ? 2 : 1)
    type = local.is_production ? "t3.large" : (local.is_staging ? "t3.medium" : "t3.micro")
    monitoring = local.is_production ? true : false
  }
  
  # Lifecycle configurations
  lifecycle_config = {
    create_before_destroy = local.is_production ? true : false
    prevent_destroy = local.is_production ? true : false
    ignore_changes = [
      "tags[\"LastModified\"]",
      "tags[\"ModifiedBy\"]"
    ]
  }
}

# VPC with prevent_destroy for production
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Prevent accidental deletion of VPC
  lifecycle {
    prevent_destroy = local.is_production ? true : false
  }
  
  tags = {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# EC2 Instances with create_before_destroy for zero-downtime deployments
resource "aws_instance" "web" {
  count = local.instance_config.count
  
  ami           = var.ami_id
  instance_type = local.instance_config.type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.instance_config.monitoring
  
  # Create new instance before destroying old one
  lifecycle {
    create_before_destroy = local.lifecycle_config.create_before_destroy
    prevent_destroy = local.lifecycle_config.prevent_destroy
    ignore_changes = local.lifecycle_config.ignore_changes
  }
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    lifecycle_demo = "active"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    InstanceType = local.instance_config.type
    Monitoring = local.instance_config.monitoring ? "Enabled" : "Disabled"
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# RDS Instance with combined lifecycle rules
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
  
  skip_final_snapshot = var.environment != "production"
  
  # Combined lifecycle rules
  lifecycle {
    create_before_destroy = local.lifecycle_config.create_before_destroy  # Zero-downtime deployment
    prevent_destroy = local.lifecycle_config.prevent_destroy         # Prevent accidental deletion
    ignore_changes = [
      "password",                   # Ignore password changes
      "tags[\"LastModified\"]",     # Ignore external tag changes
      "tags[\"ModifiedBy\"]"        # Ignore external tag changes
    ]
  }
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    InstanceClass = var.database_instance_class
    MultiAZ = var.enable_multi_az ? "Enabled" : "Disabled"
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# S3 Bucket with prevent_destroy for production
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  # Prevent accidental deletion of production bucket
  lifecycle {
    prevent_destroy = local.is_production ? true : false
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_encryption ? 1 : 0
  
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# S3 Object with ignore_changes for external modifications
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    instance_count = local.instance_config.count
    lifecycle_demo = "active"
  })
  
  content_type = "text/plain"
  
  # Ignore changes to content made outside Terraform
  lifecycle {
    ignore_changes = ["content", "tags[\"LastModified\"]"]
  }
  
  tags = {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# CloudWatch Log Group with ignore_changes
resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  # Ignore changes to retention_in_days made outside Terraform
  lifecycle {
    ignore_changes = ["retention_in_days", "tags[\"LastModified\"]"]
  }
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Load Balancer with create_before_destroy
resource "aws_lb" "web" {
  count = var.create_load_balancer ? 1 : 0
  
  name               = "${local.resource_prefix}-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  # Create new load balancer before destroying old one
  lifecycle {
    create_before_destroy = local.lifecycle_config.create_before_destroy
    prevent_destroy = local.lifecycle_config.prevent_destroy
    ignore_changes = local.lifecycle_config.ignore_changes
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-lb"
    Type = "Application Load Balancer"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Load Balancer Target Group
resource "aws_lb_target_group" "web" {
  count = var.create_load_balancer ? 1 : 0
  
  name     = "${local.resource_prefix}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-tg"
    Type = "Load Balancer Target Group"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "web" {
  count = var.create_load_balancer ? 1 : 0
  
  load_balancer_arn = aws_lb.web[0].arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web[0].arn
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-listener"
    Type = "Load Balancer Listener"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
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
