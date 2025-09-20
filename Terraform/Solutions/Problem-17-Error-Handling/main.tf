# Error Handling and Validation - AWS Examples

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

# Configure AWS Provider with error handling
provider "aws" {
  region = var.aws_region
  
  # Validate region
  lifecycle {
    precondition {
      condition = can(regex("^[a-z0-9-]+$", var.aws_region))
      error_message = "AWS region must be a valid region identifier."
    }
  }
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Error Handling Demo"
    }
  }
}

# Generate random values with error handling
resource "random_id" "suffix" {
  byte_length = 4
  
  # Validate byte length
  lifecycle {
    precondition {
      condition = var.random_byte_length >= 1 && var.random_byte_length <= 8
      error_message = "Random byte length must be between 1 and 8."
    }
  }
}

# Local values for error handling
locals {
  # Resource naming with validation
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Environment-specific configurations with validation
  environment_config = {
    dev = {
      instance_count = 1
      instance_type = "t3.micro"
      enable_monitoring = false
      enable_encryption = false
      backup_retention = 1
    }
    staging = {
      instance_count = 2
      instance_type = "t3.small"
      enable_monitoring = true
      enable_encryption = true
      backup_retention = 7
    }
    prod = {
      instance_count = 3
      instance_type = "t3.large"
      enable_monitoring = true
      enable_encryption = true
      backup_retention = 30
    }
  }
  
  # Current environment configuration with validation
  current_config = try(
    local.environment_config[var.environment],
    local.environment_config["dev"]
  )
  
  # Validate environment configuration
  environment_validation = {
    for env, config in local.environment_config : env => {
      valid = config.instance_count >= 1 && config.instance_count <= 10
      message = "Instance count must be between 1 and 10 for environment ${env}"
    }
  }
}

