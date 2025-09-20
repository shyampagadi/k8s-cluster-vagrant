# Problem 1: Understanding Infrastructure as Code - Outputs

output "iac_demo_bucket_name" {
  description = "Name of the S3 bucket created for IaC demonstration"
  value       = aws_s3_bucket.iac_demo.bucket
}

output "iac_demo_bucket_arn" {
  description = "ARN of the S3 bucket created for IaC demonstration"
  value       = aws_s3_bucket.iac_demo.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.iac_demo.name
}

output "iac_principles" {
  description = "Key principles of Infrastructure as Code"
  value       = local.iac_principles
}

output "iac_benefits" {
  description = "Benefits of using Infrastructure as Code"
  value       = local.iac_benefits
}

output "terraform_version" {
  description = "Terraform version used for this deployment"
  value       = "~> 1.0"
}

output "aws_provider_version" {
  description = "AWS provider version used"
  value       = "~> 5.0"
}

output "resource_summary" {
  description = "Summary of resources created in this IaC demonstration"
  value = {
    s3_bucket           = 1
    cloudwatch_log_group = 1
    total_resources     = 2
  }
}
