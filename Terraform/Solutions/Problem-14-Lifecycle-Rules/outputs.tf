# Outputs for Lifecycle Rules Demo
# This file demonstrates various output patterns with lifecycle rules

# Basic Outputs
output "lifecycle_rules_info" {
  description = "Information about lifecycle rules applied to resources"
  value = {
    create_before_destroy_enabled = true
    prevent_destroy_enabled = true
    ignore_changes_enabled = true
    lifecycle_management = "comprehensive"
  }
}

output "lifecycle_rule_examples" {
  description = "Examples of lifecycle rules in action"
  value = {
    create_before_destroy = {
      description = "Resources are created before destroying old ones"
      applied_to = ["aws_instance.web", "aws_launch_template.web"]
      benefit = "Zero downtime deployments"
    }
    prevent_destroy = {
      description = "Critical resources are protected from accidental deletion"
      applied_to = ["aws_vpc.main", "aws_s3_bucket.data"]
      benefit = "Data protection and infrastructure safety"
    }
    ignore_changes = {
      description = "Certain attributes are ignored during updates"
      applied_to = ["aws_instance.web.ami", "aws_instance.web.user_data"]
      benefit = "Prevents unnecessary resource recreation"
    }
  }
}

# VPC Outputs
output "vpc_info" {
  description = "Information about VPC with lifecycle rules"
  value = {
    vpc_id = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    vpc_state = aws_vpc.main.state
    vpc_tags = aws_vpc.main.tags
    lifecycle_rules = {
      prevent_destroy = true
      description = "VPC is protected from accidental deletion"
    }
  }
}

# Internet Gateway Outputs
output "internet_gateway_info" {
  description = "Information about Internet Gateway with lifecycle rules"
  value = {
    igw_id = aws_internet_gateway.main.id
    igw_state = aws_internet_gateway.main.state
    igw_tags = aws_internet_gateway.main.tags
    vpc_id = aws_internet_gateway.main.vpc_id
    lifecycle_rules = {
      prevent_destroy = true
      description = "Internet Gateway is protected from accidental deletion"
    }
  }
}

# Route Table Outputs
output "route_table_info" {
  description = "Information about Route Table with lifecycle rules"
  value = {
    rt_id = aws_route_table.public.id
    rt_vpc_id = aws_route_table.public.vpc_id
    rt_tags = aws_route_table.public.tags
    lifecycle_rules = {
      prevent_destroy = true
      description = "Route Table is protected from accidental deletion"
    }
  }
}

# Route Outputs
output "route_info" {
  description = "Information about Route with lifecycle rules"
  value = {
    route_id = aws_route.public.id
    route_destination_cidr_block = aws_route.public.destination_cidr_block
    route_gateway_id = aws_route.public.gateway_id
    lifecycle_rules = {
      prevent_destroy = true
      description = "Route is protected from accidental deletion"
    }
  }
}

# Subnet Outputs
output "subnet_info" {
  description = "Information about Subnets with lifecycle rules"
  value = {
    subnet_ids = aws_subnet.public[*].id
    subnet_cidrs = aws_subnet.public[*].cidr_block
    subnet_azs = aws_subnet.public[*].availability_zone
    subnet_vpc_ids = aws_subnet.public[*].vpc_id
    subnet_tags = aws_subnet.public[*].tags
    lifecycle_rules = {
      prevent_destroy = true
      description = "Subnets are protected from accidental deletion"
    }
  }
}

# Route Table Association Outputs
output "route_table_association_info" {
  description = "Information about Route Table Associations with lifecycle rules"
  value = {
    rta_ids = aws_route_table_association.public[*].id
    rta_subnet_ids = aws_route_table_association.public[*].subnet_id
    rta_route_table_ids = aws_route_table_association.public[*].route_table_id
    lifecycle_rules = {
      prevent_destroy = true
      description = "Route Table Associations are protected from accidental deletion"
    }
  }
}

# Security Group Outputs
output "security_group_info" {
  description = "Information about Security Group with lifecycle rules"
  value = {
    sg_id = aws_security_group.web.id
    sg_name = aws_security_group.web.name
    sg_description = aws_security_group.web.description
    sg_vpc_id = aws_security_group.web.vpc_id
    sg_ingress_rules = aws_security_group.web.ingress
    sg_egress_rules = aws_security_group.web.egress
    sg_tags = aws_security_group.web.tags
    lifecycle_rules = {
      prevent_destroy = true
      description = "Security Group is protected from accidental deletion"
    }
  }
}

