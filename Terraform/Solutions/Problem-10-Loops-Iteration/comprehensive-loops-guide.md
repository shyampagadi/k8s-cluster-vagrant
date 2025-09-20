# Terraform Loops and Iteration - Complete Implementation Guide

## Overview

This comprehensive guide covers Terraform's loop mechanisms including `count`, `for_each`, and advanced iteration patterns. Mastering these concepts is essential for creating scalable, maintainable infrastructure configurations.

## Loop Fundamentals

### Why Use Loops in Terraform?

Loops enable:
- **Resource Multiplication**: Create multiple instances without code duplication
- **Dynamic Configuration**: Adapt resources based on input data
- **Collection Management**: Handle groups of related resources
- **Code Reusability**: Follow DRY (Don't Repeat Yourself) principles

### Loop Types in Terraform

1. **Count Meta-argument**: Integer-based iteration
2. **For_each Meta-argument**: Map/set-based iteration
3. **For Expressions**: Data transformation
4. **Dynamic Blocks**: Nested block iteration

## Count Meta-argument Deep Dive

### Basic Count Usage

```hcl
# Create multiple EC2 instances
resource "aws_instance" "web" {
  count = 3
  
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
```

### Count with Variables

```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 3
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
```

### Conditional Count

```hcl
variable "create_instances" {
  description = "Whether to create instances"
  type        = bool
  default     = true
}

resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
```

### Count with Lists

```hcl
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
    AZ   = var.availability_zones[count.index]
  }
}
```

## For_each Meta-argument Deep Dive

### Basic For_each with Sets

```hcl
variable "user_names" {
  description = "Set of user names"
  type        = set(string)
  default     = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "users" {
  for_each = var.user_names
  
  name = each.value
  
  tags = {
    Name = each.value
    Type = "terraform-managed"
  }
}
```

### For_each with Maps

```hcl
variable "environments" {
  description = "Map of environments and their configurations"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
  }))
  default = {
    dev = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 2
    }
    staging = {
      instance_type = "t3.small"
      min_size      = 2
      max_size      = 4
    }
    prod = {
      instance_type = "t3.medium"
      min_size      = 3
      max_size      = 10
    }
  }
}

resource "aws_autoscaling_group" "app" {
  for_each = var.environments
  
  name                = "${each.key}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = each.value.min_size
  max_size            = each.value.max_size
  desired_capacity    = each.value.min_size
  
  launch_template {
    id      = aws_launch_template.app[each.key].id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${each.key}-asg"
    propagate_at_launch = false
  }
  
  tag {
    key                 = "Environment"
    value               = each.key
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "app" {
  for_each = var.environments
  
  name_prefix   = "${each.key}-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  
  vpc_security_group_ids = [aws_security_group.app[each.key].id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = each.key
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${each.key}-instance"
      Environment = each.key
    }
  }
}
```

### For_each with Complex Objects

```hcl
variable "security_groups" {
  description = "Map of security groups and their rules"
  type = map(object({
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
  default = {
    web = {
      description = "Web server security group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    database = {
      description = "Database security group"
      ingress_rules = [
        {
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
        }
      ]
      egress_rules = []
    }
  }
}

resource "aws_security_group" "app" {
  for_each = var.security_groups
  
  name_prefix = "${each.key}-sg-"
  description = each.value.description
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = {
    Name = "${each.key}-security-group"
    Type = each.key
  }
}
```

## For Expressions

### List Transformation

```hcl
variable "users" {
  type = list(object({
    name  = string
    role  = string
    email = string
  }))
  default = [
    {
      name  = "alice"
      role  = "admin"
      email = "alice@example.com"
    },
    {
      name  = "bob"
      role  = "user"
      email = "bob@example.com"
    },
    {
      name  = "charlie"
      role  = "admin"
      email = "charlie@example.com"
    }
  ]
}

locals {
  # Extract user names
  user_names = [for user in var.users : user.name]
  
  # Extract admin users
  admin_users = [for user in var.users : user if user.role == "admin"]
  
  # Create email map
  user_emails = {
    for user in var.users : user.name => user.email
  }
  
  # Transform to uppercase names
  upper_names = [for user in var.users : upper(user.name)]
}
```

### Map Transformation

```hcl
variable "servers" {
  type = map(object({
    instance_type = string
    disk_size     = number
    environment   = string
  }))
  default = {
    web1 = {
      instance_type = "t3.micro"
      disk_size     = 20
      environment   = "production"
    }
    web2 = {
      instance_type = "t3.small"
      disk_size     = 30
      environment   = "staging"
    }
    db1 = {
      instance_type = "t3.medium"
      disk_size     = 100
      environment   = "production"
    }
  }
}

locals {
  # Filter production servers
  production_servers = {
    for name, config in var.servers : name => config
    if config.environment == "production"
  }
  
  # Transform disk sizes to GB
  server_disk_gb = {
    for name, config in var.servers : name => {
      instance_type = config.instance_type
      disk_size_gb  = config.disk_size
      disk_size_mb  = config.disk_size * 1024
      environment   = config.environment
    }
  }
  
  # Group by environment
  servers_by_env = {
    for env in distinct([for server in var.servers : server.environment]) : env => {
      for name, config in var.servers : name => config
      if config.environment == env
    }
  }
}
```

## Dynamic Blocks

### Basic Dynamic Block

```hcl
variable "ingress_ports" {
  description = "List of ingress ports"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Nested Dynamic Blocks

```hcl
variable "load_balancer_config" {
  type = object({
    listeners = list(object({
      port     = number
      protocol = string
      rules = list(object({
        priority = number
        conditions = list(object({
          field  = string
          values = list(string)
        }))
        actions = list(object({
          type               = string
          target_group_arn   = string
          redirect_config    = optional(object({
            status_code = string
            host        = string
            path        = string
          }))
        }))
      }))
    }))
  })
}

resource "aws_lb_listener" "app" {
  for_each = {
    for idx, listener in var.load_balancer_config.listeners : idx => listener
  }
  
  load_balancer_arn = aws_lb.app.arn
  port              = each.value.port
  protocol          = each.value.protocol
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      priority = rule.value.priority
      
      dynamic "condition" {
        for_each = rule.value.conditions
        content {
          field  = condition.value.field
          values = condition.value.values
        }
      }
      
      dynamic "action" {
        for_each = rule.value.actions
        content {
          type             = action.value.type
          target_group_arn = action.value.target_group_arn
          
          dynamic "redirect" {
            for_each = action.value.redirect_config != null ? [action.value.redirect_config] : []
            content {
              status_code = redirect.value.status_code
              host        = redirect.value.host
              path        = redirect.value.path
            }
          }
        }
      }
    }
  }
}
```

## Advanced Iteration Patterns

### Conditional Iteration

```hcl
variable "environments" {
  type = map(object({
    create_database = bool
    instance_type   = string
    backup_enabled  = bool
  }))
}

