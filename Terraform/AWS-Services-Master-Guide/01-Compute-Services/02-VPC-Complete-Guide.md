# VPC (Virtual Private Cloud) - Complete Terraform Guide

## 🎯 Overview

Amazon Virtual Private Cloud (VPC) is the foundation of AWS networking. It provides a logically isolated section of the AWS cloud where you can launch AWS resources in a virtual network that you define. VPC is essential for every AWS deployment and provides the networking foundation for all other services.

### **What is VPC?**
VPC is a virtual network dedicated to your AWS account. It's logically isolated from other virtual networks in the AWS cloud and provides complete control over your virtual networking environment, including IP address ranges, subnets, route tables, and network gateways.

### **Key Concepts**
- **VPC**: Virtual network isolated from other AWS accounts
- **Subnets**: Segments of your VPC's IP address range
- **Route Tables**: Rules that determine where network traffic is directed
- **Internet Gateway**: Gateway that connects your VPC to the internet
- **NAT Gateway**: Allows private subnets to access the internet
- **Security Groups**: Virtual firewalls for EC2 instances
- **Network ACLs**: Subnet-level security

### **When to Use VPC**
- **Every AWS deployment** - VPC is the foundation
- **Network isolation** - Separate environments (dev, staging, prod)
- **Compliance requirements** - Network security and isolation
- **Hybrid cloud** - Connect to on-premises networks
- **Multi-tier applications** - Separate web, app, and database tiers

## 🏗️ Architecture Patterns

### **Basic VPC Structure**
```
VPC (10.0.0.0/16)
├── Public Subnets
│   ├── Public Subnet 1 (10.0.1.0/24) - AZ-a
│   └── Public Subnet 2 (10.0.2.0/24) - AZ-b
├── Private Subnets
│   ├── Private Subnet 1 (10.0.10.0/24) - AZ-a
│   └── Private Subnet 2 (10.0.20.0/24) - AZ-b
├── Database Subnets
│   ├── DB Subnet 1 (10.0.100.0/24) - AZ-a
│   └── DB Subnet 2 (10.0.200.0/24) - AZ-b
├── Internet Gateway
├── NAT Gateway
└── Route Tables
```

### **Multi-Tier VPC Pattern**
```
VPC (10.0.0.0/16)
├── Web Tier (Public Subnets)
│   ├── Web Subnet 1 (10.0.1.0/24)
│   └── Web Subnet 2 (10.0.2.0/24)
├── Application Tier (Private Subnets)
│   ├── App Subnet 1 (10.0.10.0/24)
│   └── App Subnet 2 (10.0.20.0/24)
├── Database Tier (Private Subnets)
│   ├── DB Subnet 1 (10.0.100.0/24)
│   └── DB Subnet 2 (10.0.200.0/24)
└── Management Tier (Private Subnets)
    ├── Mgmt Subnet 1 (10.0.50.0/24)
    └── Mgmt Subnet 2 (10.0.60.0/24)
```

### **Enterprise VPC Pattern**
```
Organization
├── Production VPC (10.0.0.0/16)
├── Staging VPC (10.1.0.0/16)
├── Development VPC (10.2.0.0/16)
├── Shared Services VPC (10.3.0.0/16)
├── Transit Gateway
└── VPC Peering Connections
```

## 📝 Terraform Implementation

### **Basic VPC Setup**
```hcl
# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "Main VPC"
    Environment = "production"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "Main Internet Gateway"
    Environment = "production"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "Public Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Public"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name        = "Private Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Private"
  }
}

# Create database subnets
resource "aws_subnet" "database" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 100}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name        = "Database Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Database"
  }
}
```

### **Route Tables and Routing**
```hcl
# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "Public Route Table"
    Environment = "production"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = 2
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create NAT Gateway
resource "aws_eip" "nat" {
  count = 2
  
  domain = "vpc"
  
  tags = {
    Name        = "NAT Gateway EIP ${count.index + 1}"
    Environment = "production"
  }
}

resource "aws_nat_gateway" "main" {
  count = 2
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name        = "NAT Gateway ${count.index + 1}"
    Environment = "production"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  count = 2
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name        = "Private Route Table ${count.index + 1}"
    Environment = "production"
  }
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = 2
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Create route table for database subnets
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "Database Route Table"
    Environment = "production"
  }
}

# Associate database subnets with database route table
resource "aws_route_table_association" "database" {
  count = 2
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
```

