# Variables - Basic Types and Usage - Output Definitions

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

# Variable Usage Examples
output "string_variables" {
  description = "String variables used in configuration"
  value = {
    project_name = var.project_name
    environment = var.environment
    app_name = var.app_name
    aws_region = var.aws_region
    domain_name = var.domain_name
    subdomain = var.subdomain
  }
}

output "number_variables" {
  description = "Number variables used in configuration"
  value = {
    instance_count = var.instance_count
    subnet_count = var.subnet_count
    hourly_rate = var.hourly_rate
    database_port = var.database_port
    database_allocated_storage = var.database_allocated_storage
    log_retention_days = var.log_retention_days
  }
}

output "boolean_variables" {
  description = "Boolean variables used in configuration"
  value = {
    create_instances = var.create_instances
    create_database = var.create_database
    enable_monitoring = var.enable_monitoring
    enable_encryption = var.enable_encryption
    enable_http = var.enable_http
    enable_https = var.enable_https
    enable_ssh = var.enable_ssh
    enable_versioning = var.enable_versioning
    enable_multi_az = var.enable_multi_az
    block_public_access = var.block_public_access
  }
}

# Local Values Demonstrating Variable Usage
output "local_values" {
  description = "Local values demonstrating variable usage"
  value = {
    resource_prefix = local.resource_prefix
    instance_type = local.instance_type
    instance_count = local.instance_count
    bucket_name = local.bucket_name
    dns_name = local.dns_name
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

# Security Group Information
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database ? aws_security_group.database[0].id : null
}

# EC2 Instance Information
output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.web[*].private_ip
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

# Variable Precedence Demonstration
output "variable_precedence_example" {
  description = "Example of variable precedence"
  value = {
    command_line = "terraform apply -var='instance_count=5'"
    environment_variable = "export TF_VAR_instance_count=3"
    variable_file = "terraform.tfvars: instance_count = 2"
    default_value = "variable definition: default = 1"
    current_value = var.instance_count
  }
}

# Variable Validation Examples
output "variable_validation_examples" {
  description = "Examples of variable validation"
  value = {
    string_validation = {
      project_name = "Must contain only lowercase letters, numbers, and hyphens"
      environment = "Must be one of: development, staging, production"
      domain_name = "Must be a valid domain format"
    }
    number_validation = {
      instance_count = "Must be between 1 and 10"
      database_port = "Must be between 1 and 65535"
      database_allocated_storage = "Must be at least 20 GB"
    }
    boolean_validation = {
      create_instances = "Must be true or false"
      enable_monitoring = "Must be true or false"
      enable_encryption = "Must be true or false"
    }
  }
}

# Variable Usage Patterns
output "variable_usage_patterns" {
  description = "Examples of variable usage patterns"
  value = {
    basic_reference = "var.project_name"
    conditional_usage = "var.environment == 'production' ? 't3.large' : 't3.micro'"
    string_interpolation = "${var.project_name}-${var.environment}"
    boolean_logic = "var.enable_monitoring && var.environment == 'production'"
    number_calculation = "var.instance_count * var.hourly_rate"
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
  }
}

# Variable File Organization
output "variable_file_organization" {
  description = "Variable file organization examples"
  value = {
    main_file = "terraform.tfvars"
    example_file = "terraform.tfvars.example"
    environment_files = [
      "production.tfvars",
      "staging.tfvars",
      "development.tfvars"
    ]
    variable_definitions = "variables.tf"
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Variables Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Variables Used:
  - String Variables: %d
  - Number Variables: %d
  - Boolean Variables: %d
  
  Resources Created:
  - VPC: %s
  - Subnets: %d public, %d private
  - Instances: %d
  - Database: %s
  - S3 Bucket: %s
  - Monitoring: %s
  
  Variable Usage Patterns:
  - Basic Reference: var.project_name
  - Conditional Usage: var.environment == 'production' ? 't3.large' : 't3.micro'
  - String Interpolation: ${var.project_name}-${var.environment}
  - Boolean Logic: var.enable_monitoring && var.environment == 'production'
  - Number Calculation: var.instance_count * var.hourly_rate
  
  Next Steps:
  1. Test variable precedence
  2. Validate variable inputs
  3. Test conditional logic
  4. Verify string interpolation
  5. Test boolean expressions
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  6,  # String variables count
  6,  # Number variables count
  11, # Boolean variables count
  aws_vpc.main.id,
  length(aws_subnet.public),
  length(aws_subnet.private),
  length(aws_instance.web),
  var.create_database ? "Created" : "Not Created",
  aws_s3_bucket.main.id,
  local.enable_monitoring ? "Enabled" : "Disabled"
  )
}