# Create databases only for environments where create_database is true
resource "aws_db_instance" "app" {
  for_each = {
    for name, config in var.environments : name => config
    if config.create_database
  }
  
  identifier     = "${each.key}-database"
  engine         = "mysql"
  instance_class = "db.t3.micro"
  
  backup_retention_period = each.value.backup_enabled ? 7 : 0
  
  tags = {
    Name        = "${each.key}-database"
    Environment = each.key
  }
}
```

### Cross-Product Iteration

```hcl
variable "environments" {
  type    = list(string)
  default = ["dev", "staging", "prod"]
}

variable "regions" {
  type    = list(string)
  default = ["us-west-2", "us-east-1"]
}

locals {
  # Create cross-product of environments and regions
  env_region_combinations = {
    for combination in setproduct(var.environments, var.regions) :
    "${combination[0]}-${combination[1]}" => {
      environment = combination[0]
      region      = combination[1]
    }
  }
}

# Create S3 buckets for each environment-region combination
resource "aws_s3_bucket" "app" {
  for_each = local.env_region_combinations
  
  bucket = "myapp-${each.value.environment}-${each.value.region}"
  
  tags = {
    Name        = "myapp-${each.value.environment}-${each.value.region}"
    Environment = each.value.environment
    Region      = each.value.region
  }
}
```

## Count vs For_each Decision Matrix

| Scenario | Use Count | Use For_each | Reason |
|----------|-----------|--------------|---------|
| Fixed number of identical resources | ✅ | ❌ | Simple integer-based iteration |
| Variable number based on list length | ✅ | ❌ | Length function works well |
| Resources with different configurations | ❌ | ✅ | Each resource needs unique config |
| Resources that may be added/removed | ❌ | ✅ | Stable resource addresses |
| Resources based on map keys | ❌ | ✅ | Natural key-value mapping |
| Simple scaling scenarios | ✅ | ❌ | Count is more straightforward |

## Performance Considerations

### Resource Creation Parallelism

```hcl
# Terraform creates these resources in parallel
resource "aws_instance" "web" {
  count = 10
  
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  
  # No dependencies between instances
}
```

### Dependency Management

```hcl
# Create subnets first, then instances
resource "aws_subnet" "app" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_instance" "web" {
  count = 3
  
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.app[count.index].id  # Creates dependency
}
```

## Error Handling and Validation

### Input Validation

```hcl
variable "instance_configs" {
  description = "Map of instance configurations"
  type = map(object({
    instance_type = string
    disk_size     = number
    environment   = string
  }))
  
  validation {
    condition = alltrue([
      for config in values(var.instance_configs) :
      contains(["t3.micro", "t3.small", "t3.medium"], config.instance_type)
    ])
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
  
  validation {
    condition = alltrue([
      for config in values(var.instance_configs) :
      config.disk_size >= 20 && config.disk_size <= 1000
    ])
    error_message = "Disk size must be between 20 and 1000 GB."
  }
}
```

### Error Prevention

```hcl
# Prevent empty iterations
resource "aws_instance" "web" {
  count = length(var.instance_configs) > 0 ? length(var.instance_configs) : 0
  
  # Resource configuration
}

# Use try() for safe access
locals {
  instance_names = [
    for i in range(var.instance_count) :
    try(var.instance_names[i], "instance-${i + 1}")
  ]
}
```

## Troubleshooting Common Issues

### Issue 1: Count Cannot Be Computed

```hcl
# Problem: Count depends on resource attribute
resource "aws_instance" "web" {
  count = length(aws_subnet.app)  # Error: count cannot be computed
}

# Solution: Use data source or separate apply
data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
}

