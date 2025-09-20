# EC2 Module - outputs.tf

output "instance_ids" {
  description = "List of IDs of instances"
  value       = aws_instance.this[*].id
}

output "instance_arns" {
  description = "List of ARNs of instances"
  value       = aws_instance.this[*].arn
}

output "instance_availability_zones" {
  description = "List of availability zones of instances"
  value       = aws_instance.this[*].availability_zone
}

output "instance_key_names" {
  description = "List of key names of instances"
  value       = aws_instance.this[*].key_name
}

output "instance_public_dns" {
  description = "List of public DNS names assigned to the instances"
  value       = aws_instance.this[*].public_dns
}

output "instance_public_ips" {
  description = "List of public IP addresses assigned to the instances"
  value       = aws_instance.this[*].public_ip
}

output "instance_private_dns" {
  description = "List of private DNS names assigned to the instances"
  value       = aws_instance.this[*].private_dns
}

output "instance_private_ips" {
  description = "List of private IP addresses assigned to the instances"
  value       = aws_instance.this[*].private_ip
}

output "instance_security_groups" {
  description = "List of associated security groups of instances"
  value       = aws_instance.this[*].security_groups
}

output "instance_vpc_security_group_ids" {
  description = "List of associated security groups of instances, if running in non-default VPC"
  value       = aws_instance.this[*].vpc_security_group_ids
}

output "instance_subnet_ids" {
  description = "List of IDs of VPC subnets of instances"
  value       = aws_instance.this[*].subnet_id
}

output "instance_credit_specifications" {
  description = "List of credit specification of instances"
  value       = aws_instance.this[*].credit_specification
}

output "instance_tags" {
  description = "List of tags of instances"
  value       = aws_instance.this[*].tags_all
}

output "instance_state" {
  description = "List of instance states"
  value       = aws_instance.this[*].instance_state
}