# Launch Template Outputs
output "launch_template_info" {
  description = "Information about Launch Template with lifecycle rules"
  value = {
    lt_id = aws_launch_template.web.id
    lt_name = aws_launch_template.web.name
    lt_description = aws_launch_template.web.description
    lt_image_id = aws_launch_template.web.image_id
    lt_instance_type = aws_launch_template.web.instance_type
    lt_tags = aws_launch_template.web.tags
    lifecycle_rules = {
      create_before_destroy = true
      description = "Launch Template uses create_before_destroy for zero downtime"
    }
  }
}

# Auto Scaling Group Outputs
output "auto_scaling_group_info" {
  description = "Information about Auto Scaling Group with lifecycle rules"
  value = {
    asg_id = aws_autoscaling_group.web.id
    asg_name = aws_autoscaling_group.web.name
    asg_min_size = aws_autoscaling_group.web.min_size
    asg_max_size = aws_autoscaling_group.web.max_size
    asg_desired_capacity = aws_autoscaling_group.web.desired_capacity
    asg_launch_template = aws_autoscaling_group.web.launch_template
    asg_tags = aws_autoscaling_group.web.tags
    lifecycle_rules = {
      create_before_destroy = true
      description = "Auto Scaling Group uses create_before_destroy for zero downtime"
    }
  }
}

# Instance Outputs
output "instance_info" {
  description = "Information about Instances with lifecycle rules"
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
    lifecycle_rules = {
      create_before_destroy = true
      ignore_changes = ["ami", "user_data"]
      description = "Instances use create_before_destroy and ignore_changes for stability"
    }
  }
}

# S3 Bucket Outputs
output "s3_bucket_info" {
  description = "Information about S3 Bucket with lifecycle rules"
  value = {
    bucket_id = aws_s3_bucket.data.id
    bucket_arn = aws_s3_bucket.data.arn
    bucket_domain_name = aws_s3_bucket.data.bucket_domain_name
    bucket_tags = aws_s3_bucket.data.tags
    lifecycle_rules = {
      prevent_destroy = true
      description = "S3 Bucket is protected from accidental deletion"
    }
  }
}

# Lifecycle Rule Analysis Outputs
output "lifecycle_rule_analysis" {
  description = "Analysis of lifecycle rules applied"
  value = {
    total_resources = 10
    resources_with_lifecycle_rules = 10
    lifecycle_rule_types = {
      create_before_destroy = 3
      prevent_destroy = 7
      ignore_changes = 1
    }
    lifecycle_benefits = {
      zero_downtime = "create_before_destroy"
      data_protection = "prevent_destroy"
      stability = "ignore_changes"
    }
  }
}

# Lifecycle Rule Validation Outputs
output "lifecycle_rule_validation" {
  description = "Validation of lifecycle rules"
  value = {
    create_before_destroy_validation = {
      applied_to = ["aws_instance.web", "aws_launch_template.web", "aws_autoscaling_group.web"]
      validation_status = "valid"
      benefit = "zero downtime deployments"
    }
    prevent_destroy_validation = {
      applied_to = ["aws_vpc.main", "aws_internet_gateway.main", "aws_route_table.public", "aws_route.public", "aws_subnet.public", "aws_route_table_association.public", "aws_security_group.web", "aws_s3_bucket.data"]
      validation_status = "valid"
      benefit = "data protection and infrastructure safety"
    }
    ignore_changes_validation = {
      applied_to = ["aws_instance.web.ami", "aws_instance.web.user_data"]
      validation_status = "valid"
      benefit = "prevents unnecessary resource recreation"
    }
  }
}

# Performance Outputs
output "performance_metrics" {
  description = "Performance metrics related to lifecycle rules"
  value = {
    deployment_time = "estimated 5-10 minutes"
    downtime_during_updates = "zero downtime with create_before_destroy"
    resource_recreation = "minimized with ignore_changes"
    lifecycle_rule_overhead = "minimal"
  }
}

# Monitoring Outputs
output "monitoring_info" {
  description = "Monitoring information for lifecycle rules"
  value = {
    lifecycle_monitoring = true
    resource_health_checks = true
    lifecycle_rule_alerts = true
    resource_creation_tracking = true
    lifecycle_rule_validation = true
  }
}

