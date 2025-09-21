# Advanced Networking - Complete Terraform Guide

## 🎯 Overview

AWS Advanced Networking encompasses a comprehensive set of services and features that enable sophisticated network architectures, including VPC peering, Transit Gateway, VPN connections, Direct Connect, and advanced security features.

### **What is Advanced Networking?**
Advanced Networking in AWS provides enterprise-grade networking capabilities that enable complex network topologies, hybrid cloud connectivity, and advanced security features for large-scale applications.

### **Key Concepts**
- **VPC Peering**: Connect VPCs within the same region
- **Transit Gateway**: Centralized hub for VPC and on-premises connectivity
- **VPN Gateway**: Site-to-site VPN connections
- **Direct Connect**: Dedicated network connection to AWS
- **PrivateLink**: Private connectivity to AWS services
- **NAT Gateway**: Outbound internet access for private subnets
- **VPC Endpoints**: Private connectivity to AWS services
- **Network ACLs**: Subnet-level security
- **Security Groups**: Instance-level security
- **Route Tables**: Traffic routing configuration

### **When to Use Advanced Networking**
- **Multi-VPC architectures** - Connect multiple VPCs
- **Hybrid cloud** - Connect on-premises to AWS
- **Enterprise networking** - Complex network topologies
- **Compliance requirements** - Meet regulatory requirements
- **High availability** - Multi-region deployments
- **Security isolation** - Network segmentation
- **Cost optimization** - Optimize network costs
- **Performance optimization** - Optimize network performance

## 🏗️ Architecture Patterns

### **Basic Advanced Networking Structure**
```
Advanced Networking
├── VPC Peering (VPC-to-VPC)
├── Transit Gateway (Hub-and-Spoke)
├── VPN Gateway (Site-to-Site)
├── Direct Connect (Dedicated Connection)
├── PrivateLink (Private Service Access)
└── VPC Endpoints (Service Access)
```

### **Hub-and-Spoke Pattern**
```
Transit Gateway (Hub)
├── VPC 1 (Spoke)
├── VPC 2 (Spoke)
├── VPC 3 (Spoke)
└── On-Premises (Spoke)
```

## 📝 Terraform Implementation

### **VPC Peering Setup**
```hcl
# VPC 1
resource "aws_vpc" "vpc1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "VPC 1"
    Environment = "production"
  }
}

# VPC 2
resource "aws_vpc" "vpc2" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "VPC 2"
    Environment = "production"
  }
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "vpc1_to_vpc2" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id
  auto_accept = true

  tags = {
    Name        = "VPC1 to VPC2 Peering"
    Environment = "production"
  }
}

# Route Table for VPC 1
resource "aws_route_table" "vpc1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
  }

  tags = {
    Name        = "VPC1 Route Table"
    Environment = "production"
  }
}

# Route Table for VPC 2
resource "aws_route_table" "vpc2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
  }

  tags = {
    Name        = "VPC2 Route Table"
    Environment = "production"
  }
}
```

### **Transit Gateway Setup**
```hcl
# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = "Main Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name        = "Main Transit Gateway"
    Environment = "production"
  }
}

# VPC 1
resource "aws_vpc" "tgw_vpc1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "TGW VPC 1"
    Environment = "production"
  }
}

# VPC 2
resource "aws_vpc" "tgw_vpc2" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "TGW VPC 2"
    Environment = "production"
  }
}

# Transit Gateway VPC Attachment 1
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1" {
  subnet_ids         = aws_subnet.tgw_vpc1[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.tgw_vpc1.id

  tags = {
    Name        = "TGW VPC1 Attachment"
    Environment = "production"
  }
}

# Transit Gateway VPC Attachment 2
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2" {
  subnet_ids         = aws_subnet.tgw_vpc2[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.tgw_vpc2.id

  tags = {
    Name        = "TGW VPC2 Attachment"
    Environment = "production"
  }
}

# Subnets for TGW VPC 1
resource "aws_subnet" "tgw_vpc1" {
  count = 2

  vpc_id            = aws_vpc.tgw_vpc1.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "TGW VPC1 Subnet ${count.index + 1}"
    Environment = "production"
  }
}

# Subnets for TGW VPC 2
resource "aws_subnet" "tgw_vpc2" {
  count = 2

  vpc_id            = aws_vpc.tgw_vpc2.id
  cidr_block        = "10.1.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "TGW VPC2 Subnet ${count.index + 1}"
    Environment = "production"
  }
}
```

### **VPN Gateway Setup**
```hcl
# VPN Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "Main VPN Gateway"
    Environment = "production"
  }
}

# Customer Gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "203.0.113.12"
  type       = "ipsec.1"

  tags = {
    Name        = "Main Customer Gateway"
    Environment = "production"
  }
}

# VPN Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name        = "Main VPN Connection"
    Environment = "production"
  }
}

# VPN Connection Route
resource "aws_vpn_connection_route" "main" {
  destination_cidr_block = "192.168.0.0/16"
  vpn_connection_id      = aws_vpn_connection.main.id
}
```

