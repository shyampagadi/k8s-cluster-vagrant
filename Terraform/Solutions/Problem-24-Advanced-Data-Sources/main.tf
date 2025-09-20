# Problem 24: Advanced Data Sources and Dynamic Resource Discovery
# Comprehensive data source usage patterns and dynamic infrastructure discovery

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

# Data sources for account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Advanced VPC discovery
data "aws_vpcs" "all" {
  tags = var.vpc_filter_tags
}

data "aws_vpc" "selected" {
  count = var.use_existing_vpc ? 1 : 0
  
  # Dynamic VPC selection based on tags or CIDR
  dynamic "filter" {
    for_each = var.vpc_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Advanced subnet discovery with complex filtering
data "aws_subnets" "private" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Private", "private"]
  }
  
  # Additional filters based on availability zones
  dynamic "filter" {
    for_each = length(var.required_azs) > 0 ? [1] : []
    content {
      name   = "availability-zone"
      values = var.required_azs
    }
  }
}

data "aws_subnets" "public" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Public", "public"]
  }
}

data "aws_subnets" "database" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Database", "database", "DB", "db"]
  }
}

# Advanced subnet details with dynamic iteration
data "aws_subnet" "private_details" {
  count = var.use_existing_vpc ? length(data.aws_subnets.private[0].ids) : 0
  id    = data.aws_subnets.private[0].ids[count.index]
}

data "aws_subnet" "public_details" {
  count = var.use_existing_vpc ? length(data.aws_subnets.public[0].ids) : 0
  id    = data.aws_subnets.public[0].ids[count.index]
}

