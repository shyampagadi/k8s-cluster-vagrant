# Loops and Iteration - Count and For Each - Output Definitions

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

# Count Examples
output "instance_count" {
  description = "Number of instances created using count"
  value       = local.instance_count
}

output "subnet_count" {
  description = "Number of subnets created using count"
  value       = local.subnet_count
}

output "web_instance_ids" {
  description = "IDs of web instances created using count"
  value       = aws_instance.web[*].id
}

output "web_instance_public_ips" {
  description = "Public IP addresses of web instances created using count"
  value       = aws_instance.web[*].public_ip
}

output "web_instance_private_ips" {
  description = "Private IP addresses of web instances created using count"
  value       = aws_instance.web[*].private_ip
}

output "public_subnet_ids" {
  description = "IDs of public subnets created using count"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets created using count"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets created using count"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets created using count"
  value       = aws_subnet.private[*].cidr_block
}

# For Each Examples
output "app_instance_ids" {
  description = "IDs of app instances created using for_each"
  value       = values(aws_instance.app)[*].id
}

output "app_instance_details" {
  description = "Details of app instances created using for_each"
  value = {
    for name, instance in aws_instance.app : name => {
      id = instance.id
      public_ip = instance.public_ip
      private_ip = instance.private_ip
      instance_type = instance.instance_type
    }
  }
}

output "security_group_ids" {
  description = "IDs of security groups created using for_each"
  value       = values(aws_security_group.web)[*].id
}

output "security_group_details" {
  description = "Details of security groups created using for_each"
  value = {
    for name, sg in aws_security_group.web : name => {
      id = sg.id
      name = sg.name
      vpc_id = sg.vpc_id
    }
  }
}

output "s3_bucket_ids" {
  description = "IDs of S3 buckets created using for_each"
  value       = values(aws_s3_bucket.main)[*].id
}

output "s3_bucket_details" {
  description = "Details of S3 buckets created using for_each"
  value = {
    for name, bucket in aws_s3_bucket.main : name => {
      id = bucket.id
      arn = bucket.arn
      bucket_name = bucket.bucket
    }
  }
}

output "cloudwatch_log_group_names" {
  description = "Names of CloudWatch log groups created using for_each"
  value       = values(aws_cloudwatch_log_group.main)[*].name
}

output "cloudwatch_log_group_details" {
  description = "Details of CloudWatch log groups created using for_each"
  value = {
    for name, lg in aws_cloudwatch_log_group.main : name => {
      name = lg.name
      arn = lg.arn
      retention_in_days = lg.retention_in_days
    }
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

# Database Information
output "database_instance_id" {
  description = "ID of the database instance created using count"
  value       = var.create_database ? aws_db_instance.main[0].id : null
}

output "database_instance_endpoint" {
  description = "Endpoint of the database instance created using count"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

# Loop Usage Examples
output "count_usage_examples" {
  description = "Examples of count usage patterns"
  value = {
    basic_count = "count = var.instance_count"
    conditional_count = "count = var.create_instances ? var.instance_count : 0"
    environment_count = "count = var.environment == 'production' ? 3 : 1"
    splat_expressions = "aws_instance.web[*].id"
  }
}

output "for_each_usage_examples" {
  description = "Examples of for_each usage patterns"
  value = {
    map_for_each = "for_each = var.server_configs"
    set_for_each = "for_each = toset(var.security_group_names)"
    filtered_for_each = "for_each = { for name, config in var.server_configs : name => config if config.environment == 'production' }"
    each_references = "each.key, each.value"
  }
}

output "dynamic_blocks_examples" {
  description = "Examples of dynamic blocks with iteration"
  value = {
    security_group_rules = "dynamic 'ingress' { for_each = var.ingress_rules; content { ... } }"
    ebs_volumes = "dynamic 'ebs_block_device' { for_each = each.value.ebs_volumes; content { ... } }"
  }
}

# Performance Considerations
output "performance_considerations" {
  description = "Performance considerations for loops"
  value = {
    count_optimization = "Use locals for computed count values"
    for_each_optimization = "Use locals for data transformation"
    resource_naming = "Use consistent naming patterns"
    error_handling = "Validate iteration data"
  }
}

# Count vs For Each Comparison
output "count_vs_for_each_comparison" {
  description = "Comparison between count and for_each"
  value = {
    count_use_cases = [
      "Simple numeric iteration",
      "List-based iteration",
      "Conditional resource creation"
    ]
    for_each_use_cases = [
      "Map-based iteration",
      "Set-based iteration",
      "Complex data structures"
    ]
    count_benefits = [
      "Simple syntax",
      "Easy to understand",
      "Good for numeric iteration"
    ]
    for_each_benefits = [
      "More flexible",
      "Better for complex data",
      "Easier to manage individual resources"
    ]
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
    web_instance_count = length(aws_instance.web)
    app_instance_count = length(aws_instance.app)
    security_group_count = length(aws_security_group.web)
    bucket_count = length(aws_s3_bucket.main)
    log_group_count = length(aws_cloudwatch_log_group.main)
    database_created = var.create_database
    
    loop_types_used = {
      count_resources = 4
      for_each_resources = 5
      dynamic_blocks = 3
    }
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Loops and Iteration Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Loop Types Used:
  - Count Resources: %d
  - For Each Resources: %d
  - Dynamic Blocks: %d
  
  Resources Created:
  - VPC: %s
  - Subnets: %d public, %d private
  - Web Instances (count): %d
  - App Instances (for_each): %d
  - Security Groups (for_each): %d
  - S3 Buckets (for_each): %d
  - Log Groups (for_each): %d
  - Database: %s
  
  Count Examples:
  - Basic Count: count = var.instance_count
  - Conditional Count: count = var.create_instances ? var.instance_count : 0
  - Splat Expressions: aws_instance.web[*].id
  
  For Each Examples:
  - Map For Each: for_each = var.server_configs
  - Set For Each: for_each = toset(var.security_group_names)
  - Each References: each.key, each.value
  
  Dynamic Blocks Examples:
  - Security Group Rules: dynamic 'ingress' { for_each = var.ingress_rules }
  - EBS Volumes: dynamic 'ebs_block_device' { for_each = each.value.ebs_volumes }
  
  Next Steps:
  1. Test count-based resource creation
  2. Test for_each-based resource creation
  3. Verify dynamic blocks functionality
  4. Test conditional loop logic
  5. Validate splat expressions
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  4,  # Count resources count
  5,  # For each resources count
  3,  # Dynamic blocks count
  aws_vpc.main.id,
  length(aws_subnet.public),
  length(aws_subnet.private),
  length(aws_instance.web),
  length(aws_instance.app),
  length(aws_security_group.web),
  length(aws_s3_bucket.main),
  length(aws_cloudwatch_log_group.main),
  var.create_database ? "Created" : "Not Created"
  )
}
