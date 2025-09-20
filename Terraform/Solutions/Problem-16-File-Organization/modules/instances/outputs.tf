# Instances Module - Output Values

output "instance_ids" {
  description = "IDs of the created instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = aws_instance.web[*].private_ip
}
