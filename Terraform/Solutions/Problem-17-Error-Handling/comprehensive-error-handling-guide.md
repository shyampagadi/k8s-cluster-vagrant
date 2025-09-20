# Terraform Error Handling and Validation - Complete Guide

## Overview

This comprehensive guide covers Terraform error handling, validation strategies, debugging techniques, and enterprise-grade error prevention patterns for robust infrastructure management.

## Error Types and Categories

### Syntax Errors

```hcl
# Common syntax errors and fixes

# Error: Missing quotes
resource "aws_instance" "web" {
  ami = ami-12345678  # Should be "ami-12345678"
}

# Error: Invalid block structure  
resource "aws_instance" "web" 
  ami = "ami-12345678"  # Missing opening brace
}

# Error: Invalid attribute name
resource "aws_instance" "web" {
  ami-id = "ami-12345678"  # Should be "ami"
}

# Correct syntax
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server"
  }
}
```

### Validation Errors

```hcl
# Input validation with comprehensive error handling
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be one of: t3.micro, t3.small, t3.medium, t3.large, t3.xlarge. Received: ${var.instance_type}"
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block. Received: ${var.vpc_cidr}"
  }
  
  validation {
    condition = can(regex("^10\\.|^172\\.(1[6-9]|2[0-9]|3[01])\\.|^192\\.168\\.", var.vpc_cidr))
    error_message = "VPC CIDR must be within private IP ranges (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16). Received: ${var.vpc_cidr}"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod. Received: ${var.environment}"
  }
  
  validation {
    condition     = length(var.environment) >= 3 && length(var.environment) <= 10
    error_message = "Environment name must be between 3 and 10 characters. Received: ${var.environment} (${length(var.environment)} characters)"
  }
}
```

### Runtime Errors

```hcl
# Handle runtime errors with try() and can()
variable "optional_config" {
  description = "Optional configuration"
  type        = map(any)
  default     = {}
}

locals {
  # Safe access to potentially missing values
  database_port = try(tonumber(var.optional_config.database_port), 5432)
  cache_enabled = try(tobool(var.optional_config.cache_enabled), false)
  
  # Safe string operations
  project_name = try(
    replace(lower(trimspace(var.optional_config.project_name)), " ", "-"),
    "default-project"
  )
  
  # Validate complex data structures
  is_valid_config = can(jsondecode(var.optional_config.json_config))
  
  # Conditional validation
  config_validation = local.is_valid_config ? null : file("ERROR: Invalid JSON configuration provided")
}

# Error-resistant resource creation
resource "aws_instance" "web" {
  count = try(var.instance_count > 0 ? var.instance_count : 1, 1)
  
  ami           = try(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type = try(var.instance_type, "t3.micro")
  
  # Safe subnet selection
  subnet_id = try(
    var.subnet_ids[count.index % length(var.subnet_ids)],
    data.aws_subnets.default.ids[0]
  )
  
  tags = merge(
    try(var.common_tags, {}),
    {
      Name = "web-server-${count.index + 1}"
    }
  )
}
```

## Advanced Validation Patterns

### Cross-Field Validation

```hcl
variable "ssl_config" {
  description = "SSL configuration"
  type = object({
    enabled         = bool
    certificate_arn = optional(string)
    domain_name     = optional(string)
  })
  
  validation {
    condition = (
      !var.ssl_config.enabled ||
      (var.ssl_config.enabled && var.ssl_config.certificate_arn != null)
    )
    error_message = "Certificate ARN is required when SSL is enabled."
  }
  
  validation {
    condition = (
      !var.ssl_config.enabled ||
      (var.ssl_config.enabled && var.ssl_config.domain_name != null)
    )
    error_message = "Domain name is required when SSL is enabled."
  }
  
  validation {
    condition = (
      !var.ssl_config.enabled ||
      can(regex("^arn:aws:acm:", var.ssl_config.certificate_arn))
    )
    error_message = "Certificate ARN must be a valid ACM certificate ARN."
  }
}

variable "backup_config" {
  description = "Backup configuration"
  type = object({
    enabled           = bool
    retention_days    = number
    backup_window     = string
    maintenance_window = string
  })
  
  validation {
    condition = (
      !var.backup_config.enabled ||
      (var.backup_config.retention_days >= 1 && var.backup_config.retention_days <= 35)
    )
    error_message = "Backup retention must be between 1 and 35 days when backups are enabled."
  }
  
  validation {
    condition = (
      !var.backup_config.enabled ||
      can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_config.backup_window))
    )
    error_message = "Backup window must be in format HH:MM-HH:MM (e.g., '03:00-04:00')."
  }
}
```

