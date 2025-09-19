# Resource Lifecycle and State Management - Output Definitions

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

# VPC Information
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

# Internet Gateway Information
output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.main.id
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

# Route Table Information
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
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
  value       = aws_instance.web[*].id
}

output "instance_arns" {
  description = "ARNs of the EC2 instances"
  value       = aws_instance.web[*].arn
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.web[*].private_ip
}

output "instance_public_dns" {
  description = "Public DNS names of the EC2 instances"
  value       = aws_instance.web[*].public_dns
}

output "instance_private_dns" {
  description = "Private DNS names of the EC2 instances"
  value       = aws_instance.web[*].private_dns
}

# Database Information
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

# S3 Bucket Information
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

# S3 Object Information
output "s3_object_key" {
  description = "Key of the S3 object"
  value       = aws_s3_object.config.key
}

output "s3_object_etag" {
  description = "ETag of the S3 object"
  value       = aws_s3_object.config.etag
}

# CloudWatch Log Group Information
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].arn : null
}

# Data Source Information
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

# Random Values
output "random_suffix" {
  description = "Random suffix used for unique naming"
  value       = random_id.suffix.hex
}

output "random_password" {
  description = "Random password generated for database"
  value       = random_string.password.result
  sensitive   = true
}

# Resource Lifecycle Information
output "lifecycle_configuration" {
  description = "Lifecycle configuration summary"
  value = {
    prevent_destroy = var.prevent_destroy
    create_before_destroy = true
    ignore_changes = ["tags.LastModified", "user_data", "password"]
  }
}

# State Management Information
output "state_management_info" {
  description = "State management information"
  value = {
    backend_type = "s3"
    state_locking = "enabled"
    state_encryption = "enabled"
    state_versioning = "enabled"
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
    monitoring_enabled = var.enable_monitoring
  }
}

# Dependency Information
output "dependency_graph" {
  description = "Resource dependency information"
  value = {
    vpc = {
      dependencies = []
      dependents = ["internet_gateway", "subnets", "security_groups"]
    }
    internet_gateway = {
      dependencies = ["vpc"]
      dependents = ["route_table"]
    }
    subnets = {
      dependencies = ["vpc"]
      dependents = ["instances", "database"]
    }
    instances = {
      dependencies = ["subnets", "security_groups"]
      dependents = []
    }
    database = {
      dependencies = ["subnets", "security_groups"]
      dependents = []
    }
  }
}

# Lifecycle Rules Summary
output "lifecycle_rules_summary" {
  description = "Summary of lifecycle rules applied"
  value = {
    create_before_destroy = [
      "aws_vpc.main",
      "aws_internet_gateway.main",
      "aws_subnet.public",
      "aws_subnet.private",
      "aws_route_table.public",
      "aws_route_table.private",
      "aws_security_group.web",
      "aws_security_group.database",
      "aws_instance.web",
      "aws_db_instance.main",
      "aws_db_subnet_group.main",
      "aws_s3_bucket_versioning.main",
      "aws_s3_bucket_server_side_encryption_configuration.main",
      "aws_s3_bucket_public_access_block.main",
      "aws_s3_object.config",
      "aws_cloudwatch_log_group.main",
      "null_resource.example"
    ]
    prevent_destroy = var.prevent_destroy ? [
      "aws_vpc.main",
      "aws_instance.web",
      "aws_db_instance.main",
      "aws_s3_bucket.main"
    ] : []
    ignore_changes = [
      "tags.LastModified",
      "user_data",
      "password"
    ]
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Resource Lifecycle Demo Deployment Complete!
  
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
  
  Lifecycle Configuration:
  - Prevent Destroy: %s
  - Create Before Destroy: Enabled
  - Ignore Changes: tags.LastModified, user_data, password
  
  Next Steps:
  1. Test resource lifecycle operations
  2. Verify state management
  3. Test dependency management
  4. Validate lifecycle rules
  5. Test state operations
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
  var.prevent_destroy ? "Enabled" : "Disabled"
  )
}
