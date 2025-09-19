# Problem 11: Conditional Logic and Dynamic Blocks

## Overview

This solution provides comprehensive understanding of Terraform conditional logic and dynamic blocks, focusing on advanced conditional patterns, dynamic resource creation, and complex configuration scenarios. These are essential for creating flexible, environment-aware infrastructure.

## Learning Objectives

- Understand Terraform conditional logic concepts and purposes
- Master conditional expressions and ternary operators
- Learn dynamic blocks for conditional resource configuration
- Understand conditional resource creation patterns
- Master complex conditional scenarios and nested conditions
- Learn performance considerations and best practices
- Understand troubleshooting conditional logic issues

## Problem Statement

You've mastered loops and iteration patterns. Now your team lead wants you to become proficient in Terraform conditional logic and dynamic blocks, focusing on advanced conditional patterns and dynamic resource creation. You need to understand how to create flexible, environment-aware infrastructure that adapts to different scenarios.

## Solution Components

This solution includes:
1. **Conditional Logic Fundamentals** - Understanding what conditional logic is and why it's important
2. **Conditional Expressions** - Ternary operators and conditional values
3. **Dynamic Blocks** - Conditional resource configuration
4. **Conditional Resource Creation** - Creating resources based on conditions
5. **Complex Conditional Scenarios** - Nested conditions and advanced patterns
6. **Performance Considerations** - Optimizing conditional logic
7. **Best Practices** - When and how to use conditional logic effectively

## Implementation Guide

### Step 1: Understanding Conditional Logic Fundamentals

#### What is Conditional Logic in Terraform?
Conditional logic in Terraform allows you to create dynamic configurations that adapt based on conditions. It serves several purposes:
- **Environment Adaptation**: Configure resources differently for different environments
- **Feature Toggles**: Enable/disable features based on conditions
- **Resource Optimization**: Create resources only when needed
- **Configuration Flexibility**: Adapt configurations to different scenarios

#### Conditional Logic Benefits
- **Environment Awareness**: Different configurations for dev/staging/prod
- **Feature Control**: Enable features conditionally
- **Cost Optimization**: Create resources only when needed
- **Maintenance Efficiency**: Single configuration for multiple scenarios

### Step 2: Conditional Expressions

#### Basic Conditional Expressions
```hcl
# Ternary operator for conditional values
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "web-instance"
    Environment = var.environment
    InstanceType = var.environment == "production" ? "Production" : "Development"
  }
}

# Conditional values based on multiple conditions
locals {
  instance_count = var.environment == "production" ? 3 : (var.environment == "staging" ? 2 : 1)
  enable_monitoring = var.environment == "production" ? true : false
  backup_retention = var.environment == "production" ? 30 : (var.environment == "staging" ? 7 : 1)
}
```

#### Complex Conditional Expressions
```hcl
# Nested conditional expressions
locals {
  database_config = {
    instance_class = var.environment == "production" ? "db.r5.large" : 
                    var.environment == "staging" ? "db.t3.medium" : "db.t3.micro"
    multi_az = var.environment == "production" ? true : false
    backup_retention = var.environment == "production" ? 30 : 7
    encryption = var.environment == "production" ? true : false
  }
  
  security_config = {
    enable_waf = var.environment == "production" ? true : false
    enable_shield = var.environment == "production" ? true : false
    enable_guardduty = var.environment == "production" ? true : false
  }
}
```

### Step 3: Dynamic Blocks

#### Basic Dynamic Blocks
```hcl
# Dynamic security group rules
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = var.environment == "production" ? var.production_ingress_rules : var.development_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  dynamic "egress" {
    for_each = var.enable_egress ? var.egress_rules : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
```

#### Advanced Dynamic Blocks
```hcl
# Dynamic EBS volumes
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  dynamic "ebs_block_device" {
    for_each = var.environment == "production" ? var.production_volumes : var.development_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
      encrypted   = var.environment == "production" ? true : false
    }
  }
  
  dynamic "root_block_device" {
    for_each = var.enable_root_encryption ? [1] : []
    content {
      volume_size = var.root_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }
}
```

### Step 4: Conditional Resource Creation

#### Basic Conditional Resource Creation
```hcl
# Conditional resource creation using count
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

# Conditional resource creation using for_each
resource "aws_instance" "web" {
  for_each = var.environment == "production" ? var.production_configs : var.development_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = each.key
    Environment = var.environment
  }
}
```

#### Advanced Conditional Resource Creation
```hcl
# Complex conditional resource creation
resource "aws_instance" "web" {
  count = var.environment == "production" ? var.production_instance_count : 
          var.environment == "staging" ? var.staging_instance_count : 
          var.development_instance_count
  
  ami           = var.ami_id
  instance_type = var.environment == "production" ? var.production_instance_type : 
                  var.environment == "staging" ? var.staging_instance_type : 
                  var.development_instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Environment = var.environment
    InstanceType = var.environment == "production" ? "Production" : 
                   var.environment == "staging" ? "Staging" : "Development"
  }
}
```

### Step 5: Complex Conditional Scenarios

#### Environment-Specific Configurations
```hcl
# Environment-specific resource configurations
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  # Conditional monitoring
  monitoring = var.environment == "production" ? true : false
  
  # Conditional user data
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
    enable_monitoring = var.environment == "production" ? true : false
    enable_debug = var.environment == "development" ? true : false
    enable_ssl = var.environment == "production" ? true : false
  }))
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Environment = var.environment
    Monitoring = var.environment == "production" ? "Enabled" : "Disabled"
    SSL = var.environment == "production" ? "Enabled" : "Disabled"
  }
}
```

