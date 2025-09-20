# Terraform AWS Data Sources - Complete Integration Guide

## Overview

This comprehensive guide covers AWS data sources in Terraform, including advanced filtering, cross-account access, and enterprise-grade AWS resource discovery patterns.

## AWS Data Source Fundamentals

### Core AWS Data Sources

```hcl
# Current AWS account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Availability zones
data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Use in outputs
output "aws_environment_info" {
  description = "AWS environment information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    partition  = data.aws_partition.current.partition
    azs        = data.aws_availability_zones.available.names
  }
}
```

## AMI Data Sources

### Latest AMI Discovery

```hcl
# Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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

# Amazon Linux 2
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

# Windows Server
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

# Custom AMI by tags
data "aws_ami" "custom_app" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "tag:Application"
    values = ["web-app"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Output AMI information
output "ami_inventory" {
  description = "Available AMI inventory"
  value = {
    ubuntu = {
      id           = data.aws_ami.ubuntu.id
      name         = data.aws_ami.ubuntu.name
      architecture = data.aws_ami.ubuntu.architecture
      creation_date = data.aws_ami.ubuntu.creation_date
    }
    amazon_linux = {
      id           = data.aws_ami.amazon_linux.id
      name         = data.aws_ami.amazon_linux.name
      architecture = data.aws_ami.amazon_linux.architecture
      creation_date = data.aws_ami.amazon_linux.creation_date
    }
    windows = {
      id           = data.aws_ami.windows.id
      name         = data.aws_ami.windows.name
      architecture = data.aws_ami.windows.architecture
      creation_date = data.aws_ami.windows.creation_date
    }
  }
}
```

## VPC and Networking Data Sources

### VPC Discovery

```hcl
# Default VPC
data "aws_vpc" "default" {
  default = true
}

# VPC by name tag
data "aws_vpc" "main" {
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# VPC by CIDR
data "aws_vpc" "by_cidr" {
  cidr_block = "10.0.0.0/16"
}

# Multiple VPCs
data "aws_vpcs" "all" {
  tags = {
    Environment = var.environment
  }
}

# Get details for each VPC
data "aws_vpc" "details" {
  for_each = toset(data.aws_vpcs.all.ids)
  id       = each.value
}

output "vpc_inventory" {
  description = "VPC inventory"
  value = {
    default_vpc = {
      id         = data.aws_vpc.default.id
      cidr_block = data.aws_vpc.default.cidr_block
      state      = data.aws_vpc.default.state
    }
    
    environment_vpcs = {
      for vpc in data.aws_vpc.details :
      vpc.id => {
        cidr_block = vpc.cidr_block
        state      = vpc.state
        tags       = vpc.tags
      }
    }
  }
}
```

### Subnet Discovery

```hcl
# Public subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "public"
  }
}

# Private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "private"
  }
}

# Database subnets
data "aws_subnets" "database" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "database"
  }
}

# Get subnet details
data "aws_subnet" "public_details" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_subnet" "private_details" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# Subnet analysis
locals {
  subnet_analysis = {
    public_subnets = {
      count = length(data.aws_subnets.public.ids)
      azs   = distinct([for s in data.aws_subnet.public_details : s.availability_zone])
      cidrs = [for s in data.aws_subnet.public_details : s.cidr_block]
    }
    
    private_subnets = {
      count = length(data.aws_subnets.private.ids)
      azs   = distinct([for s in data.aws_subnet.private_details : s.availability_zone])
      cidrs = [for s in data.aws_subnet.private_details : s.cidr_block]
    }
    
    az_distribution = {
      for az in data.aws_availability_zones.available.names :
      az => {
        public_subnets  = length([for s in data.aws_subnet.public_details : s if s.availability_zone == az])
        private_subnets = length([for s in data.aws_subnet.private_details : s if s.availability_zone == az])
      }
    }
  }
}

output "network_topology" {
  description = "Network topology analysis"
  value = local.subnet_analysis
}
```

## Security Group Data Sources

### Security Group Discovery

