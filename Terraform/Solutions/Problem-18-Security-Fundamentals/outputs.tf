# Security Fundamentals - Outputs

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

output "security_level" {
  description = "Security level configured"
  value       = var.security_level
}

output "compliance_level" {
  description = "Compliance level configured"
  value       = var.compliance_level
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.secure_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.secure_vpc.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.secure_vpc.arn
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

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

# Security Group Information
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database ? aws_security_group.database[0].id : null
}

# IAM Information
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_policy_arn" {
  description = "ARN of the EC2 IAM policy"
  value       = aws_iam_policy.ec2_policy.arn
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

# Load Balancer Information
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

# Instance Information
output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.web[*].id
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

# KMS Information
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "Name of the KMS alias"
  value       = aws_kms_alias.main.name
}

# Secrets Manager Information
output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = var.create_database ? aws_secretsmanager_secret.db_password[0].arn : null
}

output "db_password_secret_name" {
  description = "Name of the database password secret"
  value       = var.create_database ? aws_secretsmanager_secret.db_password[0].name : null
}

# Parameter Store Information
output "app_config_parameter_arn" {
  description = "ARN of the app configuration parameter"
  value       = aws_ssm_parameter.app_config.arn
}

output "app_config_parameter_name" {
  description = "Name of the app configuration parameter"
  value       = aws_ssm_parameter.app_config.name
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

# CloudTrail Information
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = length(aws_cloudtrail.audit_trail) > 0 ? aws_cloudtrail.audit_trail[0].arn : null
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = length(aws_cloudtrail.audit_trail) > 0 ? aws_cloudtrail.audit_trail[0].name : null
}

# Security Configuration
output "security_configuration" {
  description = "Security configuration summary"
  value = {
    security_level = var.security_level
    compliance_level = var.compliance_level
    data_classification = var.data_classification
    encryption_enabled = var.encryption_enabled
    backup_required = var.backup_required
    monitoring_enabled = var.monitoring_enabled
    audit_logging_enabled = var.enable_audit_logging
    security_scanning_enabled = var.enable_security_scanning
  }
}

# Compliance Information
output "compliance_status" {
  description = "Compliance status"
  value = {
    standards = var.compliance_standards
    data_residency = var.data_residency_requirements
    audit_logging = var.enable_audit_logging
    encryption = var.encryption_enabled
    backup = var.backup_required
    monitoring = var.monitoring_enabled
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

# Summary Information
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    project_name = var.project_name
    environment = var.environment
    aws_region = var.aws_region
    vpc_id = aws_vpc.secure_vpc.id
    instance_count = length(aws_instance.web)
    database_created = var.create_database
    s3_bucket_id = aws_s3_bucket.main.id
    security_level = var.security_level
    compliance_level = var.compliance_level
    encryption_enabled = var.encryption_enabled
    monitoring_enabled = var.monitoring_enabled
    audit_logging_enabled = var.enable_audit_logging
  }
}

# Connection Information
output "alb_endpoint" {
  description = "Application Load Balancer endpoint"
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_connection_info" {
  description = "Database connection information"
  value = var.create_database ? {
    endpoint = aws_db_instance.main[0].endpoint
    port = aws_db_instance.main[0].port
    database_name = aws_db_instance.main[0].db_name
    username = aws_db_instance.main[0].username
    secret_arn = aws_secretsmanager_secret.db_password[0].arn
  } : null
}

# Security Endpoints
output "security_endpoints" {
  description = "Security-related endpoints and information"
  value = {
    alb_endpoint = "http://${aws_lb.main.dns_name}"
    health_check = "http://${aws_lb.main.dns_name}/health"
    status_endpoint = "http://${aws_lb.main.dns_name}/status"
    kms_key_arn = aws_kms_key.main.arn
    secrets_manager_arn = var.create_database ? aws_secretsmanager_secret.db_password[0].arn : null
    parameter_store_name = aws_ssm_parameter.app_config.name
    cloudtrail_arn = length(aws_cloudtrail.audit_trail) > 0 ? aws_cloudtrail.audit_trail[0].arn : null
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    instances = length(aws_instance.web) * 10  # Approximate cost per instance
    database = var.create_database ? 25 : 0    # Approximate cost for database
    storage = 5                                  # Approximate cost for S3 storage
    monitoring = var.monitoring_enabled ? 10 : 0 # Approximate cost for monitoring
    load_balancer = 20                           # Approximate cost for ALB
    kms = 5                                      # Approximate cost for KMS
    secrets_manager = var.create_database ? 5 : 0 # Approximate cost for Secrets Manager
    cloudtrail = var.enable_audit_logging ? 5 : 0 # Approximate cost for CloudTrail
    total = (length(aws_instance.web) * 10) + (var.create_database ? 25 : 0) + 5 + (var.monitoring_enabled ? 10 : 0) + 20 + 5 + (var.create_database ? 5 : 0) + (var.enable_audit_logging ? 5 : 0)
  }
}
