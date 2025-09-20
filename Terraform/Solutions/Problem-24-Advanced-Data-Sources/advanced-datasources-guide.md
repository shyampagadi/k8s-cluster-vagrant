# Advanced Data Sources - Comprehensive Guide

## Overview
This guide covers advanced Terraform data source concepts including complex queries, filtering, external data sources, and performance optimization strategies.

## Advanced Data Source Patterns

### Complex AWS Data Sources
```hcl
# Advanced AMI filtering
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
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Advanced VPC data source with complex filtering
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Advanced subnet filtering
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

### External Data Sources
```hcl
# HTTP data source for external APIs
data "http" "external_api" {
  url = "https://api.example.com/data"
  
  request_headers = {
    "Authorization" = "Bearer ${var.api_token}"
    "Content-Type"  = "application/json"
  }
  
  # Optional: Retry configuration
  retry {
    attempts = 3
    min_delay = 1000
    max_delay = 5000
  }
}

# Local file data source
data "local_file" "config" {
  filename = "${path.module}/config/app.conf"
}

# Template file data source
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")
  
  vars = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
  }
}
```

## Data Source Performance Optimization

### Efficient Querying
```hcl
# Optimized data source queries
locals {
  # Pre-compute common values
  vpc_id = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids
  ami_id = data.aws_ami.amazon_linux.id
}

# Use locals to avoid repeated data source calls
resource "aws_instance" "web" {
  count = length(local.subnet_ids)
  
  ami           = local.ami_id
  instance_type = var.instance_type
  subnet_id     = local.subnet_ids[count.index]
  
  tags = {
    Name        = "${var.project_name}-web-${count.index + 1}"
    Environment = var.environment
    VPC         = local.vpc_id
  }
}
```

### Data Source Caching
```hcl
# Cached data source configuration
data "aws_availability_zones" "available" {
  state = "available"
  
  # Cache the result for the duration of the Terraform run
  lifecycle {
    ignore_changes = [names]
  }
}

# Use cached data source results
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}
```

## Advanced Filtering and Querying

### Complex Filter Combinations
```hcl
# Complex security group filtering
data "aws_security_groups" "web_sgs" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["web"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "group-name"
    values = ["*web*"]
  }
}

# Advanced RDS instance filtering
data "aws_db_instances" "production" {
  filter {
    name   = "db-instance-status"
    values = ["available"]
  }
  
  filter {
    name   = "engine"
    values = ["mysql", "postgres"]
  }
  
  filter {
    name   = "tag:Environment"
    values = ["production"]
  }
}
```

### Dynamic Data Source Queries
```hcl
# Dynamic data source based on variables
locals {
  ami_filters = var.environment == "production" ? [
    {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    },
    {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  ] : [
    {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
  ]
}

data "aws_ami" "dynamic" {
  most_recent = true
  owners      = ["amazon"]
  
  dynamic "filter" {
    for_each = local.ami_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}
```

## Data Source Error Handling

### Robust Error Handling
```hcl
# Data source with error handling
data "aws_ami" "robust" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  # Handle cases where no AMI is found
  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "No suitable AMI found for the specified criteria."
    }
  }
}

# Fallback data source
data "aws_ami" "fallback" {
  count       = data.aws_ami.robust.id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

# Use primary or fallback AMI
locals {
  selected_ami = data.aws_ami.robust.id != null ? data.aws_ami.robust.id : data.aws_ami.fallback[0].id
}
```

## Data Source Validation

### Input Validation
```hcl
# Validate data source inputs
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Data source with validation
data "aws_vpc" "validated" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "No VPC found for environment: ${var.environment}"
    }
  }
}
```

## Data Source Monitoring

### Performance Monitoring
```hcl
# Monitor data source performance
resource "aws_cloudwatch_metric_alarm" "data_source_performance" {
  alarm_name          = "terraform-data-source-performance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Terraform"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "Data source query taking too long"
  
  alarm_actions = [aws_sns_topic.terraform_alerts.arn]
}
```

## Data Source Best Practices

### Performance Best Practices
- **Efficient Filtering**: Use specific filters to reduce query time
- **Caching**: Cache frequently used data source results
- **Batch Queries**: Combine related queries when possible
- **Error Handling**: Implement robust error handling
- **Validation**: Validate data source results

### Security Best Practices
- **Access Control**: Implement proper IAM policies
- **Sensitive Data**: Handle sensitive data appropriately
- **Audit Logging**: Enable audit logging for data sources
- **Encryption**: Use encryption for sensitive data sources
- **Validation**: Validate all data source inputs

## Data Source Troubleshooting

### Common Issues
1. **Query Timeouts**: Resolving data source query timeouts
2. **Access Denied**: Resolving access permission issues
3. **No Results**: Handling empty query results
4. **Performance Issues**: Optimizing slow data source queries
5. **Validation Errors**: Resolving data source validation issues

### Troubleshooting Commands
```bash
# Debug data source issues
terraform plan -debug

# Validate data source configuration
terraform validate

# Check data source results
terraform show -json | jq '.values.root_module.resources'

# Test data source queries
terraform console
```

## Conclusion

Advanced data sources enable sophisticated infrastructure queries and external integrations. By implementing efficient querying patterns, robust error handling, and performance optimization strategies, you can build reliable and performant Terraform configurations.

Regular review and optimization of data source usage ensures continued effectiveness and adaptation to changing requirements and performance needs.
