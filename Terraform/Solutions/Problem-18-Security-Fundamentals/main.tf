# Security Fundamentals - AWS Examples

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
  
  # Secure remote state backend (commented for demo)
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "path/to/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  #   kms_key_id     = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  # }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "Security Demo"
      SecurityLevel = var.security_level
    }
  }
}

# Generate random values for secure naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Generate secure random password
resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Local values for security
locals {
  # Resource naming with security prefix
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  
  # Common security tags
  security_tags = {
    Environment = var.environment
    Project = var.project_name
    SecurityLevel = var.security_level
    Compliance = var.compliance_level
    DataClass = var.data_classification
    Backup = var.backup_required ? "Required" : "Optional"
    Monitoring = var.monitoring_enabled ? "Enabled" : "Disabled"
    Encryption = var.encryption_enabled ? "Enabled" : "Disabled"
  }
  
  # Environment-specific security configurations
  security_config = {
    dev = {
      encryption_enabled = true
      backup_retention = 7
      monitoring_enabled = true
      compliance_level = "basic"
    }
    staging = {
      encryption_enabled = true
      backup_retention = 14
      monitoring_enabled = true
      compliance_level = "standard"
    }
    prod = {
      encryption_enabled = true
      backup_retention = 30
      monitoring_enabled = true
      compliance_level = "high"
    }
  }
  
  # Current security configuration
  current_security = local.security_config[var.environment]
}

# Data sources for security
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

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-kms-key"
    Type = "KMS Key"
    Purpose = "Encryption"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.resource_prefix}-key"
  target_key_id = aws_kms_key.main.key_id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-kms-alias"
    Type = "KMS Alias"
  })
}

# Secure VPC
resource "aws_vpc" "secure_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-secure-vpc"
    Type = "VPC"
    SecurityLevel = "High"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.secure_vpc.id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-igw"
    Type = "Internet Gateway"
  })
}

# Private subnets for sensitive resources
resource "aws_subnet" "private" {
  count = var.subnet_count
  
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone  = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-private-${count.index + 1}"
    Type = "Private Subnet"
    SecurityLevel = "High"
    SubnetType = "Private"
  })
}

# Public subnets for load balancers
resource "aws_subnet" "public" {
  count = var.subnet_count
  
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone        = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    SecurityLevel = "Medium"
    SubnetType = "Public"
  })
}

# Route Table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.secure_vpc.id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-private-rt"
    Type = "Private Route Table"
  })
}

# Route Table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.secure_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-public-rt"
    Type = "Public Route Table"
  })
}

# Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-private-rta-${count.index + 1}"
    Type = "Route Table Association"
  })
}

resource "aws_route_table_association" "public" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-public-rta-${count.index + 1}"
    Type = "Route Table Association"
  })
}

# Security Groups with least privilege
resource "aws_security_group" "alb" {
  name_prefix = "${local.resource_prefix}-alb-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # HTTP access from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS access from internet
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
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-alb-sg"
    Type = "Security Group"
    SecurityGroupType = "ALB"
  })
}

resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # HTTP access from ALB only
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # HTTPS access from ALB only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # SSH access from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
    SecurityGroupType = "Web"
  })
}

resource "aws_security_group" "bastion" {
  name_prefix = "${local.resource_prefix}-bastion-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # SSH access from specific IPs
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
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-bastion-sg"
    Type = "Security Group"
    SecurityGroupType = "Bastion"
  })
}

resource "aws_security_group" "database" {
  count = var.create_database ? 1 : 0
  
  name_prefix = "${local.resource_prefix}-db-"
  vpc_id      = aws_vpc.secure_vpc.id
  
  # Database access from web servers only
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
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-db-sg"
    Type = "Security Group"
    SecurityGroupType = "Database"
    SecurityLevel = "Critical"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${local.resource_prefix}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-ec2-role"
    Type = "IAM Role"
  })
}

