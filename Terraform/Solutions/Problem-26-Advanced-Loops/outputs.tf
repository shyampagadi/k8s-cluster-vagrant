# Problem 26: Advanced Loops - Complex Iteration Patterns
# Output values for the advanced loops configuration

output "vpc_ids" {
  description = "IDs of the created VPCs for each environment"
  value = {
    for env_name, vpc in aws_vpc.environments : env_name => vpc.id
  }
}

output "subnet_ids" {
  description = "IDs of the created subnets for each environment"
  value = {
    for env_name, subnets in aws_subnet.environments : env_name => subnets[*].id
  }
}

output "security_group_ids" {
  description = "IDs of the created security groups for each environment"
  value = {
    for env_name, sg in aws_security_group.environments : env_name => sg.id
  }
}

output "instance_ids" {
  description = "IDs of the created instances for each environment"
  value = {
    for env_name, instances in aws_instance.environments : env_name => instances[*].id
  }
}

output "s3_bucket_names" {
  description = "Names of the created S3 buckets"
  value = {
    for bucket_key, bucket in aws_s3_bucket.storage : bucket_key => bucket.id
  }
}

output "cloudwatch_log_groups" {
  description = "Names of the created CloudWatch log groups"
  value = {
    for env_name, log_group in aws_cloudwatch_log_group.environments : env_name => log_group.name
  }
}

output "loop_summary" {
  description = "Summary of loop-generated resources"
  value = {
    environments_created = length(aws_vpc.environments)
    total_instances = sum([for instances in aws_instance.environments : length(instances)])
    total_subnets = sum([for subnets in aws_subnet.environments : length(subnets)])
    total_buckets = length(aws_s3_bucket.storage)
    total_log_groups = length(aws_cloudwatch_log_group.environments)
  }
}

output "resource_counts_by_environment" {
  description = "Resource counts by environment"
  value = {
    for env_name in keys(aws_vpc.environments) : env_name => {
      instances = length(aws_instance.environments[env_name])
      subnets = length(aws_subnet.environments[env_name])
      buckets = length([for k, v in aws_s3_bucket.storage : k if v.tags.Environment == env_name])
      log_groups = contains(keys(aws_cloudwatch_log_group.environments), env_name) ? 1 : 0
    }
  }
}
