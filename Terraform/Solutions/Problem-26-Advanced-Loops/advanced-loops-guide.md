# Advanced Terraform Loops - Comprehensive Guide

## Overview
This guide covers advanced Terraform looping concepts including complex iteration patterns, nested loops, dynamic resource creation, and performance optimization strategies.

## Advanced Loop Patterns

### Complex For Each Patterns
```hcl
# Complex for_each with nested structures
locals {
  environments = {
    development = {
      instance_count = 1
      instance_type  = "t3.micro"
      enable_monitoring = false
      subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      enable_monitoring = true
      subnets = ["10.1.1.0/24", "10.1.2.0/24"]
    }
    production = {
      instance_count = 3
      instance_type  = "t3.medium"
      enable_monitoring = true
      subnets = ["10.2.1.0/24", "10.2.2.0/24"]
    }
  }
}

# Create VPCs for each environment
resource "aws_vpc" "environment" {
  for_each = local.environments
  
  cidr_block           = "10.${index(keys(local.environments), each.key)}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${each.key}-vpc"
    Environment = each.key
  }
}

# Create subnets for each environment
resource "aws_subnet" "environment" {
  for_each = merge([
    for env_name, env_config in local.environments : {
      for subnet_cidr in env_config.subnets : 
      "${env_name}-${subnet_cidr}" => {
        vpc_id     = aws_vpc.environment[env_name].id
        cidr_block = subnet_cidr
        az_index   = index(env_config.subnets, subnet_cidr)
      }
    }
  ]...)
  
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]
  
  tags = {
    Name        = each.key
    Environment = split("-", each.key)[0]
  }
}
```

### Nested Loop Patterns
```hcl
# Nested loops for complex resource creation
locals {
  regions = ["us-west-2", "us-east-1", "eu-west-1"]
  environments = ["development", "staging", "production"]
  
  # Create a map of all combinations
  region_environment_combinations = merge([
    for region in local.regions : {
      for environment in local.environments : 
      "${region}-${environment}" => {
        region      = region
        environment = environment
        vpc_cidr    = "10.${index(local.regions, region)}.${index(local.environments, environment)}.0/24"
      }
    }
  ]...)
}

# Create resources for each region-environment combination
resource "aws_vpc" "regional" {
  for_each = local.region_environment_combinations
  
  provider = aws.regional[each.value.region]
  
  cidr_block           = each.value.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${each.value.region}-${each.value.environment}-vpc"
    Region      = each.value.region
    Environment = each.value.environment
  }
}
```

## Dynamic Resource Creation

### Conditional Resource Creation with Loops
```hcl
# Conditional resource creation based on environment
locals {
  environment_configs = {
    development = {
      create_database = false
      create_cache   = false
      instance_count = 1
    }
    staging = {
      create_database = true
      create_cache   = false
      instance_count = 2
    }
    production = {
      create_database = true
      create_cache   = true
      instance_count = 3
    }
  }
}

# Create databases conditionally
resource "aws_db_instance" "environment" {
  for_each = {
    for env, config in local.environment_configs : env => config
    if config.create_database
  }
  
  identifier = "${each.key}-database"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "${each.key}_db"
  username = "admin"
  password = random_password.db_password[each.key].result
  
  vpc_security_group_ids = [aws_security_group.database[each.key].id]
  db_subnet_group_name   = aws_db_subnet_group.environment[each.key].name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  tags = {
    Name        = "${each.key}-database"
    Environment = each.key
  }
}

# Create cache clusters conditionally
resource "aws_elasticache_cluster" "environment" {
  for_each = {
    for env, config in local.environment_configs : env => config
    if config.create_cache
  }
  
  cluster_id           = "${each.key}-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name = aws_elasticache_subnet_group.environment[each.key].name
  security_group_ids = [aws_security_group.cache[each.key].id]
  
  tags = {
    Name        = "${each.key}-cache"
    Environment = each.key
  }
}
```

