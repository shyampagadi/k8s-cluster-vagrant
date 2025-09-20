# Advanced Data Sources Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for advanced Terraform data sources, complex queries, performance optimization, and dynamic resource discovery issues.

## 📋 Table of Contents

1. [Data Source Query Failures](#data-source-query-failures)
2. [Performance and Optimization Issues](#performance-and-optimization-issues)
3. [Complex Filtering Problems](#complex-filtering-problems)
4. [Dynamic Resource Discovery Issues](#dynamic-resource-discovery-issues)
5. [Data Transformation Errors](#data-transformation-errors)
6. [Cross-Region Data Source Problems](#cross-region-data-source-problems)
7. [Custom Data Source Integration Issues](#custom-data-source-integration-issues)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 🔍 Data Source Query Failures

### Problem: Data Source Not Found

**Symptoms:**
```
Error: No matching AMI found
```

**Root Causes:**
- Incorrect filter criteria
- Missing required parameters
- Resource not available in region
- Permissions issues

**Solutions:**

#### Solution 1: Verify Filter Criteria
```hcl
# ❌ Problematic: Too restrictive filters
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2023.12.13-x86_64-gp2"]  # Too specific
  }
}

# ✅ Solution: Use broader, more flexible filters
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # More flexible
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

#### Solution 2: Add Fallback Logic
```hcl
# ✅ Implement fallback data sources
data "aws_ami" "primary" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "fallback" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Use fallback logic
locals {
  selected_ami = data.aws_ami.primary.id != "" ? data.aws_ami.primary.id : data.aws_ami.fallback.id
}
```

### Problem: Permission Denied Errors

**Symptoms:**
```
Error: AccessDenied: User is not authorized to perform: ec2:DescribeImages
```

**Root Causes:**
- Insufficient IAM permissions
- Resource-based policies
- Cross-account access issues

**Solutions:**

#### Solution 1: Verify IAM Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Solution 2: Use Data Source with Explicit Permissions
```hcl
# ✅ Use data sources that require minimal permissions
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
```

---

## ⚡ Performance and Optimization Issues

### Problem: Slow Data Source Queries

**Symptoms:**
- Data source queries taking > 30 seconds
- High AWS API usage
- Terraform plan timeouts

**Root Causes:**
- Too many data sources
- Inefficient filter criteria
- Large result sets
- Network latency

**Solutions:**

#### Solution 1: Optimize Filter Criteria
```hcl
# ❌ Inefficient: Too many filters
data "aws_ami" "slow" {
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
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
  
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ✅ Optimized: Essential filters only
data "aws_ami" "fast" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

#### Solution 2: Cache Data Source Results
```hcl
# ✅ Use locals to cache expensive data source results
locals {
  # Cache AMI data
  ami_data = data.aws_ami.example
  
  # Cache subnet data
  subnet_data = data.aws_subnets.example
  
  # Use cached data in resources
  instance_ami = local.ami_data.id
  subnet_ids   = local.subnet_data.ids
}
```

#### Solution 3: Parallel Data Source Queries
```hcl
# ✅ Use multiple data sources in parallel
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Use appropriate AMI based on requirements
locals {
  selected_ami = var.use_ubuntu ? data.aws_ami.ubuntu.id : data.aws_ami.amazon_linux.id
}
```

---

## 🔍 Complex Filtering Problems

### Problem: Complex Filter Logic Failures

**Symptoms:**
```
Error: Invalid filter value: expected string, got number
```

**Root Causes:**
- Incorrect data types in filters
- Complex filter combinations
- Missing filter values

**Solutions:**

#### Solution 1: Proper Data Type Handling
```hcl
# ❌ Problematic: Wrong data type
data "aws_instances" "example" {
  filter {
    name   = "instance-state-name"
    values = ["running"]  # Correct
  }
  
  filter {
    name   = "instance-type"
    values = [var.instance_type]  # May be wrong type
  }
}

# ✅ Solution: Ensure correct data types
data "aws_instances" "example" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  
  filter {
    name   = "instance-type"
    values = [tostring(var.instance_type)]  # Ensure string
  }
}
```

#### Solution 2: Complex Filter Validation
```hcl
# ✅ Validate complex filter inputs
locals {
  # Validate filter criteria
  valid_filters = {
    instance_types = [
      for type in var.instance_types :
      type if contains(["t3.micro", "t3.small", "t3.medium"], type)
    ]
    
    states = [
      for state in var.instance_states :
      state if contains(["running", "stopped", "pending"], state)
    ]
  }
}

data "aws_instances" "filtered" {
  filter {
    name   = "instance-type"
    values = local.valid_filters.instance_types
  }
  
  filter {
    name   = "instance-state-name"
    values = local.valid_filters.states
  }
}
```

---

## 🔄 Dynamic Resource Discovery Issues

### Problem: Dynamic Resource Selection Failures

**Symptoms:**
```
Error: Invalid index: 0 on empty list
```

**Root Causes:**
- Empty data source results
- Incorrect resource selection logic
- Missing fallback mechanisms

**Solutions:**

#### Solution 1: Safe Resource Selection
```hcl
# ❌ Problematic: No validation
data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_instance" "example" {
  subnet_id = data.aws_subnets.example.ids[0]  # May fail if empty
}

# ✅ Solution: Safe selection with validation
data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

locals {
  available_subnets = length(data.aws_subnets.example.ids) > 0 ? data.aws_subnets.example.ids : [var.default_subnet_id]
}

resource "aws_instance" "example" {
  subnet_id = local.available_subnets[0]
}
```

#### Solution 2: Conditional Resource Discovery
```hcl
# ✅ Conditional data source usage
locals {
  use_dynamic_discovery = var.enable_auto_discovery
}

data "aws_subnets" "dynamic" {
  count = local.use_dynamic_discovery ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "static" {
  count = local.use_dynamic_discovery ? 0 : 1
  id    = var.static_subnet_id
}

locals {
  selected_subnets = local.use_dynamic_discovery ? 
    data.aws_subnets.dynamic[0].ids : 
    [data.aws_subnet.static[0].id]
}
```

---

## 🔄 Data Transformation Errors

### Problem: Data Structure Transformation Failures

**Symptoms:**
```
Error: Invalid function call: lookup() function expects a map as first argument
```

**Root Causes:**
- Incorrect data structure assumptions
- Missing data validation
- Complex transformation logic errors

**Solutions:**

#### Solution 1: Safe Data Access Patterns
```hcl
# ❌ Problematic: Unsafe data access
data "aws_instance" "example" {
  instance_id = var.instance_id
}

locals {
  instance_tags = data.aws_instance.example.tags  # May be null
  environment   = lookup(local.instance_tags, "Environment", "unknown")  # May fail
}

# ✅ Solution: Safe data access
data "aws_instance" "example" {
  instance_id = var.instance_id
}

locals {
  instance_tags = try(data.aws_instance.example.tags, {})
  environment   = lookup(local.instance_tags, "Environment", "unknown")
}
```

#### Solution 2: Complex Data Transformation
```hcl
# ✅ Safe complex data transformation
locals {
  # Transform instance data safely
  instance_data = try({
    for instance in data.aws_instances.example.ids :
    instance => {
      id          = instance
      tags        = try(data.aws_instance.details[instance].tags, {})
      state       = try(data.aws_instance.details[instance].instance_state, "unknown")
      type        = try(data.aws_instance.details[instance].instance_type, "unknown")
      environment = try(data.aws_instance.details[instance].tags["Environment"], "unknown")
    }
  }, {})
  
  # Filter instances by criteria
  filtered_instances = {
    for id, data in local.instance_data :
    id => data if data.environment == var.target_environment && data.state == "running"
  }
}
```

---

## 🌍 Cross-Region Data Source Problems

### Problem: Cross-Region Data Source Failures

**Symptoms:**
```
Error: No matching resources found in region us-east-1
```

**Root Causes:**
- Resources not available in target region
- Incorrect provider configuration
- Cross-region permission issues

**Solutions:**

#### Solution 1: Multi-Region Data Source Configuration
```hcl
# ✅ Proper multi-region data source setup
provider "aws" {
  alias  = "primary"
  region = "us-west-2"
}

provider "aws" {
  alias  = "secondary"
  region = "us-east-1"
}

# Primary region data
data "aws_ami" "primary" {
  provider = aws.primary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Secondary region data
data "aws_ami" "secondary" {
  provider = aws.secondary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use appropriate AMI based on region
locals {
  region_amis = {
    "us-west-2" = data.aws_ami.primary.id
    "us-east-1" = data.aws_ami.secondary.id
  }
  
  selected_ami = local.region_amis[var.target_region]
}
```

#### Solution 2: Cross-Region Resource Discovery
```hcl
# ✅ Cross-region resource discovery
data "aws_instances" "cross_region" {
  provider = aws.secondary
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Process cross-region data
locals {
  cross_region_instances = try([
    for instance in data.aws_instances.cross_region.ids :
    {
      id     = instance
      region = "us-east-1"
    }
  ], [])
}
```

---

## 🔧 Custom Data Source Integration Issues

### Problem: Custom Data Source Failures

**Symptoms:**
```
Error: Failed to read data source: HTTP request failed
```

**Root Causes:**
- Network connectivity issues
- Authentication failures
- Invalid data source configuration
- External service unavailability

**Solutions:**

#### Solution 1: Robust Custom Data Source Configuration
```hcl
# ✅ Robust custom data source with error handling
data "http" "external_api" {
  url = var.api_endpoint
  
  request_headers = {
    Authorization = "Bearer ${var.api_token}"
    Content-Type  = "application/json"
  }
  
  # Add timeout and retry logic
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "API request failed with status ${self.status_code}"
    }
  }
}

locals {
  # Safe data parsing
  api_data = try(jsondecode(data.http.external_api.response_body), {})
  
  # Validate required fields
  validated_data = try({
    instances = local.api_data.instances
    region    = local.api_data.region
  }, {
    instances = []
    region    = "unknown"
  })
}
```

#### Solution 2: Fallback Data Sources
```hcl
# ✅ Implement fallback data sources
data "http" "primary_api" {
  url = var.primary_api_endpoint
  
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Primary API failed"
    }
  }
}

data "http" "fallback_api" {
  url = var.fallback_api_endpoint
  
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Fallback API failed"
    }
  }
}

locals {
  # Use primary data if available, otherwise fallback
  api_data = try(
    jsondecode(data.http.primary_api.response_body),
    jsondecode(data.http.fallback_api.response_body),
    {}
  )
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Data Source Inspection
```bash
# ✅ Inspect data source results
terraform console
> data.aws_ami.example
> data.aws_subnets.example.ids
> data.aws_instances.example.ids
```

### Technique 2: Debug Data Source Queries
```hcl
# ✅ Add debug outputs to data sources
output "debug_ami_data" {
  description = "Debug AMI data source results"
  value = {
    ami_id      = data.aws_ami.example.id
    ami_name    = data.aws_ami.example.name
    ami_owner   = data.aws_ami.example.owner_id
    creation_date = data.aws_ami.example.creation_date
  }
}

output "debug_subnet_data" {
  description = "Debug subnet data source results"
  value = {
    subnet_count = length(data.aws_subnets.example.ids)
    subnet_ids   = data.aws_subnets.example.ids
  }
}
```

### Technique 3: Data Source Performance Monitoring
```bash
# ✅ Monitor data source performance
time terraform plan
time terraform apply

# ✅ Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform plan
```

### Technique 4: Data Source Validation
```hcl
# ✅ Validate data source results
locals {
  # Validate AMI data
  ami_validation = {
    has_ami     = data.aws_ami.example.id != ""
    is_recent   = data.aws_ami.example.creation_date > "2023-01-01"
    is_available = data.aws_ami.example.state == "available"
  }
  
  # Validate subnet data
  subnet_validation = {
    has_subnets = length(data.aws_subnets.example.ids) > 0
    subnet_count = length(data.aws_subnets.example.ids)
  }
}
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Data Source Testing
```hcl
# ✅ Test data sources in isolation
# tests/test_datasources.tf
data "aws_ami" "test" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "test_ami_id" {
  value = data.aws_ami.test.id
}
```

### Strategy 2: Data Source Monitoring
```bash
# ✅ Monitor data source performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name APIRequestCount \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Strategy 3: Data Source Documentation
```markdown
# ✅ Document data source usage
## Data Source: aws_ami

### Purpose
Discovers the latest Amazon Linux 2 AMI for EC2 instances.

### Requirements
- EC2:DescribeImages permission
- Valid AWS region
- Available AMI in region

### Usage
```hcl
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### Outputs
- `id`: AMI ID
- `name`: AMI name
- `owner_id`: AMI owner ID
```

---

## 📞 Getting Help

### Internal Resources
- Review data source documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [Terraform Data Sources Documentation](https://www.terraform.io/docs/language/data-sources/index.html)
- [AWS Provider Data Sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources)
- [Terraform Functions Documentation](https://www.terraform.io/docs/language/functions/index.html)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review data source documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Optimize Queries**: Use efficient filter criteria
- **Handle Errors**: Implement proper error handling
- **Validate Data**: Always validate data source results
- **Monitor Performance**: Track data source performance
- **Test Thoroughly**: Test data sources in isolation
- **Document Usage**: Maintain clear documentation
- **Plan Fallbacks**: Implement fallback mechanisms
- **Monitor Costs**: Track AWS API usage costs

Remember: Advanced data sources require careful planning, optimization, and error handling. Proper implementation ensures reliable and efficient infrastructure management.
