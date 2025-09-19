# Storage Module Outputs
# Output values for the storage module

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "volume_ids" {
  description = "IDs of the created EBS volumes"
  value       = aws_ebs_volume.main[*].id
}

output "volume_arns" {
  description = "ARNs of the created EBS volumes"
  value       = aws_ebs_volume.main[*].arn
}

output "snapshot_ids" {
  description = "IDs of the created EBS snapshots (if lifecycle enabled)"
  value       = var.storage_config.lifecycle ? aws_ebs_snapshot.main[*].id : []
}

output "snapshot_arns" {
  description = "ARNs of the created EBS snapshots (if lifecycle enabled)"
  value       = var.storage_config.lifecycle ? aws_ebs_snapshot.main[*].arn : []
}
