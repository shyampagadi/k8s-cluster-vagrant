# Problem 33: Final Project - Complete Infrastructure Solution
# Output values for the final project configuration

output "vpc_id" {
  description = "The ID of the final project VPC"
  value       = aws_vpc.final_project.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    web      = aws_security_group.web.id
    database = aws_security_group.database.id
  }
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.final_project.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the Application Load Balancer"
  value       = aws_lb.final_project.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.final_project.arn
}

output "auto_scaling_group_id" {
  description = "The ID of the auto scaling group"
  value       = aws_autoscaling_group.final_project.id
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.final_project.id
}

output "s3_bucket_names" {
  description = "Names of the S3 buckets"
  value = {
    data = aws_s3_bucket.final_project_data.id
    logs = aws_s3_bucket.final_project_logs.id
  }
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.final_project.name
}

output "final_project_summary" {
  description = "Summary of the final project infrastructure"
  value = {
    vpc_id = aws_vpc.final_project.id
    public_subnets = length(aws_subnet.public)
    private_subnets = length(aws_subnet.private)
    security_groups = 2
    alb_dns_name = aws_lb.final_project.dns_name
    asg_desired = aws_autoscaling_group.final_project.desired_capacity
    s3_buckets = 2
    log_groups = 1
    monitoring_enabled = var.enable_monitoring
    security_enabled = var.enable_security
    total_resources = 1 + length(aws_subnet.public) + length(aws_subnet.private) + 2 + 1 + 1 + 1 + 1 + 2 + 1
  }
}
