# Workspaces and Environment Management - AWS Examples

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
      Environment = terraform.workspace
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Workspaces Demo"
      Workspace   = terraform.workspace
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for workspace management
locals {
  # Workspace validation
  valid_workspaces = ["dev", "staging", "prod"]
  
  # Validate current workspace
  current_workspace = contains(local.valid_workspaces, terraform.workspace) ? terraform.workspace : "dev"
  
  # Workspace-specific resource naming
  resource_prefix = "${var.project_name}-${local.current_workspace}"
  
  # Workspace-specific CIDR blocks
  workspace_cidrs = {
    dev = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod = "10.2.0.0/16"
  }
  
  # Workspace-specific availability zones
  workspace_azs = {
    dev = ["us-west-2a", "us-west-2b"]
    staging = ["us-west-2a", "us-west-2b", "us-west-2c"]
    prod = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
  
  # Current workspace configuration
  current_cidr = local.workspace_cidrs[local.current_workspace]
  current_azs = local.workspace_azs[local.current_workspace]
  
  # Workspace-specific instance configurations
  instance_configs = {
    dev = {
      count = 1
      type = "t3.micro"
      monitoring = false
      encryption = false
    }
    staging = {
      count = 2
      type = "t3.small"
      monitoring = true
      encryption = true
    }
    prod = {
      count = 3
      type = "t3.large"
      monitoring = true
      encryption = true
    }
  }
  
  # Workspace-specific database configurations
  database_configs = {
    dev = {
      instance_class = "db.t3.micro"
      allocated_storage = 20
      multi_az = false
      backup_retention = 1
    }
    staging = {
      instance_class = "db.t3.small"
      allocated_storage = 50
      multi_az = false
      backup_retention = 7
    }
    prod = {
      instance_class = "db.r5.large"
      allocated_storage = 100
      multi_az = true
      backup_retention = 30
    }
  }
  
  # Workspace-specific feature flags
  feature_flags = {
    dev = {
      enable_monitoring = false
      enable_logging = false
      enable_backup = false
      enable_ssl = false
      enable_waf = false
    }
    staging = {
      enable_monitoring = true
      enable_logging = true
      enable_backup = true
      enable_ssl = true
      enable_waf = false
    }
    prod = {
      enable_monitoring = true
      enable_logging = true
      enable_backup = true
      enable_ssl = true
      enable_waf = true
    }
  }
  
  # Workspace-specific security configurations
  security_configs = {
    dev = {
      allowed_cidrs = ["0.0.0.0/0"]
      ssl_certificate = "self-signed"
      encryption_at_rest = false
      encryption_in_transit = false
    }
    staging = {
      allowed_cidrs = ["10.0.0.0/8"]
      ssl_certificate = "staging-cert"
      encryption_at_rest = true
      encryption_in_transit = true
    }
    prod = {
      allowed_cidrs = ["10.0.0.0/8"]
      ssl_certificate = "production-cert"
      encryption_at_rest = true
      encryption_in_transit = true
    }
  }
  
  # Current workspace configurations
  current_instance_config = local.instance_configs[local.current_workspace]
  current_database_config = local.database_configs[local.current_workspace]
  current_features = local.feature_flags[local.current_workspace]
  current_security = local.security_configs[local.current_workspace]
  
  # Production-grade workspace configurations
  production_configs = {
    dev = {
      environment = "development"
      tier = "development"
      cost_center = "engineering"
      backup_schedule = "daily"
      monitoring_level = "basic"
      alerting = false
    }
    staging = {
      environment = "staging"
      tier = "staging"
      cost_center = "engineering"
      backup_schedule = "daily"
      monitoring_level = "standard"
      alerting = true
    }
    prod = {
      environment = "production"
      tier = "production"
      cost_center = "operations"
      backup_schedule = "hourly"
      monitoring_level = "comprehensive"
      alerting = true
    }
  }
  
  # Current production configuration
  current_production_config = local.production_configs[local.current_workspace]
}

# VPC with workspace-specific CIDR
resource "aws_vpc" "main" {
  cidr_block           = local.current_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    CIDR = local.current_cidr
    Tier = local.current_production_config.tier
    CostCenter = local.current_production_config.cost_center
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# Subnets with workspace-specific availability zones
resource "aws_subnet" "public" {
  count = length(local.current_azs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.current_cidr, 8, count.index)
  availability_zone       = local.current_azs[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = local.current_azs[count.index]
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

resource "aws_subnet" "private" {
  count = length(local.current_azs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.current_cidr, 8, count.index + 10)
  availability_zone = local.current_azs[count.index]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = local.current_azs[count.index]
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
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
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
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
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# Security Groups with workspace-specific configurations
resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules based on workspace
  dynamic "ingress" {
    for_each = local.current_security.allowed_cidrs
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  
  # Dynamic SSL ingress for staging and production
  dynamic "ingress" {
    for_each = local.current_features.enable_ssl ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.current_security.allowed_cidrs
    }
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
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
    SSL = local.current_features.enable_ssl ? "Enabled" : "Disabled"
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
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# EC2 Instances with workspace-specific configurations
resource "aws_instance" "web" {
  count = local.current_instance_config.count
  
  ami           = var.ami_id
  instance_type = local.current_instance_config.type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.current_instance_config.monitoring
  
  # Production-grade lifecycle rules
  lifecycle {
    create_before_destroy = local.current_workspace == "prod" ? true : false
    prevent_destroy = local.current_workspace == "prod" ? true : false
    ignore_changes = [
      "tags[\"LastModified\"]",
      "tags[\"ModifiedBy\"]"
    ]
  }
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = local.current_workspace
    instance_id = count.index + 1
    workspace = terraform.workspace
    tier = local.current_production_config.tier
    cost_center = local.current_production_config.cost_center
  }))
  
  tags = merge({
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    InstanceType = local.current_instance_config.type
    Monitoring = local.current_instance_config.monitoring ? "Enabled" : "Disabled"
    Tier = local.current_production_config.tier
    CostCenter = local.current_production_config.cost_center
    BackupSchedule = local.current_production_config.backup_schedule
    MonitoringLevel = local.current_production_config.monitoring_level
    Alerting = local.current_production_config.alerting
  }, var.additional_tags)
}

# RDS Instance with workspace-specific configurations
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "${local.resource_prefix}-db"
  
  engine    = var.database_engine
  engine_version = var.database_version
  instance_class = local.current_database_config.instance_class
  
  allocated_storage     = local.current_database_config.allocated_storage
  max_allocated_storage = local.current_database_config.allocated_storage * 2
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  multi_az = local.current_database_config.multi_az
  backup_retention_period = local.current_database_config.backup_retention
  
  skip_final_snapshot = local.current_workspace != "prod"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    InstanceClass = local.current_database_config.instance_class
    MultiAZ = local.current_database_config.multi_az ? "Enabled" : "Disabled"
    Tier = local.current_production_config.tier
    CostCenter = local.current_production_config.cost_center
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
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# S3 Bucket with workspace-specific naming
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
    CostCenter = local.current_production_config.cost_center
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = local.current_features.enable_backup ? "Enabled" : "Suspended"
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = local.current_instance_config.encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = local.current_workspace == "prod" ? true : false
  block_public_policy     = local.current_workspace == "prod" ? true : false
  ignore_public_acls      = local.current_workspace == "prod" ? true : false
  restrict_public_buckets = local.current_workspace == "prod" ? true : false
  
  tags = {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# S3 Object with workspace-specific configuration
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = local.current_workspace
    workspace = terraform.workspace
    tier = local.current_production_config.tier
    cost_center = local.current_production_config.cost_center
    backup_schedule = local.current_production_config.backup_schedule
    monitoring_level = local.current_production_config.monitoring_level
  })
  
  content_type = "text/plain"
  
  tags = {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
  }
}

# CloudWatch Log Group with workspace-specific configuration
resource "aws_cloudwatch_log_group" "main" {
  count = local.current_features.enable_logging ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = local.current_workspace
    Workspace = terraform.workspace
    Tier = local.current_production_config.tier
    MonitoringLevel = local.current_production_config.monitoring_level
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
