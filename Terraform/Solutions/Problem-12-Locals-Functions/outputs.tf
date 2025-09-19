# Outputs for Locals and Functions Demo
# This file demonstrates various output patterns with local values and functions

# Basic Outputs
output "local_values_demo" {
  description = "Demonstration of local values usage"
  value = {
    app_name = local.app_name
    environment = local.environment
    instance_count = local.instance_count
    instance_type = local.instance_type
    availability_zones = local.availability_zones
    subnet_cidrs = local.subnet_cidrs
    common_tags = local.common_tags
  }
}

output "function_results_demo" {
  description = "Demonstration of function results"
  value = {
    string_functions = local.string_functions
    numeric_functions = local.numeric_functions
    collection_functions = local.collection_functions
    encoding_functions = local.encoding_functions
    file_functions = local.file_functions
    template_functions = local.template_functions
  }
}

# String Function Outputs
output "string_function_examples" {
  description = "Examples of string function usage"
  value = {
    upper_case = local.string_functions.upper_case
    lower_case = local.string_functions.lower_case
    title_case = local.string_functions.title_case
    reverse = local.string_functions.reverse
    replace = local.string_functions.replace
    split = local.string_functions.split
    join = local.string_functions.join
    substr = local.string_functions.substr
    trim = local.string_functions.trim
    format = local.string_functions.format
  }
}

# Numeric Function Outputs
output "numeric_function_examples" {
  description = "Examples of numeric function usage"
  value = {
    abs = local.numeric_functions.abs
    ceil = local.numeric_functions.ceil
    floor = local.numeric_functions.floor
    log = local.numeric_functions.log
    max = local.numeric_functions.max
    min = local.numeric_functions.min
    pow = local.numeric_functions.pow
    signum = local.numeric_functions.signum
  }
}

# Collection Function Outputs
output "collection_function_examples" {
  description = "Examples of collection function usage"
  value = {
    all_true = local.collection_functions.all_true
    any_true = local.collection_functions.any_true
    chunklist = local.collection_functions.chunklist
    coalesce = local.collection_functions.coalesce
    coalescelist = local.collection_functions.coalescelist
    compact = local.collection_functions.compact
    concat = local.collection_functions.concat
    contains = local.collection_functions.contains
    distinct = local.collection_functions.distinct
    element = local.collection_functions.element
    index = local.collection_functions.index
    keys = local.collection_functions.keys
    length = local.collection_functions.length
    lookup = local.collection_functions.lookup
    map = local.collection_functions.map
    matchkeys = local.collection_functions.matchkeys
    merge = local.collection_functions.merge
    range = local.collection_functions.range
    reverse = local.collection_functions.reverse
    setintersection = local.collection_functions.setintersection
    setproduct = local.collection_functions.setproduct
    setsubtract = local.collection_functions.setsubtract
    setunion = local.collection_functions.setunion
    slice = local.collection_functions.slice
    sort = local.collection_functions.sort
    sum = local.collection_functions.sum
    transpose = local.collection_functions.transpose
    values = local.collection_functions.values
    zipmap = local.collection_functions.zipmap
  }
}

# Encoding Function Outputs
output "encoding_function_examples" {
  description = "Examples of encoding function usage"
  value = {
    base64encode = local.encoding_functions.base64encode
    base64decode = local.encoding_functions.base64decode
    base64gzip = local.encoding_functions.base64gzip
    base64gunzip = local.encoding_functions.base64gunzip
    csvdecode = local.encoding_functions.csvdecode
    jsonencode = local.encoding_functions.jsonencode
    jsondecode = local.encoding_functions.jsondecode
    urlencode = local.encoding_functions.urlencode
    urldecode = local.encoding_functions.urldecode
    yamlencode = local.encoding_functions.yamlencode
    yamldecode = local.encoding_functions.yamldecode
  }
}

# File Function Outputs
output "file_function_examples" {
  description = "Examples of file function usage"
  value = {
    file = local.file_functions.file
    filebase64 = local.file_functions.filebase64
    filebase64sha256 = local.file_functions.filebase64sha256
    filebase64sha512 = local.file_functions.filebase64sha512
    fileexists = local.file_functions.fileexists
    filemd5 = local.file_functions.filemd5
    filesha1 = local.file_functions.filesha1
    filesha256 = local.file_functions.filesha256
    filesha512 = local.file_functions.filesha512
    pathexpand = local.file_functions.pathexpand
    templatefile = local.file_functions.templatefile
  }
}

# Template Function Outputs
output "template_function_examples" {
  description = "Examples of template function usage"
  value = {
    templatefile = local.template_functions.templatefile
    templatefile_with_vars = local.template_functions.templatefile_with_vars
  }
}