# Data sources with error handling
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  
  # Validate AMI exists
  lifecycle {
    postcondition {
      condition = self.id != ""
      error_message = "Ubuntu AMI not found. Please check AMI availability."
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
  
  # Validate availability zones
  lifecycle {
    postcondition {
      condition = length(self.names) >= 2
      error_message = "At least 2 availability zones must be available."
    }
  }
}

# VPC with comprehensive validation
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Validate VPC CIDR
  lifecycle {
    precondition {
      condition = can(cidrhost(var.vpc_cidr, 0))
      error_message = "VPC CIDR must be a valid IPv4 CIDR block."
    }
  }
  
  # Validate VPC CIDR range
  lifecycle {
    precondition {
      condition = can(cidrsubnet(var.vpc_cidr, 8, 0))
      error_message = "VPC CIDR must have at least /24 subnet capacity."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# Internet Gateway with validation
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  # Validate VPC exists
  lifecycle {
    precondition {
      condition = aws_vpc.main.id != ""
      error_message = "VPC must exist before creating Internet Gateway."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# Subnets with validation
resource "aws_subnet" "public" {
  count = var.subnet_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  
  # Validate subnet CIDR
  lifecycle {
    precondition {
      condition = can(cidrhost(cidrsubnet(var.vpc_cidr, 8, count.index), 0))
      error_message = "Subnet CIDR must be valid for index ${count.index}."
    }
  }
  
  # Validate availability zone
  lifecycle {
    precondition {
      condition = count.index < length(data.aws_availability_zones.available.names)
      error_message = "Subnet count exceeds available zones."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
    SubnetType = "Public"
    Index = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  # Validate subnet CIDR
  lifecycle {
    precondition {
      condition = can(cidrhost(cidrsubnet(var.vpc_cidr, 8, count.index + 10), 0))
      error_message = "Private subnet CIDR must be valid for index ${count.index}."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
    SubnetType = "Private"
    Index = count.index + 1
  }
}

# Route Table with validation
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  # Validate Internet Gateway exists
  lifecycle {
    precondition {
      condition = aws_internet_gateway.main.id != ""
      error_message = "Internet Gateway must exist before creating route table."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# Route Table Associations with validation
resource "aws_route_table_association" "public" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  # Validate subnet exists
  lifecycle {
    precondition {
      condition = aws_subnet.public[count.index].id != ""
      error_message = "Public subnet must exist before creating route table association."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# Security Groups with validation
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
  
  # SSH access with validation
  dynamic "ingress" {
    for_each = var.ssh_cidr_blocks
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Validate VPC exists
  lifecycle {
    precondition {
      condition = aws_vpc.main.id != ""
      error_message = "VPC must exist before creating security group."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
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
  
  # Validate database port
  lifecycle {
    precondition {
      condition = var.database_port >= 1024 && var.database_port <= 65535
      error_message = "Database port must be between 1024 and 65535."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
    SecurityGroupType = "Database"
  }
}

# EC2 Instances with comprehensive validation
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_config.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  monitoring = local.current_config.enable_monitoring
  
  # Validate instance type
  lifecycle {
    precondition {
      condition = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", local.current_config.instance_type))
      error_message = "Instance type must be in format 'family.size'."
    }
  }
  
  # Validate AMI
  lifecycle {
    precondition {
      condition = data.aws_ami.ubuntu.id != ""
      error_message = "AMI must be available."
    }
  }
  
  # Validate subnet
  lifecycle {
    precondition {
      condition = aws_subnet.public[count.index % length(aws_subnet.public)].id != ""
      error_message = "Subnet must exist before creating instance."
    }
  }
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    project_name = var.project_name
    error_handling = "enabled"
  }))
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
    InstanceType = local.current_config.instance_type
    Monitoring = local.current_config.enable_monitoring ? "Enabled" : "Disabled"
  }
}

# RDS Instance with comprehensive validation
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
  
  backup_retention_period = local.current_config.backup_retention
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "prod"
  
  # Validate database engine
  lifecycle {
    precondition {
      condition = contains(["mysql", "postgres", "oracle-ee", "sqlserver-ee"], var.database_engine)
      error_message = "Database engine must be mysql, postgres, oracle-ee, or sqlserver-ee."
    }
  }
  
  # Validate instance class
  lifecycle {
    precondition {
      condition = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.database_instance_class))
      error_message = "Database instance class must be a valid RDS instance class."
    }
  }
  
  # Validate allocated storage
  lifecycle {
    precondition {
      condition = var.database_allocated_storage >= 20 && var.database_allocated_storage <= 1000
      error_message = "Database allocated storage must be between 20 and 1000 GB."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
    Engine = var.database_engine
    Version = var.database_version
  }
}

# DB Subnet Group with validation
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  # Validate subnet count
  lifecycle {
    precondition {
      condition = length(aws_subnet.private) >= 2
      error_message = "At least 2 private subnets required for database subnet group."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# S3 Bucket with validation
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  # Validate bucket name
  lifecycle {
    precondition {
      condition = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", "${local.resource_prefix}-bucket"))
      error_message = "S3 bucket name must be valid."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# S3 Bucket Versioning with validation
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
  
  # Validate bucket exists
  lifecycle {
    precondition {
      condition = aws_s3_bucket.main.id != ""
      error_message = "S3 bucket must exist before configuring versioning."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# S3 Bucket Encryption with validation
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = local.current_config.enable_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  # Validate bucket exists
  lifecycle {
    precondition {
      condition = aws_s3_bucket.main.id != ""
      error_message = "S3 bucket must exist before configuring encryption."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# S3 Bucket Public Access Block with validation
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
  
  # Validate bucket exists
  lifecycle {
    precondition {
      condition = aws_s3_bucket.main.id != ""
      error_message = "S3 bucket must exist before configuring public access block."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# CloudWatch Log Group with validation
resource "aws_cloudwatch_log_group" "main" {
  count = local.current_config.enable_monitoring ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  
  # Validate log retention days
  lifecycle {
    precondition {
      condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 3653], var.log_retention_days)
      error_message = "Log retention days must be a valid CloudWatch retention period."
    }
  }
  
  tags = {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Validated"
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = local.current_config.enable_monitoring ? length(aws_instance.web) : 0
  
  alarm_name          = "${local.resource_prefix}-cpu-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = {
    Name = "${local.resource_prefix}-cpu-alarm-${count.index + 1}"
    Type = "CloudWatch Alarm"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Monitored"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  count = local.current_config.enable_monitoring ? length(aws_instance.web) : 0
  
  alarm_name          = "${local.resource_prefix}-disk-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors disk utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = {
    Name = "${local.resource_prefix}-disk-alarm-${count.index + 1}"
    Type = "CloudWatch Alarm"
    Environment = var.environment
    Project = var.project_name
    ErrorHandling = "Monitored"
  }
}
