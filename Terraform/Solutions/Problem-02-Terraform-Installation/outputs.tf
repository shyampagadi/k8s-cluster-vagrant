# S3 Bucket Information
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.bucket_regional_domain_name
}

# S3 Bucket Configuration
output "bucket_versioning_status" {
  description = "Versioning status of the S3 bucket"
  value       = aws_s3_bucket_versioning.my_bucket_versioning.versioning_configuration[0].status
}

output "bucket_encryption_status" {
  description = "Encryption status of the S3 bucket"
  value       = aws_s3_bucket_server_side_encryption_configuration.my_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

# S3 Object Information
output "sample_file_key" {
  description = "Key of the sample file in the S3 bucket"
  value       = aws_s3_object.sample_file.key
}

output "sample_file_etag" {
  description = "ETag of the sample file"
  value       = aws_s3_object.sample_file.etag
}

# Random ID Information
output "bucket_suffix" {
  description = "Random suffix used for bucket name"
  value       = random_id.bucket_suffix.hex
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    bucket_name = aws_s3_bucket.my_bucket.id
    bucket_arn  = aws_s3_bucket.my_bucket.arn
    file_count  = 1
    environment = var.environment
    project     = var.project_name
  }
}