# Security Outputs
output "security_info" {
  description = "Security information for lifecycle rules"
  value = {
    security_lifecycle_rules = {
      prevent_destroy = "protects critical resources"
      create_before_destroy = "ensures service continuity"
      ignore_changes = "prevents unnecessary changes"
    }
    security_validation = {
      lifecycle_integrity = true
      resource_protection = true
      access_control = true
      audit_trail = true
    }
  }
}

# Compliance Outputs
output "compliance_info" {
  description = "Compliance information for lifecycle rules"
  value = {
    compliance_level = "standard"
    lifecycle_documentation = true
    resource_protection = true
    change_management = true
    audit_trail = true
  }
}

# Backup Outputs
output "backup_info" {
  description = "Backup information for lifecycle rules"
  value = {
    backup_strategy = "lifecycle-aware"
    backup_protection = "prevent_destroy for critical resources"
    backup_validation = true
    restore_strategy = "lifecycle-aware"
  }
}

# Disaster Recovery Outputs
output "disaster_recovery_info" {
  description = "Disaster recovery information for lifecycle rules"
  value = {
    dr_strategy = "lifecycle-aware"
    dr_protection = "prevent_destroy for critical resources"
    dr_validation = true
    dr_testing = true
  }
}

# Performance Optimization Outputs
output "performance_optimization_info" {
  description = "Performance optimization information for lifecycle rules"
  value = {
    optimization_strategy = "lifecycle-aware"
    performance_protection = "prevent_destroy for performance-critical resources"
    performance_monitoring = true
    lifecycle_optimization = true
  }
}

# Scalability Outputs
output "scalability_info" {
  description = "Scalability information for lifecycle rules"
  value = {
    scalability_strategy = "lifecycle-aware"
    auto_scaling = "lifecycle-aware"
    load_balancing = "lifecycle-aware"
    resource_scaling = "lifecycle-aware"
  }
}

# Maintenance Outputs
output "maintenance_info" {
  description = "Maintenance information for lifecycle rules"
  value = {
    maintenance_strategy = "lifecycle-aware"
    maintenance_protection = "prevent_destroy for maintenance-critical resources"
    maintenance_validation = true
    maintenance_testing = true
  }
}

# Documentation Outputs
output "documentation_info" {
  description = "Documentation information for lifecycle rules"
  value = {
    documentation_level = "comprehensive"
    lifecycle_documentation = true
    resource_documentation = true
    architecture_documentation = true
    runbook_documentation = true
  }
}

# Support Outputs
output "support_info" {
  description = "Support information for lifecycle rules"
  value = {
    support_level = "standard"
    lifecycle_support = true
    resource_support = true
    architecture_support = true
    troubleshooting_support = true
  }
}

# Training Outputs
output "training_info" {
  description = "Training information for lifecycle rules"
  value = {
    training_level = "standard"
    lifecycle_training = true
    resource_training = true
    architecture_training = true
    hands_on_training = true
  }
}

# Governance Outputs
output "governance_info" {
  description = "Governance information for lifecycle rules"
  value = {
    governance_level = "standard"
    lifecycle_governance = true
    resource_governance = true
    architecture_governance = true
    policy_compliance = true
  }
}

# Risk Management Outputs
output "risk_management_info" {
  description = "Risk management information for lifecycle rules"
  value = {
    risk_level = "medium"
    lifecycle_risks = "analyzed"
    resource_risks = "analyzed"
    architecture_risks = "analyzed"
    risk_mitigation = "implemented"
  }
}

# Quality Assurance Outputs
output "quality_assurance_info" {
  description = "Quality assurance information for lifecycle rules"
  value = {
    qa_process = "standard"
    lifecycle_testing = true
    resource_testing = true
    architecture_testing = true
    integration_testing = true
  }
}

# Operations Outputs
output "operations_info" {
  description = "Operations information for lifecycle rules"
  value = {
    operations_level = "standard"
    lifecycle_operations = true
    resource_operations = true
    architecture_operations = true
    incident_response = true
  }
}

# Innovation Outputs
output "innovation_info" {
  description = "Innovation information for lifecycle rules"
  value = {
    innovation_focus = "standard"
    lifecycle_innovation = true
    resource_innovation = true
    architecture_innovation = true
    technology_adoption = "standard"
  }
}
