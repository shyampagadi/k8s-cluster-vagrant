# Problem 14: Lifecycle Rules

## Overview

This solution provides comprehensive understanding of Terraform lifecycle rules, focusing on resource lifecycle management, advanced lifecycle patterns, and production-grade lifecycle strategies. These are essential for creating robust, production-ready infrastructure deployments.

## Learning Objectives

- Understand Terraform lifecycle concepts and purposes
- Master create_before_destroy lifecycle rule
- Learn prevent_destroy lifecycle rule
- Understand ignore_changes lifecycle rule
- Master advanced lifecycle patterns and scenarios
- Learn production-grade lifecycle strategies
- Understand troubleshooting lifecycle issues

## Problem Statement

You've mastered resource dependencies and execution order. Now your team lead wants you to become proficient in Terraform lifecycle rules, focusing on resource lifecycle management, advanced lifecycle patterns, and production-grade lifecycle strategies. You need to understand how to create robust, production-ready infrastructure deployments.

## Solution Components

This solution includes:
1. **Lifecycle Fundamentals** - Understanding what lifecycle rules are and why they're important
2. **Create Before Destroy** - Managing resource replacement and zero-downtime deployments
3. **Prevent Destroy** - Protecting critical resources from accidental deletion
4. **Ignore Changes** - Managing resource drift and external modifications
5. **Advanced Lifecycle Patterns** - Complex lifecycle scenarios
6. **Production Strategies** - Production-grade lifecycle management
7. **Best Practices** - When and how to use lifecycle rules effectively

## Implementation Guide

### Step 1: Understanding Lifecycle Fundamentals

#### What are Lifecycle Rules in Terraform?
Lifecycle rules in Terraform control how resources are created, updated, and destroyed. They serve several purposes:
- **Resource Replacement**: Control how resources are replaced during updates
- **Resource Protection**: Prevent accidental resource deletion
- **Drift Management**: Handle external modifications to resources
- **Zero-Downtime Deployments**: Ensure continuous service availability

#### Lifecycle Rules Benefits
- **Zero-Downtime Deployments**: Replace resources without service interruption
- **Resource Protection**: Prevent accidental deletion of critical resources
- **Drift Management**: Handle external modifications gracefully
- **Production Readiness**: Create robust, production-grade infrastructure

### Step 2: Create Before Destroy

#### Basic Create Before Destroy
```hcl
# Basic create_before_destroy for zero-downtime deployments
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Create new instance before destroying old one
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "web-instance"
  }
}

# Create before destroy for load balancer
resource "aws_lb" "web" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  # Create new load balancer before destroying old one
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "web-lb"
  }
}
```

#### Advanced Create Before Destroy
```hcl
# Advanced create_before_destroy with complex resources
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Create new instances before destroying old ones
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

# Create before destroy for database
resource "aws_db_instance" "main" {
  identifier = "main-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Create new database before destroying old one
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "main-db"
  }
}
```

### Step 3: Prevent Destroy

#### Basic Prevent Destroy
```hcl
# Basic prevent_destroy for critical resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  # Prevent accidental deletion of VPC
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "main-vpc"
  }
}

# Prevent destroy for production database
resource "aws_db_instance" "production" {
  count = var.environment == "production" ? 1 : 0
  
  identifier = "production-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  
  db_name  = "production"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  # Prevent accidental deletion of production database
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "production-db"
    Environment = "production"
  }
}
```

#### Advanced Prevent Destroy
```hcl
# Advanced prevent_destroy with conditional logic
resource "aws_s3_bucket" "critical_data" {
  bucket = "critical-data-bucket"
  
  # Prevent destroy for critical data bucket
  lifecycle {
    prevent_destroy = var.environment == "production" ? true : false
  }
  
  tags = {
    Name = "critical-data-bucket"
    Environment = var.environment
  }
}

# Prevent destroy for production resources
resource "aws_instance" "production" {
  count = var.environment == "production" ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = "t3.large"
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Prevent accidental deletion of production instances
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "production-instance-${count.index + 1}"
    Environment = "production"
  }
}
```

### Step 4: Ignore Changes

#### Basic Ignore Changes
```hcl
# Basic ignore_changes for external modifications
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Ignore changes to tags made outside Terraform
  lifecycle {
    ignore_changes = [tags]
  }
  
  tags = {
    Name = "web-instance"
    Environment = var.environment
  }
}

# Ignore changes to user data
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    app_name = var.app_name
    environment = var.environment
  }))
  
  # Ignore changes to user data made outside Terraform
  lifecycle {
    ignore_changes = [user_data]
  }
  
  tags = {
    Name = "web-instance"
  }
}
```

