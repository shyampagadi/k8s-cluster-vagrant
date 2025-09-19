# Error Handling and Validation - Outputs

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

# CloudWatch Alarms Information
output "cpu_alarm_names" {
  description = "Names of the CPU utilization alarms"
  value       = aws_cloudwatch_metric_alarm.cpu_utilization[*].alarm_name
}

output "disk_alarm_names" {
  description = "Names of the disk utilization alarms"
  value       = aws_cloudwatch_metric_alarm.disk_utilization[*].alarm_name
}

output "alarm_count" {
  description = "Number of CloudWatch alarms created"
  value       = length(aws_cloudwatch_metric_alarm.cpu_utilization) + length(aws_cloudwatch_metric_alarm.disk_utilization)
}

# Error Handling Information
output "error_handling_enabled" {
  description = "Whether error handling is enabled"
  value       = var.enable_error_handling
}

output "validation_enabled" {
  description = "Whether validation is enabled"
  value       = var.enable_validation
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "error_thresholds" {
  description = "Error thresholds configured"
  value = {
    cpu = var.error_threshold_cpu
    disk = var.error_threshold_disk
    memory = var.error_threshold_memory
  }
}

output "recovery_configuration" {
  description = "Recovery configuration"
  value = {
    auto_recovery = var.enable_auto_recovery
    backup_retention = var.backup_retention_days
    rollback_enabled = var.enable_rollback
  }
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

# Validation Information
output "validation_results" {
  description = "Results of validation checks"
  value = {
    vpc_cidr_valid = can(cidrhost(var.vpc_cidr, 0))
    subnet_count_valid = var.subnet_count >= 1 && var.subnet_count <= 6
    database_engine_valid = contains(["mysql", "postgres", "oracle-ee", "sqlserver-ee"], var.database_engine)
    instance_class_valid = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.database_instance_class))
    password_strength_valid = length(var.database_password) >= 8
  }
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
    error_handling_enabled = var.enable_error_handling
    validation_enabled = var.enable_validation
    monitoring_enabled = var.enable_monitoring
    alarm_count = length(aws_cloudwatch_metric_alarm.cpu_utilization) + length(aws_cloudwatch_metric_alarm.disk_utilization)
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

# Monitoring Information
output "monitoring_endpoints" {
  description = "Monitoring endpoints and information"
  value = {
    cloudwatch_logs = length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].name : null
    cpu_alarms = aws_cloudwatch_metric_alarm.cpu_utilization[*].alarm_name
    disk_alarms = aws_cloudwatch_metric_alarm.disk_utilization[*].alarm_name
    log_retention_days = var.log_retention_days
  }
}

# Error Handling Status
output "error_handling_status" {
  description = "Status of error handling implementation"
  value = {
    validation_enabled = var.enable_validation
    monitoring_enabled = var.enable_monitoring
    auto_recovery_enabled = var.enable_auto_recovery
    rollback_enabled = var.enable_rollback
    backup_retention_days = var.backup_retention_days
    error_thresholds = {
      cpu = var.error_threshold_cpu
      disk = var.error_threshold_disk
      memory = var.error_threshold_memory
    }
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    instances = length(aws_instance.web) * 10  # Approximate cost per instance
    database = var.create_database ? 25 : 0    # Approximate cost for database
    storage = 5                                  # Approximate cost for S3 storage
    monitoring = var.enable_monitoring ? 10 : 0 # Approximate cost for monitoring
    total = (length(aws_instance.web) * 10) + (var.create_database ? 25 : 0) + 5 + (var.enable_monitoring ? 10 : 0)
  }
}
