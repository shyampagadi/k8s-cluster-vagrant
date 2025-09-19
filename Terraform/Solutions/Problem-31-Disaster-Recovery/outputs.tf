# Problem 31: Disaster Recovery - Multi-Region Backup and Recovery
# Output values for the disaster recovery configuration

output "primary_vpc_id" {
  description = "The ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  description = "The ID of the secondary VPC"
  value       = aws_vpc.secondary.id
}

output "primary_bucket_name" {
  description = "The name of the primary S3 bucket"
  value       = aws_s3_bucket.primary_data.id
}

output "secondary_bucket_name" {
  description = "The name of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary_backup.id
}

output "primary_instance_id" {
  description = "The ID of the primary instance"
  value       = aws_instance.primary.id
}

output "secondary_instance_id" {
  description = "The ID of the secondary instance"
  value       = aws_instance.secondary.id
}

output "disaster_recovery_summary" {
  description = "Summary of disaster recovery configuration"
  value = {
    primary_region = var.primary_region
    secondary_region = var.secondary_region
    automated_failover = var.enable_automated_failover
    backup_retention = var.backup_retention_days
    replication_enabled = true
    primary_bucket = aws_s3_bucket.primary_data.id
    secondary_bucket = aws_s3_bucket.secondary_backup.id
  }
}
