# Locals and Functions - AWS Examples

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
      Purpose     = "Locals Functions Demo"
    }
  }
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for data transformation and computation
locals {
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # String functions
  project_name_clean = replace(var.project_name, "-", "_")
  project_name_upper = upper(var.project_name)
  project_name_lower = lower(var.project_name)
  project_name_title = title(var.project_name)
  
  # String formatting and concatenation
  formatted_name = format("%s-%s-%s", var.project_name, var.environment, var.aws_region)
  resource_naming = {
    prefix = "${var.project_name}-${var.environment}"
    suffix = var.environment
    environment = var.environment
  }
  
  # Numeric functions
  instance_count = max(1, min(10, var.instance_count))
  total_cost = var.instance_count * var.instance_hourly_cost
  average_cost = var.total_cost / var.instance_count
  rounded_cost = round(local.average_cost)
  
  # Numeric validation and bounds
  bounded_count = max(1, min(10, var.instance_count))
  valid_percentage = max(0, min(100, var.cpu_threshold))
  
  # Numeric conversions
  gb_to_mb = var.storage_gb * 1024
  hours_to_seconds = var.duration_hours * 3600
  
  # Collection functions - Lists
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  sorted_zones = sort(local.availability_zones)
  reversed_zones = reverse(local.availability_zones)
  filtered_zones = [for az in local.availability_zones : az if can(regex("us-west-2", az))]
  transformed_zones = [for az in local.availability_zones : upper(az)]
  zone_count = length(local.availability_zones)
  first_zone = local.availability_zones[0]
  last_zone = local.availability_zones[length(local.availability_zones) - 1]
  all_zones = concat(local.availability_zones, ["us-west-2d"])
  unique_zones = distinct(local.all_zones)
  
  # Collection functions - Maps
  server_configs = {
    web1 = { type = "t3.micro", disk = 20, cost = 0.01 }
    web2 = { type = "t3.micro", disk = 20, cost = 0.01 }
    app1 = { type = "t3.small", disk = 50, cost = 0.02 }
    app2 = { type = "t3.small", disk = 50, cost = 0.02 }
  }
  
  web_servers = {
    for name, config in local.server_configs : name => config
    if can(regex("web", name))
  }
  
  transformed_configs = {
    for name, config in local.server_configs : name => {
      type = config.type
      disk_size = config.disk * 1024  # Convert GB to MB
      cost = config.cost
    }
  }
  
  config_count = length(local.server_configs)
  config_keys = keys(local.server_configs)
  config_values = values(local.server_configs)
  
  additional_configs = {
    db1 = { type = "db.t3.micro", disk = 100, cost = 0.05 }
  }
  all_configs = merge(local.server_configs, local.additional_configs)
  
  # Collection functions - Sets
  security_groups = toset(["web", "app", "database"])
  additional_groups = toset(["monitoring", "logging"])
  all_groups = union(local.security_groups, local.additional_groups)
  common_groups = intersection(local.security_groups, local.additional_groups)
  unique_groups = setsubtract(local.all_groups, local.common_groups)
  
  # Encoding functions
  encoded_password = base64encode(var.database_password)
  encoded_config = base64encode(jsonencode(var.app_config))
  decoded_password = base64decode(local.encoded_password)
  decoded_config = jsondecode(base64decode(local.encoded_config))
  
  url_encoded_name = urlencode(var.project_name)
  url_encoded_path = urlencode("/api/v1/users")
  
  json_config = jsonencode({
    app_name = var.app_name
    environment = var.environment
    features = var.enabled_features
  })
  
  yaml_config = yamlencode({
    app_name = var.app_name
    environment = var.environment
    features = var.enabled_features
  })
  
  # File functions
  config_content = file("${path.module}/config/app.conf")
  json_config_file = jsondecode(file("${path.module}/config/app.json"))
  config_exists = fileexists("${path.module}/config/app.conf")
  config_hash = filesha256("${path.module}/config/app.conf")
  config_size = filesize("${path.module}/config/app.conf")
  config_files = fileset("${path.module}/config", "*.conf")
  all_files = fileset("${path.module}", "**/*")
  
  # Template functions
  user_data = templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_count = var.instance_count
    project_name_clean = local.project_name_clean
    project_name_upper = local.project_name_upper
  })
  
  config_template = templatefile("${path.module}/templates/app.conf", {
    app_name = var.app_name
    environment = var.environment
    features = var.enabled_features
    database_config = var.database_config
    json_config = local.json_config
    yaml_config = local.yaml_config
  })
  
  # Advanced function combinations
  transformed_data = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size_mb = config.disk_size_gb * 1024
      formatted_name = format("%s-%s", var.project_name, name)
      encoded_config = base64encode(jsonencode(config))
    }
  }
  
  valid_configs = {
    for name, config in var.server_configs : name => config
    if config.disk_size_gb > 0 && can(regex("^t3\\.", config.instance_type))
  }
  
  cost_analysis = {
    total_cost = sum([for config in values(var.server_configs) : config.hourly_cost])
    average_cost = local.cost_analysis.total_cost / length(var.server_configs)
    max_cost = max([for config in values(var.server_configs) : config.hourly_cost])
    min_cost = min([for config in values(var.server_configs) : config.hourly_cost])
  }
  
  formatted_outputs = {
    for name, config in var.server_configs : name => {
      display_name = title(replace(name, "-", " "))
      formatted_cost = format("$%.2f/hour", config.hourly_cost)
      status = config.enabled ? "Active" : "Inactive"
    }
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
    ProjectNameClean = local.project_name_clean
    ProjectNameUpper = local.project_name_upper
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

# Subnets using collection functions
resource "aws_subnet" "public" {
  count = length(local.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = local.availability_zones[count.index]
    Environment = var.environment
    ZoneIndex = count.index + 1
  }
}

resource "aws_subnet" "private" {
  count = length(local.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.availability_zones[count.index]
  
  tags = {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    AZ   = local.availability_zones[count.index]
    Environment = var.environment
    ZoneIndex = count.index + 10
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

# Security Groups using collection functions
resource "aws_security_group" "web" {
  for_each = local.security_groups
  
  name_prefix = "${each.value}-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = each.value
    Type = "Security Group"
    Environment = var.environment
  }
}

# EC2 Instances using numeric functions
resource "aws_instance" "web" {
  count = local.bounded_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web["web"].id]
  
  monitoring = var.enable_monitoring
  
  user_data = base64encode(local.user_data)
  
  tags = {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    Environment = var.environment
    InstanceCount = local.bounded_count
    TotalCost = format("$%.2f", local.total_cost)
    AverageCost = format("$%.2f", local.average_cost)
  }
}

# RDS Instance using encoding functions
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
  password = local.decoded_password  # Using decoded password
  
  vpc_security_group_ids = [aws_security_group.web["database"].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Environment = var.environment
    EncodedConfig = local.encoded_config
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

# S3 Bucket using string functions
resource "aws_s3_bucket" "main" {
  bucket = "${local.project_name_clean}-${var.environment}-bucket"
  
  tags = {
    Name = "${local.project_name_clean}-${var.environment}-bucket"
    Type = "S3 Bucket"
    Environment = var.environment
    ProjectNameClean = local.project_name_clean
    ProjectNameUpper = local.project_name_upper
  }
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
  count = var.enable_encryption ? 1 : 0
  
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

# S3 Object using template functions
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.main.id
  key    = "config/app.conf"
  
  content = local.config_template
  
  content_type = "text/plain"
  
  tags = {
    Name = "${local.resource_prefix}-config"
    Type = "S3 Object"
    Environment = var.environment
    ConfigHash = local.config_hash
    ConfigSize = local.config_size
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_monitoring ? 1 : 0
  
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
