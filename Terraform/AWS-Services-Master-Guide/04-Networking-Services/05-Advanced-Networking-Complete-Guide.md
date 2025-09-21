# Advanced Networking - Complete Terraform Guide

## 🎯 Overview

AWS Advanced Networking encompasses enterprise-grade networking services that provide scalable, secure, and high-performance connectivity solutions for complex cloud architectures.

### **What is Advanced Networking?**
Advanced Networking in AWS includes services like Transit Gateway, Direct Connect, VPN Gateway, VPC Peering, PrivateLink, and VPC Endpoints that enable sophisticated network architectures for enterprise applications.

### **Key Concepts**
- **Transit Gateway**: Central hub for VPC connectivity
- **Direct Connect**: Dedicated network connection to AWS
- **VPN Gateway**: Site-to-site VPN connectivity
- **VPC Peering**: Direct VPC-to-VPC connectivity
- **PrivateLink**: Private connectivity to AWS services
- **VPC Endpoints**: Private access to AWS services
- **NAT Gateway**: Outbound internet access
- **Network ACLs**: Subnet-level security
- **Security Groups**: Instance-level security
- **Route Tables**: Traffic routing

### **When to Use Advanced Networking**
- **Multi-VPC architectures** - Connect multiple VPCs
- **Hybrid cloud** - On-premises and cloud integration
- **Enterprise connectivity** - Dedicated network connections
- **Microservices** - Service-to-service communication
- **Compliance** - Network isolation and security
- **Global applications** - Multi-region connectivity
- **Disaster recovery** - Cross-region networking
- **Cost optimization** - Efficient traffic routing

## 🏗️ Architecture Patterns

### **Basic Advanced Networking Structure**
```
Advanced Networking
├── Transit Gateway (Central Hub)
├── Direct Connect (Dedicated Connection)
├── VPN Gateway (Site-to-Site VPN)
├── VPC Peering (Direct Connectivity)
├── PrivateLink (Private Services)
├── VPC Endpoints (Private Access)
└── NAT Gateway (Outbound Access)
```

### **Enterprise Networking Pattern**
```
On-Premises
├── Direct Connect
├── VPN Gateway
└── Transit Gateway
    ├── VPC 1 (Production)
    ├── VPC 2 (Staging)
    ├── VPC 3 (Development)
    └── Shared Services VPC
```

## 📝 Terraform Implementation

### **Transit Gateway Setup**
```hcl
# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = "Main Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Main Transit Gateway"
    Environment = "production"
  }
}

# Transit Gateway route table
resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "Main Transit Gateway Route Table"
    Environment = "production"
  }
}

# Transit Gateway VPC attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids                                      = aws_subnet.private[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name        = "Main Transit Gateway VPC Attachment"
    Environment = "production"
  }
}

# Transit Gateway route
resource "aws_ec2_transit_gateway_route" "main" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
```

### **Direct Connect Setup**
```hcl
# Direct Connect connection
resource "aws_dx_connection" "main" {
  name      = "main-direct-connect"
  bandwidth = "1Gbps"
  location  = "EqDC2"
  tags = {
    Name        = "Main Direct Connect"
    Environment = "production"
  }
}

# Direct Connect gateway
resource "aws_dx_gateway" "main" {
  name            = "main-dx-gateway"
  amazon_side_asn = 64512
}

# Direct Connect gateway association
resource "aws_dx_gateway_association" "main" {
  dx_gateway_id         = aws_dx_gateway.main.id
  associated_gateway_id = aws_ec2_transit_gateway.main.id
}

# Direct Connect virtual interface
resource "aws_dx_private_virtual_interface" "main" {
  connection_id    = aws_dx_connection.main.id
  dx_gateway_id    = aws_dx_gateway.main.id
  name             = "main-private-vif"
  vlan             = 4094
  address_family   = "ipv4"
  bgp_asn          = 65000
  customer_address = "169.254.249.2/30"
  amazon_address   = "169.254.249.1/30"
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
  destination_cidr_block = "10.0.0.0/16"
  vpn_connection_id      = aws_vpn_connection.main.id
}
```

