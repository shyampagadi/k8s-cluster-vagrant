# Compute Module Outputs
# Output values for the compute module

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.main.arn
}

output "auto_scaling_group_id" {
  description = "The ID of the auto scaling group (if created)"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].id : null
}

output "auto_scaling_group_arn" {
  description = "The ARN of the auto scaling group (if created)"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].arn : null
}

output "instance_ids" {
  description = "IDs of the created instances"
  value = var.enable_auto_scaling ? [] : aws_instance.standalone[*].id
}

output "instance_arns" {
  description = "ARNs of the created instances"
  value = var.enable_auto_scaling ? [] : aws_instance.standalone[*].arn
}

output "scaling_policy_arns" {
  description = "ARNs of the scaling policies (if created)"
  value = var.enable_auto_scaling ? [
    aws_autoscaling_policy.scale_up[0].arn,
    aws_autoscaling_policy.scale_down[0].arn
  ] : []
}

output "cloudwatch_alarm_arns" {
  description = "ARNs of the CloudWatch alarms (if created)"
  value = var.enable_auto_scaling ? [
    aws_cloudwatch_metric_alarm.cpu_high[0].arn,
    aws_cloudwatch_metric_alarm.cpu_low[0].arn
  ] : []
}
