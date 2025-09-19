# Problem 27: Enterprise Patterns - Large-Scale Infrastructure
# This configuration demonstrates enterprise-level infrastructure patterns

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

# Multi-region provider configuration
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "primary" {
  provider = aws.primary
}
data "aws_region" "secondary" {
  provider = aws.secondary
}

# Generate enterprise project ID
resource "random_id" "enterprise_id" {
  byte_length = 8
}

# Enterprise VPC in primary region
resource "aws_vpc" "primary" {
  provider = aws.primary

  cidr_block           = var.primary_vpc_cr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.enterprise_name}-primary-vpc-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Region      = "primary"
  }
}

# Enterprise VPC in secondary region
resource "aws_vpc" "secondary" {
  provider = aws.secondary

  cidr_block           = var.secondary_vpc_cr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.enterprise_name}-secondary-vpc-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Region      = "secondary"
  }
}

# Enterprise subnets in primary region
resource "aws_subnet" "primary_public" {
  provider = aws.primary
  count    = length(var.primary_azs)

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cr, 8, count.index)
  availability_zone       = var.primary_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.enterprise_name}-primary-public-subnet-${count.index + 1}-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "public"
    Region      = "primary"
  }
}

resource "aws_subnet" "primary_private" {
  provider = aws.primary
  count    = length(var.primary_azs)

  vpc_id            = aws_vpc.primary.id
  cidr_block         = cidrsubnet(var.primary_vpc_cr, 8, count.index + 10)
  availability_zone = var.primary_azs[count.index]

  tags = {
    Name        = "${var.enterprise_name}-primary-private-subnet-${count.index + 1}-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "private"
    Region      = "primary"
  }
}

# Enterprise subnets in secondary region
resource "aws_subnet" "secondary_public" {
  provider = aws.secondary
  count    = length(var.secondary_azs)

  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cr, 8, count.index)
  availability_zone       = var.secondary_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.enterprise_name}-secondary-public-subnet-${count.index + 1}-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "public"
    Region      = "secondary"
  }
}

resource "aws_subnet" "secondary_private" {
  provider = aws.secondary
  count    = length(var.secondary_azs)

  vpc_id            = aws_vpc.secondary.id
  cidr_block         = cidrsubnet(var.secondary_vpc_cr, 8, count.index + 10)
  availability_zone = var.secondary_azs[count.index]

  tags = {
    Name        = "${var.enterprise_name}-secondary-private-subnet-${count.index + 1}-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "private"
    Region      = "secondary"
  }
}

# Internet Gateways
resource "aws_internet_gateway" "primary" {
  provider = aws.primary

  vpc_id = aws_vpc.primary.id

  tags = {
    Name        = "${var.enterprise_name}-primary-igw-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Region      = "primary"
  }
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary

  vpc_id = aws_vpc.secondary.id

  tags = {
    Name        = "${var.enterprise_name}-secondary-igw-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Region      = "secondary"
  }
}

# Enterprise Security Groups
resource "aws_security_group" "enterprise_web" {
  provider = aws.primary

  name_prefix = "${var.enterprise_name}-web-sg-${random_id.enterprise_id.hex}"
  vpc_id      = aws_vpc.primary.id

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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.enterprise_name}-web-sg-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "web"
  }
}

resource "aws_security_group" "enterprise_database" {
  provider = aws.primary

  name_prefix = "${var.enterprise_name}-db-sg-${random_id.enterprise_id.hex}"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.enterprise_web.id]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.enterprise_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.enterprise_name}-db-sg-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Type        = "database"
  }
}

# Enterprise Auto Scaling Groups
resource "aws_launch_template" "enterprise" {
  provider = aws.primary

  name_prefix   = "${var.enterprise_name}-lt-${random_id.enterprise_id.hex}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.enterprise_instance_type

  vpc_security_group_ids = [aws_security_group.enterprise_web.id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    enterprise_name = var.enterprise_name
    environment     = var.environment
    region          = "primary"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.enterprise_name}-instance-${random_id.enterprise_id.hex}"
      Environment = var.environment
      Project     = var.enterprise_name
      Module      = "enterprise-patterns"
    }
  }

  tags = {
    Name        = "${var.enterprise_name}-lt-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
  }
}

resource "aws_autoscaling_group" "enterprise" {
  provider = aws.primary

  name                = "${var.enterprise_name}-asg-${random_id.enterprise_id.hex}"
  vpc_zone_identifier = aws_subnet.primary_private[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.enterprise.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.enterprise_name}-asg-${random_id.enterprise_id.hex}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.enterprise_name
    propagate_at_launch = true
  }
}

# Enterprise S3 Buckets
resource "aws_s3_bucket" "enterprise_logs" {
  provider = aws.primary

  bucket = "${var.enterprise_name}-logs-${random_id.enterprise_id.hex}"

  tags = {
    Name        = "${var.enterprise_name}-logs-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Purpose     = "logs"
  }
}

resource "aws_s3_bucket" "enterprise_data" {
  provider = aws.primary

  bucket = "${var.enterprise_name}-data-${random_id.enterprise_id.hex}"

  tags = {
    Name        = "${var.enterprise_name}-data-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
    Purpose     = "data"
  }
}

# Enable encryption on S3 buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "enterprise_logs" {
  provider = aws.primary

  bucket = aws_s3_bucket.enterprise_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enterprise_data" {
  provider = aws.primary

  bucket = aws_s3_bucket.enterprise_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enterprise CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "enterprise" {
  provider = aws.primary

  name              = "/aws/ec2/${var.enterprise_name}-${random_id.enterprise_id.hex}"
  retention_in_days = 30

  tags = {
    Name        = "${var.enterprise_name}-log-group-${random_id.enterprise_id.hex}"
    Environment = var.environment
    Project     = var.enterprise_name
    Module      = "enterprise-patterns"
  }
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  provider = aws.primary

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
