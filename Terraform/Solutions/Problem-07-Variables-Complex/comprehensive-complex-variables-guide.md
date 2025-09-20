# Terraform Complex Variables and Validation - Complete Guide

## Overview

This comprehensive guide covers advanced Terraform variable types, complex validation patterns, and enterprise-grade variable management strategies for scalable infrastructure configurations.

## Complex Variable Types

### List Variables

```hcl
# Simple list
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

# List of objects
variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
  
  default = [
    {
      name              = "public-1"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-west-2a"
      public            = true
    },
    {
      name              = "private-1"
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-west-2a"
      public            = false
    }
  ]
  
  validation {
    condition = alltrue([
      for subnet in var.subnets : can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All subnet CIDR blocks must be valid."
  }
}
```

### Map Variables

```hcl
# Map of strings
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "web-app"
    Owner       = "devops-team"
  }
  
  validation {
    condition = alltrue([
      for key, value in var.tags : 
      length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be ≤128 chars, values ≤256 chars."
  }
}

# Map of objects
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    instance_type     = string
    instance_count    = number
    enable_monitoring = bool
    backup_retention  = number
    allowed_cidrs     = list(string)
  }))
  
  default = {
    dev = {
      instance_type     = "t3.micro"
      instance_count    = 1
      enable_monitoring = false
      backup_retention  = 1
      allowed_cidrs     = ["10.0.0.0/8"]
    }
    prod = {
      instance_type     = "t3.large"
      instance_count    = 5
      enable_monitoring = true
      backup_retention  = 30
      allowed_cidrs     = ["10.0.1.0/24"]
    }
  }
}
```

### Object Variables

```hcl
# Complex object structure
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine    = string
    version   = string
    instance_class = string
    allocated_storage = number
    backup_config = object({
      retention_period = number
      backup_window   = string
      maintenance_window = string
    })
    security = object({
      encryption_enabled = bool
      kms_key_id        = optional(string)
      security_groups   = list(string)
    })
  })
  
  validation {
    condition = contains([
      "mysql", "postgres", "oracle", "sqlserver"
    ], var.database_config.engine)
    error_message = "Database engine must be mysql, postgres, oracle, or sqlserver."
  }
  
  validation {
    condition = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}
```

## Advanced Validation Patterns

### Cross-Field Validation

```hcl
variable "server_config" {
  description = "Server configuration"
  type = object({
    instance_type = string
    volume_size   = number
    volume_type   = string
    iops          = optional(number)
  })
  
  validation {
    condition = (
      var.server_config.volume_type != "io1" ||
      (var.server_config.volume_type == "io1" && var.server_config.iops != null)
    )
    error_message = "IOPS must be specified when volume_type is io1."
  }
  
  validation {
    condition = (
      var.server_config.volume_type != "io1" ||
      (var.server_config.iops >= var.server_config.volume_size * 3 &&
       var.server_config.iops <= var.server_config.volume_size * 50)
    )
    error_message = "IOPS must be 3-50x the volume size for io1 volumes."
  }
}
```

### Conditional Validation

```hcl
variable "load_balancer_config" {
  description = "Load balancer configuration"
  type = object({
    type                = string
    scheme             = string
    certificate_arn    = optional(string)
    ssl_policy         = optional(string)
    enable_deletion_protection = bool
  })
  
  validation {
    condition = contains(["application", "network"], var.load_balancer_config.type)
    error_message = "Load balancer type must be 'application' or 'network'."
  }
  
  validation {
    condition = (
      var.load_balancer_config.scheme != "internet-facing" ||
      var.load_balancer_config.certificate_arn != null
    )
    error_message = "Certificate ARN required for internet-facing load balancers."
  }
}
```

### Regular Expression Validation