# Advanced AMI discovery with complex filtering
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Custom AMI discovery based on tags
data "aws_ami" "custom" {
  count = length(var.custom_ami_filters) > 0 ? 1 : 0
  
  most_recent = true
  owners      = var.custom_ami_owners

  dynamic "filter" {
    for_each = var.custom_ami_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Advanced security group discovery
data "aws_security_groups" "existing" {
  count = var.use_existing_security_groups ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = var.use_existing_vpc ? [data.aws_vpc.selected[0].id] : [aws_vpc.main[0].id]
  }
  
  dynamic "filter" {
    for_each = var.security_group_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Route53 hosted zone discovery
data "aws_route53_zone" "main" {
  count = var.domain_name != null ? 1 : 0
  
  name         = var.domain_name
  private_zone = false
}

# ACM certificate discovery
data "aws_acm_certificate" "main" {
  count = var.domain_name != null ? 1 : 0
  
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

# Advanced IAM role and policy discovery
data "aws_iam_role" "existing_roles" {
  for_each = toset(var.existing_iam_roles)
  name     = each.value
}

data "aws_iam_policy" "aws_managed" {
  for_each = toset(var.aws_managed_policies)
  name     = each.value
}

# KMS key discovery
data "aws_kms_key" "main" {
  count = var.kms_key_alias != null ? 1 : 0
  
  key_id = "alias/${var.kms_key_alias}"
}

# Advanced RDS discovery
data "aws_db_instances" "existing" {
  count = var.discover_existing_databases ? 1 : 0
  
  dynamic "filter" {
    for_each = var.db_instance_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

data "aws_db_subnet_group" "existing" {
  count = var.existing_db_subnet_group != null ? 1 : 0
  name  = var.existing_db_subnet_group
}

# Advanced ELB/ALB discovery
data "aws_lb" "existing" {
  count = var.existing_load_balancer_name != null ? 1 : 0
  name  = var.existing_load_balancer_name
}

data "aws_lbs" "all" {
  count = var.discover_load_balancers ? 1 : 0
  
  dynamic "filter" {
    for_each = var.load_balancer_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Advanced S3 bucket discovery
data "aws_s3_bucket" "existing" {
  for_each = toset(var.existing_s3_buckets)
  bucket   = each.value
}

# CloudWatch Log Groups discovery
data "aws_cloudwatch_log_groups" "existing" {
  count = var.discover_log_groups ? 1 : 0
  
  log_group_name_prefix = var.log_group_prefix
}

# Advanced EC2 instance discovery
data "aws_instances" "existing" {
  count = var.discover_existing_instances ? 1 : 0
  
  dynamic "filter" {
    for_each = var.instance_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Local values for dynamic resource creation
locals {
  # Dynamic VPC configuration
  vpc_id = var.use_existing_vpc ? data.aws_vpc.selected[0].id : aws_vpc.main[0].id
  vpc_cidr = var.use_existing_vpc ? data.aws_vpc.selected[0].cidr_block : var.vpc_cidr
  
  # Dynamic subnet configuration
  private_subnets = var.use_existing_vpc ? data.aws_subnets.private[0].ids : aws_subnet.private[*].id
  public_subnets  = var.use_existing_vpc ? data.aws_subnets.public[0].ids : aws_subnet.public[*].id
  
  # Dynamic AMI selection
  selected_ami = var.ami_type == "amazon-linux" ? data.aws_ami.amazon_linux.id : (
    var.ami_type == "ubuntu" ? data.aws_ami.ubuntu.id : (
      length(var.custom_ami_filters) > 0 ? data.aws_ami.custom[0].id : data.aws_ami.amazon_linux.id
    )
  )
  
  # Dynamic security group configuration
  security_group_ids = var.use_existing_security_groups ? data.aws_security_groups.existing[0].ids : [aws_security_group.main[0].id]
  
  # Dynamic availability zones from subnets
  availability_zones = var.use_existing_vpc ? [
    for subnet in data.aws_subnet.private_details : subnet.availability_zone
  ] : data.aws_availability_zones.available.names
  
  # Dynamic tags based on discovered resources
  common_tags = merge(var.tags, {
    VpcId           = local.vpc_id
    DiscoveredVpc   = var.use_existing_vpc
    SelectedAmi     = local.selected_ami
    AvailabilityZones = join(",", local.availability_zones)
  })
}

# Conditional VPC creation
resource "aws_vpc" "main" {
  count = var.use_existing_vpc ? 0 : 1
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Conditional subnet creation
resource "aws_subnet" "private" {
  count = var.use_existing_vpc ? 0 : length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_subnet" "public" {
  count = var.use_existing_vpc ? 0 : length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Conditional security group creation
resource "aws_security_group" "main" {
  count = var.use_existing_security_groups ? 0 : 1
  
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name}"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
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
    Name = "${var.project_name}-sg"
  })
}

# Launch template using discovered AMI
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-"
  image_id      = local.selected_ami
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = local.security_group_ids

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    project_name = var.project_name
    ami_type     = var.ami_type
    vpc_id       = local.vpc_id
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
      volume_type = "gp3"
      encrypted   = var.kms_key_alias != null ? true : false
      kms_key_id  = var.kms_key_alias != null ? data.aws_kms_key.main[0].arn : null
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group using discovered subnets
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = local.private_subnets
  target_group_arns   = var.create_load_balancer ? [aws_lb_target_group.main[0].arn] : []
  health_check_type   = var.create_load_balancer ? "ELB" : "EC2"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }
}

# Conditional Load Balancer creation
resource "aws_lb" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = local.security_group_ids
  subnets            = local.public_subnets

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id

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

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-tg"
  })
}

resource "aws_lb_listener" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.domain_name != null ? data.aws_acm_certificate.main[0].arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# Conditional Route53 record creation
resource "aws_route53_record" "main" {
  count = var.domain_name != null && var.create_load_balancer ? 1 : 0
  
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.subdomain != null ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main[0].dns_name
    zone_id                = aws_lb.main[0].zone_id
    evaluate_target_health = true
  }
}

# S3 bucket using discovered KMS key
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-bucket"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_alias != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_alias != null ? data.aws_kms_key.main[0].arn : null
    }
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_alias != null ? data.aws_kms_key.main[0].arn : null

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs"
  })
}
