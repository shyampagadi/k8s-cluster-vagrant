# Problem 9: AWS Data Sources Mastery - Dynamic Resource Discovery

## Data Source Fundamentals

### What are Data Sources?
Data sources in Terraform allow you to fetch information about existing resources that are managed outside of your current Terraform configuration. They provide read-only access to infrastructure data.

### Basic Data Source Syntax
```hcl
data "provider_resource_type" "name" {
  # Filter criteria
  filter {
    name   = "attribute_name"
    values = ["value1", "value2"]
  }
}

# Reference the data source
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest.id
  instance_type = "t3.micro"
}
```

## Essential AWS Data Sources

### AMI Discovery
```hcl
# Latest Amazon Linux 2 AMI
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
}

# Latest Ubuntu AMI
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

# Windows Server AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Custom AMI by tag
data "aws_ami" "custom_app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Application"
    values = ["web-server"]
  }

  filter {
    name   = "tag:Version"
    values = ["2.1.0"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Use AMI data in resources
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  tags = {
    Name = "Web Server"
    AMI  = data.aws_ami.amazon_linux.name
  }
}
```

### VPC and Network Discovery
```hcl
# Default VPC
data "aws_vpc" "default" {
  default = true
}

# VPC by tag
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

# VPC by CIDR
data "aws_vpc" "production" {
  filter {
    name   = "cidr"
    values = ["10.0.0.0/16"]
  }
}

# Subnets in VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Specific subnet by availability zone
data "aws_subnet" "public_us_west_2a" {
  vpc_id            = data.aws_vpc.main.id
  availability_zone = "us-west-2a"

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Route tables
data "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Internet Gateway
data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
```

### Availability Zones and Regions
```hcl
# Current region
data "aws_region" "current" {}

# Available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Availability zones excluding specific ones
data "aws_availability_zones" "available_filtered" {
  state = "available"
  
  exclude_names = ["us-west-2d"]
}

# Availability zones with specific services
data "aws_availability_zones" "rds_available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Use in resource creation
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}
```

### Security Groups and IAM
```hcl
# Existing security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.main.id
}

# Security group by tag
data "aws_security_group" "web" {
  filter {
    name   = "tag:Name"
    values = ["web-security-group"]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Multiple security groups
data "aws_security_groups" "web_tier" {
  filter {
    name   = "tag:Tier"
    values = ["web"]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# IAM role
data "aws_iam_role" "ec2_role" {
  name = "EC2-Role"
}

# IAM policy
data "aws_iam_policy" "s3_read_only" {
  name = "AmazonS3ReadOnlyAccess"
}

# IAM policy document
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Current caller identity
data "aws_caller_identity" "current" {}

# Use in resources
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  tags = {
    Name      = "web-server"
    AccountId = data.aws_caller_identity.current.account_id
  }
}
```

## Advanced Data Source Patterns

### Dynamic Resource Discovery
```hcl
# Discover all subnets and create resources dynamically
data "aws_subnets" "all_private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Get detailed information for each subnet
data "aws_subnet" "private_details" {
  for_each = toset(data.aws_subnets.all_private.ids)
  id       = each.value
}

# Create resources in each discovered subnet
resource "aws_instance" "app" {
  for_each = data.aws_subnet.private_details
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = each.value.id
  
  tags = {
    Name = "app-server-${each.value.availability_zone}"
    AZ   = each.value.availability_zone
    CIDR = each.value.cidr_block
  }
}
```

### Cross-Account Resource Discovery
```hcl
# Discover resources in different account
data "aws_ami" "shared_ami" {
  most_recent = true
  owners      = ["123456789012"] # Different account ID

  filter {
    name   = "name"
    values = ["shared-app-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Cross-account VPC peering
data "aws_vpc" "peer_vpc" {
  provider = aws.peer_account
  
  filter {
    name   = "tag:Name"
    values = ["peer-vpc"]
  }
}
```

### Environment-Specific Discovery
```hcl
# Environment-specific resource discovery
locals {
  environment_filters = {
    development = {
      instance_type = "t3.micro"
      ami_pattern   = "*dev*"
    }
    staging = {
      instance_type = "t3.small"
      ami_pattern   = "*staging*"
    }
    production = {
      instance_type = "t3.medium"
      ami_pattern   = "*prod*"
    }
  }
}

# Environment-specific AMI
data "aws_ami" "environment_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = [local.environment_filters[var.environment].ami_pattern]
  }

  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

# Environment-specific VPC
data "aws_vpc" "environment_vpc" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }
}
```

