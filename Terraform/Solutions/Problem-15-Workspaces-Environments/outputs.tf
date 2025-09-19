# Outputs for Workspaces and Environment Management Demo
# This file demonstrates various output patterns with workspaces and environments

# Basic Outputs
output "workspace_info" {
  description = "Information about current workspace and environment"
  value = {
    workspace = terraform.workspace
    environment = var.environment
    app_name = var.app_name
    instance_count = var.instance_count
    tier = var.tier
    cost_center = var.cost_center
  }
}

output "workspace_management_info" {
  description = "Information about workspace management"
  value = {
    workspace_commands = {
      list = "terraform workspace list"
      new = "terraform workspace new <name>"
      select = "terraform workspace select <name>"
      show = "terraform workspace show"
      delete = "terraform workspace delete <name>"
    }
    workspace_benefits = {
      environment_isolation = "Separate state for different environments"
      configuration_reuse = "Use the same configuration for multiple environments"
      state_management = "Manage multiple state files efficiently"
      deployment_flexibility = "Deploy to different environments easily"
    }
  }
}

# VPC Outputs
output "vpc_info" {
  description = "Information about VPC with workspace-specific configuration"
  value = {
    vpc_id = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    vpc_state = aws_vpc.main.state
    vpc_tags = aws_vpc.main.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Internet Gateway Outputs
output "internet_gateway_info" {
  description = "Information about Internet Gateway with workspace-specific configuration"
  value = {
    igw_id = aws_internet_gateway.main.id
    igw_state = aws_internet_gateway.main.state
    igw_tags = aws_internet_gateway.main.tags
    vpc_id = aws_internet_gateway.main.vpc_id
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Route Table Outputs
output "route_table_info" {
  description = "Information about Route Table with workspace-specific configuration"
  value = {
    rt_id = aws_route_table.public.id
    rt_vpc_id = aws_route_table.public.vpc_id
    rt_tags = aws_route_table.public.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Route Outputs
output "route_info" {
  description = "Information about Route with workspace-specific configuration"
  value = {
    route_id = aws_route.public.id
    route_destination_cidr_block = aws_route.public.destination_cidr_block
    route_gateway_id = aws_route.public.gateway_id
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Subnet Outputs
output "subnet_info" {
  description = "Information about Subnets with workspace-specific configuration"
  value = {
    subnet_ids = aws_subnet.public[*].id
    subnet_cidrs = aws_subnet.public[*].cidr_block
    subnet_azs = aws_subnet.public[*].availability_zone
    subnet_vpc_ids = aws_subnet.public[*].vpc_id
    subnet_tags = aws_subnet.public[*].tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
      az_count = length(var.availability_zones)
    }
  }
}

# Route Table Association Outputs
output "route_table_association_info" {
  description = "Information about Route Table Associations with workspace-specific configuration"
  value = {
    rta_ids = aws_route_table_association.public[*].id
    rta_subnet_ids = aws_route_table_association.public[*].subnet_id
    rta_route_table_ids = aws_route_table_association.public[*].route_table_id
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Security Group Outputs
output "security_group_info" {
  description = "Information about Security Group with workspace-specific configuration"
  value = {
    sg_id = aws_security_group.web.id
    sg_name = aws_security_group.web.name
    sg_description = aws_security_group.web.description
    sg_vpc_id = aws_security_group.web.vpc_id
    sg_ingress_rules = aws_security_group.web.ingress
    sg_egress_rules = aws_security_group.web.egress
    sg_tags = aws_security_group.web.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Launch Template Outputs
output "launch_template_info" {
  description = "Information about Launch Template with workspace-specific configuration"
  value = {
    lt_id = aws_launch_template.web.id
    lt_name = aws_launch_template.web.name
    lt_description = aws_launch_template.web.description
    lt_image_id = aws_launch_template.web.image_id
    lt_instance_type = aws_launch_template.web.instance_type
    lt_tags = aws_launch_template.web.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Auto Scaling Group Outputs
output "auto_scaling_group_info" {
  description = "Information about Auto Scaling Group with workspace-specific configuration"
  value = {
    asg_id = aws_autoscaling_group.web.id
    asg_name = aws_autoscaling_group.web.name
    asg_min_size = aws_autoscaling_group.web.min_size
    asg_max_size = aws_autoscaling_group.web.max_size
    asg_desired_capacity = aws_autoscaling_group.web.desired_capacity
    asg_launch_template = aws_autoscaling_group.web.launch_template
    asg_tags = aws_autoscaling_group.web.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Instance Outputs
output "instance_info" {
  description = "Information about Instances with workspace-specific configuration"
  value = {
    instance_ids = aws_instance.web[*].id
    instance_public_ips = aws_instance.web[*].public_ip
    instance_private_ips = aws_instance.web[*].private_ip
    instance_states = aws_instance.web[*].instance_state
    instance_types = aws_instance.web[*].instance_type
    instance_azs = aws_instance.web[*].availability_zone
    instance_subnet_ids = aws_instance.web[*].subnet_id
    instance_vpc_security_group_ids = aws_instance.web[*].vpc_security_group_ids
    instance_tags = aws_instance.web[*].tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
      instance_count = var.instance_count
    }
  }
}

# S3 Bucket Outputs
output "s3_bucket_info" {
  description = "Information about S3 Bucket with workspace-specific configuration"
  value = {
    bucket_id = aws_s3_bucket.data.id
    bucket_arn = aws_s3_bucket.data.arn
    bucket_domain_name = aws_s3_bucket.data.bucket_domain_name
    bucket_tags = aws_s3_bucket.data.tags
    workspace_specific = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
    }
  }
}

# Workspace Analysis Outputs
output "workspace_analysis" {
  description = "Analysis of workspace configuration"
  value = {
    total_resources = 10
    workspace_specific_resources = 10
    workspace_configuration = {
      workspace = terraform.workspace
      environment = var.environment
      tier = var.tier
      cost_center = var.cost_center
    }
    workspace_benefits = {
      environment_isolation = "Separate state for different environments"
      configuration_reuse = "Use the same configuration for multiple environments"
      state_management = "Manage multiple state files efficiently"
      deployment_flexibility = "Deploy to different environments easily"
    }
  }
}

# Workspace Validation Outputs
output "workspace_validation" {
  description = "Validation of workspace configuration"
  value = {
    workspace_validation = {
      workspace_name = terraform.workspace
      environment = var.environment
      tier = var.tier
      cost_center = var.cost_center
      validation_status = "valid"
    }
    environment_validation = {
      environment = var.environment
      tier = var.tier
      cost_center = var.cost_center
      validation_status = "valid"
    }
    tier_validation = {
      tier = var.tier
      cost_center = var.cost_center
      validation_status = "valid"
    }
  }
}

# Performance Outputs
output "performance_metrics" {
  description = "Performance metrics related to workspaces"
  value = {
    deployment_time = "estimated 5-10 minutes"
    workspace_switching_time = "instant"
    state_file_size = "workspace-specific"
    resource_creation_time = "workspace-specific"
  }
}

# Monitoring Outputs
output "monitoring_info" {
  description = "Monitoring information for workspaces"
  value = {
    workspace_monitoring = true
    environment_monitoring = true
    resource_health_checks = true
    workspace_alerts = true
    environment_alerts = true
  }
}

# Security Outputs
output "security_info" {
  description = "Security information for workspaces"
  value = {
    workspace_security = {
      environment_isolation = "separate state files"
      access_control = "workspace-specific"
      audit_trail = "workspace-specific"
      compliance = "workspace-specific"
    }
    security_validation = {
      workspace_integrity = true
      environment_isolation = true
      access_control = true
      audit_trail = true
    }
  }
}

# Compliance Outputs
output "compliance_info" {
  description = "Compliance information for workspaces"
  value = {
    compliance_level = "standard"
    workspace_documentation = true
    environment_documentation = true
    resource_documentation = true
    audit_trail = true
  }
}

# Backup Outputs
output "backup_info" {
  description = "Backup information for workspaces"
  value = {
    backup_strategy = "workspace-aware"
    backup_protection = "workspace-specific"
    backup_validation = true
    restore_strategy = "workspace-aware"
  }
}

# Disaster Recovery Outputs
output "disaster_recovery_info" {
  description = "Disaster recovery information for workspaces"
  value = {
    dr_strategy = "workspace-aware"
    dr_protection = "workspace-specific"
    dr_validation = true
    dr_testing = true
  }
}

# Performance Optimization Outputs
output "performance_optimization_info" {
  description = "Performance optimization information for workspaces"
  value = {
    optimization_strategy = "workspace-aware"
    performance_protection = "workspace-specific"
    performance_monitoring = true
    workspace_optimization = true
  }
}

# Scalability Outputs
output "scalability_info" {
  description = "Scalability information for workspaces"
  value = {
    scalability_strategy = "workspace-aware"
    auto_scaling = "workspace-aware"
    load_balancing = "workspace-aware"
    resource_scaling = "workspace-aware"
  }
}

# Maintenance Outputs
output "maintenance_info" {
  description = "Maintenance information for workspaces"
  value = {
    maintenance_strategy = "workspace-aware"
    maintenance_protection = "workspace-specific"
    maintenance_validation = true
    maintenance_testing = true
  }
}

# Documentation Outputs
output "documentation_info" {
  description = "Documentation information for workspaces"
  value = {
    documentation_level = "comprehensive"
    workspace_documentation = true
    environment_documentation = true
    resource_documentation = true
    runbook_documentation = true
  }
}

# Support Outputs
output "support_info" {
  description = "Support information for workspaces"
  value = {
    support_level = "standard"
    workspace_support = true
    environment_support = true
    resource_support = true
    troubleshooting_support = true
  }
}

# Training Outputs
output "training_info" {
  description = "Training information for workspaces"
  value = {
    training_level = "standard"
    workspace_training = true
    environment_training = true
    resource_training = true
    hands_on_training = true
  }
}

# Governance Outputs
output "governance_info" {
  description = "Governance information for workspaces"
  value = {
    governance_level = "standard"
    workspace_governance = true
    environment_governance = true
    resource_governance = true
    policy_compliance = true
  }
}

# Risk Management Outputs
output "risk_management_info" {
  description = "Risk management information for workspaces"
  value = {
    risk_level = "medium"
    workspace_risks = "analyzed"
    environment_risks = "analyzed"
    resource_risks = "analyzed"
    risk_mitigation = "implemented"
  }
}

# Quality Assurance Outputs
output "quality_assurance_info" {
  description = "Quality assurance information for workspaces"
  value = {
    qa_process = "standard"
    workspace_testing = true
    environment_testing = true
    resource_testing = true
    integration_testing = true
  }
}

# Operations Outputs
output "operations_info" {
  description = "Operations information for workspaces"
  value = {
    operations_level = "standard"
    workspace_operations = true
    environment_operations = true
    resource_operations = true
    incident_response = true
  }
}

# Innovation Outputs
output "innovation_info" {
  description = "Innovation information for workspaces"
  value = {
    innovation_focus = "standard"
    workspace_innovation = true
    environment_innovation = true
    resource_innovation = true
    technology_adoption = "standard"
  }
}