### **VPC Peering Setup**
```hcl
# VPC Peering connection
resource "aws_vpc_peering_connection" "main" {
  peer_vpc_id   = aws_vpc.peer.id
  vpc_id        = aws_vpc.main.id
  auto_accept   = true

  tags = {
    Name        = "Main VPC Peering Connection"
    Environment = "production"
  }
}

# Route table for VPC peering
resource "aws_route_table" "peering" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }

  tags = {
    Name        = "Peering Route Table"
    Environment = "production"
  }
}

# Route table association
resource "aws_route_table_association" "peering" {
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.peering.id
}
```

### **PrivateLink Setup**
```hcl
# VPC Endpoint Service
resource "aws_vpc_endpoint_service" "main" {
  acceptance_required        = false
  allowed_principals        = [aws_iam_role.main.arn]
  gateway_load_balancer_arns = [aws_lb.main.arn]

  tags = {
    Name        = "Main VPC Endpoint Service"
    Environment = "production"
  }
}

# VPC Endpoint
resource "aws_vpc_endpoint" "main" {
  vpc_id              = aws_vpc.main.id
  service_name        = aws_vpc_endpoint_service.main.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "Main VPC Endpoint"
    Environment = "production"
  }
}

# Security group for VPC endpoint
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

### **VPC Endpoints Setup**
```hcl
# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name        = "S3 VPC Endpoint"
    Environment = "production"
  }
}

# DynamoDB VPC Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name        = "DynamoDB VPC Endpoint"
    Environment = "production"
  }
}

# ECR VPC Endpoint
resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "ECR VPC Endpoint"
    Environment = "production"
  }
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "ECR API VPC Endpoint"
    Environment = "production"
  }
}

data "aws_region" "current" {}
```

### **NAT Gateway Setup**
```hcl
# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "Main NAT Gateway"
    Environment = "production"
  }

  depends_on = [aws_internet_gateway.main]
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "NAT Gateway EIP"
    Environment = "production"
  }
}

# Route table for NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "Private Route Table"
    Environment = "production"
  }
}

# Route table association for private subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

## 🔧 Configuration Options

### **Advanced Networking Configuration**
```hcl
# Transit Gateway configuration
resource "aws_ec2_transit_gateway" "custom" {
  description                     = var.description
  amazon_side_asn                = var.amazon_side_asn
  auto_accept_shared_attachments = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                    = var.dns_support
  vpn_ecmp_support              = var.vpn_ecmp_support

  tags = merge(var.common_tags, {
    Name = var.name
  })
}
```

### **Advanced Networking Configuration**
```hcl
# Advanced Transit Gateway
resource "aws_ec2_transit_gateway" "advanced" {
  description                     = "Advanced Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Advanced Transit Gateway"
    Environment = "production"
  }
}

# Advanced Direct Connect
resource "aws_dx_connection" "advanced" {
  name      = "advanced-direct-connect"
  bandwidth = "10Gbps"
  location  = "EqDC2"
  tags = {
    Name        = "Advanced Direct Connect"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple Transit Gateway
resource "aws_ec2_transit_gateway" "simple" {
  description = "Simple Transit Gateway"

  tags = {
    Name = "Simple Transit Gateway"
  }
}
```

### **Production Deployment**
```hcl
# Production Advanced Networking setup
locals {
  networking_config = {
    transit_gateway_name = "production-transit-gateway"
    amazon_side_asn = 64512
    enable_direct_connect = true
    enable_vpn_gateway = true
    enable_vpc_peering = true
  }
}

# Production Transit Gateway
resource "aws_ec2_transit_gateway" "production" {
  description                     = "Production Transit Gateway"
  amazon_side_asn                = local.networking_config.amazon_side_asn
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Production Transit Gateway"
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
      transit_gateway_name = "dev-transit-gateway"
      amazon_side_asn = 64512
      enable_direct_connect = false
    }
    staging = {
      transit_gateway_name = "staging-transit-gateway"
      amazon_side_asn = 64512
      enable_direct_connect = true
    }
    prod = {
      transit_gateway_name = "prod-transit-gateway"
      amazon_side_asn = 64512
      enable_direct_connect = true
    }
  }
}

# Environment-specific Transit Gateways
resource "aws_ec2_transit_gateway" "environment" {
  for_each = local.environments

  description                     = "${each.key} Transit Gateway"
  amazon_side_asn                = each.value.amazon_side_asn
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "${title(each.key)} Transit Gateway"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for Advanced Networking
resource "aws_cloudwatch_log_group" "networking_logs" {
  name              = "/aws/networking/transit-gateway"
  retention_in_days = 30

  tags = {
    Name        = "Advanced Networking Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for Transit Gateway
resource "aws_cloudwatch_log_metric_filter" "transit_gateway_errors" {
  name           = "TransitGatewayErrors"
  log_group_name = aws_cloudwatch_log_group.networking_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "TransitGatewayErrors"
    namespace = "TransitGateway/Errors"
    value     = "1"
  }
}

# CloudWatch alarm for Transit Gateway
resource "aws_cloudwatch_metric_alarm" "transit_gateway_alarm" {
  alarm_name          = "TransitGatewayAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BytesIn"
  namespace           = "AWS/TransitGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000000"
  alarm_description   = "This metric monitors Transit Gateway traffic"

  dimensions = {
    TransitGateway = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name        = "Transit Gateway Alarm"
    Environment = "production"
  }
}
```