```hcl
variable "naming_config" {
  description = "Resource naming configuration"
  type = object({
    project_name = string
    environment  = string
    region_code  = string
  })
  
  validation {
    condition = can(regex("^[a-z][a-z0-9-]{2,19}$", var.naming_config.project_name))
    error_message = "Project name must start with letter, contain only lowercase letters, numbers, hyphens, and be 3-20 chars."
  }
  
  validation {
    condition = can(regex("^(dev|test|stage|prod)$", var.naming_config.environment))
    error_message = "Environment must be dev, test, stage, or prod."
  }
  
  validation {
    condition = can(regex("^[a-z]{2}[0-9]$", var.naming_config.region_code))
    error_message = "Region code must be 2 letters followed by 1 number (e.g., us1, eu2)."
  }
}
```

## Variable Composition Patterns

### Hierarchical Configuration

```hcl
variable "infrastructure_config" {
  description = "Complete infrastructure configuration"
  type = object({
    global = object({
      project_name = string
      environment  = string
      region       = string
      tags         = map(string)
    })
    
    networking = object({
      vpc_cidr             = string
      enable_dns_hostnames = bool
      enable_nat_gateway   = bool
      subnets = list(object({
        name              = string
        cidr_block        = string
        availability_zone = string
        type              = string
      }))
    })
    
    compute = object({
      instances = map(object({
        instance_type = string
        count         = number
        subnet_type   = string
        security_groups = list(string)
      }))
    })
    
    database = optional(object({
      engine         = string
      instance_class = string
      storage_size   = number
      multi_az       = bool
    }))
  })
}
```

### Environment-Specific Defaults

```hcl
locals {
  environment_defaults = {
    dev = {
      instance_type     = "t3.micro"
      instance_count    = 1
      enable_monitoring = false
      backup_retention  = 1
      multi_az         = false
    }
    staging = {
      instance_type     = "t3.small"
      instance_count    = 2
      enable_monitoring = true
      backup_retention  = 7
      multi_az         = false
    }
    prod = {
      instance_type     = "t3.medium"
      instance_count    = 3
      enable_monitoring = true
      backup_retention  = 30
      multi_az         = true
    }
  }
  
  # Merge environment defaults with user overrides
  final_config = merge(
    local.environment_defaults[var.environment],
    var.config_overrides
  )
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(keys(local.environment_defaults), var.environment)
    error_message = "Environment must be one of: ${join(", ", keys(local.environment_defaults))}."
  }
}

variable "config_overrides" {
  description = "Configuration overrides"
  type = object({
    instance_type     = optional(string)
    instance_count    = optional(number)
    enable_monitoring = optional(bool)
    backup_retention  = optional(number)
    multi_az         = optional(bool)
  })
  default = {}
}
```

## Dynamic Variable Processing

### Variable Transformation

```hcl
variable "raw_subnets" {
  description = "Raw subnet configuration"
  type = list(object({
    name = string
    cidr = string
    az   = string
    type = string
  }))
}

locals {
  # Transform and enrich subnet configuration
  processed_subnets = {
    for subnet in var.raw_subnets : subnet.name => {
      cidr_block                  = subnet.cidr
      availability_zone          = subnet.az
      map_public_ip_on_launch    = subnet.type == "public"
      
      tags = merge(var.common_tags, {
        Name = "${var.project_name}-${subnet.name}"
        Type = subnet.type
        AZ   = subnet.az
      })
    }
  }
  
  # Separate by type
  public_subnets  = { for k, v in local.processed_subnets : k => v if v.map_public_ip_on_launch }
  private_subnets = { for k, v in local.processed_subnets : k => v if !v.map_public_ip_on_launch }
}
```

### Computed Variables

```hcl
variable "cluster_config" {
  description = "Kubernetes cluster configuration"
  type = object({
    node_groups = map(object({
      instance_types = list(string)
      min_size      = number
      max_size      = number
      desired_size  = number
    }))
  })
}

locals {
  # Compute total cluster capacity
  total_min_nodes = sum([
    for ng in var.cluster_config.node_groups : ng.min_size
  ])
  
  total_max_nodes = sum([
    for ng in var.cluster_config.node_groups : ng.max_size
  ])
  
  # Validate cluster sizing
  cluster_validation = (
    local.total_min_nodes >= 1 && 
    local.total_max_nodes <= 100 &&
    local.total_min_nodes <= local.total_max_nodes
  ) ? null : file("ERROR: Invalid cluster sizing configuration")
}
```