### **Security Groups**
```hcl
# Security group for web servers
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
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
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Web Security Group"
    Environment = "production"
  }
}

# Security group for application servers
resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "HTTP from web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  ingress {
    description     = "HTTPS from web"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "App Security Group"
    Environment = "production"
  }
}

# Security group for database servers
resource "aws_security_group" "database" {
  name_prefix = "database-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "MySQL from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Database Security Group"
    Environment = "production"
  }
}
```

### **VPC Endpoints**
```hcl
# VPC endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  tags = {
    Name        = "S3 VPC Endpoint"
    Environment = "production"
  }
}

# VPC endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  
  tags = {
    Name        = "DynamoDB VPC Endpoint"
    Environment = "production"
  }
}

# VPC endpoint for SNS
resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  
  tags = {
    Name        = "SNS VPC Endpoint"
    Environment = "production"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpc-endpoint-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "VPC Endpoint Security Group"
    Environment = "production"
  }
}

data "aws_region" "current" {}
```

## 🔧 Configuration Options

### **VPC Configuration**
```hcl
resource "aws_vpc" "custom" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Enable IPv6
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  
  tags = merge(var.common_tags, {
    Name = "Custom VPC"
  })
}
```

### **Subnet Configuration**
```hcl
resource "aws_subnet" "custom" {
  vpc_id                  = aws_vpc.custom.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  
  # Enable IPv6
  ipv6_cidr_block                 = var.enable_ipv6 ? aws_vpc.custom.ipv6_cidr_block : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  
  tags = merge(var.common_tags, {
    Name = "Custom Subnet"
  })
}
```

### **Advanced VPC Configuration**
```hcl
# VPC with custom DNS
resource "aws_vpc" "advanced" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Custom DNS servers
  dns_servers = ["8.8.8.8", "8.8.4.4"]
  
  tags = {
    Name        = "Advanced VPC"
    Environment = "production"
  }
}

# VPC with flow logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.advanced.id
}

# CloudWatch log group for VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
  
  tags = {
    Name        = "VPC Flow Logs"
    Environment = "production"
  }
}

# IAM role for VPC flow logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple VPC for small applications
resource "aws_vpc" "simple" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "Simple VPC"
  }
}

resource "aws_internet_gateway" "simple" {
  vpc_id = aws_vpc.simple.id
  
  tags = {
    Name = "Simple IGW"
  }
}

resource "aws_subnet" "simple" {
  vpc_id                  = aws_vpc.simple.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Simple Subnet"
  }
}

resource "aws_route_table" "simple" {
  vpc_id = aws_vpc.simple.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.simple.id
  }
  
  tags = {
    Name = "Simple Route Table"
  }
}

resource "aws_route_table_association" "simple" {
  subnet_id      = aws_subnet.simple.id
  route_table_id = aws_route_table.simple.id
}
```

