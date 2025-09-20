# Problem 21: Terraform Modules - Troubleshooting Guide

## Common Module Development Issues

### Issue 1: Module Path Resolution Errors
**Problem**: `Module not found` or `Invalid module source` errors
**Symptoms**: 
```
Error: Module not found
│ The module address "./modules/vpc" could not be resolved.
```

**Root Causes**:
- Incorrect relative path to module
- Module directory doesn't exist
- Missing main.tf in module directory

**Solutions**:
```bash
# Verify module directory structure
ls -la modules/vpc/
# Should show: main.tf, variables.tf, outputs.tf

# Check current working directory
pwd
# Ensure you're in the root module directory

# Verify module source path
module "vpc" {
  source = "./modules/vpc"  # Correct relative path
  # source = "modules/vpc"  # Also works
}
```

**Prevention**:
- Always use consistent directory structure
- Test module paths with `terraform init`
- Use absolute paths for complex directory structures

### Issue 2: Variable Validation Failures
**Problem**: Variable validation blocks prevent deployment
**Symptoms**:
```
Error: Invalid value for variable
│ The given value for var.vpc_cidr is not valid: VPC CIDR must be a valid CIDR block.
```

**Root Causes**:
- Invalid CIDR block format
- Values outside validation constraints
- Type mismatches

**Solutions**:
```hcl
# Fix CIDR validation
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

# Test CIDR blocks
# Valid: "10.0.0.0/16", "172.16.0.0/16", "192.168.0.0/16"
# Invalid: "10.0.0.0", "256.0.0.0/16", "10.0.0.0/33"
```

**Debugging Steps**:
```bash
# Test CIDR validation in Terraform console
terraform console
> can(cidrhost("10.0.0.0/16", 0))
true
> can(cidrhost("invalid-cidr", 0))
false
```

### Issue 3: Module Output Reference Errors
**Problem**: Cannot reference module outputs
**Symptoms**:
```
Error: Reference to undeclared output value
│ An output value with the name "vpc_id" has not been declared in module.vpc.
```

**Root Causes**:
- Output not defined in module
- Typo in output name
- Output not properly exported

**Solutions**:
```hcl
# modules/vpc/outputs.tf - Ensure output is defined
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# main.tf - Reference output correctly
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]  # Correct reference
  # subnet_id = module.vpc.subnet_id           # Wrong - doesn't exist
}
```

**Debugging**:
```bash
# List all module outputs
terraform output
terraform output -json

# Check specific module output
terraform output module.vpc
```

### Issue 4: Circular Dependencies
**Problem**: Modules create circular dependency chains
**Symptoms**:
```
Error: Cycle in module dependencies
│ Module "vpc" depends on module "security_groups", which depends on module "vpc".
```

**Root Causes**:
- Modules referencing each other's outputs
- Improper dependency design
- Security groups in wrong module

**Solutions**:
```hcl
# BAD: Circular dependency
module "vpc" {
  source = "./modules/vpc"
  security_group_id = module.security_groups.web_sg_id  # Creates cycle
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id  # Depends on VPC
}

# GOOD: Proper dependency flow
module "vpc" {
  source = "./modules/vpc"
  # No dependency on security groups
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id  # One-way dependency
}
```

### Issue 5: Resource Naming Conflicts
**Problem**: Resources with duplicate names across modules
**Symptoms**:
```
Error: resource "aws_security_group" "main" already exists
```

**Root Causes**:
- Same resource names in different modules
- Missing name prefixes
- Hardcoded resource names

**Solutions**:
```hcl
# BAD: Hardcoded names cause conflicts
resource "aws_security_group" "main" {
  name = "web-sg"  # Conflicts if used in multiple modules
}

# GOOD: Use name_prefix or dynamic names
resource "aws_security_group" "main" {
  name_prefix = "${var.name}-"  # Unique names
  # or
  name = "${var.name}-${var.environment}-sg"
}
```

## Advanced Troubleshooting Scenarios