## Variable Security Patterns

### Sensitive Data Handling

```hcl
variable "secrets_config" {
  description = "Secrets configuration"
  type = object({
    database_password_secret_arn = string
    api_keys_secret_arn         = string
    ssl_certificate_secret_arn  = string
  })
  sensitive = true
  
  validation {
    condition = alltrue([
      for arn in values(var.secrets_config) :
      can(regex("^arn:aws:secretsmanager:", arn))
    ])
    error_message = "All secret ARNs must be valid AWS Secrets Manager ARNs."
  }
}

# Use secrets in resources
data "aws_secretsmanager_secret_version" "database_password" {
  secret_id = var.secrets_config.database_password_secret_arn
}

locals {
  database_password = jsondecode(data.aws_secretsmanager_secret_version.database_password.secret_string)["password"]
}
```

### Access Control Variables

```hcl
variable "access_control" {
  description = "Access control configuration"
  type = object({
    admin_users = list(string)
    readonly_users = list(string)
    allowed_cidrs = list(string)
    mfa_required = bool
  })
  
  validation {
    condition = alltrue([
      for cidr in var.access_control.allowed_cidrs :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
  
  validation {
    condition = !contains(var.access_control.allowed_cidrs, "0.0.0.0/0")
    error_message = "Cannot allow access from anywhere (0.0.0.0/0)."
  }
}
```

## Testing Complex Variables

### Variable Testing Framework

```hcl
# test-variables.tf
variable "test_scenarios" {
  description = "Test scenarios for variable validation"
  type = map(object({
    input    = any
    expected = string
  }))
  
  default = {
    valid_config = {
      input = {
        instance_type = "t3.medium"
        count        = 3
        monitoring   = true
      }
      expected = "success"
    }
    invalid_instance_type = {
      input = {
        instance_type = "invalid"
        count        = 3
        monitoring   = true
      }
      expected = "validation_error"
    }
  }
}
```

### Validation Testing Script

```bash
#!/bin/bash
# test-complex-variables.sh

echo "Testing complex variable validation..."

# Test valid configurations
echo "Testing valid configurations..."
for scenario in valid_basic valid_complex valid_minimal; do
    if terraform validate -var-file="test-scenarios/${scenario}.tfvars"; then
        echo "✅ ${scenario}: PASSED"
    else
        echo "❌ ${scenario}: FAILED"
        exit 1
    fi
done

# Test invalid configurations (should fail)
echo "Testing invalid configurations..."
for scenario in invalid_type invalid_range invalid_format; do
    if terraform validate -var-file="test-scenarios/${scenario}.tfvars" 2>/dev/null; then
        echo "❌ ${scenario}: Should have failed but passed"
        exit 1
    else
        echo "✅ ${scenario}: Correctly rejected"
    fi
done

echo "All variable validation tests passed!"
```

## Performance Optimization

### Efficient Variable Processing

```hcl
# Optimize complex variable processing
locals {
  # Pre-compute expensive operations
  subnet_cidrs = [for subnet in var.subnets : subnet.cidr_block]
  
  # Use maps for O(1) lookups instead of lists
  subnet_map = {
    for subnet in var.subnets : subnet.name => subnet
  }
  
  # Cache complex calculations
  network_config = {
    vpc_cidr = var.vpc_cidr
    subnets  = local.subnet_map
    
    # Pre-calculate subnet associations
    public_subnet_names  = [for s in var.subnets : s.name if s.public]
    private_subnet_names = [for s in var.subnets : s.name if !s.public]
  }
}
```

### Memory-Efficient Patterns

