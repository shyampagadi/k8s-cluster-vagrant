# Development Environment Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_id
}

output "database_endpoint" {
  description = "Endpoint of the database"
  value       = module.storage.rds_instance_endpoint
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.storage.s3_bucket_id
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.monitoring.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.monitoring.sns_topic_arn
}
