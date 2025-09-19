# Monitoring Module Outputs
# Output values for the monitoring module

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.arn
}

output "log_stream_name" {
  description = "The name of the CloudWatch log stream"
  value       = aws_cloudwatch_log_stream.main.name
}

output "alarm_arns" {
  description = "ARNs of the created CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.arn,
    aws_cloudwatch_metric_alarm.low_cpu.arn,
    aws_cloudwatch_metric_alarm.high_memory.arn
  ]
}

output "dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "The ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}
