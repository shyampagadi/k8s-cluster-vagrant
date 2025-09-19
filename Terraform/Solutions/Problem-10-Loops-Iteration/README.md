# Problem 10: Loops and Iteration - Count and For Each

## Overview

This solution provides comprehensive understanding of Terraform loops and iteration, focusing on the `count` and `for_each` meta-arguments. These are essential for creating multiple resources dynamically and managing resource collections effectively.

## Learning Objectives

- Understand Terraform loop concepts and purposes
- Master the `count` meta-argument for resource iteration
- Learn the `for_each` meta-argument for map-based iteration
- Understand when to use `count` vs `for_each`
- Learn advanced iteration patterns and expressions
- Master iteration with complex data structures
- Understand performance considerations and best practices

## Problem Statement

You've mastered data sources and external integration. Now your team lead wants you to become proficient in Terraform loops and iteration, starting with `count` and `for_each` meta-arguments. You need to understand how to create multiple resources dynamically and manage resource collections effectively.

## Solution Components

This solution includes:
1. **Loop Fundamentals** - Understanding what loops are and why they're important
2. **Count Meta-argument** - Creating multiple resources with count
3. **For Each Meta-argument** - Map-based resource iteration
4. **Advanced Patterns** - Complex iteration scenarios
5. **Performance Considerations** - Optimizing loop performance
6. **Best Practices** - When to use count vs for_each
7. **Troubleshooting** - Common issues and solutions

## Implementation Guide

### Step 1: Understanding Loop Fundamentals

#### What are Loops in Terraform?
Loops in Terraform allow you to create multiple resources dynamically without duplicating code. They serve several purposes:
- **Resource Multiplication**: Create multiple instances of the same resource
- **Dynamic Configuration**: Configure resources based on data structures
- **Collection Management**: Manage groups of related resources
- **Code Reusability**: Avoid duplicating resource definitions

#### Loop Benefits
- **DRY Principle**: Don't Repeat Yourself
- **Dynamic Scaling**: Create resources based on variables
- **Configuration Flexibility**: Adapt to different environments
- **Maintenance Efficiency**: Update one definition affects all instances

### Step 2: Count Meta-argument

#### Basic Count Usage
```hcl
# Create multiple instances using count
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Type = "Web Server"
  }
}

# Create multiple subnets using count
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
    AZ   = var.availability_zones[count.index]
  }
}
```

#### Count with Conditional Logic
```hcl
# Conditional resource creation with count
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

# Count based on environment
resource "aws_instance" "web" {
  count = var.environment == "production" ? 3 : 1
  
  ami           = var.ami_id
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Environment = var.environment
  }
}
```

#### Count with Splat Expressions
```hcl
# Using splat expressions with count
output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of instance public IPs"
  value       = aws_instance.web[*].public_ip
}

# Using splat expressions in resources
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

### Step 3: For Each Meta-argument

#### Basic For Each Usage
```hcl
# Create resources using for_each with a map
resource "aws_instance" "web" {
  for_each = var.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = each.key
    Type = each.value.type
    Environment = each.value.environment
  }
}

# Create resources using for_each with a set
resource "aws_security_group" "web" {
  for_each = toset(var.security_group_names)
  
  name_prefix = "${each.value}-"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = each.value
    Type = "Security Group"
  }
}
```

#### For Each with Complex Data Structures
```hcl
# For each with complex object data
resource "aws_instance" "web" {
  for_each = var.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  # Dynamic block based on each.value
  dynamic "ebs_block_device" {
    for_each = each.value.ebs_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
    }
  }
  
  tags = merge(each.value.tags, {
    Name = each.key
    Type = "Web Server"
  })
}
```

#### For Each with Conditional Logic
```hcl
# Conditional for_each based on environment
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

# For each with filtering
resource "aws_instance" "web" {
  for_each = {
    for name, config in var.server_configs : name => config
    if config.environment == "production"
  }
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = each.key
    Environment = each.value.environment
  }
}
```

### Step 4: Advanced Iteration Patterns

#### Nested Iteration
```hcl
# Nested iteration with count and for_each
resource "aws_instance" "web" {
  for_each = var.environments
  
  count = each.value.instance_count
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${each.key}-web-${count.index + 1}"
    Environment = each.key
  }
}
```

#### Dynamic Blocks with Iteration
```hcl
# Dynamic blocks with for_each
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
```

#### Complex Data Structure Iteration
```hcl
# Iteration with complex nested data
resource "aws_instance" "web" {
  for_each = var.server_configs
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  # Dynamic user data based on configuration
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = each.value.app_name
    environment = each.value.environment
    features = each.value.features
  }))
  
  tags = merge(each.value.tags, {
    Name = each.key
    Type = "Web Server"
  })
}
```

### Step 5: Count vs For Each Comparison

#### When to Use Count
```hcl
# Use count for:
# 1. Simple numeric iteration
resource "aws_instance" "web" {
  count = 3
  # ...
}

