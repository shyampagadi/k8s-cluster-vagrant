# Problem 22: Modules - Advanced Features and Patterns
# Output values for the advanced module configuration

# Networking module outputs
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the created VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "security_group_ids" {
  description = "IDs of the created security groups"
  value       = module.networking.security_group_ids
}

# Compute module outputs (conditional)
output "compute_instance_ids" {
  description = "IDs of the compute instances"
  value       = var.create_compute_resources ? module.compute[0].instance_ids : []
}

output "auto_scaling_group_id" {
  description = "ID of the auto scaling group"
  value       = var.create_compute_resources ? module.compute[0].auto_scaling_group_id : null
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = var.create_compute_resources ? module.compute[0].launch_template_id : null
}

# Storage module outputs (multiple instances)
output "storage_bucket_names" {
  description = "Names of all created S3 buckets"
  value = {
    for k, v in module.storage : k => v.bucket_name
  }
}

output "storage_bucket_arns" {
  description = "ARNs of all created S3 buckets"
  value = {
    for k, v in module.storage : k => v.bucket_arn
  }
}

output "storage_volume_ids" {
  description = "IDs of all created EBS volumes"
  value = {
    for k, v in module.storage : k => v.volume_ids
  }
}

# Monitoring module outputs (conditional)
output "monitoring_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_monitoring ? module.monitoring[0].log_group_name : null
}

output "monitoring_alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value       = var.enable_monitoring ? module.monitoring[0].alarm_arns : []
}

# Summary outputs
output "module_summary" {
  description = "Summary of all created modules and their resources"
  value = {
    networking = {
      vpc_id           = module.networking.vpc_id
      subnet_count     = length(module.networking.public_subnet_ids) + length(module.networking.private_subnet_ids)
      security_groups  = length(module.networking.security_group_ids)
    }
    compute = var.create_compute_resources ? {
      instances        = length(module.compute[0].instance_ids)
      auto_scaling     = module.compute[0].auto_scaling_group_id != null
    } : null
    storage = {
      buckets          = length(module.storage)
      volumes         = sum([for k, v in module.storage : length(v.volume_ids)])
    }
    monitoring = var.enable_monitoring ? {
      log_groups      = 1
      alarms          = length(module.monitoring[0].alarm_arns)
    } : null
  }
}

output "resource_counts" {
  description = "Count of resources created by each module type"
  value = {
    networking_resources = 4  # VPC, IGW, Route Table, Security Group
    compute_resources    = var.create_compute_resources ? 3 : 0  # Launch Template, ASG, Instances
    storage_resources    = length(module.storage) * 2  # S3 Bucket + EBS Volume per storage config
    monitoring_resources = var.enable_monitoring ? 2 : 0  # Log Group + Alarms
  }
}
