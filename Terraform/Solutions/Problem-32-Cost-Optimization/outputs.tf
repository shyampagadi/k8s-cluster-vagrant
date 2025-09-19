# Problem 32: Cost Optimization - Resource Efficiency and Monitoring
# Output values for the cost optimization configuration

output "vpc_id" {
  description = "The ID of the cost-optimized VPC"
  value       = aws_vpc.cost_optimized.id
}

output "subnet_ids" {
  description = "IDs of the cost-optimized subnets"
  value       = aws_subnet.cost_optimized[*].id
}

output "security_group_id" {
  description = "The ID of the cost-optimized security group"
  value       = aws_security_group.cost_optimized.id
}

output "auto_scaling_group_id" {
  description = "The ID of the cost-optimized auto scaling group"
  value       = aws_autoscaling_group.cost_optimized.id
}

output "launch_template_id" {
  description = "The ID of the cost-optimized launch template"
  value       = aws_launch_template.cost_optimized.id
}

output "s3_bucket_name" {
  description = "The name of the cost-optimized S3 bucket"
  value       = aws_s3_bucket.cost_optimized.id
}

output "cost_dashboard_name" {
  description = "The name of the cost monitoring dashboard"
  value       = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
}

output "cost_optimization_summary" {
  description = "Summary of cost optimization configuration"
  value = {
    vpc_id = aws_vpc.cost_optimized.id
    subnets = length(aws_subnet.cost_optimized)
    asg_desired = aws_autoscaling_group.cost_optimized.desired_capacity
    spot_instances = var.enable_spot_instances
    reserved_instances = var.enable_reserved_instances
    cost_dashboard = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
    lifecycle_policy = "enabled"
  }
}