# 2. List-based iteration
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  # ...
}

# 3. Conditional resource creation
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  # ...
}
```

#### When to Use For Each
```hcl
# Use for_each for:
# 1. Map-based iteration
resource "aws_instance" "web" {
  for_each = var.server_configs
  # ...
}

# 2. Set-based iteration
resource "aws_security_group" "web" {
  for_each = toset(var.security_group_names)
  # ...
}

# 3. Complex data structures
resource "aws_instance" "web" {
  for_each = var.environments
  # ...
}
```

### Step 6: Performance Considerations

#### Optimizing Count Performance
```hcl
# Use locals for computed values
locals {
  instance_count = var.environment == "production" ? 3 : 1
  subnet_count = length(var.availability_zones)
}

resource "aws_instance" "web" {
  count = local.instance_count
  # ...
}

resource "aws_subnet" "public" {
  count = local.subnet_count
  # ...
}
```

#### Optimizing For Each Performance
```hcl
# Use locals for data transformation
locals {
  server_configs = {
    for name, config in var.server_configs : name => {
      instance_type = config.instance_type
      disk_size = config.disk_size * 1024  # Convert GB to MB
      monitoring = config.monitoring
    }
  }
}

resource "aws_instance" "web" {
  for_each = local.server_configs
  # ...
}
```

### Step 7: Best Practices

#### Resource Naming
```hcl
# Consistent naming patterns
resource "aws_instance" "web" {
  count = var.instance_count
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
    Type = "Web Server"
    Index = count.index + 1
  }
}

resource "aws_instance" "web" {
  for_each = var.server_configs
  
  tags = {
    Name = "${var.project_name}-${each.key}"
    Type = "Web Server"
    ServerName = each.key
  }
}
```

#### Error Handling
```hcl
# Validate iteration data
variable "server_configs" {
  description = "Server configurations"
  type = map(object({
    instance_type = string
    disk_size     = number
    monitoring    = bool
  }))
  
  validation {
    condition     = alltrue([for name, config in var.server_configs : config.disk_size > 0])
    error_message = "All disk sizes must be greater than 0."
  }
}
```

## Expected Deliverables

### 1. Count Meta-argument Examples
- Basic count usage with numeric iteration
- Count with conditional logic
- Count with splat expressions
- Count performance optimization

### 2. For Each Meta-argument Examples
- Basic for_each with map iteration
- For_each with set iteration
- For_each with complex data structures
- For_each with conditional logic

### 3. Advanced Iteration Patterns
- Nested iteration scenarios
- Dynamic blocks with iteration
- Complex data structure iteration
- Performance optimization techniques

### 4. Count vs For Each Comparison
- When to use count vs for_each
- Performance considerations
- Use case examples
- Best practices

### 5. Best Practices Implementation
- Resource naming conventions
- Error handling patterns
- Performance optimization
- Maintenance guidelines

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are Terraform loops, and why are they important?**
   - Loops allow creating multiple resources dynamically without duplicating code
   - They enable resource multiplication, dynamic configuration, and code reusability

2. **What is the difference between count and for_each?**
   - Count: Numeric iteration, creates resources with count.index
   - For_each: Map/set iteration, creates resources with each.key and each.value

3. **When should you use count vs for_each?**
   - Count: Simple numeric iteration, list-based iteration, conditional creation
   - For_each: Map-based iteration, set-based iteration, complex data structures

4. **How do you handle conditional resource creation with loops?**
   - Count: count = condition ? value : 0
   - For_each: Use conditional expressions in the for_each value

5. **What are splat expressions, and how do you use them?**
   - Splat expressions (*) create lists from count/for_each resources
   - Example: aws_instance.web[*].id

6. **How do you optimize loop performance?**
   - Use locals for computed values
   - Avoid complex calculations in resource definitions
   - Consider resource creation order

7. **What are the best practices for loop resource naming?**
   - Use consistent naming patterns
   - Include index or key in names
   - Use meaningful prefixes and suffixes

## Troubleshooting

### Common Loop Issues

#### 1. Index Out of Range
```bash
# Error: Index out of range
# Solution: Check count value and array length
resource "aws_instance" "web" {
  count = var.instance_count
  subnet_id = aws_subnet.public[count.index].id  # Ensure count <= length(aws_subnet.public)
}
```

#### 2. For Each Key Conflicts
```bash
# Error: Duplicate key in for_each
# Solution: Ensure unique keys
resource "aws_instance" "web" {
  for_each = var.server_configs  # Ensure all keys are unique
  # ...
}
```

#### 3. Conditional Loop Issues
```bash
# Error: Conditional loop issues
# Solution: Use proper conditional expressions
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  # ...
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform loops and iteration
- Knowledge of count and for_each meta-arguments
- Understanding of when to use each approach
- Ability to optimize loop performance

Proceed to [Problem 11: Conditional Logic and Dynamic Blocks](../Problem-11-Conditional-Logic/) to learn about advanced conditional patterns and dynamic resource creation.
