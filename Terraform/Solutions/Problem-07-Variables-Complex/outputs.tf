# Variables - Complex Types and Validation - Output Definitions

# Project Information
output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "resource_prefix" {
  description = "Resource prefix used for naming"
  value       = local.resource_prefix
}

# Complex Variable Examples
output "list_variables" {
  description = "List variables used in configuration"
  value = {
    availability_zones = var.availability_zones
    port_numbers = var.port_numbers
    unique_tags = var.unique_tags
    unique_ports = var.unique_ports
  }
}

output "map_variables" {
  description = "Map variables used in configuration"
  value = {
    environment_tags = var.environment_tags
    server_configs = var.server_configs
  }
}

output "tuple_variables" {
  description = "Tuple variables used in configuration"
  value = {
    server_info = var.server_info
    database_info = var.database_info
  }
}

output "object_variables" {
  description = "Object variables used in configuration"
  value = {
    database_config = var.database_config
  }
}

output "complex_list_variables" {
  description = "Complex list variables used in configuration"
  value = {
    ingress_ports = var.ingress_ports
    egress_rules = var.egress_rules
  }
}

# Local Values Demonstrating Complex Variable Usage
output "local_values" {
  description = "Local values demonstrating complex variable usage"
  value = {
    resource_prefix = local.resource_prefix
    instance_names = local.instance_names
    subnet_cidrs = local.subnet_cidrs
    server_configs = local.server_configs
    production_configs = local.production_configs
    database_config = local.database_config
    server_info = local.server_info
    enable_monitoring = local.enable_monitoring
    enable_encryption = local.enable_encryption
    total_cost = local.total_cost
    backup_retention = local.backup_retention
  }
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Information
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# Security Group Information
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# EC2 Instance Information
output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = values(aws_instance.web)[*].id
}

output "instance_arns" {
  description = "ARNs of the EC2 instances"
  value       = values(aws_instance.web)[*].arn
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = values(aws_instance.web)[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = values(aws_instance.web)[*].private_ip
}

# Database Information
output "database_instance_id" {
  description = "ID of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].id : null
}

output "database_instance_endpoint" {
  description = "Endpoint of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

# S3 Bucket Information
output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

# CloudWatch Log Group Information
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = local.enable_monitoring ? aws_cloudwatch_log_group.main[0].name : null
}

# Complex Variable Usage Patterns
output "variable_usage_patterns" {
  description = "Examples of complex variable usage patterns"
  value = {
    list_usage = {
      count_usage = "count = length(var.availability_zones)"
      for_each_usage = "for_each = var.port_numbers"
      index_usage = "var.availability_zones[count.index]"
    }
    map_usage = {
      for_each_usage = "for_each = var.server_configs"
      key_usage = "each.key"
      value_usage = "each.value.instance_type"
      merge_usage = "merge(var.environment_tags, {Name = each.key})"
    }
    object_usage = {
      attribute_access = "var.database_config.engine"
      nested_access = "var.database_config.backup_retention_period"
    }
    tuple_usage = {
      index_access = "var.server_info[0]"
      element_access = "var.server_info[1]"
    }
  }
}

# Variable Validation Examples
output "variable_validation_examples" {
  description = "Examples of complex variable validation"
  value = {
    list_validation = {
      availability_zones = "length(var.availability_zones) >= 2"
      port_numbers = "alltrue([for port in var.port_numbers : port > 0 && port <= 65535])"
    }
    map_validation = {
      environment_tags = "contains(keys(var.environment_tags), 'Environment')"
      server_configs = "alltrue([for name, config in var.server_configs : can(regex('^[a-z0-9.]+$', config.instance_type))])"
    }
    object_validation = {
      database_config = "var.database_config.allocated_storage >= 20"
    }
    complex_validation = {
      ingress_ports = "alltrue([for rule in var.ingress_ports : rule.port > 0 && rule.port <= 65535])"
    }
  }
}

# Variable Precedence Examples
output "variable_precedence_examples" {
  description = "Examples of complex variable precedence"
  value = {
    command_line = "terraform apply -var='availability_zones=[\"us-east-1a\",\"us-east-1b\"]'"
    environment_variable = "export TF_VAR_availability_zones='[\"us-west-2a\",\"us-west-2b\"]'"
    variable_file = "terraform.tfvars: availability_zones = [\"us-central1-a\",\"us-central1-b\"]"
    default_value = "variable definition: default = [\"us-west-2a\", \"us-west-2b\", \"us-west-2c\"]"
    current_value = var.availability_zones
  }
}

# Performance Considerations
output "performance_considerations" {
  description = "Performance considerations for complex variables"
  value = {
    local_values = "Use locals for computed values to avoid repeated calculations"
    data_transformation = "Transform data in locals for better performance"
    filtering = "Use for expressions for efficient filtering and mapping"
    large_datasets = "Consider memory usage for large complex variables"
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    project_name = var.project_name
    environment = var.environment
    resource_prefix = local.resource_prefix
    
    vpc_id = aws_vpc.main.id
    subnet_count = length(aws_subnet.public) + length(aws_subnet.private)
    instance_count = length(aws_instance.web)
    bucket_name = aws_s3_bucket.main.id
    database_created = var.create_database
    monitoring_enabled = local.enable_monitoring
    encryption_enabled = local.enable_encryption
    
    complex_variables_used = {
      list_variables = 4
      map_variables = 2
      tuple_variables = 2
      object_variables = 1
      complex_list_variables = 2
    }
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Complex Variables Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Complex Variables Used:
  - List Variables: %d
  - Map Variables: %d
  - Tuple Variables: %d
  - Object Variables: %d
  - Complex List Variables: %d
  
  Resources Created:
  - VPC: %s
  - Subnets: %d public, %d private
  - Instances: %d
  - Database: %s
  - S3 Bucket: %s
  - Monitoring: %s
  
  Complex Variable Usage Patterns:
  - List Usage: count = length(var.availability_zones)
  - Map Usage: for_each = var.server_configs
  - Object Usage: var.database_config.engine
  - Tuple Usage: var.server_info[0]
  - Complex Validation: alltrue([for port in var.port_numbers : port > 0])
  
  Next Steps:
  1. Test complex variable validation
  2. Verify variable precedence
  3. Test performance with large datasets
  4. Validate complex data structures
  5. Test error handling
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  4,  # List variables count
  2,  # Map variables count
  2,  # Tuple variables count
  1,  # Object variables count
  2,  # Complex list variables count
  aws_vpc.main.id,
  length(aws_subnet.public),
  length(aws_subnet.private),
  length(aws_instance.web),
  var.create_database ? "Created" : "Not Created",
  aws_s3_bucket.main.id,
  local.enable_monitoring ? "Enabled" : "Disabled"
  )
}
