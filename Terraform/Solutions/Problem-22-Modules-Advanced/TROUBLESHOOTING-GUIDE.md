# Advanced Modules Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers advanced troubleshooting techniques for complex Terraform module implementations, enterprise-scale issues, and sophisticated debugging scenarios.

## 📋 Table of Contents

1. [Module Dependency Issues](#module-dependency-issues)
2. [Complex Variable Validation Problems](#complex-variable-validation-problems)
3. [Dynamic Block and Conditional Logic Issues](#dynamic-block-and-conditional-logic-issues)
4. [Cross-Module Data Flow Problems](#cross-module-data-flow-problems)
5. [Performance and Scalability Issues](#performance-and-scalability-issues)
6. [Enterprise Governance Challenges](#enterprise-governance-challenges)
7. [Advanced Debugging Techniques](#advanced-debugging-techniques)
8. [Prevention Strategies](#prevention-strategies)

---

## 🔗 Module Dependency Issues

### Problem: Circular Dependencies Between Modules

**Symptoms:**
```
Error: Cycle found: module.compute -> module.networking -> module.compute
```

**Root Causes:**
- Modules referencing each other's outputs
- Complex interdependencies not properly designed
- Missing intermediate data sources

**Solutions:**

#### Solution 1: Restructure Module Hierarchy
```hcl
# ❌ Problematic: Circular dependency
module "networking" {
  source = "./modules/networking"
  compute_security_groups = module.compute.security_group_ids
}

module "compute" {
  source = "./modules/compute"
  subnet_ids = module.networking.subnet_ids
}

# ✅ Solution: Use data sources or restructure
module "networking" {
  source = "./modules/networking"
  # Remove direct compute dependency
}

module "compute" {
  source = "./modules/compute"
  subnet_ids = module.networking.subnet_ids
  # Get security groups from networking module
  security_group_ids = module.networking.security_group_ids
}
```

#### Solution 2: Use Data Sources for Cross-References
```hcl
# ✅ Use data sources to break circular dependencies
data "aws_security_groups" "existing" {
  filter {
    name   = "group-name"
    values = ["existing-security-group"]
  }
}

module "compute" {
  source = "./modules/compute"
  subnet_ids = module.networking.subnet_ids
  security_group_ids = data.aws_security_groups.existing.ids
}
```

### Problem: Module Version Conflicts

**Symptoms:**
```
Error: Module version conflict: module.networking requires provider version >= 4.0, but current version is 3.74.0
```

**Solutions:**

#### Solution 1: Consistent Provider Versioning
```hcl
# ✅ Specify consistent provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Consistent across all modules
    }
  }
}
```

#### Solution 2: Module Version Constraints
```hcl
# ✅ Use version constraints in module sources
module "networking" {
  source  = "git::https://github.com/company/terraform-modules.git//networking?ref=v2.1.0"
  # Module configuration...
}
```

---

## 🔍 Complex Variable Validation Problems

### Problem: Validation Rules Too Restrictive

**Symptoms:**
```
Error: Invalid value for variable "instance_types": instance type "t3.micro" is not allowed in production environment
```

**Root Causes:**
- Overly strict validation rules
- Environment-specific constraints not properly handled
- Missing conditional validation logic

**Solutions:**

#### Solution 1: Conditional Validation
```hcl
# ✅ Use conditional validation based on environment
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = var.environment == "development" ? 
      contains(["t3.micro", "t3.small"], var.instance_type) :
      contains(["t3.small", "t3.medium", "t3.large"], var.instance_type)
    error_message = "Instance type must be appropriate for the environment."
  }
}
```

#### Solution 2: Flexible Validation with Warnings
```hcl
# ✅ Use locals for complex validation logic
locals {
  # Validate instance type appropriateness
  instance_type_valid = var.environment == "development" ? 
    contains(["t3.micro", "t3.small"], var.instance_type) :
    contains(["t3.small", "t3.medium", "t3.large", "t3.xlarge"], var.instance_type)
  
  # Provide helpful error message
  validation_error = local.instance_type_valid ? null : 
    "Instance type ${var.instance_type} is not recommended for ${var.environment} environment"
}

# Use validation in resource creation
resource "aws_instance" "example" {
  count = local.instance_type_valid ? 1 : 0
  # Resource configuration...
}
```

### Problem: Complex Object Validation Failures

**Symptoms:**
```
Error: Invalid value for variable "networking_config": missing required field "subnet_configuration"
```

**Solutions:**

#### Solution 1: Nested Object Validation
```hcl
# ✅ Comprehensive nested object validation
variable "networking_config" {
  description = "Networking configuration"
  type = object({
    vpc_cidr = string
    availability_zones = list(string)
    subnet_configuration = object({
      public_subnets = list(object({
        cidr_block = string
        az          = string
      }))
      private_subnets = list(object({
        cidr_block = string
        az          = string
      }))
    })
  })
  
  validation {
    condition = length(var.networking_config.subnet_configuration.public_subnets) > 0
    error_message = "At least one public subnet must be configured."
  }
  
  validation {
    condition = length(var.networking_config.subnet_configuration.private_subnets) > 0
    error_message = "At least one private subnet must be configured."
  }
}
```

---

## 🔄 Dynamic Block and Conditional Logic Issues

### Problem: Dynamic Blocks Not Rendering Correctly

**Symptoms:**
```
Error: Invalid dynamic block: expected "content" block
```

**Root Causes:**
- Incorrect dynamic block syntax
- Missing content blocks
- Complex iteration logic errors

**Solutions:**

#### Solution 1: Proper Dynamic Block Structure
```hcl
# ✅ Correct dynamic block syntax
resource "aws_security_group" "example" {
  name_prefix = "example-"
  vpc_id      = var.vpc_id
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}
```

#### Solution 2: Conditional Dynamic Blocks
```hcl
# ✅ Conditional dynamic blocks
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Conditional additional volumes
  dynamic "ebs_block_device" {
    for_each = var.enable_additional_storage ? var.additional_volumes : []
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
      encrypted   = ebs_block_device.value.encrypted
    }
  }
  
  # Conditional user data
  user_data = var.enable_user_data ? base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    app_config  = var.app_configuration
  })) : null
}
```

### Problem: Complex Conditional Resource Creation

**Symptoms:**
```
Error: Resource count must be a whole number, got 0.5
```

**Solutions:**

#### Solution 1: Proper Conditional Logic
```hcl
# ✅ Use proper conditional expressions
locals {
  # Calculate resource counts based on conditions
  instance_count = var.environment == "production" ? 3 : 
                   var.environment == "staging" ? 2 : 1
  
  # Conditional resource creation
  create_monitoring = var.enable_monitoring && var.environment != "development"
}

resource "aws_instance" "example" {
  count = local.instance_count
  # Resource configuration...
}

resource "aws_cloudwatch_dashboard" "example" {
  count = local.create_monitoring ? 1 : 0
  # Resource configuration...
}
```

---

## 📊 Cross-Module Data Flow Problems

### Problem: Output Dependencies Not Resolving

**Symptoms:**
```
Error: Reference to undeclared output value: module.networking.subnet_ids
```

**Root Causes:**
- Missing output definitions
- Incorrect output references
- Module execution order issues

**Solutions:**

#### Solution 1: Comprehensive Output Definitions
```hcl
# ✅ Ensure all required outputs are defined
output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.example[*].id
}

output "security_group_ids" {
  description = "List of security group IDs"
  value       = aws_security_group.example[*].id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.example.id
}
```

#### Solution 2: Explicit Dependencies
```hcl
# ✅ Use explicit dependencies when needed
module "compute" {
  source = "./modules/compute"
  
  subnet_ids = module.networking.subnet_ids
  vpc_id     = module.networking.vpc_id
  
  depends_on = [module.networking]
}
```

### Problem: Complex Data Transformations

**Symptoms:**
```
Error: Invalid function call: lookup() function expects a map as first argument
```

**Solutions:**

#### Solution 1: Safe Data Access Patterns
```hcl
# ✅ Use try() function for safe data access
locals {
  # Safe data transformation
  transformed_data = try({
    for key, value in var.complex_data : key => {
      processed_value = value.enabled ? value.value : null
      metadata       = value.metadata
    }
  }, {})
  
  # Safe lookup with defaults
  default_config = try(var.configuration.defaults, {
    instance_type = "t3.micro"
    volume_size   = 20
  })
}
```

---

## ⚡ Performance and Scalability Issues

### Problem: Slow Plan/Apply Operations

**Symptoms:**
- Terraform plan takes > 10 minutes
- Apply operations timeout
- High memory usage during operations

**Root Causes:**
- Too many resources in single module
- Complex data source queries
- Inefficient resource dependencies

**Solutions:**

#### Solution 1: Module Decomposition
```hcl
# ✅ Break large modules into smaller, focused modules
module "networking_core" {
  source = "./modules/networking/core"
  # Core networking resources only
}

module "networking_security" {
  source = "./modules/networking/security"
  # Security groups and NACLs
  depends_on = [module.networking_core]
}

module "networking_routing" {
  source = "./modules/networking/routing"
  # Route tables and gateways
  depends_on = [module.networking_core]
}
```

#### Solution 2: Optimize Data Sources
```hcl
# ✅ Use specific filters to reduce data source overhead
data "aws_ami" "optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ❌ Avoid broad data source queries
# data "aws_instances" "all" {}  # Too broad
```

### Problem: State File Performance Issues

**Symptoms:**
- Large state files (> 100MB)
- Slow state operations
- State locking timeouts

**Solutions:**

#### Solution 1: State File Optimization
```hcl
# ✅ Use remote state backends with locking
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "advanced-modules/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

#### Solution 2: State File Splitting
```hcl
# ✅ Split state files by environment or component
# environments/dev/terraform.tfstate
# environments/staging/terraform.tfstate
# environments/prod/terraform.tfstate
```

---

## 🏢 Enterprise Governance Challenges

### Problem: Inconsistent Tagging Across Modules

**Symptoms:**
- Missing required tags on resources
- Inconsistent tag naming conventions
- Compliance violations

**Solutions:**

#### Solution 1: Centralized Tagging Strategy
```hcl
# ✅ Implement consistent tagging across all modules
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    Owner         = var.owner
    CostCenter    = var.cost_center
    Compliance    = var.compliance_level
    ManagedBy     = "terraform"
    LastModified  = timestamp()
  }
  
  # Merge with resource-specific tags
  resource_tags = merge(local.common_tags, var.additional_tags)
}
```

#### Solution 2: Tag Validation
```hcl
# ✅ Validate required tags
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  
  validation {
    condition = contains(keys(var.tags), "Environment")
    error_message = "Environment tag is required."
  }
  
  validation {
    condition = contains(keys(var.tags), "Project")
    error_message = "Project tag is required."
  }
}
```

### Problem: Security Policy Violations

**Symptoms:**
- Resources created without encryption
- Overly permissive security groups
- Missing compliance controls

**Solutions:**

#### Solution 1: Security-First Module Design
```hcl
# ✅ Implement security by default
resource "aws_s3_bucket" "secure" {
  bucket = var.bucket_name
  
  # Encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Versioning enabled
  versioning {
    enabled = true
  }
  
  # Public access blocked
  public_access_block {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Terraform Debug Logging
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform operations
terraform plan
terraform apply
```

### Technique 2: State Inspection
```bash
# Inspect state file
terraform state list
terraform state show aws_instance.example
terraform state pull | jq '.resources[] | select(.type == "aws_instance")'
```

### Technique 3: Plan Analysis
```bash
# Generate detailed plan
terraform plan -out=plan.out

# Analyze plan file
terraform show -json plan.out | jq '.planned_values.root_module'
```

### Technique 4: Module Debugging
```hcl
# ✅ Add debug outputs to modules
output "debug_info" {
  description = "Debug information for troubleshooting"
  value = {
    module_version = "2.1.0"
    configuration = {
      environment = var.environment
      region      = var.aws_region
      features    = var.enabled_features
    }
    resources_created = {
      instances = length(aws_instance.example)
      subnets   = length(aws_subnet.example)
    }
  }
}
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Comprehensive Testing
```hcl
# ✅ Implement module testing
# tests/test_module.tf
module "test_networking" {
  source = "../modules/networking"
  
  environment = "test"
  vpc_cidr    = "10.0.0.0/16"
  
  # Test configuration...
}
```

### Strategy 2: Validation Pipelines
```yaml
# .github/workflows/terraform-validation.yml
name: Terraform Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Terraform Format
        run: terraform fmt -check
      - name: Terraform Init
        run: terraform init
      - name: Terraform Validate
        run: terraform validate
      - name: Terraform Plan
        run: terraform plan
```

### Strategy 3: Documentation Standards
```markdown
# ✅ Comprehensive module documentation
## Module: Advanced Networking

### Purpose
Creates a multi-tier VPC architecture with advanced security and routing.

### Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | n/a | yes |
| vpc_cidr | VPC CIDR block | string | n/a | yes |

### Outputs
| Name | Description |
|------|-------------|
| vpc_id | VPC identifier |
| subnet_ids | List of subnet IDs |

### Examples
[Include usage examples]
```

---

## 📞 Getting Help

### Internal Resources
- Review module documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [Terraform Documentation](https://www.terraform.io/docs/)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review module documentation and examples
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Design First**: Plan module architecture before implementation
- **Test Early**: Implement comprehensive testing from the start
- **Document Everything**: Maintain detailed documentation
- **Monitor Performance**: Track and optimize module performance
- **Follow Standards**: Adhere to enterprise governance requirements
- **Debug Systematically**: Use structured debugging approaches
- **Prevent Issues**: Implement proactive prevention strategies

Remember: Advanced module development requires patience, systematic thinking, and continuous learning. Each challenge is an opportunity to improve your skills and create better infrastructure solutions.
