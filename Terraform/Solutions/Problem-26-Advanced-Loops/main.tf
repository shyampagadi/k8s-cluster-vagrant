# Problem 26: Advanced Loops and Iteration Patterns
# Comprehensive advanced looping constructs and dynamic resource creation

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local values for complex iteration patterns
locals {
  # Multi-dimensional data structures for complex loops
  environments = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
      subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
      databases    = ["app", "cache"]
    }
    staging = {
      instance_type = "t3.small"
      min_size     = 2
      max_size     = 4
      subnets      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
      databases    = ["app", "cache", "analytics"]
    }
    prod = {
      instance_type = "t3.medium"
      min_size     = 3
      max_size     = 10
      subnets      = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24"]
      databases    = ["app", "cache", "analytics", "reporting"]
    }
  }
  
  # Flattened structure for cross-product iterations
  env_subnet_combinations = flatten([
    for env_name, env_config in local.environments : [
      for subnet_idx, subnet_cidr in env_config.subnets : {
        env_name    = env_name
        subnet_idx  = subnet_idx
        subnet_cidr = subnet_cidr
        config      = env_config
      }
    ]
  ])
  
  # Database configurations per environment
  env_database_combinations = flatten([
    for env_name, env_config in local.environments : [
      for db_name in env_config.databases : {
        env_name = env_name
        db_name  = db_name
        config   = env_config
      }
    ]
  ])
  
  # Security group rules matrix
  security_rules = {
    web = {
      ingress = [
        { port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "HTTP" },
        { port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "HTTPS" }
      ]
      egress = [
        { port = 0, protocol = "-1", cidr = "0.0.0.0/0", description = "All outbound" }
      ]
    }
    app = {
      ingress = [
        { port = 8080, protocol = "tcp", cidr = "10.0.0.0/8", description = "App port" },
        { port = 9090, protocol = "tcp", cidr = "10.0.0.0/8", description = "Metrics" }
      ]
      egress = [
        { port = 0, protocol = "-1", cidr = "0.0.0.0/0", description = "All outbound" }
      ]
    }
    db = {
      ingress = [
        { port = 3306, protocol = "tcp", cidr = "10.0.0.0/8", description = "MySQL" },
        { port = 5432, protocol = "tcp", cidr = "10.0.0.0/8", description = "PostgreSQL" }
      ]
      egress = []
    }
  }
}

# VPC creation using for_each with environments
resource "aws_vpc" "environments" {
  for_each = local.environments

  cidr_block           = "10.${each.key == "dev" ? 0 : each.key == "staging" ? 1 : 2}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${each.key}-vpc"
    Environment = each.key
  }
}

# Internet Gateways for each VPC
resource "aws_internet_gateway" "environments" {
  for_each = aws_vpc.environments

  vpc_id = each.value.id

  tags = {
    Name        = "${var.project_name}-${each.key}-igw"
    Environment = each.key
  }
}

# Subnets using nested loops with flattened structure
resource "aws_subnet" "all" {
  for_each = {
    for combo in local.env_subnet_combinations :
    "${combo.env_name}-${combo.subnet_idx}" => combo
  }

  vpc_id                  = aws_vpc.environments[each.value.env_name].id
  cidr_block              = each.value.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[each.value.subnet_idx % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${each.value.env_name}-subnet-${each.value.subnet_idx + 1}"
    Environment = each.value.env_name
    Type        = "Public"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route tables with dynamic associations
resource "aws_route_table" "environments" {
  for_each = aws_vpc.environments

  vpc_id = each.value.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.environments[each.key].id
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-rt"
    Environment = each.key
  }
}

# Route table associations using complex iteration
resource "aws_route_table_association" "all" {
  for_each = aws_subnet.all

  subnet_id      = each.value.id
  route_table_id = aws_route_table.environments[split("-", each.key)[0]].id
}

# Security groups with nested rule iteration
resource "aws_security_group" "all" {
  for_each = {
    for combo in flatten([
      for env_name in keys(local.environments) : [
        for sg_name in keys(local.security_rules) : {
          key     = "${env_name}-${sg_name}"
          env     = env_name
          sg_name = sg_name
          rules   = local.security_rules[sg_name]
        }
      ]
    ]) : combo.key => combo
  }

  name        = "${var.project_name}-${each.value.env}-${each.value.sg_name}-sg"
  description = "Security group for ${each.value.sg_name} in ${each.value.env}"
  vpc_id      = aws_vpc.environments[each.value.env].id

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = each.value.rules.ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }

  # Dynamic egress rules
  dynamic "egress" {
    for_each = each.value.rules.egress
    content {
      description = egress.value.description
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = [egress.value.cidr]
    }
  }

  tags = {
    Name        = "${var.project_name}-${each.value.env}-${each.value.sg_name}-sg"
    Environment = each.value.env
    Type        = each.value.sg_name
  }
}