#### Advanced Ignore Changes
```hcl
# Advanced ignore_changes with multiple attributes
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Ignore changes to multiple attributes
  lifecycle {
    ignore_changes = [
      tags,
      user_data,
      vpc_security_group_ids
    ]
  }
  
  tags = {
    Name = "web-instance"
    Environment = var.environment
  }
}

# Ignore changes to specific tag keys
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Ignore changes to specific tag keys
  lifecycle {
    ignore_changes = [
      tags["LastModified"],
      tags["ModifiedBy"]
    ]
  }
  
  tags = {
    Name = "web-instance"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "admin"
  }
}
```

### Step 5: Advanced Lifecycle Patterns

#### Combined Lifecycle Rules
```hcl
# Combined lifecycle rules for production resources
resource "aws_instance" "production" {
  count = var.environment == "production" ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = "t3.large"
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Combined lifecycle rules
  lifecycle {
    create_before_destroy = true  # Zero-downtime deployment
    prevent_destroy = true         # Prevent accidental deletion
    ignore_changes = [tags]        # Ignore external tag changes
  }
  
  tags = {
    Name = "production-instance-${count.index + 1}"
    Environment = "production"
  }
}

# Combined lifecycle rules for database
resource "aws_db_instance" "production" {
  count = var.environment == "production" ? 1 : 0
  
  identifier = "production-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  
  db_name  = "production"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  # Combined lifecycle rules
  lifecycle {
    create_before_destroy = true  # Zero-downtime deployment
    prevent_destroy = true         # Prevent accidental deletion
    ignore_changes = [
      password,                   # Ignore password changes
      tags["LastModified"]        # Ignore external tag changes
    ]
  }
  
  tags = {
    Name = "production-db"
    Environment = "production"
    LastModified = timestamp()
  }
}
```

#### Environment-Specific Lifecycle Rules
```hcl
# Environment-specific lifecycle rules
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Environment-specific lifecycle rules
  lifecycle {
    create_before_destroy = var.environment == "production" ? true : false
    prevent_destroy = var.environment == "production" ? true : false
    ignore_changes = var.environment == "production" ? [tags] : []
  }
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# Environment-specific database lifecycle rules
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "main-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = var.environment == "production" ? "db.r5.large" : "db.t3.micro"
  
  allocated_storage     = var.environment == "production" ? 100 : 20
  max_allocated_storage = var.environment == "production" ? 1000 : 100
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  # Environment-specific lifecycle rules
  lifecycle {
    create_before_destroy = var.environment == "production" ? true : false
    prevent_destroy = var.environment == "production" ? true : false
    ignore_changes = var.environment == "production" ? [password, tags] : [tags]
  }
  
  tags = {
    Name = "main-db"
    Environment = var.environment
  }
}
```

### Step 6: Production Strategies

#### Production-Grade Lifecycle Management
```hcl
# Production-grade lifecycle management
resource "aws_instance" "production" {
  count = var.environment == "production" ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = "t3.large"
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Production-grade lifecycle rules
  lifecycle {
    create_before_destroy = true  # Zero-downtime deployment
    prevent_destroy = true        # Prevent accidental deletion
    ignore_changes = [
      tags["LastModified"],       # Ignore external tag changes
      tags["ModifiedBy"],         # Ignore external tag changes
      user_data                   # Ignore external user data changes
    ]
  }
  
  tags = {
    Name = "production-instance-${count.index + 1}"
    Environment = "production"
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Production-grade database lifecycle management
resource "aws_db_instance" "production" {
  count = var.environment == "production" ? 1 : 0
  
  identifier = "production-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  
  db_name  = "production"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  # Production-grade lifecycle rules
  lifecycle {
    create_before_destroy = true  # Zero-downtime deployment
    prevent_destroy = true        # Prevent accidental deletion
    ignore_changes = [
      password,                   # Ignore password changes
      tags["LastModified"],       # Ignore external tag changes
      tags["ModifiedBy"]          # Ignore external tag changes
    ]
  }
  
  tags = {
    Name = "production-db"
    Environment = "production"
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}
```

### Step 7: Best Practices