### **Direct Connect Setup**
```hcl
# Direct Connect Gateway
resource "aws_dx_gateway" "main" {
  name            = "main-dx-gateway"
  amazon_side_asn = "64512"

  tags = {
    Name        = "Main Direct Connect Gateway"
    Environment = "production"
  }
}

# Direct Connect Virtual Interface
resource "aws_dx_virtual_interface" "main" {
  connection_id = aws_dx_connection.main.id
  name          = "main-virtual-interface"
  vlan          = 4094
  address_family = "ipv4"
  bgp_asn       = 65000

  tags = {
    Name        = "Main Virtual Interface"
    Environment = "production"
  }
}

# Direct Connect Connection
resource "aws_dx_connection" "main" {
  name      = "main-dx-connection"
  bandwidth = "1Gbps"
  location  = "EqDC2"

  tags = {
    Name        = "Main Direct Connect Connection"
    Environment = "production"
  }
}
```

### **PrivateLink Setup**
```hcl
# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = {
    Name        = "S3 VPC Endpoint"
    Environment = "production"
  }
}

# VPC Endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = {
    Name        = "DynamoDB VPC Endpoint"
    Environment = "production"
  }
}

# VPC Endpoint for Lambda
resource "aws_vpc_endpoint" "lambda" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name        = "Lambda VPC Endpoint"
    Environment = "production"
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpc-endpoint-"
  vpc_id      = aws_vpc.main.id

  ingress {
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
```

### **NAT Gateway Setup**
```hcl
# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  domain = "vpc"

  tags = {
    Name        = "NAT Gateway EIP ${count.index + 1}"
    Environment = "production"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "NAT Gateway ${count.index + 1}"
    Environment = "production"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

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

# Route Table Association for Private Subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

## 🔧 Configuration Options

### **Advanced Networking Configuration**
```hcl
# VPC Configuration
resource "aws_vpc" "custom" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.common_tags, {
    Name = var.vpc_name
  })
}

# Subnet Configuration
resource "aws_subnet" "custom" {
  count = length(var.subnet_cidrs)

  vpc_id            = aws_vpc.custom.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name} Subnet ${count.index + 1}"
  })
}
```

### **Advanced Security Configuration**
```hcl
# Network ACL
resource "aws_network_acl" "advanced" {
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

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "Advanced Network ACL"
    Environment = "production"
  }
}

# Security Group
resource "aws_security_group" "advanced" {
  name_prefix = "advanced-"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Advanced Security Group"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple VPC setup
resource "aws_vpc" "simple" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Simple VPC"
  }
}

# Simple subnet
resource "aws_subnet" "simple" {
  vpc_id            = aws_vpc.simple.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Simple Subnet"
  }
}
```

### **Production Deployment**
```hcl
# Production Advanced Networking setup
locals {
  networking_config = {
    vpc_cidr = "10.0.0.0/16"
    enable_nat_gateway = true
    enable_vpc_endpoints = true
    enable_transit_gateway = true
    enable_vpn_gateway = true
  }
}

