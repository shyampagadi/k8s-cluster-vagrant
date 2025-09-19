# Data Sources - AWS and External - Output Definitions

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

# AWS Data Source Outputs
output "ubuntu_ami_id" {
  description = "ID of the Ubuntu AMI from data source"
  value       = data.aws_ami.ubuntu.id
}

output "ubuntu_ami_name" {
  description = "Name of the Ubuntu AMI from data source"
  value       = data.aws_ami.ubuntu.name
}

output "ubuntu_ami_architecture" {
  description = "Architecture of the Ubuntu AMI from data source"
  value       = data.aws_ami.ubuntu.architecture
}

output "available_availability_zones" {
  description = "List of available availability zones from data source"
  value       = data.aws_availability_zones.available.names
}

output "aws_account_id" {
  description = "AWS account ID from data source"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_user_id" {
  description = "AWS user ID from data source"
  value       = data.aws_caller_identity.current.user_id
}

output "aws_arn" {
  description = "AWS ARN from data source"
  value       = data.aws_caller_identity.current.arn
}

output "aws_region_name" {
  description = "AWS region name from data source"
  value       = data.aws_region.current.name
}

output "aws_region_endpoint" {
  description = "AWS region endpoint from data source"
  value       = data.aws_region.current.endpoint
}

output "default_vpc_id" {
  description = "ID of the default VPC from data source"
  value       = data.aws_vpc.default.id
}

output "default_vpc_cidr_block" {
  description = "CIDR block of the default VPC from data source"
  value       = data.aws_vpc.default.cidr_block
}

output "default_subnet_id" {
  description = "ID of the default subnet from data source"
  value       = data.aws_subnet.default.id
}

output "default_subnet_cidr_block" {
  description = "CIDR block of the default subnet from data source"
  value       = data.aws_subnet.default.cidr_block
}

# External Data Source Outputs
output "external_api_status" {
  description = "Status of external API call"
  value       = data.http.external_api.status_code
}

output "external_api_body" {
  description = "Body of external API response"
  value       = data.http.external_api.body
}

output "external_service_status" {
  description = "Status of external service call"
  value       = data.http.external_service.status_code
}

output "config_file_content" {
  description = "Content of local config file"
  value       = data.local_file.config_file.content
}

output "json_file_content" {
  description = "Content of local JSON file"
  value       = data.local_file.json_file.content
}

output "external_command_result" {
  description = "Result of external command execution"
  value       = data.external.external_command.result
}

# Processed External Data
output "external_data_processed" {
  description = "Processed external data from API"
  value       = local.external_data
}

output "config_data_processed" {
  description = "Processed configuration data from file"
  value       = local.config_data
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

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

# CloudWatch Log Group Information
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].name : null
}

# Data Source Usage Examples
output "data_source_usage_examples" {
  description = "Examples of data source usage patterns"
  value = {
    aws_data_sources = {
      ami_discovery = "data.aws_ami.ubuntu.id"
      az_discovery = "data.aws_availability_zones.available.names"
      account_info = "data.aws_caller_identity.current.account_id"
      region_info = "data.aws_region.current.name"
    }
    external_data_sources = {
      http_api = "data.http.external_api.body"
      local_file = "data.local_file.config_file.content"
      external_command = "data.external.external_command.result"
    }
    local_processing = {
      ami_id = "local.ami_id"
      vpc_id = "local.vpc_id"
      external_data = "local.external_data"
    }
  }
}

# Data Source Filtering Examples
output "data_source_filtering_examples" {
  description = "Examples of data source filtering"
  value = {
    ami_filtering = {
      most_recent = true
      owners = ["099720109477"]
      filters = [
        "name: ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*",
        "virtualization-type: hvm",
        "architecture: x86_64"
      ]
    }
    az_filtering = {
      state = "available"
    }
    vpc_filtering = {
      default = true
    }
  }
}

# Data Source Dependencies
output "data_source_dependencies" {
  description = "Data source dependency information"
  value = {
    implicit_dependencies = [
      "data.aws_subnet.default depends on data.aws_vpc.default",
      "aws_instance.web depends on data.aws_ami.ubuntu"
    ]
    explicit_dependencies = [
      "aws_db_instance.main depends_on aws_db_subnet_group.main"
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
    instance_count = length(aws_instance.web)
    bucket_name = aws_s3_bucket.main.id
    database_created = var.create_database
    monitoring_enabled = var.enable_monitoring
    
    data_sources_used = {
      aws_data_sources = 6
      external_data_sources = 4
      local_processing = 3
    }
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information and next steps"
  value = format("""
  Data Sources Demo Deployment Complete!
  
  Project: %s
  Environment: %s
  Resource Prefix: %s
  
  Data Sources Used:
  - AWS Data Sources: %d
  - External Data Sources: %d
  - Local Processing: %d
  
  Resources Created:
  - VPC: %s
  - Subnets: %d public, %d private
  - Instances: %d
  - Database: %s
  - S3 Bucket: %s
  - Monitoring: %s
  
  Data Source Examples:
  - AMI Discovery: data.aws_ami.ubuntu.id
  - AZ Discovery: data.aws_availability_zones.available.names
  - Account Info: data.aws_caller_identity.current.account_id
  - External API: data.http.external_api.body
  - Local File: data.local_file.config_file.content
  
  Next Steps:
  1. Test data source queries
  2. Verify external data integration
  3. Check data source filtering
  4. Test data source dependencies
  5. Validate data processing
  """, 
  var.project_name,
  var.environment,
  local.resource_prefix,
  6,  # AWS data sources count
  4,  # External data sources count
  3,  # Local processing count
  aws_vpc.main.id,
  length(aws_subnet.public),
  length(aws_subnet.private),
  length(aws_instance.web),
  var.create_database ? "Created" : "Not Created",
  aws_s3_bucket.main.id,
  var.enable_monitoring ? "Enabled" : "Disabled"
  )
}