### Business Logic Validation

```hcl
variable "instance_config" {
  description = "Instance configuration"
  type = object({
    instance_type = string
    volume_size   = number
    volume_type   = string
    iops          = optional(number)
  })
  
  validation {
    condition = (
      var.instance_config.volume_type != "io1" ||
      (var.instance_config.volume_type == "io1" && var.instance_config.iops != null)
    )
    error_message = "IOPS must be specified when volume type is io1."
  }
  
  validation {
    condition = (
      var.instance_config.volume_type != "io1" ||
      (var.instance_config.iops >= var.instance_config.volume_size * 3 &&
       var.instance_config.iops <= var.instance_config.volume_size * 50)
    )
    error_message = "For io1 volumes, IOPS must be between 3x and 50x the volume size."
  }
  
  validation {
    condition = (
      !contains(["t3.large", "t3.xlarge"], var.instance_config.instance_type) ||
      var.instance_config.volume_size >= 50
    )
    error_message = "Large instance types require at least 50GB storage."
  }
}

variable "security_config" {
  description = "Security configuration"
  type = object({
    allowed_cidrs     = list(string)
    enable_ssh        = bool
    ssh_key_name      = optional(string)
    enable_monitoring = bool
  })
  
  validation {
    condition = alltrue([
      for cidr in var.security_config.allowed_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
  
  validation {
    condition = !contains(var.security_config.allowed_cidrs, "0.0.0.0/0") || !var.security_config.enable_ssh
    error_message = "SSH cannot be enabled when allowing access from anywhere (0.0.0.0/0)."
  }
  
  validation {
    condition = (
      !var.security_config.enable_ssh ||
      var.security_config.ssh_key_name != null
    )
    error_message = "SSH key name is required when SSH is enabled."
  }
}
```

## Error Prevention Strategies

### Defensive Programming

```hcl
# Defensive variable handling
variable "user_data_script" {
  description = "User data script path"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

locals {
  # Safe file reading with fallback
  user_data = var.user_data_script != "" && fileexists(var.user_data_script) ? file(var.user_data_script) : ""
  
  # Safe tag merging
  default_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    CreatedDate = timestamp()
  }
  
  merged_tags = merge(local.default_tags, var.tags)
  
  # Safe list operations
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  
  # Safe numeric operations
  instance_count = max(1, min(var.instance_count, 10))  # Ensure between 1 and 10
}

# Error-resistant resource creation
resource "aws_instance" "web" {
  count = local.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  # Safe subnet assignment
  subnet_id = try(
    local.availability_zones[count.index % length(local.availability_zones)],
    data.aws_subnets.default.ids[0]
  )
  
  # Safe user data assignment
  user_data = local.user_data != "" ? base64encode(local.user_data) : null
  
  tags = local.merged_tags
  
  # Lifecycle rules for error prevention
  lifecycle {
    create_before_destroy = true
    
    # Ignore changes that might cause issues
    ignore_changes = [
      user_data,  # Prevent replacement due to user data changes
      ami         # Prevent replacement due to AMI updates
    ]
  }
}
```

### Resource Validation

```hcl
# Validate resource dependencies
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}

locals {
  # Validate VPC exists
  vpc_validation = data.aws_vpc.main.id != "" ? null : file("ERROR: VPC ${var.vpc_id} not found")
  
  # Validate subnets exist and belong to VPC
  subnet_validation = length(data.aws_subnets.selected.ids) == length(var.subnet_ids) ? null : file("ERROR: Some subnets not found or not in specified VPC")
  
  # Validate subnet distribution across AZs
  subnet_azs = [for subnet_id in var.subnet_ids : data.aws_subnet.details[subnet_id].availability_zone]
  unique_azs = distinct(local.subnet_azs)
  az_validation = length(local.unique_azs) >= 2 ? null : file("ERROR: Subnets must span at least 2 availability zones")
}

data "aws_subnet" "details" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}
```

## Error Recovery Patterns

### Graceful Degradation

