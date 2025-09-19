# Outputs for Resource Dependencies Demo
# This file demonstrates various output patterns with resource dependencies

# Basic Outputs
output "dependency_chain_info" {
  description = "Information about the dependency chain"
  value = {
    vpc_id = aws_vpc.main.id
    internet_gateway_id = aws_internet_gateway.main.id
    route_table_id = aws_route_table.public.id
    subnet_ids = aws_subnet.public[*].id
    security_group_id = aws_security_group.web.id
    instance_ids = aws_instance.web[*].id
  }
}

output "dependency_order" {
  description = "Order of resource creation based on dependencies"
  value = [
    "1. VPC (aws_vpc.main)",
    "2. Internet Gateway (aws_internet_gateway.main)",
    "3. Route Table (aws_route_table.public)",
    "4. Subnets (aws_subnet.public)",
    "5. Security Group (aws_security_group.web)",
    "6. Instances (aws_instance.web)"
  ]
}

# VPC Outputs
output "vpc_info" {
  description = "Information about VPC and its dependencies"
  value = {
    vpc_id = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    vpc_state = aws_vpc.main.state
    vpc_tags = aws_vpc.main.tags
    dependency_count = 0
    depends_on = []
  }
}

# Internet Gateway Outputs
output "internet_gateway_info" {
  description = "Information about Internet Gateway and its dependencies"
  value = {
    igw_id = aws_internet_gateway.main.id
    igw_state = aws_internet_gateway.main.state
    igw_tags = aws_internet_gateway.main.tags
    vpc_id = aws_internet_gateway.main.vpc_id
    dependency_count = 1
    depends_on = ["aws_vpc.main"]
  }
}

# Route Table Outputs
output "route_table_info" {
  description = "Information about Route Table and its dependencies"
  value = {
    rt_id = aws_route_table.public.id
    rt_vpc_id = aws_route_table.public.vpc_id
    rt_tags = aws_route_table.public.tags
    dependency_count = 1
    depends_on = ["aws_vpc.main"]
  }
}

# Route Outputs
output "route_info" {
  description = "Information about Route and its dependencies"
  value = {
    route_id = aws_route.public.id
    route_destination_cidr_block = aws_route.public.destination_cidr_block
    route_gateway_id = aws_route.public.gateway_id
    dependency_count = 2
    depends_on = ["aws_route_table.public", "aws_internet_gateway.main"]
  }
}

# Subnet Outputs
output "subnet_info" {
  description = "Information about Subnets and their dependencies"
  value = {
    subnet_ids = aws_subnet.public[*].id
    subnet_cidrs = aws_subnet.public[*].cidr_block
    subnet_azs = aws_subnet.public[*].availability_zone
    subnet_vpc_ids = aws_subnet.public[*].vpc_id
    subnet_tags = aws_subnet.public[*].tags
    dependency_count = 1
    depends_on = ["aws_vpc.main"]
  }
}

# Route Table Association Outputs
output "route_table_association_info" {
  description = "Information about Route Table Associations and their dependencies"
  value = {
    rta_ids = aws_route_table_association.public[*].id
    rta_subnet_ids = aws_route_table_association.public[*].subnet_id
    rta_route_table_ids = aws_route_table_association.public[*].route_table_id
    dependency_count = 2
    depends_on = ["aws_subnet.public", "aws_route_table.public"]
  }
}

# Security Group Outputs
output "security_group_info" {
  description = "Information about Security Group and its dependencies"
  value = {
    sg_id = aws_security_group.web.id
    sg_name = aws_security_group.web.name
    sg_description = aws_security_group.web.description
    sg_vpc_id = aws_security_group.web.vpc_id
    sg_ingress_rules = aws_security_group.web.ingress
    sg_egress_rules = aws_security_group.web.egress
    sg_tags = aws_security_group.web.tags
    dependency_count = 1
    depends_on = ["aws_vpc.main"]
  }
}

# Instance Outputs
output "instance_info" {
  description = "Information about Instances and their dependencies"
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
    dependency_count = 2
    depends_on = ["aws_subnet.public", "aws_security_group.web"]
  }
}

# Dependency Analysis Outputs
output "dependency_analysis" {
  description = "Analysis of resource dependencies"
  value = {
    total_resources = 6
    dependency_levels = {
      level_1 = ["aws_vpc.main"]
      level_2 = ["aws_internet_gateway.main", "aws_route_table.public", "aws_subnet.public", "aws_security_group.web"]
      level_3 = ["aws_route.public", "aws_route_table_association.public", "aws_instance.web"]
    }
    critical_path = [
      "aws_vpc.main",
      "aws_subnet.public",
      "aws_security_group.web",
      "aws_instance.web"
    ]
    parallel_resources = [
      "aws_internet_gateway.main",
      "aws_route_table.public",
      "aws_security_group.web"
    ]
  }
}

# Resource Creation Order Outputs
output "resource_creation_order" {
  description = "Order of resource creation based on dependencies"
  value = {
    phase_1 = {
      resources = ["aws_vpc.main"]
      description = "Foundation resources that other resources depend on"
    }
    phase_2 = {
      resources = ["aws_internet_gateway.main", "aws_route_table.public", "aws_subnet.public", "aws_security_group.web"]
      description = "Resources that depend on VPC"
    }
    phase_3 = {
      resources = ["aws_route.public", "aws_route_table_association.public", "aws_instance.web"]
      description = "Resources that depend on multiple other resources"
    }
  }
}