```hcl
# Security groups by VPC
data "aws_security_groups" "vpc_sgs" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Specific security group by name
data "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = data.aws_vpc.main.id
}

# Security group by tags
data "aws_security_group" "database" {
  tags = {
    Name = "${var.project_name}-database-sg"
    Type = "database"
  }
}

# Default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.main.id
}

# Security group analysis
data "aws_security_group" "all_details" {
  for_each = toset(data.aws_security_groups.vpc_sgs.ids)
  id       = each.value
}

locals {
  security_analysis = {
    total_security_groups = length(data.aws_security_groups.vpc_sgs.ids)
    
    by_type = {
      for sg in data.aws_security_group.all_details :
      sg.id => {
        name        = sg.name
        description = sg.description
        type        = try(sg.tags.Type, "untagged")
        
        ingress_rules = length(sg.ingress)
        egress_rules  = length(sg.egress)
        
        allows_ssh = length([
          for rule in sg.ingress :
          rule if rule.from_port == 22 && rule.to_port == 22
        ]) > 0
        
        allows_http = length([
          for rule in sg.ingress :
          rule if rule.from_port == 80 && rule.to_port == 80
        ]) > 0
        
        allows_https = length([
          for rule in sg.ingress :
          rule if rule.from_port == 443 && rule.to_port == 443
        ]) > 0
      }
    }
  }
}

output "security_analysis" {
  description = "Security group analysis"
  value = local.security_analysis
}
```

## EC2 Instance Data Sources

### Instance Discovery

```hcl
# Running instances by tag
data "aws_instances" "web_servers" {
  filter {
    name   = "tag:Role"
    values = ["web"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Instance details
data "aws_instance" "web_details" {
  for_each    = toset(data.aws_instances.web_servers.ids)
  instance_id = each.value
}

# Instance type information
data "aws_ec2_instance_type" "current_types" {
  for_each      = toset(distinct([for i in data.aws_instance.web_details : i.instance_type]))
  instance_type = each.value
}

# Spot price history
data "aws_ec2_spot_price" "current" {
  for_each = toset(distinct([for i in data.aws_instance.web_details : i.instance_type]))
  
  instance_type     = each.value
  availability_zone = data.aws_availability_zones.available.names[0]
  
  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}

# Instance analysis
locals {
  instance_analysis = {
    total_instances = length(data.aws_instances.web_servers.ids)
    
    by_az = {
      for az in data.aws_availability_zones.available.names :
      az => length([
        for instance in data.aws_instance.web_details :
        instance if instance.availability_zone == az
      ])
    }
    
    by_type = {
      for type in distinct([for i in data.aws_instance.web_details : i.instance_type]) :
      type => {
        count = length([for i in data.aws_instance.web_details : i if i.instance_type == type])
        specs = {
          vcpus         = data.aws_ec2_instance_type.current_types[type].default_vcpus
          memory        = data.aws_ec2_instance_type.current_types[type].memory_size
          network_performance = data.aws_ec2_instance_type.current_types[type].network_performance
        }
        current_spot_price = data.aws_ec2_spot_price.current[type].spot_price
      }
    }
    
    cost_estimate = {
      total_vcpus = sum([
        for instance in data.aws_instance.web_details :
        data.aws_ec2_instance_type.current_types[instance.instance_type].default_vcpus
      ])
      
      total_memory_gb = sum([
        for instance in data.aws_instance.web_details :
        data.aws_ec2_instance_type.current_types[instance.instance_type].memory_size / 1024
      ])
    }
  }
}

output "instance_inventory" {
  description = "EC2 instance inventory and analysis"
  value = local.instance_analysis
}
```

## RDS Data Sources

### Database Discovery

