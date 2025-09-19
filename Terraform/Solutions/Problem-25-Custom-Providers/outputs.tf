# Problem 25: Custom Providers - Development and Integration
# Output values for the custom providers configuration

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "The ID of the created security group"
  value       = aws_security_group.web_sg.id
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "provider_summary" {
  description = "Summary of provider configuration"
  value = {
    aws_provider_version = "~> 5.0"
    random_provider_version = "~> 3.1"
    custom_provider_enabled = false
  }
}
