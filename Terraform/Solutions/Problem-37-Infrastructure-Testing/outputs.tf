output "test_results" {
  description = "Infrastructure testing results"
  value       = local.test_results
}

output "vpc_id" {
  description = "VPC ID for testing"
  value       = aws_vpc.test.id
}

output "security_group_id" {
  description = "Security group ID for testing"
  value       = aws_security_group.test.id
}

locals {
  test_results = {
    vpc_cidr_valid        = can(cidrhost(aws_vpc.test.cidr_block, 0))
    subnet_count          = length(local.subnet_cidrs)
    security_group_rules  = length(aws_security_group.test.ingress)
    environment_valid     = contains(["dev", "staging", "prod", "test"], var.environment)
    all_tests_passed      = can(cidrhost(aws_vpc.test.cidr_block, 0)) && length(aws_security_group.test.ingress) > 0
  }
}
