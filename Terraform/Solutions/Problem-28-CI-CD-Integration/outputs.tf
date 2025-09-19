# Problem 28: CI/CD Integration - DevOps Automation
# Output values for the CI/CD integration configuration

output "vpc_id" {
  description = "The ID of the CI/CD VPC"
  value       = aws_vpc.cicd.id
}

output "subnet_ids" {
  description = "IDs of the CI/CD subnets"
  value       = aws_subnet.cicd_public[*].id
}

output "security_group_id" {
  description = "The ID of the CI/CD security group"
  value       = aws_security_group.cicd.id
}

output "cicd_runner_id" {
  description = "The ID of the CI/CD runner instance"
  value       = aws_instance.cicd_runner.id
}

output "artifacts_bucket_name" {
  description = "The name of the CI/CD artifacts S3 bucket"
  value       = aws_s3_bucket.cicd_artifacts.id
}

output "log_group_name" {
  description = "The name of the CI/CD CloudWatch log group"
  value       = aws_cloudwatch_log_group.cicd.name
}

output "cicd_summary" {
  description = "Summary of CI/CD infrastructure"
  value = {
    vpc_id = aws_vpc.cicd.id
    subnets = length(aws_subnet.cicd_public)
    runner_instance = aws_instance.cicd_runner.id
    artifacts_bucket = aws_s3_bucket.cicd_artifacts.id
    log_group = aws_cloudwatch_log_group.cicd.name
    automated_testing = var.enable_automated_testing
    security_scanning = var.enable_security_scanning
  }
}
