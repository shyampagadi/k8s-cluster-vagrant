# Problem 23: State Management - Remote State and Collaboration
# Output values for the state management configuration

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cr_block" {
  description = "The CIDR block of the created VPC"
  value       = aws_vpc.main.cr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "The ID of the created security group"
  value       = aws_security_group.web_sg.id
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "ec2_instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.app_data.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "state_management_summary" {
  description = "Summary of state management configuration"
  value = {
    backend_type     = "s3"
    state_locking    = "enabled"
    state_encryption = "enabled"
    state_versioning = "enabled"
    workspace        = terraform.workspace
  }
}

output "resource_counts" {
  description = "Count of resources managed by state"
  value = {
    vpc_resources     = 1
    subnet_resources   = length(aws_subnet.public) + length(aws_subnet.private)
    security_groups    = 1
    instances         = 1
    s3_buckets        = 1
    total_resources   = 1 + length(aws_subnet.public) + length(aws_subnet.private) + 1 + 1 + 1
  }
}