# Launch templates with conditional configurations
resource "aws_launch_template" "environments" {
  for_each = local.environments

  name_prefix   = "${var.project_name}-${each.key}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.all["${each.key}-web"].id,
    aws_security_group.all["${each.key}-app"].id
  ]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = each.key
    databases   = join(",", each.value.databases)
  }))

  # Conditional block device mappings based on environment
  dynamic "block_device_mappings" {
    for_each = each.key == "prod" ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        volume_size = 50
        volume_type = "gp3"
        encrypted   = true
      }
    }
  }

  dynamic "block_device_mappings" {
    for_each = each.key != "prod" ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        volume_size = 20
        volume_type = "gp3"
        encrypted   = false
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${each.key}-instance"
      Environment = each.key
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Auto Scaling Groups with environment-specific configurations
resource "aws_autoscaling_group" "environments" {
  for_each = local.environments

  name                = "${var.project_name}-${each.key}-asg"
  vpc_zone_identifier = [for k, v in aws_subnet.all : v.id if startswith(k, each.key)]
  target_group_arns   = [aws_lb_target_group.environments[each.key].arn]
  health_check_type   = "ELB"

  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.min_size

  launch_template {
    id      = aws_launch_template.environments[each.key].id
    version = "$Latest"
  }

  # Dynamic tags based on environment
  dynamic "tag" {
    for_each = merge(
      {
        Name        = "${var.project_name}-${each.key}-asg"
        Environment = each.key
      },
      each.key == "prod" ? { Backup = "required", Monitoring = "enhanced" } : {}
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Load Balancers for each environment
resource "aws_lb" "environments" {
  for_each = local.environments

  name               = "${var.project_name}-${each.key}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all["${each.key}-web"].id]
  subnets            = [for k, v in aws_subnet.all : v.id if startswith(k, each.key)]

  enable_deletion_protection = each.key == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-${each.key}-alb"
    Environment = each.key
  }
}

# Target Groups
resource "aws_lb_target_group" "environments" {
  for_each = local.environments

  name     = "${var.project_name}-${each.key}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.environments[each.key].id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-tg"
    Environment = each.key
  }
}

# Listeners
resource "aws_lb_listener" "environments" {
  for_each = local.environments

  load_balancer_arn = aws_lb.environments[each.key].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.environments[each.key].arn
  }
}

# RDS instances using flattened database combinations
resource "aws_db_subnet_group" "environments" {
  for_each = local.environments

  name       = "${var.project_name}-${each.key}-db-subnet-group"
  subnet_ids = [for k, v in aws_subnet.all : v.id if startswith(k, each.key)]

  tags = {
    Name        = "${var.project_name}-${each.key}-db-subnet-group"
    Environment = each.key
  }
}

resource "aws_db_instance" "all" {
  for_each = {
    for combo in local.env_database_combinations :
    "${combo.env_name}-${combo.db_name}" => combo
  }

  identifier = "${var.project_name}-${each.value.env_name}-${each.value.db_name}-db"

  engine         = each.value.db_name == "cache" ? "redis" : "mysql"
  engine_version = each.value.db_name == "cache" ? "7.0" : "8.0"
  instance_class = each.value.env_name == "prod" ? "db.t3.medium" : "db.t3.micro"

  allocated_storage     = each.value.env_name == "prod" ? 100 : 20
  max_allocated_storage = each.value.env_name == "prod" ? 1000 : 100
  storage_type          = "gp3"
  storage_encrypted     = each.value.env_name == "prod" ? true : false

  db_name  = each.value.db_name
  username = "admin"
  password = random_password.db_passwords["${each.value.env_name}-${each.value.db_name}"].result

  vpc_security_group_ids = [aws_security_group.all["${each.value.env_name}-db"].id]
  db_subnet_group_name   = aws_db_subnet_group.environments[each.value.env_name].name

  backup_retention_period = each.value.env_name == "prod" ? 7 : 1
  multi_az               = each.value.env_name == "prod" ? true : false

  skip_final_snapshot = each.value.env_name != "prod"

  tags = {
    Name        = "${var.project_name}-${each.value.env_name}-${each.value.db_name}-db"
    Environment = each.value.env_name
    Database    = each.value.db_name
  }
}

# Random passwords for each database
resource "random_password" "db_passwords" {
  for_each = {
    for combo in local.env_database_combinations :
    "${combo.env_name}-${combo.db_name}" => combo
  }

  length  = 16
  special = true
}

# S3 buckets with conditional configurations
resource "aws_s3_bucket" "environments" {
  for_each = local.environments

  bucket = "${var.project_name}-${each.key}-${random_id.bucket_suffix[each.key].hex}"

  tags = {
    Name        = "${var.project_name}-${each.key}-bucket"
    Environment = each.key
  }
}

resource "random_id" "bucket_suffix" {
  for_each = local.environments

  byte_length = 4
}

# Conditional S3 bucket configurations
resource "aws_s3_bucket_versioning" "environments" {
  for_each = { for k, v in local.environments : k => v if k == "prod" }

  bucket = aws_s3_bucket.environments[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "environments" {
  for_each = local.environments

  bucket = aws_s3_bucket.environments[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.key == "prod" ? "aws:kms" : "AES256"
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "environments" {
  for_each = local.environments

  name              = "/aws/ec2/${var.project_name}-${each.key}"
  retention_in_days = each.key == "prod" ? 30 : 7

  tags = {
    Name        = "${var.project_name}-${each.key}-logs"
    Environment = each.key
  }
}
