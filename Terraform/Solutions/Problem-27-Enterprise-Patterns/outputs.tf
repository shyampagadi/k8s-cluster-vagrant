# Problem 27: Enterprise Patterns - Large-Scale Infrastructure
# Output values for the enterprise patterns configuration

output "primary_vpc_id" {
  description = "The ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  description = "The ID of the secondary VPC"
  value       = aws_vpc.secondary.id
}

output "primary_subnet_ids" {
  description = "IDs of the primary region subnets"
  value = {
    public  = aws_subnet.primary_public[*].id
    private = aws_subnet.primary_private[*].id
  }
}

output "secondary_subnet_ids" {
  description = "IDs of the secondary region subnets"
  value = {
    public  = aws_subnet.secondary_public[*].id
    private = aws_subnet.secondary_private[*].id
  }
}

output "security_group_ids" {
  description = "IDs of the enterprise security groups"
  value = {
    web      = aws_security_group.enterprise_web.id
    database = aws_security_group.enterprise_database.id
  }
}

output "auto_scaling_group_id" {
  description = "The ID of the enterprise auto scaling group"
  value       = aws_autoscaling_group.enterprise.id
}

output "launch_template_id" {
  description = "The ID of the enterprise launch template"
  value       = aws_launch_template.enterprise.id
}

output "s3_bucket_names" {
  description = "Names of the enterprise S3 buckets"
  value = {
    logs = aws_s3_bucket.enterprise_logs.id
    data = aws_s3_bucket.enterprise_data.id
  }
}

output "cloudwatch_log_group_name" {
  description = "The name of the enterprise CloudWatch log group"
  value       = aws_cloudwatch_log_group.enterprise.name
}

output "enterprise_summary" {
  description = "Summary of enterprise infrastructure"
  value = {
    regions = {
      primary   = var.primary_region
      secondary = var.secondary_region
    }
    vpcs = {
      primary   = aws_vpc.primary.id
      secondary = aws_vpc.secondary.id
    }
    subnets = {
      primary_public  = length(aws_subnet.primary_public)
      primary_private = length(aws_subnet.primary_private)
      secondary_public  = length(aws_subnet.secondary_public)
      secondary_private = length(aws_subnet.secondary_private)
    }
    instances = {
      min     = var.min_instances
      max     = var.max_instances
      desired = var.desired_instances
    }
    buckets = 2
    log_groups = 1
  }
}