# Advanced Function Outputs
output "advanced_function_examples" {
  description = "Examples of advanced function usage"
  value = {
    try_function = local.try_function
    for_expression = local.for_expression
    conditional_expression = local.conditional_expression
    complex_transformation = local.complex_transformation
  }
}

# Resource Outputs
output "instance_info" {
  description = "Information about created instances"
  value = {
    instance_ids = aws_instance.web[*].id
    instance_ips = aws_instance.web[*].public_ip
    instance_states = aws_instance.web[*].instance_state
    instance_types = aws_instance.web[*].instance_type
    instance_azs = aws_instance.web[*].availability_zone
  }
}

output "security_group_info" {
  description = "Information about security groups"
  value = {
    sg_id = aws_security_group.web.id
    sg_name = aws_security_group.web.name
    sg_description = aws_security_group.web.description
    ingress_rules = aws_security_group.web.ingress
    egress_rules = aws_security_group.web.egress
  }
}

output "vpc_info" {
  description = "Information about VPC"
  value = {
    vpc_id = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    vpc_tags = aws_vpc.main.tags
  }
}

output "subnet_info" {
  description = "Information about subnets"
  value = {
    subnet_ids = aws_subnet.public[*].id
    subnet_cidrs = aws_subnet.public[*].cidr_block
    subnet_azs = aws_subnet.public[*].availability_zone
    subnet_tags = aws_subnet.public[*].tags
  }
}

# Function Combination Outputs
output "function_combinations" {
  description = "Examples of function combinations"
  value = {
    string_and_numeric = {
      formatted_string = format("Instance-%s-%d", local.app_name, local.instance_count)
      calculated_value = pow(local.instance_count, 2)
    }
    collection_and_string = {
      joined_tags = join(", ", [for k, v in local.common_tags : "${k}=${v}"])
      sorted_azs = sort(local.availability_zones)
    }
    encoding_and_file = {
      encoded_config = base64encode(local.file_functions.file)
      json_config = jsonencode(local.common_tags)
    }
  }
}

# Performance Outputs
output "performance_metrics" {
  description = "Performance metrics using functions"
  value = {
    total_resources = length(aws_instance.web) + length(aws_subnet.public) + 1
    resource_distribution = {
      instances = length(aws_instance.web)
      subnets = length(aws_subnet.public)
      security_groups = 1
      vpcs = 1
    }
    cost_estimation = {
      estimated_monthly_cost = local.instance_count * 50
      cost_per_instance = 50
      total_instances = local.instance_count
    }
  }
}

# Monitoring Outputs
output "monitoring_info" {
  description = "Monitoring information using functions"
  value = {
    monitoring_enabled = true
    log_level = local.environment == "production" ? "INFO" : "DEBUG"
    metrics_collection = {
      cpu_utilization = true
      memory_utilization = true
      disk_utilization = true
      network_utilization = true
    }
    alerting_thresholds = {
      cpu_threshold = 80
      memory_threshold = 85
      disk_threshold = 90
    }
  }
}

# Security Outputs
output "security_info" {
  description = "Security information using functions"
  value = {
    security_level = local.environment == "production" ? "high" : "standard"
    encryption_enabled = true
    backup_enabled = local.environment == "production" ? true : false
    monitoring_enabled = true
    compliance_checks = {
      encryption_at_rest = true
      encryption_in_transit = true
      access_logging = true
      audit_logging = local.environment == "production" ? true : false
    }
  }
}

# Compliance Outputs
output "compliance_info" {
  description = "Compliance information using functions"
  value = {
    environment = local.environment
    compliance_level = local.environment == "production" ? "high" : "standard"
    audit_logging = local.environment == "production" ? true : false
    data_retention = local.environment == "production" ? 365 : 90
    access_controls = {
      mfa_required = local.environment == "production" ? true : false
      role_based_access = true
      least_privilege = true
    }
  }
}

# Backup Outputs
output "backup_info" {
  description = "Backup information using functions"
  value = {
    backup_enabled = local.environment == "production" ? true : false
    backup_frequency = local.environment == "production" ? "daily" : "weekly"
    backup_retention = local.environment == "production" ? 30 : 7
    cross_region_backup = local.environment == "production" ? true : false
    backup_encryption = true
  }
}

# Disaster Recovery Outputs
output "disaster_recovery_info" {
  description = "Disaster recovery information using functions"
  value = {
    dr_enabled = local.environment == "production" ? true : false
    rto = local.environment == "production" ? "4 hours" : "24 hours"
    rpo = local.environment == "production" ? "1 hour" : "12 hours"
    failover_automation = local.environment == "production" ? true : false
    cross_region_replication = local.environment == "production" ? true : false
  }
}

