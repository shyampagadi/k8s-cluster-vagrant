# Production Environment Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "instance_ids" {
  description = "IDs of the created instances"
  value       = module.instances.instance_ids
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = module.instances.instance_public_ips
}
