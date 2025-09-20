output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.policy_recorder.name
}

output "compliance_status" {
  description = "Policy compliance status"
  value       = local.policy_compliance
}