```hcl
# RDS instances
data "aws_db_instances" "all" {
  tags = {
    Environment = var.environment
  }
}

# Specific database instance
data "aws_db_instance" "main" {
  db_instance_identifier = "${var.project_name}-${var.environment}-db"
}

# RDS subnet groups
data "aws_db_subnet_group" "main" {
  name = "${var.project_name}-${var.environment}-subnet-group"
}

# Database snapshots
data "aws_db_snapshots" "recent" {
  db_instance_identifier = data.aws_db_instance.main.id
  most_recent           = true
  snapshot_type         = "automated"
}

# Database analysis
locals {
  database_analysis = {
    total_instances = length(data.aws_db_instances.all.instance_identifiers)
    
    main_database = {
      identifier    = data.aws_db_instance.main.id
      engine        = data.aws_db_instance.main.engine
      engine_version = data.aws_db_instance.main.engine_version
      instance_class = data.aws_db_instance.main.db_instance_class
      allocated_storage = data.aws_db_instance.main.allocated_storage
      
      backup_config = {
        retention_period = data.aws_db_instance.main.backup_retention_period
        backup_window   = data.aws_db_instance.main.backup_window
        maintenance_window = data.aws_db_instance.main.maintenance_window
      }
      
      security = {
        encrypted = data.aws_db_instance.main.storage_encrypted
        multi_az  = data.aws_db_instance.main.multi_az
        publicly_accessible = data.aws_db_instance.main.publicly_accessible
      }
      
      latest_snapshot = try({
        id           = data.aws_db_snapshots.recent.db_snapshots[0].id
        created_time = data.aws_db_snapshots.recent.db_snapshots[0].snapshot_create_time
        type         = data.aws_db_snapshots.recent.db_snapshots[0].snapshot_type
      }, null)
    }
  }
}

output "database_inventory" {
  description = "RDS database inventory"
  value = local.database_analysis
}
```

## Load Balancer Data Sources

### ALB/NLB Discovery

```hcl
# Application Load Balancers
data "aws_lb" "web" {
  name = "${var.project_name}-${var.environment}-alb"
}

# Load balancer listeners
data "aws_lb_listener" "web_http" {
  load_balancer_arn = data.aws_lb.web.arn
  port              = 80
}

data "aws_lb_listener" "web_https" {
  load_balancer_arn = data.aws_lb.web.arn
  port              = 443
}

# Target groups
data "aws_lb_target_group" "web" {
  name = "${var.project_name}-${var.environment}-tg"
}

# Load balancer analysis
locals {
  lb_analysis = {
    load_balancer = {
      arn       = data.aws_lb.web.arn
      dns_name  = data.aws_lb.web.dns_name
      zone_id   = data.aws_lb.web.zone_id
      type      = data.aws_lb.web.load_balancer_type
      scheme    = data.aws_lb.web.scheme
      
      security = {
        security_groups = data.aws_lb.web.security_groups
        subnets        = data.aws_lb.web.subnets
      }
    }
    
    listeners = {
      http = try({
        arn      = data.aws_lb_listener.web_http.arn
        port     = data.aws_lb_listener.web_http.port
        protocol = data.aws_lb_listener.web_http.protocol
      }, null)
      
      https = try({
        arn           = data.aws_lb_listener.web_https.arn
        port          = data.aws_lb_listener.web_https.port
        protocol      = data.aws_lb_listener.web_https.protocol
        ssl_policy    = data.aws_lb_listener.web_https.ssl_policy
        certificate_arn = data.aws_lb_listener.web_https.certificate_arn
      }, null)
    }
    
    target_group = {
      arn                = data.aws_lb_target_group.web.arn
      port               = data.aws_lb_target_group.web.port
      protocol           = data.aws_lb_target_group.web.protocol
      target_type        = data.aws_lb_target_group.web.target_type
      health_check_path  = data.aws_lb_target_group.web.health_check[0].path
      health_check_port  = data.aws_lb_target_group.web.health_check[0].port
    }
  }
}

output "load_balancer_config" {
  description = "Load balancer configuration"
  value = local.lb_analysis
}
```

## Route 53 Data Sources

### DNS Discovery

