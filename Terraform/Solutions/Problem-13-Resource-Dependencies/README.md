# Problem 13: Resource Dependencies

## Overview

This solution provides comprehensive understanding of Terraform resource dependencies, focusing on implicit and explicit dependencies, dependency management, and advanced dependency patterns. These are essential for creating reliable, well-ordered infrastructure deployments.

## Learning Objectives

- Understand Terraform dependency concepts and purposes
- Master implicit dependencies and resource references
- Learn explicit dependencies with depends_on
- Understand dependency graphs and execution order
- Master advanced dependency patterns and scenarios
- Learn performance considerations and best practices
- Understand troubleshooting dependency issues

## Problem Statement

You've mastered local values and built-in functions. Now your team lead wants you to become proficient in Terraform resource dependencies, focusing on implicit and explicit dependencies, dependency management, and advanced dependency patterns. You need to understand how to create reliable, well-ordered infrastructure deployments.

## Solution Components

This solution includes:
1. **Dependency Fundamentals** - Understanding what dependencies are and why they're important
2. **Implicit Dependencies** - Resource references and automatic dependency detection
3. **Explicit Dependencies** - Using depends_on for explicit dependency management
4. **Dependency Graphs** - Understanding execution order and dependency resolution
5. **Advanced Dependency Patterns** - Complex dependency scenarios
6. **Performance Considerations** - Optimizing dependency performance
7. **Best Practices** - When and how to use dependencies effectively

## Implementation Guide

### Step 1: Understanding Dependency Fundamentals

#### What are Resource Dependencies in Terraform?
Resource dependencies in Terraform define the order in which resources are created, updated, and destroyed. They serve several purposes:
- **Execution Order**: Ensure resources are created in the correct order
- **Resource Relationships**: Define relationships between resources
- **Data Flow**: Ensure data is available when needed
- **Reliability**: Prevent resource creation failures due to missing dependencies

#### Dependency Benefits
- **Reliable Deployments**: Ensure resources are created in the correct order
- **Data Availability**: Ensure data is available when resources need it
- **Relationship Management**: Define clear relationships between resources
- **Error Prevention**: Prevent resource creation failures

### Step 2: Implicit Dependencies

#### Basic Implicit Dependencies
```hcl
# Implicit dependencies through resource references
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency on aws_vpc.main
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id  # Implicit dependency on aws_subnet.public
  
  tags = {
    Name = "web-instance"
  }
}
```

#### Advanced Implicit Dependencies
```hcl
# Complex implicit dependencies
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency
  
  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # Implicit dependency
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Implicit dependency
  }
  
  tags = {
    Name = "public-rt"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id  # Implicit dependency
  route_table_id = aws_route_table.public.id  # Implicit dependency
}
```

### Step 3: Explicit Dependencies

#### Basic Explicit Dependencies
```hcl
# Explicit dependencies using depends_on
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Explicit dependency on security group
  depends_on = [aws_security_group.web]
  
  tags = {
    Name = "web-instance"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "web-sg"
  }
}
```

#### Advanced Explicit Dependencies
```hcl
# Complex explicit dependencies
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  # Explicit dependencies on multiple resources
  depends_on = [
    aws_security_group.web,
    aws_route_table_association.public,
    aws_db_instance.main
  ]
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

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
  
  # Explicit dependency on subnet group
  depends_on = [aws_db_subnet_group.main]
  
  tags = {
    Name = "main-db"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "main-db-subnet-group"
  }
}
```

### Step 4: Dependency Graphs and Execution Order

#### Understanding Dependency Resolution
```hcl
# Dependency graph example
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

# Level 1: VPC-dependent resources
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  
  tags = {
    Name = "private-subnet"
  }
}

# Level 2: Gateway and subnet-dependent resources
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "public-rt"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private.id]
  
  tags = {
    Name = "main-db-subnet-group"
  }
}

# Level 3: Route table and subnet group-dependent resources
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

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
  
  tags = {
    Name = "main-db"
  }
}

# Level 4: All previous resources-dependent resources
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "web-instance"
  }
}
```

### Step 5: Advanced Dependency Patterns

#### Conditional Dependencies
```hcl
# Conditional dependencies
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  # Conditional explicit dependency
  depends_on = var.create_database ? [aws_db_instance.main] : [aws_security_group.web]
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "main-db"
  
  engine    = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "webapp"
  username = "admin"
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  tags = {
    Name = "main-db"
  }
}
```