```hcl
# Graceful degradation for optional resources
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Primary application resources (always created)
resource "aws_instance" "app" {
  count = var.instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  tags = {
    Name = "app-server-${count.index + 1}"
  }
}

# Optional monitoring (degrades gracefully if it fails)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_monitoring ? var.instance_count : 0
  
  alarm_name          = "app-server-${count.index + 1}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  
  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }
  
  # Don't fail deployment if alarm creation fails
  lifecycle {
    ignore_changes = [alarm_description]
  }
}

# Optional backup (degrades gracefully)
resource "aws_backup_plan" "app" {
  count = var.enable_backup ? 1 : 0
  
  name = "app-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.app[0].name
    schedule          = "cron(0 5 ? * * *)"
    
    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }
  }
}

resource "aws_backup_vault" "app" {
  count = var.enable_backup ? 1 : 0
  
  name        = "app-backup-vault"
  kms_key_arn = try(aws_kms_key.backup[0].arn, null)
}
```

### Retry and Circuit Breaker Patterns

```hcl
# Retry pattern for external dependencies
data "external" "api_check" {
  program = ["bash", "-c", <<-EOF
    for i in {1..3}; do
      if curl -s --fail "${var.api_endpoint}/health" > /dev/null; then
        echo '{"status": "healthy"}'
        exit 0
      fi
      sleep 5
    done
    echo '{"status": "unhealthy"}'
    exit 1
  EOF
  ]
}

locals {
  api_healthy = try(data.external.api_check.result.status == "healthy", false)
  
  # Circuit breaker: disable features if external API is unhealthy
  enable_api_integration = local.api_healthy && var.enable_api_integration
}

# Conditional resource creation based on external dependencies
resource "aws_lambda_function" "api_integration" {
  count = local.enable_api_integration ? 1 : 0
  
  filename         = "api_integration.zip"
  function_name    = "api-integration"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  
  environment {
    variables = {
      API_ENDPOINT = var.api_endpoint
    }
  }
}
```

## Debugging Techniques

### Debug Logging

```hcl
# Enable debug logging
locals {
  debug_enabled = var.debug_mode
  
  debug_info = local.debug_enabled ? {
    vpc_id           = data.aws_vpc.main.id
    subnet_ids       = var.subnet_ids
    instance_count   = var.instance_count
    availability_zones = data.aws_availability_zones.available.names
    
    computed_values = {
      merged_tags    = local.merged_tags
      instance_count = local.instance_count
      user_data_length = length(local.user_data)
    }
  } : {}
}

# Debug outputs
output "debug_information" {
  description = "Debug information (only when debug mode is enabled)"
  value       = local.debug_enabled ? local.debug_info : null
}

# Conditional debug resources
resource "local_file" "debug_log" {
  count = local.debug_enabled ? 1 : 0
  
  filename = "debug.json"
  content  = jsonencode(local.debug_info)
}
```

### State Inspection

```bash
#!/bin/bash
# debug-terraform.sh

echo "=== Terraform Debug Information ==="

echo "1. Terraform Version:"
terraform version

echo -e "\n2. Current Workspace:"
terraform workspace show

echo -e "\n3. State Resources:"
terraform state list

echo -e "\n4. Provider Status:"
terraform providers

echo -e "\n5. Configuration Validation:"
terraform validate

echo -e "\n6. Plan Summary:"
terraform plan -detailed-exitcode -no-color | head -20

echo -e "\n7. Recent State Changes:"
if [ -f terraform.tfstate.backup ]; then
    echo "Backup state file exists"
    terraform show terraform.tfstate.backup | head -10
else
    echo "No backup state file found"
fi

echo -e "\n8. Environment Variables:"
env | grep TF_ | sort

echo -e "\n9. AWS Configuration:"
aws sts get-caller-identity 2>/dev/null || echo "AWS CLI not configured"

echo -e "\n10. Disk Space:"
df -h .
```

### Error Analysis Tools

```bash
#!/bin/bash
# analyze-errors.sh

LOG_FILE="terraform.log"
ERROR_REPORT="error_report.txt"

echo "Analyzing Terraform errors..." > $ERROR_REPORT

# Extract errors from log
echo "=== ERRORS ===" >> $ERROR_REPORT
grep -i "error" $LOG_FILE >> $ERROR_REPORT

echo -e "\n=== WARNINGS ===" >> $ERROR_REPORT
grep -i "warning" $LOG_FILE >> $ERROR_REPORT

echo -e "\n=== FAILED RESOURCES ===" >> $ERROR_REPORT
grep -A 5 -B 5 "Error:" $LOG_FILE >> $ERROR_REPORT

echo -e "\n=== TIMEOUT ISSUES ===" >> $ERROR_REPORT
grep -i "timeout" $LOG_FILE >> $ERROR_REPORT

echo -e "\n=== PERMISSION ISSUES ===" >> $ERROR_REPORT
grep -i "access denied\|unauthorized\|forbidden" $LOG_FILE >> $ERROR_REPORT

echo "Error analysis complete. Check $ERROR_REPORT"
```

