# Performance Optimization - Outputs

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
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = [for subnet in aws_subnet.private : subnet.cidr_block]
}

output "availability_zones" {
  description = "Availability zones used for subnets"
  value       = [for subnet in aws_subnet.public : subnet.availability_zone]
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

# Auto Scaling Information
output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = length(aws_autoscaling_group.web) > 0 ? aws_autoscaling_group.web[0].arn : null
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = length(aws_autoscaling_group.web) > 0 ? aws_autoscaling_group.web[0].name : null
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = length(aws_launch_template.web) > 0 ? aws_launch_template.web[0].id : null
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = length(aws_launch_template.web) > 0 ? aws_launch_template.web[0].arn : null
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

# Performance Configuration
output "performance_configuration" {
  description = "Performance configuration summary"
  value = {
    optimization_enabled = var.enable_performance_optimization
    parallel_execution = var.enable_parallel_execution
    caching_enabled = var.enable_caching
    auto_scaling = var.enable_auto_scaling
    monitoring_enabled = var.enable_monitoring
    load_balancing = var.enable_load_balancing
    performance_insights = var.enable_performance_insights
    enhanced_monitoring = var.enable_enhanced_monitoring
  }
}

# Performance Metrics
output "performance_metrics" {
  description = "Performance metrics and thresholds"
  value = {
    cpu_threshold = var.cpu_threshold
    memory_threshold = var.memory_threshold
    disk_threshold = var.disk_threshold
    min_instances = var.min_instance_count
    max_instances = var.max_instance_count
    desired_instances = var.desired_instance_count
    current_instances = length(aws_instance.web)
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

# Performance Optimization Status
output "optimization_status" {
  description = "Status of performance optimizations"
  value = {
    resource_optimization = "enabled"
    parallel_execution = var.enable_parallel_execution ? "enabled" : "disabled"
    caching = var.enable_caching ? "enabled" : "disabled"
    auto_scaling = var.enable_auto_scaling ? "enabled" : "disabled"
    load_balancing = var.enable_load_balancing ? "enabled" : "disabled"
    monitoring = var.enable_monitoring ? "enabled" : "disabled"
    performance_insights = var.enable_performance_insights ? "enabled" : "disabled"
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
    performance_optimized = var.enable_performance_optimization
    auto_scaling_enabled = var.enable_auto_scaling
    load_balancing_enabled = var.enable_load_balancing
    monitoring_enabled = var.enable_monitoring
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
    connection_string = "mysql://${aws_db_instance.main[0].username}:${var.database_password}@${aws_db_instance.main[0].endpoint}:${aws_db_instance.main[0].port}/${aws_db_instance.main[0].db_name}"
  } : null
}

# Performance Endpoints
output "performance_endpoints" {
  description = "Performance-related endpoints and information"
  value = {
    alb_endpoint = "http://${aws_lb.main.dns_name}"
    health_check = "http://${aws_lb.main.dns_name}/health"
    status_endpoint = "http://${aws_lb.main.dns_name}/status"
    metrics_endpoint = "http://${aws_lb.main.dns_name}/metrics"
    cloudwatch_logs = length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].name : null
    cpu_alarms = aws_cloudwatch_metric_alarm.cpu_utilization[*].alarm_name
    disk_alarms = aws_cloudwatch_metric_alarm.disk_utilization[*].alarm_name
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
    load_balancer = var.enable_load_balancing ? 20 : 0 # Approximate cost for ALB
    auto_scaling = var.enable_auto_scaling ? 5 : 0 # Approximate cost for auto scaling
    performance_insights = var.enable_performance_insights ? 5 : 0 # Approximate cost for performance insights
    total = (length(aws_instance.web) * 10) + (var.create_database ? 25 : 0) + 5 + (var.enable_monitoring ? 10 : 0) + (var.enable_load_balancing ? 20 : 0) + (var.enable_auto_scaling ? 5 : 0) + (var.enable_performance_insights ? 5 : 0)
  }
}
