# Outputs - Basic and Advanced Usage - Output Definitions

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

# Basic String Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.main.id
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

# Basic Number Outputs
output "instance_count" {
  description = "Number of instances created"
  value       = length(aws_instance.web)
}

output "subnet_count" {
  description = "Number of subnets created"
  value       = length(aws_subnet.public) + length(aws_subnet.private)
}

output "total_cost" {
  description = "Estimated monthly cost"
  value       = local.total_cost
}

output "backup_retention_days" {
  description = "Backup retention period in days"
  value       = local.backup_retention
}

# Basic Boolean Outputs
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "encryption_enabled" {
  description = "Whether encryption is enabled"
  value       = var.enable_encryption
}

output "database_created" {
  description = "Whether database was created"
  value       = var.create_database
}

output "versioning_enabled" {
  description = "Whether S3 versioning is enabled"
  value       = var.enable_versioning
}

output "multi_az_enabled" {
  description = "Whether Multi-AZ is enabled for database"
  value       = var.enable_multi_az
}

# Basic List Outputs
output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of instance public IP addresses"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "List of instance private IP addresses"
  value       = aws_instance.web[*].private_ip
}

# Basic Map Outputs
output "environment_tags" {
  description = "Environment tags applied to resources"
  value       = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "Outputs Demo"
  }
}

output "resource_tags" {
  description = "Common tags applied to all resources"
  value       = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "Outputs Demo"
  }
}

# Advanced Output Patterns
output "resource_summary" {
  description = "Summary of all created resources"
  value       = local.resource_summary
}

output "instance_details" {
  description = "Details of all instances"
  value       = local.instance_details
}

output "subnet_details" {
  description = "Details of all subnets"
  value       = local.subnet_details
}

# Conditional Outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

output "database_port" {
  description = "Database port"
  value       = var.create_database ? aws_db_instance.main[0].port : null
}

output "database_arn" {
  description = "Database ARN"
  value       = var.create_database ? aws_db_instance.main[0].arn : null
}

output "monitoring_dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}" : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].arn : null
}

# Sensitive Outputs
output "database_password" {
  description = "Database password"
  value       = var.database_password
  sensitive   = true
}

output "database_credentials" {
  description = "Database credentials"
  value = var.create_database ? {
    username = var.database_username
    password = var.database_password
    endpoint = aws_db_instance.main[0].endpoint
    port     = aws_db_instance.main[0].port
  } : null
  sensitive = true
}

# Formatted Outputs
output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = format("""
  🚀 Deployment Complete!
  
  📋 Project: %s
  🌍 Environment: %s
  🏗️  VPC: %s
  🖥️  Instances: %d
  🗄️  Database: %s
  📊 Monitoring: %s
  🔒 Encryption: %s
  
  🌐 Access URLs:
  - Web App: http://%s
  - Health Check: http://%s/health
  
  📝 Next Steps:
  1. Verify all resources are running
  2. Test application functionality
  3. Configure monitoring alerts
  4. Set up backup procedures
  """, 
  var.project_name,
  var.environment,
  aws_vpc.main.id,
  length(aws_instance.web),
  var.create_database ? "✅ Created" : "❌ Not Created",
  var.enable_monitoring ? "✅ Enabled" : "❌ Disabled",
  var.enable_encryption ? "✅ Enabled" : "❌ Disabled",
  aws_instance.web[0].public_ip,
  aws_instance.web[0].public_ip
  )
}

output "infrastructure_summary" {
  description = "Structured infrastructure summary"
  value = {
    project = {
      name = var.project_name
      environment = var.environment
      region = var.aws_region
    }
    networking = {
      vpc_id = aws_vpc.main.id
      vpc_cidr = aws_vpc.main.cidr_block
      public_subnets = aws_subnet.public[*].id
      private_subnets = aws_subnet.private[*].id
    }
    compute = {
      instance_count = length(aws_instance.web)
      instance_ids = aws_instance.web[*].id
      instance_types = aws_instance.web[*].instance_type
    }
    storage = {
      bucket_name = aws_s3_bucket.main.id
      bucket_arn = aws_s3_bucket.main.arn
    }
    database = {
      created = var.create_database
      endpoint = var.create_database ? aws_db_instance.main[0].endpoint : null
      port = var.create_database ? aws_db_instance.main[0].port : null
    }
  }
}

# Data Source Outputs
output "ubuntu_ami_id" {
  description = "ID of the Ubuntu AMI"
  value       = data.aws_ami.ubuntu.id
}

output "ubuntu_ami_name" {
  description = "Name of the Ubuntu AMI"
  value       = data.aws_ami.ubuntu.name
}

output "available_availability_zones" {
  description = "List of available availability zones"
  value       = data.aws_availability_zones.available.names
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database ? aws_security_group.database[0].id : null
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# S3 Object Outputs
output "s3_object_key" {
  description = "Key of the S3 object"
  value       = aws_s3_object.config.key
}

output "s3_object_etag" {
  description = "ETag of the S3 object"
  value       = aws_s3_object.config.etag
}

# Cost and Performance Outputs
output "cost_breakdown" {
  description = "Cost breakdown by resource type"
  value = {
    instances = length(aws_instance.web) * var.hourly_rate * 24 * 30
    database = var.create_database ? 50.0 : 0.0  # Estimated monthly cost
    storage = 5.0  # Estimated monthly cost
    total = local.total_cost + (var.create_database ? 50.0 : 0.0) + 5.0
  }
}

output "performance_metrics" {
  description = "Performance metrics and recommendations"
  value = {
    instance_count = length(aws_instance.web)
    monitoring_enabled = var.enable_monitoring
    encryption_enabled = var.enable_encryption
    backup_enabled = var.create_database
    recommendations = [
      "Enable CloudWatch alarms for monitoring",
      "Set up automated backups",
      "Implement log rotation",
      "Configure auto-scaling if needed"
    ]
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Outputs Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Resources Created:
  - VPC: %s
  - Subnets: %d public, %d private
  - Instances: %d
  - Database: %s
  - S3 Bucket: %s
  - Monitoring: %s
  
  Output Types Demonstrated:
  - String Outputs: %d
  - Number Outputs: %d
  - Boolean Outputs: %d
  - List Outputs: %d
  - Map Outputs: %d
  - Conditional Outputs: %d
  - Sensitive Outputs: %d
  - Formatted Outputs: %d
  
  Next Steps:
  1. Test output values
  2. Verify conditional outputs
  3. Check sensitive output handling
  4. Test formatted outputs
  5. Validate output dependencies
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  aws_vpc.main.id,
  length(aws_subnet.public),
  length(aws_subnet.private),
  length(aws_instance.web),
  var.create_database ? "Created" : "Not Created",
  aws_s3_bucket.main.id,
  var.enable_monitoring ? "Enabled" : "Disabled",
  6,  # String outputs count
  4,  # Number outputs count
  5,  # Boolean outputs count
  6,  # List outputs count
  2,  # Map outputs count
  6,  # Conditional outputs count
  2,  # Sensitive outputs count
  2   # Formatted outputs count
  )
}