### Complex Data Transformation with Loops
```hcl
# Transform complex data structures
locals {
  # Input data structure
  application_configs = {
    web-app = {
      instances = 3
      instance_type = "t3.medium"
      ports = [80, 443]
      databases = ["users", "products"]
    }
    api-service = {
      instances = 2
      instance_type = "t3.small"
      ports = [8080]
      databases = ["api"]
    }
    worker-service = {
      instances = 1
      instance_type = "t3.large"
      ports = []
      databases = ["jobs"]
    }
  }
  
  # Transform to flat structure for resource creation
  instances = merge([
    for app_name, app_config in local.application_configs : {
      for i in range(app_config.instances) : 
      "${app_name}-${i}" => {
        app_name      = app_name
        instance_type = app_config.instance_type
        instance_index = i
        ports         = app_config.ports
        databases     = app_config.databases
      }
    }
  ]...)
  
  # Transform to security group rules
  security_group_rules = merge([
    for app_name, app_config in local.application_configs : {
      for port in app_config.ports : 
      "${app_name}-${port}" => {
        app_name = app_name
        port     = port
        protocol = "tcp"
      }
    }
  ]...)
}

# Create instances using transformed data
resource "aws_instance" "application" {
  for_each = local.instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  subnet_id = aws_subnet.private[each.value.instance_index % length(aws_subnet.private)].id
  
  vpc_security_group_ids = [
    aws_security_group.application[each.value.app_name].id
  ]
  
  tags = {
    Name        = each.key
    Application = each.value.app_name
    InstanceIndex = each.value.instance_index
  }
}

# Create security group rules using transformed data
resource "aws_security_group_rule" "application" {
  for_each = local.security_group_rules
  
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application[each.value.app_name].id
}
```

## Advanced Count Patterns

### Dynamic Count with Conditions
```hcl
# Dynamic count based on multiple conditions
locals {
  availability_zones = data.aws_availability_zones.available.names
  min_instances_per_az = 1
  max_instances_per_az = 3
  
  # Calculate instances per AZ based on environment
  instances_per_az = var.environment == "production" ? local.max_instances_per_az : local.min_instances_per_az
  
  # Create instance configuration for each AZ
  instance_configs = merge([
    for az_index, az_name in local.availability_zones : {
      for instance_index in range(local.instances_per_az) : 
      "${az_name}-${instance_index}" => {
        az_name        = az_name
        az_index       = az_index
        instance_index = instance_index
        subnet_id      = aws_subnet.private[az_index].id
      }
    }
  ]...)
}

# Create instances using dynamic count
resource "aws_instance" "multi_az" {
  for_each = local.instance_configs
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  subnet_id = each.value.subnet_id
  
  availability_zone = each.value.az_name
  
  tags = {
    Name            = each.key
    AvailabilityZone = each.value.az_name
    InstanceIndex   = each.value.instance_index
    Environment     = var.environment
  }
}
```

### Count with Complex Logic
```hcl
# Complex count logic with multiple factors
locals {
  # Base configuration
  base_instances = 2
  scaling_factor = var.environment == "production" ? 2 : 1
  redundancy_factor = var.environment == "production" ? 2 : 1
  
  # Calculate total instances
  total_instances = local.base_instances * local.scaling_factor * local.redundancy_factor
  
  # Create instance configurations
  instance_configs = {
    for i in range(local.total_instances) : 
    "instance-${i}" => {
      instance_index = i
      az_index       = i % length(data.aws_availability_zones.available.names)
      subnet_index   = i % length(aws_subnet.private)
      instance_type  = i < local.base_instances ? var.instance_type : "${var.instance_type}.large"
    }
  }
}

# Create instances with complex configuration
resource "aws_instance" "complex" {
  for_each = local.instance_configs
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  subnet_id = aws_subnet.private[each.value.subnet_index].id
  
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]
  
  # Dynamic user data based on instance configuration
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    instance_index = each.value.instance_index
    instance_type  = each.value.instance_type
    environment    = var.environment
  }))
  
  tags = {
    Name          = each.key
    InstanceIndex = each.value.instance_index
    InstanceType  = each.value.instance_type
    Environment   = var.environment
  }
}
```

## Performance Optimization

### Loop Performance Best Practices
```hcl
# Optimized loop patterns
locals {
  # Pre-compute expensive operations
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Use efficient data structures
  instance_configs = {
    for i in range(var.instance_count) : 
    "instance-${i}" => {
      instance_index = i
      subnet_id      = local.subnet_ids[i % length(local.subnet_ids)]
      instance_type  = var.instance_type
    }
  }
}

# Use locals to avoid repeated computations
resource "aws_instance" "optimized" {
  for_each = local.instance_configs
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  subnet_id = each.value.subnet_id
  
  # Use pre-computed values
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name          = each.key
    InstanceIndex = each.value.instance_index
  }
}
```