resource "aws_instance" "web" {
  count = length(data.aws_subnets.app.ids)
}
```

### Issue 2: For_each with Unknown Values

```hcl
# Problem: For_each value not known at plan time
resource "aws_instance" "web" {
  for_each = toset(aws_subnet.app[*].id)  # Error: value not known
}

# Solution: Use depends_on or separate apply
resource "aws_instance" "web" {
  for_each = toset(var.subnet_ids)  # Use variable instead
  
  depends_on = [aws_subnet.app]
}
```

### Issue 3: Resource Address Changes

```hcl
# Problem: Changing from count to for_each
# Old configuration
resource "aws_instance" "web" {
  count = 3
}

# New configuration
resource "aws_instance" "web" {
  for_each = var.instance_configs
}

# Solution: Use terraform state mv
# terraform state mv 'aws_instance.web[0]' 'aws_instance.web["web1"]'
```

## Best Practices

### 1. Choose the Right Iteration Method

```hcl
# Use count for simple scaling
resource "aws_instance" "web" {
  count = var.instance_count
}

# Use for_each for complex configurations
resource "aws_instance" "web" {
  for_each = var.instance_configs
}
```

### 2. Validate Inputs

```hcl
variable "environments" {
  type = set(string)
  
  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified."
  }
}
```

### 3. Use Meaningful Names

```hcl
# Good: Descriptive names
resource "aws_instance" "web_servers" {
  for_each = var.web_server_configs
  
  tags = {
    Name = "${each.key}-web-server"
  }
}

# Bad: Generic names
resource "aws_instance" "instance" {
  for_each = var.configs
}
```

### 4. Handle Edge Cases

```hcl
# Handle empty collections
locals {
  instance_configs = length(var.instance_configs) > 0 ? var.instance_configs : {}
}

resource "aws_instance" "web" {
  for_each = local.instance_configs
}
```

## Conclusion

Mastering Terraform loops and iteration enables you to:
- Create scalable infrastructure configurations
- Reduce code duplication and maintenance overhead
- Handle complex deployment scenarios
- Build flexible, reusable infrastructure modules

Key takeaways:
- Use `count` for simple, integer-based iteration
- Use `for_each` for map/set-based iteration with unique configurations
- Leverage for expressions for data transformation
- Apply dynamic blocks for nested resource configurations
- Always validate inputs and handle edge cases
- Choose the right iteration method for your use case