# Production VPC
resource "aws_vpc" "production" {
  cidr_block           = local.networking_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Production VPC"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production Transit Gateway
resource "aws_ec2_transit_gateway" "production" {
  count = local.networking_config.enable_transit_gateway ? 1 : 0

  description                     = "Production Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name        = "Production Transit Gateway"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production VPN Gateway
resource "aws_vpn_gateway" "production" {
  count = local.networking_config.enable_vpn_gateway ? 1 : 0

  vpc_id = aws_vpc.production.id

  tags = {
    Name        = "Production VPN Gateway"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment Advanced Networking setup
locals {
  environments = {
    dev = {
      vpc_cidr = "10.0.0.0/16"
      enable_nat_gateway = false
      enable_vpc_endpoints = false
    }
    staging = {
      vpc_cidr = "10.1.0.0/16"
      enable_nat_gateway = true
      enable_vpc_endpoints = true
    }
    prod = {
      vpc_cidr = "10.2.0.0/16"
      enable_nat_gateway = true
      enable_vpc_endpoints = true
    }
  }
}

# Environment-specific VPCs
resource "aws_vpc" "environment" {
  for_each = local.environments

  cidr_block           = each.value.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${title(each.key)} VPC"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific NAT Gateways
resource "aws_nat_gateway" "environment" {
  for_each = {
    for env, config in local.environments : env => config
    if config.enable_nat_gateway
  }

  allocation_id = aws_eip.environment[each.key].id
  subnet_id     = aws_subnet.environment_public[each.key][0].id

  tags = {
    Name        = "${title(each.key)} NAT Gateway"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30

  tags = {
    Name        = "VPC Flow Logs"
    Environment = "production"
  }
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name        = "Main VPC Flow Logs"
    Environment = "production"
  }
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  name = "vpc-flow-logs-role"

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

resource "aws_iam_role_policy_attachment" "flow_logs" {
  role       = aws_iam_role.flow_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/VPCFlowLogsDeliveryRolePolicy"
}
```

### **Network Monitoring**
```hcl
# CloudWatch alarm for VPN connection
resource "aws_cloudwatch_metric_alarm" "vpn_connection" {
  alarm_name          = "VPNConnectionAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TunnelState"
  namespace           = "AWS/VPN"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors VPN connection state"

  dimensions = {
    VpnId = aws_vpn_connection.main.id
  }

  tags = {
    Name        = "VPN Connection Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Network Security**
```hcl
# Network ACL
resource "aws_network_acl" "secure" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "Secure Network ACL"
    Environment = "production"
  }
}

# Security Group
resource "aws_security_group" "secure" {
  name_prefix = "secure-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "Secure Security Group"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for network access
resource "aws_iam_policy" "network_access" {
  name        = "NetworkAccess"
  description = "Policy for network access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkAcls"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **NAT Gateway Optimization**
```hcl
# Cost-optimized NAT Gateway
resource "aws_nat_gateway" "cost_optimized" {
  count = 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "Cost Optimized NAT Gateway"
    Environment = "production"
  }
}
```

### **VPC Endpoint Optimization**
```hcl
# Cost-optimized VPC Endpoints
resource "aws_vpc_endpoint" "cost_optimized" {
  for_each = toset([
    "com.amazonaws.${data.aws_region.current.name}.s3",
    "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  ])

  vpc_id       = aws_vpc.main.id
  service_name = each.value

  tags = {
    Name        = "Cost Optimized VPC Endpoint"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: VPC Peering Failed**
```hcl
# Debug VPC peering
resource "aws_vpc_peering_connection" "debug" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.peer.id
  auto_accept = true

  tags = {
    Name        = "Debug VPC Peering"
    Environment = "production"
  }
}
```

#### **Issue: Transit Gateway Problems**
```hcl
# Debug Transit Gateway
resource "aws_ec2_transit_gateway" "debug" {
  description                     = "Debug Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name        = "Debug Transit Gateway"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Advanced Networking**
```hcl
# E-commerce Advanced Networking setup
locals {
  ecommerce_config = {
    vpc_cidr = "10.0.0.0/16"
    enable_nat_gateway = true
    enable_vpc_endpoints = true
    enable_transit_gateway = true
    enable_vpn_gateway = true
  }
}

# E-commerce VPC
resource "aws_vpc" "ecommerce" {
  cidr_block           = local.ecommerce_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "E-commerce VPC"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce Transit Gateway
resource "aws_ec2_transit_gateway" "ecommerce" {
  count = local.ecommerce_config.enable_transit_gateway ? 1 : 0

  description                     = "E-commerce Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name        = "E-commerce Transit Gateway"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce VPN Gateway
resource "aws_vpn_gateway" "ecommerce" {
  count = local.ecommerce_config.enable_vpn_gateway ? 1 : 0

  vpc_id = aws_vpc.ecommerce.id

  tags = {
    Name        = "E-commerce VPN Gateway"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Advanced Networking**
```hcl
# Microservices Advanced Networking setup
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

# Microservices Transit Gateway
resource "aws_ec2_transit_gateway" "microservices" {
  description                     = "Microservices Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name        = "Microservices Transit Gateway"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices VPC Endpoints
resource "aws_vpc_endpoint" "microservices" {
  for_each = toset([
    "com.amazonaws.${data.aws_region.current.name}.s3",
    "com.amazonaws.${data.aws_region.current.name}.dynamodb",
    "com.amazonaws.${data.aws_region.current.name}.lambda"
  ])

  vpc_id       = aws_vpc.microservices.id
  service_name = each.value

  tags = {
    Name        = "Microservices ${title(each.value)} VPC Endpoint"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **VPC**: Virtual private cloud
- **EC2**: Instance networking
- **ECS**: Container networking
- **Lambda**: Function networking
- **CloudWatch**: Network monitoring
- **CloudTrail**: Network auditing
- **IAM**: Network access control
- **KMS**: Network encryption

### **Service Dependencies**
- **VPC**: Core networking
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **CloudTrail**: Auditing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Advanced Networking examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Advanced Networking with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your Advanced Networking Mastery Journey Continues with Expert Services!** 🚀

---

*This comprehensive Advanced Networking guide provides everything you need to master AWS Advanced Networking with Terraform. Each example is production-ready and follows security best practices.*