#### Lifecycle Rule Best Practices
```hcl
# Best practices for lifecycle rules
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Best practices for lifecycle rules
  lifecycle {
    # Use create_before_destroy for zero-downtime deployments
    create_before_destroy = var.environment == "production" ? true : false
    
    # Use prevent_destroy for critical resources
    prevent_destroy = var.environment == "production" ? true : false
    
    # Use ignore_changes for external modifications
    ignore_changes = [
      tags["LastModified"],
      tags["ModifiedBy"],
      user_data
    ]
  }
  
  tags = {
    Name = "web-instance"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}

# Document lifecycle rules
resource "aws_db_instance" "main" {
  identifier = "main-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Document lifecycle rules
  lifecycle {
    # Zero-downtime deployment for production
    create_before_destroy = var.environment == "production" ? true : false
    
    # Prevent accidental deletion of production database
    prevent_destroy = var.environment == "production" ? true : false
    
    # Ignore external modifications
    ignore_changes = [
      password,                   # Ignore password changes
      tags["LastModified"],       # Ignore external tag changes
      tags["ModifiedBy"]          # Ignore external tag changes
    ]
  }
  
  tags = {
    Name = "main-db"
    Environment = var.environment
    LastModified = timestamp()
    ModifiedBy = "terraform"
  }
}
```

## Expected Deliverables

### 1. Create Before Destroy Examples
- Basic create_before_destroy usage
- Advanced create_before_destroy scenarios
- Zero-downtime deployment patterns
- Performance optimization techniques

### 2. Prevent Destroy Examples
- Basic prevent_destroy usage
- Advanced prevent_destroy scenarios
- Critical resource protection
- Conditional prevent_destroy patterns

### 3. Ignore Changes Examples
- Basic ignore_changes usage
- Advanced ignore_changes scenarios
- External modification handling
- Drift management patterns

### 4. Advanced Lifecycle Patterns
- Combined lifecycle rules
- Environment-specific lifecycle rules
- Production-grade lifecycle management
- Complex lifecycle scenarios

### 5. Best Practices Implementation
- When to use each lifecycle rule
- Performance optimization techniques
- Error handling patterns
- Maintenance guidelines

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are lifecycle rules in Terraform, and why are they important?**
   - Lifecycle rules control how resources are created, updated, and destroyed
   - They enable zero-downtime deployments, resource protection, and drift management

2. **What are the main lifecycle rules?**
   - create_before_destroy: Create new resource before destroying old one
   - prevent_destroy: Prevent accidental resource deletion
   - ignore_changes: Ignore external modifications to resources

3. **When should you use create_before_destroy?**
   - For zero-downtime deployments
   - When replacing resources that provide services
   - For production environments

4. **When should you use prevent_destroy?**
   - For critical resources
   - For production environments
   - For resources that cannot be easily recreated

5. **When should you use ignore_changes?**
   - For external modifications to resources
   - For tags that are managed outside Terraform
   - For attributes that change frequently

6. **What are the best practices for lifecycle rules?**
   - Use create_before_destroy for zero-downtime deployments
   - Use prevent_destroy for critical resources
   - Use ignore_changes for external modifications
   - Document lifecycle rules clearly

7. **How do you optimize lifecycle rule performance?**
   - Use conditional lifecycle rules
   - Minimize unnecessary lifecycle rules
   - Consider resource creation order
   - Use appropriate lifecycle rules for each environment

## Troubleshooting

### Common Lifecycle Issues

#### 1. Create Before Destroy Issues
```bash
# Error: Cannot create resource before destroying
# Solution: Check resource dependencies and constraints
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
  }
}
```

#### 2. Prevent Destroy Issues
```bash
# Error: Cannot destroy resource
# Solution: Temporarily disable prevent_destroy
resource "aws_instance" "web" {
  lifecycle {
    prevent_destroy = false  # Temporarily disable
  }
}
```

#### 3. Ignore Changes Issues
```bash
# Error: Ignore changes not working
# Solution: Check attribute names and syntax
resource "aws_instance" "web" {
  lifecycle {
    ignore_changes = [tags]  # Correct syntax
  }
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform lifecycle rules
- Knowledge of create_before_destroy, prevent_destroy, and ignore_changes
- Understanding of advanced lifecycle patterns
- Ability to create robust, production-ready infrastructure

Proceed to [Problem 15: Workspaces and Environment Management](../Problem-15-Workspaces-Environments/) to learn about Terraform workspaces and environment management strategies.