## Testing and Validation

### Automated Testing

```hcl
# test/validation_test.tf
variable "test_cases" {
  description = "Test cases for validation"
  type = map(object({
    input          = any
    should_succeed = bool
    expected_error = optional(string)
  }))
  
  default = {
    valid_vpc_cidr = {
      input          = "10.0.0.0/16"
      should_succeed = true
    }
    invalid_vpc_cidr = {
      input          = "invalid-cidr"
      should_succeed = false
      expected_error = "must be a valid IPv4 CIDR block"
    }
    public_cidr = {
      input          = "8.8.8.8/24"
      should_succeed = false
      expected_error = "must be within private IP ranges"
    }
  }
}

# Test validation logic
locals {
  test_results = {
    for name, test_case in var.test_cases :
    name => {
      input = test_case.input
      
      # Test CIDR validation
      is_valid_cidr = can(cidrhost(test_case.input, 0))
      is_private_cidr = can(regex("^10\\.|^172\\.(1[6-9]|2[0-9]|3[01])\\.|^192\\.168\\.", test_case.input))
      
      validation_passed = local.is_valid_cidr && local.is_private_cidr
      test_passed = test_case.should_succeed == local.validation_passed
    }
  }
}

output "test_results" {
  description = "Validation test results"
  value = {
    for name, result in local.test_results :
    name => {
      test_passed = result.test_passed
      details = {
        input = result.input
        is_valid_cidr = result.is_valid_cidr
        is_private_cidr = result.is_private_cidr
        validation_passed = result.validation_passed
      }
    }
  }
}
```

### Integration Testing

```bash
#!/bin/bash
# integration-test.sh

set -e

ENVIRONMENTS=("dev" "staging")
TEST_RESULTS=()

echo "Starting integration tests..."

for env in "${ENVIRONMENTS[@]}"; do
    echo "Testing environment: $env"
    
    cd "environments/$env"
    
    # Initialize
    terraform init -input=false
    
    # Validate
    if terraform validate; then
        echo "✅ $env: Validation passed"
        TEST_RESULTS+=("$env:validation:PASS")
    else
        echo "❌ $env: Validation failed"
        TEST_RESULTS+=("$env:validation:FAIL")
        continue
    fi
    
    # Plan
    if terraform plan -input=false -detailed-exitcode; then
        echo "✅ $env: Plan succeeded"
        TEST_RESULTS+=("$env:plan:PASS")
    else
        echo "❌ $env: Plan failed"
        TEST_RESULTS+=("$env:plan:FAIL")
    fi
    
    cd ../..
done

echo -e "\n=== Test Results ==="
for result in "${TEST_RESULTS[@]}"; do
    echo "$result"
done

# Check if all tests passed
if echo "${TEST_RESULTS[@]}" | grep -q "FAIL"; then
    echo -e "\n❌ Some tests failed"
    exit 1
else
    echo -e "\n✅ All tests passed"
    exit 0
fi
```

## Best Practices

### 1. Comprehensive Validation

```hcl
# Always validate inputs thoroughly
variable "config" {
  type = object({
    name = string
    size = number
  })
  
  validation {
    condition     = length(var.config.name) > 0
    error_message = "Name cannot be empty."
  }
  
  validation {
    condition     = var.config.size > 0
    error_message = "Size must be positive."
  }
}
```

### 2. Safe Error Handling

```hcl
# Use try() for safe operations
locals {
  safe_value = try(var.optional_value, "default")
  safe_number = try(tonumber(var.string_number), 0)
}
```

### 3. Meaningful Error Messages

```hcl
# Provide clear, actionable error messages
validation {
  condition = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Environment must be one of: dev, staging, prod. Received: '${var.environment}'. Please check your terraform.tfvars file."
}
```

### 4. Graceful Degradation

```hcl
# Design for graceful degradation
resource "optional_resource" "example" {
  count = var.enable_feature ? 1 : 0
  # Configuration
}
```

## Conclusion

Effective error handling enables:
- **Robust Infrastructure**: Prevent and handle failures gracefully
- **Better Debugging**: Quick identification and resolution of issues
- **Improved Reliability**: Reduce deployment failures
- **Enhanced Maintainability**: Clear error messages and validation

Key takeaways:
- Implement comprehensive input validation
- Use try() and can() for safe operations
- Provide meaningful error messages
- Design for graceful degradation
- Implement automated testing
- Use debugging tools and techniques