# IAM Policy for EC2 instances
resource "aws_iam_policy" "ec2_policy" {
  name = "${local.resource_prefix}-ec2-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "${aws_ssm_parameter.app_config.arn}"
      }
    ]
  })
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-ec2-policy"
    Type = "IAM Policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.resource_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-ec2-profile"
    Type = "IAM Instance Profile"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = var.environment == "prod"
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-alb"
    Type = "Application Load Balancer"
  })
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${local.resource_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.secure_vpc.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-tg"
    Type = "Target Group"
  })
}

# Load Balancer Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-listener"
    Type = "Load Balancer Listener"
  })
}

# EC2 Instances in private subnets
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  monitoring = var.monitoring_enabled
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    instance_id = count.index + 1
    project_name = var.project_name
    security_level = var.security_level
  }))
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
    InstanceType = var.instance_type
    Monitoring = var.monitoring_enabled ? "Enabled" : "Disabled"
  })
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "web" {
  count = var.instance_count
  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# RDS Instance with encryption
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
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  backup_retention_period = local.current_security.backup_retention
  backup_window          = var.backup_window
  maintenance_window      = var.maintenance_window
  
  multi_az = var.enable_multi_az
  
  skip_final_snapshot = var.environment != "prod"
  
  # Enable encryption
  storage_encrypted = local.current_security.encryption_enabled
  kms_key_id       = aws_kms_key.main.arn
  
  # Enable automated backups
  backup_enabled = var.backup_required
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-db"
    Type = "RDS Instance"
    Engine = var.database_engine
    Version = var.database_version
    SecurityLevel = "Critical"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_database ? 1 : 0
  
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
  })
}

# S3 Bucket with encryption
resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-bucket-versioning"
    Type = "S3 Bucket Versioning"
  })
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-bucket-encryption"
    Type = "S3 Bucket Encryption"
  })
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-bucket-pab"
    Type = "S3 Bucket Public Access Block"
  })
}

# AWS Secrets Manager for database password
resource "aws_secretsmanager_secret" "db_password" {
  count = var.create_database ? 1 : 0
  
  name                    = "${local.resource_prefix}-db-password"
  description             = "Database password for ${var.environment}"
  recovery_window_in_days = 7
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-db-password"
    Type = "Secret"
    SecurityLevel = "Critical"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count = var.create_database ? 1 : 0
  
  secret_id     = aws_secretsmanager_secret.db_password[0].id
  secret_string = random_password.db_password.result
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-db-password-version"
    Type = "Secret Version"
  })
}

# Parameter Store for configuration
resource "aws_ssm_parameter" "app_config" {
  name  = "/${var.environment}/${var.project_name}/app/config"
  type  = "String"
  value = jsonencode({
    database_host = var.create_database ? aws_db_instance.main[0].endpoint : null
    database_port = var.create_database ? aws_db_instance.main[0].port : null
    database_name = var.create_database ? aws_db_instance.main[0].db_name : null
    s3_bucket = aws_s3_bucket.main.id
    kms_key_id = aws_kms_key.main.arn
  })
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-app-config"
    Type = "Parameter"
  })
}

# CloudWatch Log Group with encryption
resource "aws_cloudwatch_log_group" "main" {
  count = var.monitoring_enabled ? 1 : 0
  
  name              = "/aws/ec2/${local.resource_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-logs"
    Type = "CloudWatch Log Group"
  })
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "audit_trail" {
  count = var.enable_audit_logging ? 1 : 0
  
  name                          = "${local.resource_prefix}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-audit-trail"
    Type = "CloudTrail"
    Purpose = "Audit"
  })
}

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  count = var.enable_audit_logging ? 1 : 0
  
  bucket = "${local.resource_prefix}-cloudtrail"
  
  tags = merge(local.security_tags, {
    Name = "${local.resource_prefix}-cloudtrail"
    Type = "S3 Bucket"
    Purpose = "CloudTrail"
  })
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_audit_logging ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