### Issue 6: Module Version Conflicts
**Problem**: Different module versions cause compatibility issues
**Symptoms**:
```
Error: Incompatible provider requirements
│ Module requires provider version ~> 4.0 but root module uses ~> 5.0
```

**Solutions**:
```hcl
# Standardize provider versions across all modules
# modules/*/versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Same version everywhere
    }
  }
}
```

### Issue 7: State Management Issues with Modules
**Problem**: Module resources not tracked in state
**Symptoms**:
- Resources exist in AWS but not in state
- `terraform plan` wants to recreate existing resources

**Solutions**:
```bash
# Import existing resources into module
terraform import module.vpc.aws_vpc.main vpc-12345678

# Check module state
terraform state list | grep module.vpc

# Move resources between modules if needed
terraform state mv aws_instance.web module.ec2.aws_instance.main
```

### Issue 8: Module Input Validation Edge Cases
**Problem**: Complex validation rules fail unexpectedly
**Symptoms**:
```
Error: Invalid function argument
│ Invalid value for "condition" parameter: cannot use functions in validation conditions.
```

**Solutions**:
```hcl
# BAD: Complex validation that might fail
variable "subnet_cidrs" {
  type = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.subnet_cidrs : 
      can(cidrhost(cidr, 0)) && 
      tonumber(split("/", cidr)[1]) >= 24  # This might fail
    ])
    error_message = "All subnet CIDRs must be valid with /24 or smaller."
  }
}

# GOOD: Simpler, more reliable validation
variable "subnet_cidrs" {
  type = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }
}
```

## Debugging Tools and Techniques

### Enable Debug Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan
```

### Module-Specific Debugging
```bash
# Validate specific module
cd modules/vpc
terraform validate

# Test module in isolation
terraform init
terraform plan -var="name=test" -var="vpc_cidr=10.0.0.0/16"
```

### State Inspection
```bash
# List all resources in modules
terraform state list | grep module

# Show specific module resource
terraform state show module.vpc.aws_vpc.main

# Check module dependencies
terraform graph | grep module
```

### Variable Testing
```bash
# Test variables in Terraform console
terraform console
> var.vpc_cidr
"10.0.0.0/16"
> cidrsubnet(var.vpc_cidr, 8, 0)
"10.0.0.0/24"
```

## Performance Troubleshooting

### Issue 9: Slow Module Execution
**Problem**: Modules take too long to plan/apply
**Symptoms**:
- Long wait times during `terraform plan`
- Timeouts during resource creation

**Solutions**:
```hcl
# Optimize data source usage
data "aws_availability_zones" "available" {
  state = "available"
  # Cache this data source result
}

# Use locals to avoid repeated calculations
locals {
  subnet_cidrs = [
    for i in range(var.subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
}

# Reduce API calls with efficient resource organization
resource "aws_subnet" "main" {
  for_each = toset(local.subnet_cidrs)
  # More efficient than count for large numbers
}
```

### Issue 10: Module Memory Issues
**Problem**: Large modules consume too much memory
**Solutions**:
- Break large modules into smaller, focused modules
- Use `for_each` instead of `count` for large resource sets
- Optimize variable structures and reduce complex objects

## Prevention Best Practices

### Module Development Checklist
- [ ] Consistent naming conventions
- [ ] Proper variable validation
- [ ] Comprehensive outputs
- [ ] Clear documentation
- [ ] Example usage provided
- [ ] Testing in isolation
- [ ] Version constraints specified

### Testing Strategy
```bash
# Test module in isolation
cd modules/vpc
terraform init
terraform validate
terraform plan -var-file="test.tfvars"

# Integration testing
cd ../..
terraform init
terraform plan
```

### Documentation Standards
- Always include README.md with usage examples
- Document all variables with descriptions and types
- Explain all outputs and their use cases
- Provide troubleshooting section
- Include version compatibility information

This comprehensive troubleshooting guide covers the most common issues encountered when developing and using Terraform modules, providing practical solutions and prevention strategies.