### **Production Deployment**
```hcl
# Production VPC with high availability
locals {
  availability_zones = data.aws_availability_zones.available.names
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets   = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnets  = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]
}

# Production VPC
resource "aws_vpc" "production" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "Production VPC"
    Environment = "production"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "production" {
  vpc_id = aws_vpc.production.id
  
  tags = {
    Name        = "Production IGW"
    Environment = "production"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(local.public_subnets)
  
  vpc_id                  = aws_vpc.production.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "Public Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(local.private_subnets)
  
  vpc_id            = aws_vpc.production.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.availability_zones[count.index]
  
  tags = {
    Name        = "Private Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Private"
  }
}

# Database subnets
resource "aws_subnet" "database" {
  count = length(local.database_subnets)
  
  vpc_id            = aws_vpc.production.id
  cidr_block        = local.database_subnets[count.index]
  availability_zone = local.availability_zones[count.index]
  
  tags = {
    Name        = "Database Subnet ${count.index + 1}"
    Environment = "production"
    Type        = "Database"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = length(local.public_subnets)
  
  domain = "vpc"
  
  tags = {
    Name        = "NAT Gateway EIP ${count.index + 1}"
    Environment = "production"
  }
}

resource "aws_nat_gateway" "production" {
  count = length(local.public_subnets)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name        = "NAT Gateway ${count.index + 1}"
    Environment = "production"
  }
  
  depends_on = [aws_internet_gateway.production]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.production.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production.id
  }
  
  tags = {
    Name        = "Public Route Table"
    Environment = "production"
  }
}

resource "aws_route_table" "private" {
  count = length(local.private_subnets)
  
  vpc_id = aws_vpc.production.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.production[count.index].id
  }
  
  tags = {
    Name        = "Private Route Table ${count.index + 1}"
    Environment = "production"
  }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.production.id
  
  tags = {
    Name        = "Database Route Table"
    Environment = "production"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = length(local.public_subnets)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(local.private_subnets)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count = length(local.database_subnets)
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment VPC setup
locals {
  environments = {
    dev = {
      vpc_cidr = "10.0.0.0/16"
      public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
    }
    staging = {
      vpc_cidr = "10.1.0.0/16"
      public_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnets = ["10.1.10.0/24", "10.1.20.0/24"]
    }
    prod = {
      vpc_cidr = "10.2.0.0/16"
      public_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
      private_subnets = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]
    }
  }
}

# Create VPCs for each environment
resource "aws_vpc" "environment" {
  for_each = local.environments
  
  cidr_block           = each.value.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${each.key} VPC"
    Environment = each.key
  }
}

# Create Internet Gateways
resource "aws_internet_gateway" "environment" {
  for_each = local.environments
  
  vpc_id = aws_vpc.environment[each.key].id
  
  tags = {
    Name        = "${each.key} IGW"
    Environment = each.key
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  for_each = {
    for env, config in local.environments : env => config.public_subnets
  }
  
  vpc_id                  = aws_vpc.environment[each.key].id
  cidr_block              = each.value[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${each.key} Public Subnet 1"
    Environment = each.key
    Type        = "Public"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  for_each = {
    for env, config in local.environments : env => config.private_subnets
  }
  
  vpc_id            = aws_vpc.environment[each.key].id
  cidr_block        = each.value[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name        = "${each.key} Private Subnet 1"
    Environment = each.key
    Type        = "Private"
  }
}
```

## 🔍 Monitoring & Observability

### **VPC Flow Logs**
```hcl
# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
  
  tags = {
    Name        = "VPC Flow Logs"
    Environment = "production"
  }
}

# IAM role for flow logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
```

### **CloudWatch Monitoring**
```hcl
# CloudWatch metric filter for security events
resource "aws_cloudwatch_log_metric_filter" "security_events" {
  name           = "SecurityEvents"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_log.name
  pattern        = "[timestamp, request_id, event_name=\"ConsoleLogin\", error_code=\"*\", ...]"
  
  metric_transformation {
    name      = "SecurityEvents"
    namespace = "VPC/Security"
    value     = "1"
  }
}

# CloudWatch alarm for security events
resource "aws_cloudwatch_metric_alarm" "security_events_alarm" {
  alarm_name          = "SecurityEventsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SecurityEvents"
  namespace           = "VPC/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors security events"
  
  tags = {
    Name        = "Security Events Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Network ACLs**
```hcl
# Network ACL for public subnets
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
  
  tags = {
    Name        = "Public Network ACL"
    Environment = "production"
  }
}

# Associate Network ACL with public subnets
resource "aws_network_acl_association" "public" {
  count = 2
  
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
```

### **Security Group Rules**
```hcl
# Restrictive security group
resource "aws_security_group" "restrictive" {
  name_prefix = "restrictive-"
  vpc_id      = aws_vpc.main.id
  
  # Allow HTTP from specific IP ranges
  ingress {
    description = "HTTP from office"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  # Allow HTTPS from specific IP ranges
  ingress {
    description = "HTTPS from office"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  # Allow SSH from specific IP ranges
  ingress {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Restrictive Security Group"
    Environment = "production"
  }
}
```

### **VPC Peering Security**
```hcl
# VPC peering connection
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = aws_vpc.peer.id
  vpc_id        = aws_vpc.main.id
  peer_region   = "us-west-1"
  
  tags = {
    Name        = "VPC Peering Connection"
    Environment = "production"
  }
}

# Route table entries for peering
resource "aws_route" "peer_route" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
```

## 💰 Cost Optimization

### **NAT Gateway Optimization**
```hcl
# Single NAT Gateway for cost optimization
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name        = "NAT Gateway EIP"
    Environment = "production"
  }
}

resource "aws_nat_gateway" "single" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name        = "Single NAT Gateway"
    Environment = "production"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Route all private subnets through single NAT Gateway
