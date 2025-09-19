# Problem 29: Advanced Security - Zero Trust and Compliance
# Output values for the advanced security configuration

output "vpc_id" {
  description = "The ID of the secure VPC"
  value       = aws_vpc.secure.id
}

output "private_subnet_ids" {
  description = "IDs of the secure private subnets"
  value       = aws_subnet.secure_private[*].id
}

output "security_group_ids" {
  description = "IDs of the secure security groups"
  value = {
    web      = aws_security_group.secure_web.id
    database = aws_security_group.secure_database.id
  }
}

output "kms_key_id" {
  description = "The ID of the security KMS key"
  value       = aws_kms_key.security.id
}

output "kms_key_arn" {
  description = "The ARN of the security KMS key"
  value       = aws_kms_key.security.arn
}

output "secure_bucket_name" {
  description = "The name of the secure S3 bucket"
  value       = aws_s3_bucket.secure_data.id
}

output "cloudtrail_name" {
  description = "The name of the security audit CloudTrail"
  value       = aws_cloudtrail.security_audit.name
}

output "security_monitor_id" {
  description = "The ID of the security monitoring instance"
  value       = aws_instance.security_monitor.id
}

output "security_summary" {
  description = "Summary of security configuration"
  value = {
    zero_trust_enabled = var.enable_zero_trust
    compliance_monitoring = var.enable_compliance_monitoring
    encryption_enabled = var.encryption_enabled
    kms_key_id = aws_kms_key.security.id
    secure_bucket = aws_s3_bucket.secure_data.id
    cloudtrail = aws_cloudtrail.security_audit.name
    security_monitor = aws_instance.security_monitor.id
  }
}