```hcl
# Avoid large variable structures in memory
variable "large_dataset_source" {
  description = "Source for large dataset (file path or URL)"
  type        = string
}

# Load data on-demand
data "local_file" "large_dataset" {
  filename = var.large_dataset_source
}

locals {
  # Process data in chunks
  dataset = jsondecode(data.local_file.large_dataset.content)
  
  # Use for expressions for efficient processing
  processed_items = {
    for item in local.dataset.items : item.id => {
      name = item.name
      type = item.type
      # Only include necessary fields
    }
  }
}
```

## Troubleshooting Complex Variables

### Common Issues

#### 1. Type Conversion Errors

```hcl
# Problem: Implicit type conversion
variable "port" {
  type = number
}

# Error when passing string "80"
# Solution: Explicit conversion
locals {
  port_number = tonumber(var.port)
}
```

#### 2. Null Value Handling

```hcl
# Problem: Null values in optional fields
variable "config" {
  type = object({
    name     = string
    optional = optional(string)
  })
}

# Solution: Use coalesce or try
locals {
  safe_optional = coalesce(var.config.optional, "default_value")
  # or
  safe_optional = try(var.config.optional, "default_value")
}
```

#### 3. Complex Validation Debugging

```hcl
# Debug complex validations
variable "debug_config" {
  type = object({
    items = list(string)
  })
  
  validation {
    # Add debug output
    condition = length(var.debug_config.items) > 0
    error_message = "Items list cannot be empty. Received: ${jsonencode(var.debug_config.items)}"
  }
}
```

### Debugging Techniques

```bash
# Debug variable values
terraform console
> var.complex_variable
> local.processed_variable

# Validate specific scenarios
terraform validate -var-file="debug.tfvars"

# Use terraform plan to see computed values
terraform plan -var-file="test.tfvars" | grep -A 10 "local.computed_value"
```

## Best Practices

### 1. Variable Organization

```hcl
# Group related variables
variable "networking" {
  description = "Networking configuration"
  type = object({
    vpc_cidr    = string
    subnets     = list(object({...}))
    nat_gateway = bool
  })
}

variable "compute" {
  description = "Compute configuration"
  type = object({
    instances = map(object({...}))
    scaling   = object({...})
  })
}
```

### 2. Documentation Standards

```hcl
variable "comprehensive_config" {
  description = <<-EOT
    Comprehensive application configuration including:
    
    - networking: VPC and subnet configuration
    - compute: Instance and scaling settings
    - database: RDS configuration (optional)
    - monitoring: CloudWatch and alerting setup
    
    Example:
    {
      networking = {
        vpc_cidr = "10.0.0.0/16"
        subnets = [...]
      }
      compute = {
        instances = {...}
      }
    }
  EOT
  
  type = object({
    networking = object({...})
    compute    = object({...})
    database   = optional(object({...}))
    monitoring = object({...})
  })
}
```

### 3. Validation Strategies

```hcl
# Comprehensive validation
variable "production_config" {
  type = object({...})
  
  # Business logic validation
  validation {
    condition = var.production_config.backup_retention >= 30
    error_message = "Production systems must retain backups for at least 30 days."
  }
  
  # Security validation
  validation {
    condition = var.production_config.encryption_enabled
    error_message = "Encryption must be enabled for production systems."
  }
  
  # Cost validation
  validation {
    condition = var.production_config.instance_count <= 10
    error_message = "Instance count limited to 10 for cost control."
  }
}
```

## Conclusion

Complex variables enable:
- **Sophisticated Configuration**: Handle complex infrastructure requirements
- **Type Safety**: Prevent configuration errors through strong typing
- **Validation**: Ensure configuration correctness and business rules
- **Maintainability**: Organize and structure large configurations

Key takeaways:
- Use appropriate complex types for your use case
- Implement comprehensive validation rules
- Document complex variable structures thoroughly
- Test variable validation scenarios
- Optimize for performance with large datasets
- Follow consistent organization patterns