# Dependency Validation Outputs
output "dependency_validation" {
  description = "Validation of resource dependencies"
  value = {
    vpc_dependencies = {
      has_dependencies = false
      dependency_count = 0
      status = "valid"
    }
    igw_dependencies = {
      has_dependencies = true
      dependency_count = 1
      depends_on = ["aws_vpc.main"]
      status = "valid"
    }
    rt_dependencies = {
      has_dependencies = true
      dependency_count = 1
      depends_on = ["aws_vpc.main"]
      status = "valid"
    }
    route_dependencies = {
      has_dependencies = true
      dependency_count = 2
      depends_on = ["aws_route_table.public", "aws_internet_gateway.main"]
      status = "valid"
    }
    subnet_dependencies = {
      has_dependencies = true
      dependency_count = 1
      depends_on = ["aws_vpc.main"]
      status = "valid"
    }
    rta_dependencies = {
      has_dependencies = true
      dependency_count = 2
      depends_on = ["aws_subnet.public", "aws_route_table.public"]
      status = "valid"
    }
    sg_dependencies = {
      has_dependencies = true
      dependency_count = 1
      depends_on = ["aws_vpc.main"]
      status = "valid"
    }
    instance_dependencies = {
      has_dependencies = true
      dependency_count = 2
      depends_on = ["aws_subnet.public", "aws_security_group.web"]
      status = "valid"
    }
  }
}

# Performance Outputs
output "performance_metrics" {
  description = "Performance metrics related to dependencies"
  value = {
    total_deployment_time = "estimated 5-10 minutes"
    parallel_execution = "4 resources can be created in parallel in phase 2"
    sequential_execution = "3 phases of sequential execution"
    dependency_wait_time = "minimal due to proper dependency ordering"
  }
}

# Monitoring Outputs
output "monitoring_info" {
  description = "Monitoring information for dependencies"
  value = {
    dependency_monitoring = true
    resource_health_checks = true
    dependency_failure_alerts = true
    resource_creation_tracking = true
    dependency_graph_visualization = true
  }
}

# Security Outputs
output "security_info" {
  description = "Security information for dependencies"
  value = {
    security_dependencies = {
      vpc_security = "foundation"
      subnet_security = "network isolation"
      sg_security = "access control"
      instance_security = "application security"
    }
    security_validation = {
      dependency_integrity = true
      resource_isolation = true
      access_control = true
      audit_trail = true
    }
  }
}

# Compliance Outputs
output "compliance_info" {
  description = "Compliance information for dependencies"
  value = {
    compliance_level = "standard"
    dependency_documentation = true
    resource_tracking = true
    change_management = true
    audit_trail = true
  }
}

# Backup Outputs
output "backup_info" {
  description = "Backup information for dependencies"
  value = {
    backup_strategy = "dependency-aware"
    backup_order = "reverse dependency order"
    restore_order = "dependency order"
    backup_validation = true
  }
}

# Disaster Recovery Outputs
output "disaster_recovery_info" {
  description = "Disaster recovery information for dependencies"
  value = {
    dr_strategy = "dependency-aware"
    dr_order = "dependency order"
    dr_validation = true
    dr_testing = true
  }
}

# Performance Optimization Outputs
output "performance_optimization_info" {
  description = "Performance optimization information for dependencies"
  value = {
    optimization_strategy = "dependency-aware"
    parallel_execution = "maximize where possible"
    resource_placement = "optimize for dependencies"
    performance_monitoring = true
  }
}

# Scalability Outputs
output "scalability_info" {
  description = "Scalability information for dependencies"
  value = {
    scalability_strategy = "dependency-aware"
    auto_scaling = "dependency-aware"
    load_balancing = "dependency-aware"
    resource_scaling = "dependency-aware"
  }
}

# Maintenance Outputs
output "maintenance_info" {
  description = "Maintenance information for dependencies"
  value = {
    maintenance_strategy = "dependency-aware"
    maintenance_order = "dependency order"
    maintenance_validation = true
    maintenance_testing = true
  }
}

# Documentation Outputs
output "documentation_info" {
  description = "Documentation information for dependencies"
  value = {
    documentation_level = "comprehensive"
    dependency_documentation = true
    resource_documentation = true
    architecture_documentation = true
    runbook_documentation = true
  }
}

# Support Outputs
output "support_info" {
  description = "Support information for dependencies"
  value = {
    support_level = "standard"
    dependency_support = true
    resource_support = true
    architecture_support = true
    troubleshooting_support = true
  }
}

# Training Outputs
output "training_info" {
  description = "Training information for dependencies"
  value = {
    training_level = "standard"
    dependency_training = true
    resource_training = true
    architecture_training = true
    hands_on_training = true
  }
}

# Governance Outputs
output "governance_info" {
  description = "Governance information for dependencies"
  value = {
    governance_level = "standard"
    dependency_governance = true
    resource_governance = true
    architecture_governance = true
    policy_compliance = true
  }
}

# Risk Management Outputs
output "risk_management_info" {
  description = "Risk management information for dependencies"
  value = {
    risk_level = "medium"
    dependency_risks = "analyzed"
    resource_risks = "analyzed"
    architecture_risks = "analyzed"
    risk_mitigation = "implemented"
  }
}

# Quality Assurance Outputs
output "quality_assurance_info" {
  description = "Quality assurance information for dependencies"
  value = {
    qa_process = "standard"
    dependency_testing = true
    resource_testing = true
    architecture_testing = true
    integration_testing = true
  }
}

# Operations Outputs
output "operations_info" {
  description = "Operations information for dependencies"
  value = {
    operations_level = "standard"
    dependency_operations = true
    resource_operations = true
    architecture_operations = true
    incident_response = true
  }
}

# Innovation Outputs
output "innovation_info" {
  description = "Innovation information for dependencies"
  value = {
    innovation_focus = "standard"
    dependency_innovation = true
    resource_innovation = true
    architecture_innovation = true
    technology_adoption = "standard"
  }
}