# Performance Optimization Outputs
output "performance_optimization_info" {
  description = "Performance optimization information using functions"
  value = {
    performance_tier = local.environment == "production" ? "high" : "standard"
    caching_enabled = local.environment == "production" ? true : false
    cdn_enabled = local.environment == "production" ? true : false
    load_balancing = local.environment == "production" ? true : false
    auto_scaling = local.environment == "production" ? true : false
  }
}

# Scalability Outputs
output "scalability_info" {
  description = "Scalability information using functions"
  value = {
    auto_scaling_enabled = local.environment == "production" ? true : false
    min_capacity = local.environment == "production" ? 2 : 1
    max_capacity = local.environment == "production" ? 10 : 3
    target_capacity = local.environment == "production" ? 5 : 2
    scaling_policies = {
      scale_up_threshold = 70
      scale_down_threshold = 30
      scale_up_cooldown = 300
      scale_down_cooldown = 300
    }
  }
}

# Maintenance Outputs
output "maintenance_info" {
  description = "Maintenance information using functions"
  value = {
    maintenance_window = local.environment == "production" ? "Sunday 02:00-04:00 UTC" : "Anytime"
    auto_updates = local.environment == "production" ? false : true
    maintenance_mode = local.environment == "production" ? "scheduled" : "immediate"
    rollback_enabled = true
    health_checks = {
      liveness_probe = true
      readiness_probe = true
      startup_probe = true
    }
  }
}

# Documentation Outputs
output "documentation_info" {
  description = "Documentation information using functions"
  value = {
    documentation_level = local.environment == "production" ? "comprehensive" : "standard"
    api_documentation = local.environment == "production" ? true : false
    user_guide = local.environment == "production" ? true : false
    technical_specifications = local.environment == "production" ? true : false
    runbooks = local.environment == "production" ? true : false
  }
}

# Support Outputs
output "support_info" {
  description = "Support information using functions"
  value = {
    support_level = local.environment == "production" ? "24/7" : "business hours"
    escalation_process = local.environment == "production" ? "immediate" : "standard"
    monitoring_team = local.environment == "production" ? "dedicated" : "shared"
    incident_response = local.environment == "production" ? "immediate" : "standard"
    post_incident_review = local.environment == "production" ? "mandatory" : "optional"
  }
}

# Training Outputs
output "training_info" {
  description = "Training information using functions"
  value = {
    training_level = local.environment == "production" ? "advanced" : "basic"
    certification_required = local.environment == "production" ? true : false
    ongoing_education = local.environment == "production" ? "mandatory" : "optional"
    hands_on_training = true
    simulation_exercises = local.environment == "production" ? true : false
  }
}

# Governance Outputs
output "governance_info" {
  description = "Governance information using functions"
  value = {
    governance_level = local.environment == "production" ? "strict" : "standard"
    approval_process = local.environment == "production" ? "multi-level" : "single-level"
    change_management = local.environment == "production" ? "formal" : "informal"
    policy_compliance = true
    audit_trail = local.environment == "production" ? true : false
  }
}

# Risk Management Outputs
output "risk_management_info" {
  description = "Risk management information using functions"
  value = {
    risk_level = local.environment == "production" ? "high" : "medium"
    risk_assessment = local.environment == "production" ? "quarterly" : "annually"
    risk_mitigation = local.environment == "production" ? "comprehensive" : "standard"
    business_continuity = local.environment == "production" ? true : false
    disaster_recovery = local.environment == "production" ? true : false
  }
}

# Quality Assurance Outputs
output "quality_assurance_info" {
  description = "Quality assurance information using functions"
  value = {
    qa_process = local.environment == "production" ? "comprehensive" : "standard"
    testing_level = local.environment == "production" ? "extensive" : "basic"
    quality_gates = local.environment == "production" ? "mandatory" : "optional"
    automated_testing = true
    performance_testing = local.environment == "production" ? true : false
  }
}

# Operations Outputs
output "operations_info" {
  description = "Operations information using functions"
  value = {
    operations_level = local.environment == "production" ? "dedicated" : "shared"
    incident_response = local.environment == "production" ? "immediate" : "standard"
    post_incident_review = local.environment == "production" ? "mandatory" : "optional"
    capacity_planning = local.environment == "production" ? true : false
    performance_monitoring = true
  }
}

# Innovation Outputs
output "innovation_info" {
  description = "Innovation information using functions"
  value = {
    innovation_focus = local.environment == "production" ? "stability" : "experimentation"
    new_feature_rollout = local.environment == "production" ? "gradual" : "immediate"
    experimental_features = local.environment == "production" ? false : true
    research_and_development = true
    technology_adoption = local.environment == "production" ? "conservative" : "aggressive"
  }
}
