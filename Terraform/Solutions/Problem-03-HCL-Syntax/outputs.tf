# HCL Syntax Deep Dive - Output Definitions

# Basic Outputs
output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region used for resources"
  value       = var.aws_region
}

# Local Value Outputs
output "formatted_name" {
  description = "Formatted project name with suffix"
  value       = local.formatted_name
}

output "upper_name" {
  description = "Project name in uppercase"
  value       = local.upper_name
}

output "lower_name" {
  description = "Project name in lowercase"
  value       = local.lower_name
}

output "clean_name" {
  description = "Project name with underscores replaced by hyphens"
  value       = local.clean_name
}

# Numeric Expression Outputs
output "total_instances" {
  description = "Total number of instances (web + db)"
  value       = local.total_instances
}

output "half_instances" {
  description = "Half of the total instance count"
  value       = local.half_instances
}

output "remaining_count" {
  description = "Remaining count after modulo operation"
  value       = local.remaining_count
}

# Boolean Expression Outputs
output "is_production" {
  description = "Whether environment is production"
  value       = local.is_production
}

output "has_enough_instances" {
  description = "Whether there are enough instances"
  value       = local.has_enough_instances
}

output "enable_monitoring" {
  description = "Whether monitoring is enabled"
  value       = local.enable_monitoring
}

# Complex Expression Outputs
output "instance_names" {
  description = "List of generated instance names"
  value       = local.instance_names
}

output "instance_type" {
  description = "Instance type based on environment"
  value       = local.instance_type
}

output "monitoring_config" {
  description = "Monitoring configuration object"
  value       = local.monitoring_config
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the main VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the main VPC"
  value       = aws_vpc.main.arn
}

# Subnet Outputs
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

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.main.id
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "web_security_group_arn" {
  description = "ARN of the web security group"
  value       = aws_security_group.web.arn
}

# EC2 Instance Outputs
output "web_instance_ids" {
  description = "IDs of the web instances"
  value       = aws_instance.web[*].id
}

output "web_instance_arns" {
  description = "ARNs of the web instances"
  value       = aws_instance.web[*].arn
}

output "web_instance_public_ips" {
  description = "Public IP addresses of the web instances"
  value       = aws_instance.web[*].public_ip
}

output "web_instance_private_ips" {
  description = "Private IP addresses of the web instances"
  value       = aws_instance.web[*].private_ip
}

output "web_instance_public_dns" {
  description = "Public DNS names of the web instances"
  value       = aws_instance.web[*].public_dns
}

output "web_instance_private_dns" {
  description = "Private DNS names of the web instances"
  value       = aws_instance.web[*].private_dns
}

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
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

# Database Outputs (Conditional)
output "database_instance_id" {
  description = "ID of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].id : null
}

output "database_instance_arn" {
  description = "ARN of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].arn : null
}

output "database_instance_endpoint" {
  description = "Endpoint of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

output "database_instance_port" {
  description = "Port of the database instance"
  value       = var.create_database ? aws_db_instance.main[0].port : null
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.create_database ? aws_db_subnet_group.main[0].name : null
}

# CloudWatch Log Group Outputs (Conditional)
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.monitoring_enabled ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.monitoring_enabled ? aws_cloudwatch_log_group.main[0].arn : null
}

# Random Value Outputs
output "random_suffix" {
  description = "Random suffix used for unique naming"
  value       = random_id.suffix.hex
}

output "random_password" {
  description = "Random password generated for database"
  value       = random_string.password.result
  sensitive   = true
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

# Complex Outputs
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    project_name = var.project_name
    environment = var.environment
    vpc_id = aws_vpc.main.id
    subnet_count = length(aws_subnet.public)
    instance_count = length(aws_instance.web)
    bucket_name = aws_s3_bucket.main.id
    database_created = var.create_database
    monitoring_enabled = var.monitoring_enabled
  }
}

output "network_summary" {
  description = "Summary of network resources"
  value = {
    vpc_cidr = aws_vpc.main.cidr_block
    public_subnets = {
      for i, subnet in aws_subnet.public : i => {
        id = subnet.id
        cidr = subnet.cidr_block
        az = subnet.availability_zone
      }
    }
    private_subnets = {
      for i, subnet in aws_subnet.private : i => {
        id = subnet.id
        cidr = subnet.cidr_block
        az = subnet.availability_zone
      }
    }
  }
}

output "instance_summary" {
  description = "Summary of EC2 instances"
  value = {
    for i, instance in aws_instance.web : i => {
      id = instance.id
      public_ip = instance.public_ip
      private_ip = instance.private_ip
      instance_type = instance.instance_type
      availability_zone = instance.availability_zone
    }
  }
}

# Conditional Outputs
output "production_resources" {
  description = "Resources created only in production"
  value = var.environment == "production" ? {
    database_endpoint = var.create_database ? aws_db_instance.main[0].endpoint : null
    monitoring_log_group = var.monitoring_enabled ? aws_cloudwatch_log_group.main[0].name : null
  } : null
}

# Sensitive Outputs
output "database_password" {
  description = "Database password (sensitive)"
  value       = random_string.password.result
  sensitive   = true
}

# Formatted Outputs
output "deployment_info" {
  description = "Formatted deployment information"
  value = format("""
  Deployment Summary:
  - Project: %s
  - Environment: %s
  - Region: %s
  - VPC ID: %s
  - Instance Count: %d
  - Database Created: %t
  - Monitoring Enabled: %t
  """, 
  var.project_name, 
  var.environment, 
  var.aws_region, 
  aws_vpc.main.id, 
  length(aws_instance.web),
  var.create_database,
  var.monitoring_enabled
  )
}
