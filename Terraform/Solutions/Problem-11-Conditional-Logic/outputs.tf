# Outputs for Conditional Logic Demo
# This file demonstrates various output patterns with conditional logic

# Basic Outputs
output "conditional_instance_count" {
  description = "Number of instances created based on environment"
  value       = local.instance_count
}

output "conditional_min_size" {
  description = "Minimum auto scaling group size"
  value       = local.min_size
}

output "conditional_max_size" {
  description = "Maximum auto scaling group size"
  value       = local.max_size
}

output "conditional_desired_capacity" {
  description = "Desired auto scaling group capacity"
  value       = local.desired_capacity
}

# Conditional Outputs
output "production_instance_id" {
  description = "Instance ID (only for production environment)"
  value       = var.environment == "production" ? aws_instance.web[0].id : null
  sensitive   = false
}

output "development_instance_id" {
  description = "Instance ID (only for development environment)"
  value       = var.environment == "development" ? aws_instance.web[0].id : null
  sensitive   = false
}

output "testing_instance_id" {
  description = "Instance ID (only for testing environment)"
  value       = var.environment == "testing" ? aws_instance.web[0].id : null
  sensitive   = false
}

# Advanced Conditional Outputs
output "conditional_instance_info" {
  description = "Conditional instance information based on environment"
  value = var.environment == "production" ? {
    instance_id = aws_instance.web[0].id
    public_ip   = aws_instance.web[0].public_ip
    private_ip  = aws_instance.web[0].private_ip
    state       = aws_instance.web[0].instance_state
    type        = "Production Instance"
  } : var.environment == "development" ? {
    instance_id = aws_instance.web[0].id
    public_ip   = aws_instance.web[0].public_ip
    private_ip  = aws_instance.web[0].private_ip
    state       = aws_instance.web[0].instance_state
    type        = "Development Instance"
  } : {
    instance_id = aws_instance.web[0].id
    public_ip   = aws_instance.web[0].public_ip
    private_ip  = aws_instance.web[0].private_ip
    state       = aws_instance.web[0].instance_state
    type        = "Testing Instance"
  }
}

output "conditional_sg_info" {
  description = "Conditional security group information"
  value = var.environment == "production" ? {
    sg_id = aws_security_group.web.id
    name  = aws_security_group.web.name
    rules = [
      "HTTP (80)",
      "HTTPS (443)"
    ]
    description = "Production Security Group"
  } : {
    sg_id = aws_security_group.web.id
    name  = aws_security_group.web.name
    rules = [
      "HTTP (80)",
      "HTTPS (443)",
      "SSH (22)"
    ]
    description = "Development/Testing Security Group"
  }
}

# Conditional Outputs with Dynamic Blocks
output "conditional_dynamic_blocks_info" {
  description = "Information about dynamic blocks usage"
  value = {
    dynamic_sg_count = length(aws_security_group.web.ingress)
    static_sg_count  = length(aws_security_group.web.egress)
    environment      = var.environment
    has_ssh_access   = var.environment != "production"
  }
}

output "conditional_resource_tags" {
  description = "Conditional resource tags based on environment"
  value = local.common_tags
}

# Conditional Outputs with Try Function
output "conditional_try_function_result" {
  description = "Result of try function usage"
  value = {
    instance_state = try(aws_instance.web[0].instance_state, "unknown")
    security_group = try(aws_security_group.web.id, "unknown")
    environment    = var.environment
  }
}

# Conditional Outputs for Different Environments
output "environment_specific_info" {
  description = "Environment-specific information"
  value = {
    environment = var.environment
    instance_count = local.instance_count
    min_size = local.min_size
    max_size = local.max_size
    desired_capacity = local.desired_capacity
    production_mode = var.environment == "production"
    development_mode = var.environment == "development"
    testing_mode = var.environment == "testing"
  }
}

# Conditional Outputs for Resource Count
output "conditional_resource_count" {
  description = "Resource count based on conditional logic"
  value = {
    instances = local.instance_count
    security_groups = 1
    launch_templates = local.instance_count > 0 ? 1 : 0
    auto_scaling_groups = local.instance_count > 0 ? 1 : 0
  }
}

# Conditional Outputs for Monitoring
output "conditional_monitoring_info" {
  description = "Conditional monitoring information"
  value = var.environment == "production" ? {
    monitoring_enabled = true
    monitoring_level = "detailed"
    log_retention = 30
    alerting_enabled = true
  } : {
    monitoring_enabled = true
    monitoring_level = "basic"
    log_retention = 7
    alerting_enabled = false
  }
}

# Conditional Outputs for Cost
output "conditional_cost_info" {
  description = "Conditional cost information"
  value = {
    environment = var.environment
    estimated_monthly_cost = var.environment == "production" ? "$150" : var.environment == "development" ? "$50" : "$30"
    cost_optimization = var.environment == "production" ? "high" : "standard"
  }
}

# Conditional Outputs for Security
output "conditional_security_info" {
  description = "Conditional security information"
  value = var.environment == "production" ? {
    security_level = "high"
    encryption_enabled = true
    backup_enabled = true
    monitoring_enabled = true
  } : {
    security_level = "standard"
    encryption_enabled = true
    backup_enabled = false
    monitoring_enabled = true
  }
}