```hcl
# Hosted zones
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

data "aws_route53_zone" "internal" {
  name         = "${var.environment}.internal"
  private_zone = true
  vpc_id       = data.aws_vpc.main.id
}

# DNS records
data "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
}

# Certificate validation records
data "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
}

# DNS analysis
locals {
  dns_analysis = {
    public_zone = {
      zone_id      = data.aws_route53_zone.main.zone_id
      name_servers = data.aws_route53_zone.main.name_servers
      record_count = data.aws_route53_zone.main.resource_record_set_count
    }
    
    private_zone = try({
      zone_id      = data.aws_route53_zone.internal.zone_id
      vpc_id       = data.aws_route53_zone.internal.vpc[0].vpc_id
      record_count = data.aws_route53_zone.internal.resource_record_set_count
    }, null)
    
    web_record = try({
      name    = data.aws_route53_record.web.name
      type    = data.aws_route53_record.web.type
      ttl     = data.aws_route53_record.web.ttl
      records = data.aws_route53_record.web.records
    }, null)
  }
}

output "dns_configuration" {
  description = "DNS configuration"
  value = local.dns_analysis
}
```

## S3 Data Sources

### S3 Bucket Discovery

```hcl
# S3 bucket
data "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${var.environment}-data"
}

# Bucket policy
data "aws_s3_bucket_policy" "app_data" {
  bucket = data.aws_s3_bucket.app_data.id
}

# Bucket objects
data "aws_s3_objects" "app_configs" {
  bucket = data.aws_s3_bucket.app_data.id
  prefix = "configs/"
}

# S3 analysis
locals {
  s3_analysis = {
    bucket = {
      name           = data.aws_s3_bucket.app_data.id
      region         = data.aws_s3_bucket.app_data.region
      hosted_zone_id = data.aws_s3_bucket.app_data.hosted_zone_id
      
      versioning = data.aws_s3_bucket.app_data.versioning[0].enabled
      
      encryption = {
        enabled = length(data.aws_s3_bucket.app_data.server_side_encryption_configuration) > 0
        algorithm = try(
          data.aws_s3_bucket.app_data.server_side_encryption_configuration[0].rule[0].apply_server_side_encryption_by_default[0].sse_algorithm,
          "none"
        )
      }
      
      logging = {
        enabled = length(data.aws_s3_bucket.app_data.logging) > 0
        target_bucket = try(data.aws_s3_bucket.app_data.logging[0].target_bucket, null)
      }
    }
    
    objects = {
      config_files = data.aws_s3_objects.app_configs.keys
      total_configs = length(data.aws_s3_objects.app_configs.keys)
    }
    
    policy = try(jsondecode(data.aws_s3_bucket_policy.app_data.policy), null)
  }
}

output "s3_inventory" {
  description = "S3 bucket inventory"
  value = local.s3_analysis
}
```

## Cross-Account Data Sources

### Cross-Account Resource Access

```hcl
# Cross-account provider
provider "aws" {
  alias  = "shared_services"
  region = var.region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/CrossAccountReadRole"
  }
}

# Shared VPC from another account
data "aws_vpc" "shared" {
  provider = aws.shared_services
  
  tags = {
    Name = "shared-services-vpc"
  }
}

# Shared subnets
data "aws_subnets" "shared_private" {
  provider = aws.shared_services
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  
  tags = {
    Type = "private"
    Shared = "true"
  }
}

# Cross-account AMI
data "aws_ami" "shared_golden" {
  provider    = aws.shared_services
  most_recent = true
  owners      = [var.shared_services_account_id]
  
  filter {
    name   = "tag:Type"
    values = ["golden-image"]
  }
  
  filter {
    name   = "tag:Application"
    values = ["web-server"]
  }
}

output "cross_account_resources" {
  description = "Cross-account resource information"
  value = {
    shared_vpc = {
      id         = data.aws_vpc.shared.id
      cidr_block = data.aws_vpc.shared.cidr_block
      account_id = var.shared_services_account_id
    }
    
    shared_subnets = {
      ids   = data.aws_subnets.shared_private.ids
      count = length(data.aws_subnets.shared_private.ids)
    }
    
    golden_ami = {
      id           = data.aws_ami.shared_golden.id
      name         = data.aws_ami.shared_golden.name
      creation_date = data.aws_ami.shared_golden.creation_date
    }
  }
}
```

## Data Source Performance Optimization

### Efficient Data Source Usage