### Memory-Efficient Patterns
```hcl
# Memory-efficient loop patterns
locals {
  # Use sets instead of lists when possible
  required_tags = toset(["Environment", "Project", "Owner"])
  
  # Use maps for efficient lookups
  environment_configs = {
    development = { instance_count = 1, instance_type = "t3.micro" }
    staging     = { instance_count = 2, instance_type = "t3.small" }
    production  = { instance_count = 3, instance_type = "t3.medium" }
  }
  
  # Efficient resource configuration
  resource_configs = {
    for env, config in local.environment_configs : env => {
      for i in range(config.instance_count) : 
      "${env}-${i}" => {
        environment    = env
        instance_type = config.instance_type
        instance_index = i
      }
    }
  }
}
```

## Error Handling and Validation

### Loop Error Handling
```hcl
# Error handling in loops
locals {
  # Validate input data
  validated_environments = {
    for env, config in var.environment_configs : env => config
    if contains(["development", "staging", "production"], env)
  }
  
  # Handle missing configurations
  default_config = {
    instance_count = 1
    instance_type  = "t3.micro"
    enable_monitoring = false
  }
  
  # Merge with defaults
  environment_configs = {
    for env, config in local.validated_environments : env => merge(local.default_config, config)
  }
}

# Create resources with error handling
resource "aws_instance" "validated" {
  for_each = local.environment_configs
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  # Validate instance type
  lifecycle {
    precondition {
      condition     = can(regex("^t3\\.[a-z]+$", each.value.instance_type))
      error_message = "Instance type must be a valid t3 instance type."
    }
  }
  
  tags = {
    Name        = "${each.key}-instance"
    Environment = each.key
  }
}
```

## Advanced Use Cases

### Multi-Region Resource Creation
```hcl
# Multi-region resource creation
locals {
  regions = ["us-west-2", "us-east-1", "eu-west-1"]
  environments = ["development", "staging", "production"]
  
  # Create cross-region configurations
  cross_region_configs = merge([
    for region in local.regions : {
      for environment in local.environments : 
      "${region}-${environment}" => {
        region      = region
        environment = environment
        provider    = "aws.${region}"
      }
    }
  ]...)
}

# Create resources in multiple regions
resource "aws_vpc" "cross_region" {
  for_each = local.cross_region_configs
  
  provider = aws.regional[each.value.region]
  
  cidr_block           = "10.${index(local.regions, each.value.region)}.${index(local.environments, each.value.environment)}.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${each.value.region}-${each.value.environment}-vpc"
    Region      = each.value.region
    Environment = each.value.environment
  }
}
```

### Complex Dependency Management
```hcl
# Complex dependency management with loops
locals {
  # Define service dependencies
  service_dependencies = {
    web-app = ["database", "cache"]
    api-service = ["database"]
    worker-service = ["database", "queue"]
  }
  
  # Create dependency configurations
  dependency_configs = merge([
    for service, dependencies in local.service_dependencies : {
      for dependency in dependencies : 
      "${service}-${dependency}" => {
        service     = service
        dependency  = dependency
        depends_on  = aws_instance.service[dependency].id
      }
    }
  ]...)
}

# Create resources with dependencies
resource "aws_instance" "service" {
  for_each = var.services
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  # Dynamic dependencies
  depends_on = [
    for dep in local.service_dependencies[each.key] : aws_instance.service[dep]
  ]
  
  tags = {
    Name        = each.key
    Service     = each.key
    Environment = var.environment
  }
}
```

## Best Practices

### Loop Design Best Practices
- **Clarity**: Use clear and descriptive loop variable names
- **Efficiency**: Optimize loop performance and memory usage
- **Validation**: Validate loop inputs and outputs
- **Documentation**: Document complex loop logic
- **Testing**: Test loop behavior thoroughly

### Performance Best Practices
- **Pre-computation**: Pre-compute expensive operations
- **Efficient Data Structures**: Use appropriate data structures
- **Memory Management**: Optimize memory usage in loops
- **Parallel Execution**: Enable parallel resource creation
- **State Optimization**: Optimize state file size

## Conclusion

Advanced Terraform loops enable sophisticated infrastructure patterns and dynamic resource creation. By implementing complex iteration patterns, performance optimization strategies, and robust error handling, you can build flexible and efficient infrastructure configurations.

Regular review and optimization of loop patterns ensure continued effectiveness and adaptation to changing requirements and performance needs.
