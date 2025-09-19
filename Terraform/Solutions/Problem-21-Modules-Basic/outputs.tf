# Problem 21: Modules - Basic Usage and Structure
# Output values for the main configuration

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the created subnet"
  value       = aws_subnet.main.id
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

# Module outputs
output "logs_bucket_name" {
  description = "Name of the logs S3 bucket created by module"
  value       = module.logs_bucket.bucket_name
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket created by module"
  value       = module.logs_bucket.bucket_arn
}

output "data_bucket_name" {
  description = "Name of the data S3 bucket created by module"
  value       = module.data_bucket.bucket_name
}

output "data_bucket_arn" {
  description = "ARN of the data S3 bucket created by module"
  value       = module.data_bucket.bucket_arn
}

output "backup_bucket_name" {
  description = "Name of the backup S3 bucket created by module"
  value       = module.backup_bucket.bucket_name
}

output "backup_bucket_arn" {
  description = "ARN of the backup S3 bucket created by module"
  value       = module.backup_bucket.bucket_arn
}

output "all_bucket_names" {
  description = "List of all S3 bucket names created by modules"
  value = [
    module.logs_bucket.bucket_name,
    module.data_bucket.bucket_name,
    module.backup_bucket.bucket_name
  ]
}

output "all_bucket_arns" {
  description = "Map of all S3 bucket ARNs created by modules"
  value = {
    logs    = module.logs_bucket.bucket_arn
    data    = module.data_bucket.bucket_arn
    backup  = module.backup_bucket.bucket_arn
  }
}
