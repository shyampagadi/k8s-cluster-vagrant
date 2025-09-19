# File Organization and Project Structure - Outputs

# Project Information
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

output "availability_zones" {
  description = "Availability zones used for subnets"
  value       = aws_subnet.public[*].availability_zone
}

# Internet Gateway Information
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Route Table Information
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# Security Group Information
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "web_security_group_arn" {
  description = "ARN of the web security group"
  value       = aws_security_group.web.arn
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database ? aws_security_group.database[0].id : null
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = var.create_database ? aws_security_group.database[0].arn : null
}

# Instance Information
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

output "instance_arns" {
  description = "ARNs of the EC2 instances"
  value       = aws_instance.web[*].arn
}

output "instance_count" {
  description = "Number of instances created"
  value       = length(aws_instance.web)
}

# Database Information
output "database_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

output "database_port" {
  description = "Port of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].port : null
}

output "database_arn" {
  description = "ARN of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].arn : null
}

output "database_identifier" {
  description = "Identifier of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].identifier : null
}

output "database_engine" {
  description = "Engine of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].engine : null
}

output "database_engine_version" {
  description = "Engine version of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].engine_version : null
}

output "database_instance_class" {
  description = "Instance class of the RDS instance"
  value       = var.create_database ? aws_db_instance.main[0].instance_class : null
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

# CloudWatch Log Group Information
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].arn : null
}

# File Organization Information
output "file_organization_pattern" {
  description = "File organization pattern used"
  value       = var.file_organization_pattern
}

output "resource_prefix" {
  description = "Resource naming prefix used"
  value       = local.resource_prefix
}

output "naming_patterns" {
  description = "Naming patterns used for resources"
  value       = local.naming_patterns
}

output "environment_configuration" {
  description = "Environment-specific configuration used"
  value       = local.current_config
}

# Data Source Information
output "ubuntu_ami_id" {
  description = "ID of the Ubuntu AMI used"
  value       = data.aws_ami.ubuntu.id
}

output "ubuntu_ami_name" {
  description = "Name of the Ubuntu AMI used"
  value       = data.aws_ami.ubuntu.name
}

output "available_availability_zones" {
  description = "List of available availability zones"
  value       = data.aws_availability_zones.available.names
}

# Summary Information
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    project_name = var.project_name
    environment = var.environment
    aws_region = var.aws_region
    vpc_id = aws_vpc.main.id
    instance_count = length(aws_instance.web)
    database_created = var.create_database
    s3_bucket_id = aws_s3_bucket.main.id
    file_organization_pattern = var.file_organization_pattern
    resource_prefix = local.resource_prefix
  }
}

# Connection Information
output "ssh_connection_info" {
  description = "SSH connection information for instances"
  value = {
    for i, instance in aws_instance.web : "instance-${i + 1}" => {
      public_ip = instance.public_ip
      private_ip = instance.private_ip
      ssh_command = "ssh -i your-key.pem ec2-user@${instance.public_ip}"
    }
  }
}

output "database_connection_info" {
  description = "Database connection information"
  value = var.create_database ? {
    endpoint = aws_db_instance.main[0].endpoint
    port = aws_db_instance.main[0].port
    database_name = aws_db_instance.main[0].db_name
    username = aws_db_instance.main[0].username
    connection_string = "mysql://${aws_db_instance.main[0].username}:${var.database_password}@${aws_db_instance.main[0].endpoint}:${aws_db_instance.main[0].port}/${aws_db_instance.main[0].db_name}"
  } : null
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    instances = length(aws_instance.web) * 10  # Approximate cost per instance
    database = var.create_database ? 25 : 0    # Approximate cost for database
    storage = 5                                  # Approximate cost for S3 storage
    total = (length(aws_instance.web) * 10) + (var.create_database ? 25 : 0) + 5
  }
}