# Conditional Outputs for Compliance
output "conditional_compliance_info" {
  description = "Conditional compliance information"
  value = {
    environment = var.environment
    compliance_level = var.environment == "production" ? "high" : "standard"
    audit_logging = var.environment == "production" ? true : false
    data_retention = var.environment == "production" ? 365 : 90
  }
}

# Conditional Outputs for Backup
output "conditional_backup_info" {
  description = "Conditional backup information"
  value = var.environment == "production" ? {
    backup_enabled = true
    backup_frequency = "daily"
    backup_retention = 30
    cross_region_backup = true
  } : {
    backup_enabled = false
    backup_frequency = "none"
    backup_retention = 0
    cross_region_backup = false
  }
}

# Conditional Outputs for Disaster Recovery
output "conditional_dr_info" {
  description = "Conditional disaster recovery information"
  value = {
    environment = var.environment
    dr_enabled = var.environment == "production" ? true : false
    rto = var.environment == "production" ? "4 hours" : "24 hours"
    rpo = var.environment == "production" ? "1 hour" : "12 hours"
  }
}

# Conditional Outputs for Performance
output "conditional_performance_info" {
  description = "Conditional performance information"
  value = {
    environment = var.environment
    performance_tier = var.environment == "production" ? "high" : "standard"
    caching_enabled = var.environment == "production" ? true : false
    cdn_enabled = var.environment == "production" ? true : false
  }
}

# Conditional Outputs for Scalability
output "conditional_scalability_info" {
  description = "Conditional scalability information"
  value = {
    environment = var.environment
    auto_scaling_enabled = local.instance_count > 0
    min_capacity = local.min_size
    max_capacity = local.max_size
    target_capacity = local.desired_capacity
  }
}

# Conditional Outputs for Maintenance
output "conditional_maintenance_info" {
  description = "Conditional maintenance information"
  value = {
    environment = var.environment
    maintenance_window = var.environment == "production" ? "Sunday 02:00-04:00 UTC" : "Anytime"
    auto_updates = var.environment == "production" ? false : true
    maintenance_mode = var.environment == "production" ? "scheduled" : "immediate"
  }
}

# Conditional Outputs for Documentation
output "conditional_documentation_info" {
  description = "Conditional documentation information"
  value = {
    environment = var.environment
    documentation_level = var.environment == "production" ? "comprehensive" : "standard"
    api_documentation = var.environment == "production" ? true : false
    user_guide = var.environment == "production" ? true : false
  }
}

# Conditional Outputs for Support
output "conditional_support_info" {
  description = "Conditional support information"
  value = {
    environment = var.environment
    support_level = var.environment == "production" ? "24/7" : "business hours"
    escalation_process = var.environment == "production" ? "immediate" : "standard"
    monitoring_team = var.environment == "production" ? "dedicated" : "shared"
  }
}

# Conditional Outputs for Training
output "conditional_training_info" {
  description = "Conditional training information"
  value = {
    environment = var.environment
    training_level = var.environment == "production" ? "advanced" : "basic"
    certification_required = var.environment == "production" ? true : false
    ongoing_education = var.environment == "production" ? "mandatory" : "optional"
  }
}

# Conditional Outputs for Governance
output "conditional_governance_info" {
  description = "Conditional governance information"
  value = {
    environment = var.environment
    governance_level = var.environment == "production" ? "strict" : "standard"
    approval_process = var.environment == "production" ? "multi-level" : "single-level"
    change_management = var.environment == "production" ? "formal" : "informal"
  }
}

# Conditional Outputs for Risk Management
output "conditional_risk_info" {
  description = "Conditional risk management information"
  value = {
    environment = var.environment
    risk_level = var.environment == "production" ? "high" : "medium"
    risk_assessment = var.environment == "production" ? "quarterly" : "annually"
    risk_mitigation = var.environment == "production" ? "comprehensive" : "standard"
  }
}

# Conditional Outputs for Quality Assurance
output "conditional_qa_info" {
  description = "Conditional quality assurance information"
  value = {
    environment = var.environment
    qa_process = var.environment == "production" ? "comprehensive" : "standard"
    testing_level = var.environment == "production" ? "extensive" : "basic"
    quality_gates = var.environment == "production" ? "mandatory" : "optional"
  }
}

# Conditional Outputs for Operations
output "conditional_operations_info" {
  description = "Conditional operations information"
  value = {
    environment = var.environment
    operations_level = var.environment == "production" ? "dedicated" : "shared"
    incident_response = var.environment == "production" ? "immediate" : "standard"
    post_incident_review = var.environment == "production" ? "mandatory" : "optional"
  }
}

# Conditional Outputs for Innovation
output "conditional_innovation_info" {
  description = "Conditional innovation information"
  value = {
    environment = var.environment
    innovation_focus = var.environment == "production" ? "stability" : "experimentation"
    new_feature_rollout = var.environment == "production" ? "gradual" : "immediate"
    experimental_features = var.environment == "production" ? false : true
  }
}