```hcl
# Cache expensive data source calls
locals {
  # Pre-fetch commonly used data
  current_region = data.aws_region.current.name
  current_account = data.aws_caller_identity.current.account_id
  available_azs = data.aws_availability_zones.available.names
  
  # Compute derived values once
  az_count = length(local.available_azs)
  region_prefix = substr(local.current_region, 0, 2)
}

# Reuse cached values
resource "aws_subnet" "public" {
  count = local.az_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = local.available_azs[count.index]
  
  tags = {
    Name = "${var.project_name}-public-${local.region_prefix}-${count.index + 1}"
  }
}
```

### Conditional Data Source Loading

```hcl
# Load data sources only when needed
data "aws_db_instance" "main" {
  count = var.use_existing_database ? 1 : 0
  
  db_instance_identifier = var.existing_db_identifier
}

data "aws_elasticache_cluster" "main" {
  count = var.use_existing_cache ? 1 : 0
  
  cluster_id = var.existing_cache_cluster_id
}

# Use conditional data
locals {
  database_endpoint = var.use_existing_database ? data.aws_db_instance.main[0].endpoint : aws_db_instance.new[0].endpoint
  cache_endpoint = var.use_existing_cache ? data.aws_elasticache_cluster.main[0].cache_nodes[0].address : aws_elasticache_cluster.new[0].cache_nodes[0].address
}
```

## Error Handling and Validation

### Data Source Validation

```hcl
# Validate data source results
locals {
  # Ensure required resources exist
  vpc_validation = data.aws_vpc.main.id != "" ? null : file("ERROR: VPC not found")
  
  # Validate subnet availability
  subnet_validation = length(data.aws_subnets.public.ids) >= 2 ? null : file("ERROR: Insufficient public subnets")
  
  # Validate AMI availability
  ami_validation = data.aws_ami.ubuntu.id != "" ? null : file("ERROR: Ubuntu AMI not found")
  
  # Cross-validation
  subnet_vpc_validation = alltrue([
    for subnet_id in data.aws_subnets.public.ids :
    contains([data.aws_vpc.main.id], data.aws_subnet.public_details[subnet_id].vpc_id)
  ]) ? null : file("ERROR: Subnets not in expected VPC")
}
```

### Safe Data Source Access

```hcl
# Use try() for safe access
locals {
  # Safe access to potentially missing resources
  database_config = try({
    endpoint = data.aws_db_instance.main.endpoint
    port     = data.aws_db_instance.main.port
    engine   = data.aws_db_instance.main.engine
  }, {
    endpoint = "not_found"
    port     = 0
    engine   = "unknown"
  })
  
  # Safe list access
  first_subnet_id = try(data.aws_subnets.public.ids[0], "")
  
  # Safe tag access
  environment_tag = try(data.aws_vpc.main.tags.Environment, "unknown")
}
```

## Best Practices

### 1. Data Source Organization

```hcl
# Group related data sources
# Network data sources
data "aws_vpc" "main" { }
data "aws_subnets" "public" { }
data "aws_subnets" "private" { }

# Compute data sources  
data "aws_ami" "ubuntu" { }
data "aws_instances" "web" { }

# Security data sources
data "aws_security_groups" "vpc_sgs" { }
```

### 2. Efficient Filtering

```hcl
# Use specific filters to reduce API calls
data "aws_instances" "web_servers" {
  filter {
    name   = "tag:Role"
    values = ["web"]
  }
  
  filter {
    name   = "tag:Environment"  
    values = [var.environment]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
```

### 3. Documentation

```hcl
# Document data source purpose
data "aws_ami" "ubuntu" {
  # Find latest Ubuntu 22.04 LTS AMI
  # Used for web server instances
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

## Conclusion

AWS data sources enable:
- **Resource Discovery**: Find existing AWS resources
- **Dynamic Configuration**: Adapt to current AWS environment  
- **Cross-Account Access**: Access resources in other accounts
- **Infrastructure Analysis**: Understand current state

Key takeaways:
- Use specific filters to optimize performance
- Cache expensive data source calls
- Validate data source results
- Handle missing resources gracefully
- Organize data sources logically
- Document data source purposes
