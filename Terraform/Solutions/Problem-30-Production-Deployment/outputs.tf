# Problem 30: Production Deployment - Blue-Green and Canary
# Output values for the production deployment configuration

output "vpc_id" {
  description = "The ID of the production VPC"
  value       = aws_vpc.production.id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.production.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the Application Load Balancer"
  value       = aws_lb.production.zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value = {
    blue  = aws_lb_target_group.blue.arn
    green = aws_lb_target_group.green.arn
  }
}

output "auto_scaling_group_ids" {
  description = "IDs of the auto scaling groups"
  value = {
    blue  = aws_autoscaling_group.blue.id
    green = aws_autoscaling_group.green.id
  }
}

output "launch_template_ids" {
  description = "IDs of the launch templates"
  value = {
    blue  = aws_launch_template.blue.id
    green = aws_launch_template.green.id
  }
}

output "deployment_summary" {
  description = "Summary of production deployment configuration"
  value = {
    alb_dns_name = aws_lb.production.dns_name
    blue_green_enabled = var.enable_blue_green
    canary_enabled = var.enable_canary
    blue_asg_desired = aws_autoscaling_group.blue.desired_capacity
    green_asg_desired = aws_autoscaling_group.green.desired_capacity
    target_groups = 2
    launch_templates = 2
  }
}
