# Problem 22: Advanced Modules - Composition and Versioning
# Fixed provider configuration and module references

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.primary, aws.secondary]
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
data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

# Local values for advanced composition
locals {
  common_tags = {
    Environment     = var.environment
    Project         = var.project_name
    ManagedBy       = "Terraform"
    Owner           = var.owner
    CostCenter      = var.cost_center
    Compliance      = var.compliance_level
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
  
  regions = {
    primary = {
      region = var.primary_region
      priority = 1
    }
    secondary = {
      region = var.secondary_region
      priority = 2
    }
  }
}

# VPC in primary region
resource "aws_vpc" "primary" {
  provider = aws.primary
  
  cidr_block           = var.vpc_cidrs.primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name   = "${local.name_prefix}-primary-vpc"
    Region = var.primary_region
  })
}

# VPC in secondary region
resource "aws_vpc" "secondary" {
  provider = aws.secondary
  
  cidr_block           = var.vpc_cidrs.secondary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name   = "${local.name_prefix}-secondary-vpc"
    Region = var.secondary_region
  })
}

# Subnets in primary region
resource "aws_subnet" "primary_public" {
  provider = aws.primary
  count    = 2

  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.vpc_cidrs.primary, 8, count.index)
  availability_zone       = data.aws_availability_zones.primary.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-public-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "primary_private" {
  provider = aws.primary
  count    = 2

  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet(var.vpc_cidrs.primary, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.primary.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-private-${count.index + 1}"
    Type = "Private"
  })
}

# Subnets in secondary region
resource "aws_subnet" "secondary_public" {
  provider = aws.secondary
  count    = 2

  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.vpc_cidrs.secondary, 8, count.index)
  availability_zone       = data.aws_availability_zones.secondary.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-public-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "secondary_private" {
  provider = aws.secondary
  count    = 2

  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet(var.vpc_cidrs.secondary, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.secondary.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-private-${count.index + 1}"
    Type = "Private"
  })
}

# Internet Gateways
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-igw"
  })
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-igw"
  })
}

# NAT Gateways for primary region
resource "aws_eip" "primary_nat" {
  provider = aws.primary
  count    = 2
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "primary" {
  provider = aws.primary
  count    = 2

  allocation_id = aws_eip.primary_nat[count.index].id
  subnet_id     = aws_subnet.primary_public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-nat-${count.index + 1}"
  })
}

# NAT Gateways for secondary region
resource "aws_eip" "secondary_nat" {
  provider = aws.secondary
  count    = 2
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "secondary" {
  provider = aws.secondary
  count    = 2

  allocation_id = aws_eip.secondary_nat[count.index].id
  subnet_id     = aws_subnet.secondary_public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-nat-${count.index + 1}"
  })
}

# Route tables for primary region
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-public-rt"
  })
}

resource "aws_route_table" "primary_private" {
  provider = aws.primary
  count    = 2
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-private-rt-${count.index + 1}"
  })
}

# Route tables for secondary region
resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-public-rt"
  })
}

resource "aws_route_table" "secondary_private" {
  provider = aws.secondary
  count    = 2
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secondary[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-private-rt-${count.index + 1}"
  })
}

# Route table associations for primary region
resource "aws_route_table_association" "primary_public" {
  provider = aws.primary
  count    = 2

  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public.id
}

resource "aws_route_table_association" "primary_private" {
  provider = aws.primary
  count    = 2

  subnet_id      = aws_subnet.primary_private[count.index].id
  route_table_id = aws_route_table.primary_private[count.index].id
}

# Route table associations for secondary region
resource "aws_route_table_association" "secondary_public" {
  provider = aws.secondary
  count    = 2

  subnet_id      = aws_subnet.secondary_public[count.index].id
  route_table_id = aws_route_table.secondary_public.id
}

resource "aws_route_table_association" "secondary_private" {
  provider = aws.secondary
  count    = 2

  subnet_id      = aws_subnet.secondary_private[count.index].id
  route_table_id = aws_route_table.secondary_private[count.index].id
}

# Security groups for primary region
resource "aws_security_group" "primary_web" {
  provider = aws.primary
  
  name        = "${local.name_prefix}-primary-web-sg"
  description = "Security group for web tier in primary region"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-web-sg"
  })
}

# Security groups for secondary region
resource "aws_security_group" "secondary_web" {
  provider = aws.secondary
  
  name        = "${local.name_prefix}-secondary-web-sg"
  description = "Security group for web tier in secondary region"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-web-sg"
  })
}

# Application Load Balancers
resource "aws_lb" "primary" {
  provider = aws.primary
  
  name               = "${local.name_prefix}-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_web.id]
  subnets            = aws_subnet.primary_public[*].id

  enable_deletion_protection = var.environment == "production"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-alb"
  })
}

resource "aws_lb" "secondary" {
  provider = aws.secondary
  
  name               = "${local.name_prefix}-secondary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_web.id]
  subnets            = aws_subnet.secondary_public[*].id

  enable_deletion_protection = var.environment == "production"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-alb"
  })
}

# S3 bucket with cross-region replication
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${local.name_prefix}-primary-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-bucket"
  })
}

resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "${local.name_prefix}-secondary-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-bucket"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "primary" {
  provider = aws.primary
  
  name              = "/aws/application/${local.name_prefix}-primary"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-logs"
  })
}

resource "aws_cloudwatch_log_group" "secondary" {
  provider = aws.secondary
  
  name              = "/aws/application/${local.name_prefix}-secondary"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secondary-logs"
  })
}
