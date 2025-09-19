# Problem 24: Advanced Data Sources - Complex Queries and Filtering
# Output values for the advanced data sources configuration

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

output "data_source_summary" {
  description = "Summary of data source queries"
  value = {
    ami_id = data.aws_ami.amazon_linux.id
    availability_zones = data.aws_availability_zones.available.names
    existing_vpcs = data.aws_vpcs.existing.ids
    existing_subnets = data.aws_subnets.existing.ids
    existing_security_groups = data.aws_security_groups.existing.ids
  }
}