#### Feature Toggle Patterns
```hcl
# Feature toggle patterns
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  # Feature toggles
  monitoring = var.enable_monitoring
  ebs_optimized = var.enable_ebs_optimization
  
  # Conditional features
  dynamic "ebs_block_device" {
    for_each = var.enable_additional_storage ? var.additional_volumes : []
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
    }
  }
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Monitoring = var.enable_monitoring ? "Enabled" : "Disabled"
    EBSOptimized = var.enable_ebs_optimization ? "Enabled" : "Disabled"
    AdditionalStorage = var.enable_additional_storage ? "Enabled" : "Disabled"
  }
}
```

### Step 6: Performance Considerations

#### Optimizing Conditional Logic
```hcl
# Use locals for complex conditional logic
locals {
  # Pre-compute conditional values
  instance_config = {
    count = var.environment == "production" ? 3 : 1
    type = var.environment == "production" ? "t3.large" : "t3.micro"
    monitoring = var.environment == "production" ? true : false
  }
  
  # Pre-compute feature flags
  feature_flags = {
    enable_monitoring = var.enable_monitoring && var.environment == "production"
    enable_encryption = var.enable_encryption || var.environment == "production"
    enable_backup = var.enable_backup && var.environment == "production"
  }
}

# Use pre-computed values in resources
resource "aws_instance" "web" {
  count = local.instance_config.count
  
  ami           = var.ami_id
  instance_type = local.instance_config.type
  subnet_id     = aws_subnet.public[count.index].id
  
  monitoring = local.instance_config.monitoring
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Environment = var.environment
    Monitoring = local.feature_flags.enable_monitoring ? "Enabled" : "Disabled"
  }
}
```

### Step 7: Best Practices

#### Conditional Logic Best Practices
```hcl
# Use meaningful variable names for conditions
variable "enable_production_features" {
  description = "Enable production-specific features"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Use locals for complex conditional logic
locals {
  is_production = var.environment == "production"
  is_staging = var.environment == "staging"
  is_development = var.environment == "development"
  
  # Environment-specific configurations
  instance_config = {
    count = local.is_production ? 3 : (local.is_staging ? 2 : 1)
    type = local.is_production ? "t3.large" : (local.is_staging ? "t3.medium" : "t3.micro")
    monitoring = local.is_production ? true : false
  }
}
```

## Expected Deliverables

### 1. Conditional Expression Examples
- Basic ternary operators and conditional values
- Complex nested conditional expressions
- Environment-specific configurations
- Feature toggle patterns

### 2. Dynamic Block Examples
- Basic dynamic blocks for security groups
- Advanced dynamic blocks for EBS volumes
- Conditional dynamic block creation
- Performance optimization techniques

### 3. Conditional Resource Creation
- Count-based conditional creation
- For_each-based conditional creation
- Complex conditional scenarios
- Environment-specific resource creation

### 4. Complex Conditional Scenarios
- Environment-specific configurations
- Feature toggle patterns
- Nested conditional logic
- Advanced conditional patterns

### 5. Best Practices Implementation
- Performance optimization techniques
- Error handling patterns
- Maintenance guidelines
- Troubleshooting approaches

## Knowledge Check

Answer these questions to validate your understanding:

1. **What is conditional logic in Terraform, and why is it important?**
   - Conditional logic allows creating dynamic configurations that adapt based on conditions
   - It enables environment adaptation, feature toggles, and resource optimization

2. **What are the main types of conditional expressions?**
   - Ternary operators: condition ? true_value : false_value
   - Complex nested conditions
   - Environment-specific configurations

3. **What are dynamic blocks, and when would you use them?**
   - Dynamic blocks allow conditional resource configuration
   - Use them when resource configuration varies based on conditions

4. **How do you create resources conditionally?**
   - Use count with conditional expressions
   - Use for_each with conditional maps
   - Use conditional resource creation patterns

5. **What are the best practices for conditional logic?**
   - Use locals for complex conditional logic
   - Pre-compute conditional values
   - Use meaningful variable names
   - Validate conditional inputs

6. **How do you optimize conditional logic performance?**
   - Use locals for pre-computed values
   - Avoid complex calculations in resource definitions
   - Consider resource creation order

7. **What are common conditional logic patterns?**
   - Environment-specific configurations
   - Feature toggle patterns
   - Resource optimization patterns
   - Configuration adaptation patterns

## Troubleshooting

### Common Conditional Logic Issues

#### 1. Conditional Expression Errors
```bash
# Error: Invalid conditional expression
# Solution: Check syntax and data types
instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
```

#### 2. Dynamic Block Issues
```bash
# Error: Dynamic block issues
# Solution: Check for_each value and content structure
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port = ingress.value.from_port
    # ...
  }
}
```

#### 3. Conditional Resource Creation Issues
```bash
# Error: Conditional resource creation issues
# Solution: Check count/for_each values
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  # ...
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform conditional logic
- Knowledge of conditional expressions and ternary operators
- Understanding of dynamic blocks and conditional resource creation
- Ability to create flexible, environment-aware infrastructure

Proceed to [Problem 12: Locals and Functions](../Problem-12-Locals-Functions/) to learn about local values and built-in functions.