#### Circular Dependency Avoidance
```hcl
# Avoiding circular dependencies
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Don't create circular dependency with security group
  # Security group should not depend on instance
  
  tags = {
    Name = "web-instance"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # No dependency on instance to avoid circular dependency
  
  tags = {
    Name = "web-sg"
  }
}
```

### Step 6: Performance Considerations

#### Optimizing Dependencies
```hcl
# Optimizing dependency performance
locals {
  # Pre-compute dependency lists
  web_dependencies = [
    aws_security_group.web,
    aws_route_table_association.public
  ]
  
  database_dependencies = [
    aws_db_subnet_group.main,
    aws_security_group.database
  ]
  
  # Conditional dependency lists
  conditional_dependencies = var.create_database ? 
    concat(local.web_dependencies, local.database_dependencies) : 
    local.web_dependencies
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Use pre-computed dependencies
  depends_on = local.conditional_dependencies
  
  tags = {
    Name = "web-instance"
  }
}
```

### Step 7: Best Practices

#### Dependency Best Practices
```hcl
# Best practices for dependencies
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Use explicit dependencies only when necessary
  depends_on = [
    aws_security_group.web,
    aws_route_table_association.public
  ]
  
  tags = {
    Name = "web-instance"
  }
}

# Use implicit dependencies when possible
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

# Document complex dependencies
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Explicit dependencies for complex scenarios
  depends_on = [
    aws_security_group.web,      # Security group must exist
    aws_route_table_association.public,  # Route table must be associated
    aws_db_instance.main         # Database must be ready
  ]
  
  tags = {
    Name = "web-instance"
  }
}
```

## Expected Deliverables

### 1. Implicit Dependency Examples
- Basic resource references and automatic dependency detection
- Complex implicit dependency chains
- Data flow and resource relationships
- Performance optimization techniques

### 2. Explicit Dependency Examples
- Basic depends_on usage
- Complex explicit dependency scenarios
- Conditional dependencies
- Circular dependency avoidance

### 3. Dependency Graph Examples
- Understanding execution order
- Dependency resolution patterns
- Resource creation sequencing
- Error handling and recovery

### 4. Advanced Dependency Patterns
- Conditional dependencies
- Circular dependency avoidance
- Performance optimization
- Complex dependency scenarios

### 5. Best Practices Implementation
- When to use implicit vs explicit dependencies
- Performance optimization techniques
- Error handling patterns
- Maintenance guidelines

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are resource dependencies in Terraform, and why are they important?**
   - Dependencies define the order in which resources are created, updated, and destroyed
   - They ensure reliable deployments and proper resource relationships

2. **What are the main types of dependencies?**
   - Implicit dependencies: through resource references
   - Explicit dependencies: using depends_on

3. **How do implicit dependencies work?**
   - Terraform automatically detects dependencies through resource references
   - Resources are created in the correct order based on references

4. **When should you use explicit dependencies?**
   - When implicit dependencies are not sufficient
   - For complex dependency scenarios
   - When you need to ensure specific creation order

5. **How do you avoid circular dependencies?**
   - Design resource relationships carefully
   - Use data sources when possible
   - Avoid bidirectional dependencies

6. **What are the best practices for dependencies?**
   - Use implicit dependencies when possible
   - Use explicit dependencies only when necessary
   - Document complex dependencies
   - Consider performance implications

7. **How do you optimize dependency performance?**
   - Use locals for pre-computed dependency lists
   - Minimize unnecessary dependencies
   - Consider resource creation order
   - Use conditional dependencies appropriately

## Troubleshooting

### Common Dependency Issues

#### 1. Circular Dependencies
```bash
# Error: Circular dependency detected
# Solution: Redesign resource relationships
resource "aws_instance" "web" {
  # Don't create circular dependency
  depends_on = [aws_security_group.web]
}

resource "aws_security_group" "web" {
  # Don't depend on instance
  # depends_on = [aws_instance.web]  # This creates circular dependency
}
```

#### 2. Missing Dependencies
```bash
# Error: Resource not found
# Solution: Add explicit dependency
resource "aws_instance" "web" {
  depends_on = [aws_security_group.web]
}
```

#### 3. Dependency Order Issues
```bash
# Error: Dependency order issues
# Solution: Check dependency graph
resource "aws_instance" "web" {
  depends_on = [
    aws_security_group.web,
    aws_route_table_association.public
  ]
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform resource dependencies
- Knowledge of implicit and explicit dependencies
- Understanding of dependency graphs and execution order
- Ability to create reliable, well-ordered infrastructure

Proceed to [Problem 14: Lifecycle Rules](../Problem-14-Lifecycle-Rules/) to learn about resource lifecycle management and advanced lifecycle patterns.