### **Advanced Networking Metrics**
```hcl
# CloudWatch alarm for Direct Connect
resource "aws_cloudwatch_metric_alarm" "direct_connect_alarm" {
  alarm_name          = "DirectConnectAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConnectionBpsIngress"
  namespace           = "AWS/DX"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"
  alarm_description   = "This metric monitors Direct Connect traffic"

  dimensions = {
    ConnectionId = aws_dx_connection.main.id
  }

  tags = {
    Name        = "Direct Connect Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Advanced Networking Security**
```hcl
# Secure Transit Gateway
resource "aws_ec2_transit_gateway" "secure" {
  description                     = "Secure Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Secure Transit Gateway"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for Advanced Networking access
resource "aws_iam_policy" "advanced_networking_access" {
  name        = "AdvancedNetworkingAccess"
  description = "Policy for Advanced Networking access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTransitGateways",
          "ec2:DescribeTransitGatewayAttachments",
          "directconnect:DescribeConnections",
          "directconnect:DescribeVirtualInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Advanced Networking Optimization**
```hcl
# Cost-optimized Transit Gateway
resource "aws_ec2_transit_gateway" "cost_optimized" {
  description                     = "Cost Optimized Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Cost Optimized Transit Gateway"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Transit Gateway Not Connecting**
```hcl
# Debug Transit Gateway
resource "aws_ec2_transit_gateway" "debug" {
  description                     = "Debug Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Debug Transit Gateway"
    Environment = "production"
  }
}
```

#### **Issue: Direct Connect Problems**
```hcl
# Debug Direct Connect
resource "aws_dx_connection" "debug" {
  name      = "debug-direct-connect"
  bandwidth = "1Gbps"
  location  = "EqDC2"
  tags = {
    Name        = "Debug Direct Connect"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Advanced Networking Setup**
```hcl
# E-commerce Advanced Networking setup
locals {
  ecommerce_config = {
    transit_gateway_name = "ecommerce-transit-gateway"
    amazon_side_asn = 64512
    enable_direct_connect = true
    enable_vpn_gateway = true
  }
}

# E-commerce Transit Gateway
resource "aws_ec2_transit_gateway" "ecommerce" {
  description                     = "E-commerce Transit Gateway"
  amazon_side_asn                = local.ecommerce_config.amazon_side_asn
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "E-commerce Transit Gateway"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Advanced Networking Setup**
```hcl
# Microservices Advanced Networking setup
resource "aws_ec2_transit_gateway" "microservices" {
  description                     = "Microservices Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                    = "enable"
  vpn_ecmp_support              = "enable"

  tags = {
    Name        = "Microservices Transit Gateway"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **VPC**: Virtual private clouds
- **EC2**: Compute instances
- **EKS**: Kubernetes clusters
- **RDS**: Database services
- **S3**: Object storage
- **CloudWatch**: Monitoring
- **IAM**: Access control
- **KMS**: Encryption

### **Service Dependencies**
- **VPC**: Networking foundation
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **Route 53**: DNS resolution

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Advanced Networking examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Advanced Networking with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your Advanced Networking Mastery Journey Continues with Multi-Region Architecture!** 🚀

---

*This comprehensive Advanced Networking guide provides everything you need to master AWS Advanced Networking with Terraform. Each example is production-ready and follows security best practices.*