resource "aws_route_table" "private_single" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.single.id
  }
  
  tags = {
    Name        = "Private Route Table (Single NAT)"
    Environment = "production"
  }
}
```

### **VPC Endpoint Optimization**
```hcl
# VPC endpoints to reduce NAT Gateway costs
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  tags = {
    Name        = "S3 VPC Endpoint"
    Environment = "production"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  
  tags = {
    Name        = "DynamoDB VPC Endpoint"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Cannot Access Internet from Private Subnets**
```hcl
# Debug route table
resource "aws_route_table" "debug_private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name        = "Debug Private Route Table"
    Environment = "production"
  }
}

# Verify NAT Gateway is in public subnet
resource "aws_nat_gateway" "debug" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Must be in public subnet
  
  tags = {
    Name        = "Debug NAT Gateway"
    Environment = "production"
  }
  
  depends_on = [aws_internet_gateway.main]
}
```

#### **Issue: Security Group Rules Not Working**
```hcl
# Debug security group with explicit rules
resource "aws_security_group" "debug" {
  name_prefix = "debug-"
  vpc_id      = aws_vpc.main.id
  
  # Explicit ingress rules
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Explicit egress rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Debug Security Group"
    Environment = "production"
  }
}
```

#### **Issue: VPC Peering Connection Problems**
```hcl
# VPC peering with explicit configuration
resource "aws_vpc_peering_connection" "debug" {
  peer_vpc_id   = aws_vpc.peer.id
  vpc_id        = aws_vpc.main.id
  peer_region   = "us-west-1"
  
  # Explicit configuration
  auto_accept = false
  
  tags = {
    Name        = "Debug VPC Peering"
    Environment = "production"
  }
}

# Accept peering connection
resource "aws_vpc_peering_connection_accepter" "debug" {
  vpc_peering_connection_id = aws_vpc_peering_connection.debug.id
  auto_accept               = true
  
  tags = {
    Name        = "Debug VPC Peering Accepter"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Platform VPC**
```hcl
# E-commerce platform VPC structure
locals {
  ecommerce_vpc = {
    cidr_block = "10.0.0.0/16"
    subnets = {
      web = {
        cidr = "10.0.1.0/24"
        az   = "us-west-2a"
        type = "public"
      }
      app = {
        cidr = "10.0.10.0/24"
        az   = "us-west-2a"
        type = "private"
      }
      db = {
        cidr = "10.0.100.0/24"
        az   = "us-west-2a"
        type = "private"
      }
    }
  }
}

# E-commerce VPC
resource "aws_vpc" "ecommerce" {
  cidr_block           = local.ecommerce_vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "E-commerce VPC"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce subnets
resource "aws_subnet" "ecommerce" {
  for_each = local.ecommerce_vpc.subnets
  
  vpc_id            = aws_vpc.ecommerce.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  
  map_public_ip_on_launch = each.value.type == "public"
  
  tags = {
    Name        = "E-commerce ${each.key} Subnet"
    Environment = "production"
    Project     = "ecommerce"
    Type        = each.value.type
  }
}
```

### **Microservices VPC**
```hcl
# Microservices VPC with service-specific subnets
locals {
  microservices = [
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ]
}

# Microservices VPC
resource "aws_vpc" "microservices" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "Microservices VPC"
    Environment = "production"
    Project     = "microservices"
  }
}

# Service-specific subnets
resource "aws_subnet" "microservice" {
  for_each = toset(local.microservices)
  
  vpc_id            = aws_vpc.microservices.id
  cidr_block        = "10.0.${index(local.microservices, each.value) + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name        = "${each.value} Subnet"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **EC2**: Instances in VPC subnets
- **RDS**: Database subnets and security groups
- **ELB**: Load balancers in VPC
- **Lambda**: VPC configuration for functions
- **ECS/EKS**: Container services in VPC
- **S3**: VPC endpoints for private access
- **CloudWatch**: VPC flow logs and monitoring
- **Route 53**: Private hosted zones

### **Service Dependencies**
- **IAM**: Roles for VPC endpoints and flow logs
- **CloudWatch**: Log groups for flow logs
- **KMS**: Encryption for flow logs
- **Direct Connect**: Dedicated connections to VPC
- **VPN**: Site-to-site VPN connections

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic VPC examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect VPC with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up VPC flow logs and monitoring
6. **Optimize**: Focus on cost and performance

**Your VPC Mastery Journey Continues with EC2!** 🚀

---

*This comprehensive VPC guide provides everything you need to master AWS Virtual Private Cloud with Terraform. Each example is production-ready and follows security best practices.*