### Database and Storage Discovery
```hcl
# RDS subnet group
data "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"
}

# RDS parameter group
data "aws_db_parameter_group" "mysql8" {
  name = "default.mysql8.0"
}

# Existing RDS instance
data "aws_db_instance" "main" {
  db_instance_identifier = "${var.project_name}-database"
}

# S3 bucket
data "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-app-data"
}

# KMS key
data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

# KMS key by alias
data "aws_kms_key" "custom" {
  key_id = "alias/${var.project_name}-encryption-key"
}

# Use in resource creation
resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-replica"
  
  replicate_source_db = data.aws_db_instance.main.id
  instance_class      = "db.t3.micro"
  
  tags = {
    Name   = "Database Replica"
    Source = data.aws_db_instance.main.id
  }
}
```

### Load Balancer and Auto Scaling Discovery
```hcl
# Application Load Balancer
data "aws_lb" "main" {
  name = "${var.project_name}-alb"
}

# Target group
data "aws_lb_target_group" "web" {
  name = "${var.project_name}-web-tg"
}

# Auto Scaling Group
data "aws_autoscaling_group" "web" {
  name = "${var.project_name}-web-asg"
}

# Launch template
data "aws_launch_template" "web" {
  name = "${var.project_name}-web-template"
}

# Use discovered resources
resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = data.aws_autoscaling_group.web.id
  lb_target_group_arn    = data.aws_lb_target_group.web.arn
}
```

## Data Source Validation and Error Handling

### Conditional Data Sources
```hcl
# Conditional data source based on variable
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = [var.existing_vpc_name]
  }
}

# Use conditional data source
resource "aws_subnet" "public" {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main.id
  
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}
```

### Data Source Validation
```hcl
# Validate data source results
locals {
  # Ensure AMI was found
  ami_validation = length(data.aws_ami.amazon_linux.id) > 0 ? data.aws_ami.amazon_linux.id : null
  
  # Ensure VPC exists
  vpc_validation = data.aws_vpc.main.id != "" ? data.aws_vpc.main.id : null
  
  # Validate subnet count
  subnet_count_valid = length(data.aws_subnets.public.ids) >= 2
}

# Use validation in resources
resource "aws_instance" "web" {
  count = local.subnet_count_valid ? var.instance_count : 0
  
  ami           = local.ami_validation
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.public.ids[count.index % length(data.aws_subnets.public.ids)]
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
```

### Error Handling Patterns
```hcl
# Handle missing resources gracefully
data "aws_security_group" "existing_web" {
  count = var.use_existing_security_group ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = [var.existing_security_group_name]
  }
}

# Fallback security group creation
resource "aws_security_group" "web" {
  count = var.use_existing_security_group ? 0 : 1
  
  name_prefix = "${var.project_name}-web-"
  vpc_id      = data.aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Use either existing or created security group
locals {
  web_security_group_id = var.use_existing_security_group ? data.aws_security_group.existing_web[0].id : aws_security_group.web[0].id
}
```

## Performance and Best Practices

### Efficient Data Source Usage
```hcl
# Cache data source results in locals
locals {
  # Cache frequently used data sources
  vpc_id                = data.aws_vpc.main.id
  availability_zones    = data.aws_availability_zones.available.names
  public_subnet_ids     = data.aws_subnets.public.ids
  private_subnet_ids    = data.aws_subnets.private.ids
  
  # Pre-calculate derived values
  az_count              = length(local.availability_zones)
  public_subnet_count   = length(local.public_subnet_ids)
  private_subnet_count  = length(local.private_subnet_ids)
}

# Use cached values in resources
resource "aws_instance" "web" {
  count = min(var.instance_count, local.public_subnet_count)
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = local.public_subnet_ids[count.index]
  
  tags = {
    Name = "web-server-${count.index + 1}"
    AZ   = local.availability_zones[count.index % local.az_count]
  }
}
```

### Data Source Dependencies
```hcl
# Explicit dependencies between data sources
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "app" {
  depends_on = [data.aws_vpc.main]
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  filter {
    name   = "tag:Tier"
    values = ["application"]
  }
}

data "aws_subnet" "app_details" {
  for_each   = toset(data.aws_subnets.app.ids)
  depends_on = [data.aws_subnets.app]
  
  id = each.value
}
```

This comprehensive guide covers all aspects of AWS data sources, from basic resource discovery to advanced patterns for dynamic infrastructure management and cross-account resource access.
