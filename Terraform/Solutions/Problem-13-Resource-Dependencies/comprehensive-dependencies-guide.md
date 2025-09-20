# Terraform Resource Dependencies - Complete Guide

## Overview

This comprehensive guide covers Terraform resource dependencies, including implicit and explicit dependencies, dependency management strategies, and enterprise-grade dependency optimization patterns.

## Dependency Fundamentals

### Implicit Dependencies

```hcl
# Implicit dependencies through resource references
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "main-vpc"
  }
}

# Subnet implicitly depends on VPC
resource "aws_subnet" "public" {
  count = 3
  
  vpc_id            = aws_vpc.main.id  # Creates implicit dependency
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
    Type = "public"
  }
}

# Internet Gateway implicitly depends on VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Creates implicit dependency
  
  tags = {
    Name = "main-igw"
  }
}

# Route table implicitly depends on VPC and IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Implicit dependency on IGW
  }
  
  tags = {
    Name = "public-route-table"
  }
}

# Route table association depends on both subnet and route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id      # Implicit dependency
  route_table_id = aws_route_table.public.id              # Implicit dependency
}
```

### Explicit Dependencies

```hcl
# Explicit dependencies using depends_on
resource "aws_instance" "web" {
  count = 3
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Explicit dependency - instance must wait for NAT gateway
  depends_on = [
    aws_nat_gateway.main,
    aws_route_table_association.private
  ]
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

# Security group with explicit dependency
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
  # Explicit dependency ensures VPC is fully configured
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.main
  ]
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database with explicit dependencies
resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true
  
  db_name  = "application"
  username = "admin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Explicit dependencies for proper setup order
  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.database,
    random_password.db_password
  ]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  
  tags = {
    Name = "main-database"
  }
}
```

## Complex Dependency Patterns

### Multi-Tier Architecture Dependencies

```hcl
# Tier 1: Network Infrastructure
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "database" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 21}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Tier 2: Internet Connectivity
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  count = 2
  
  domain = "vpc"
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = 2
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  depends_on = [aws_internet_gateway.main]
}

# Tier 3: Routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count = 2
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  depends_on = [aws_nat_gateway.main]
}

# Tier 4: Security Groups
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
  depends_on = [aws_vpc.main]
}

resource "aws_security_group" "app" {
  name_prefix = "app-sg-"
  vpc_id      = aws_vpc.main.id
  
  depends_on = [aws_security_group.web]
}

resource "aws_security_group" "database" {
  name_prefix = "db-sg-"
  vpc_id      = aws_vpc.main.id
  
  depends_on = [aws_security_group.app]
}

# Tier 5: Database Infrastructure
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  
  depends_on = [aws_subnet.database]
}

resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  
  db_name  = "application"
  username = "admin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.database,
    aws_route_table_association.private
  ]
}

# Tier 6: Application Infrastructure
resource "aws_launch_template" "app" {
  name_prefix   = "app-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    database_endpoint = aws_db_instance.main.endpoint
  }))
  
  depends_on = [
    aws_db_instance.main,
    aws_security_group.app
  ]
}

resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  
  min_size         = 2
  max_size         = 6
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  depends_on = [
    aws_launch_template.app,
    aws_lb_target_group.app,
    aws_route_table_association.private
  ]
}

# Tier 7: Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public
  ]
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
  
  depends_on = [aws_vpc.main]
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  
  depends_on = [
    aws_lb.main,
    aws_lb_target_group.app
  ]
}
```

### Cross-Module Dependencies

```hcl
# Module dependencies
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "security" {
  source = "./modules/security"
  
  vpc_id = module.networking.vpc_id
  
  # Explicit dependency on networking module
  depends_on = [module.networking]
}

module "database" {
  source = "./modules/database"
  
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.database_subnet_ids
  security_group_ids   = [module.security.database_sg_id]
  
  # Multiple module dependencies
  depends_on = [
    module.networking,
    module.security
  ]
}

module "application" {
  source = "./modules/application"
  
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  security_group_id  = module.security.app_sg_id
  database_endpoint  = module.database.endpoint
  
  # Complex dependency chain
  depends_on = [
    module.networking,
    module.security,
    module.database
  ]
}

module "load_balancer" {
  source = "./modules/load_balancer"
  
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.security.web_sg_id
  target_group_arn  = module.application.target_group_arn
  
  depends_on = [
    module.networking,
    module.security,
    module.application
  ]
}
```

## Dependency Optimization

### Parallel Resource Creation

```hcl
# Resources that can be created in parallel
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# These can be created in parallel after VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name_prefix = "app-sg-"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "database" {
  name_prefix = "db-sg-"
  vpc_id      = aws_vpc.main.id
}

# Subnets can be created in parallel
resource "aws_subnet" "public" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### Dependency Batching

```hcl
# Group related resources to minimize dependency chains
locals {
  # Pre-compute values to reduce dependencies
  subnet_configs = {
    for i in range(3) : "subnet-${i}" => {
      cidr_block        = "10.0.${i + 1}.0/24"
      availability_zone = data.aws_availability_zones.available.names[i]
    }
  }
}

# Create all subnets at once
resource "aws_subnet" "main" {
  for_each = local.subnet_configs
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  
  tags = {
    Name = each.key
  }
}

# Batch route table associations
resource "aws_route_table_association" "main" {
  for_each = aws_subnet.main
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}
```

## Dependency Troubleshooting

### Circular Dependencies

```hcl
# Problem: Circular dependency
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]  # References app SG
  }
}

resource "aws_security_group" "app" {
  name_prefix = "app-sg-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]  # References web SG - CIRCULAR!
  }
}

# Solution: Use security group rules
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name_prefix = "app-sg-"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "web_to_app" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.web.id
}

resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.app.id
}
```

### Dependency Debugging

```bash
# View dependency graph
terraform graph | dot -Tpng > dependencies.png

# Analyze specific resource dependencies
terraform graph | grep -A 5 -B 5 "aws_instance.web"

# Check for circular dependencies
terraform graph | grep -E "->.*->.*->"

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -detailed-exitcode
```

### Common Dependency Issues

```hcl
# Issue 1: Missing implicit dependency
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[0].id
  
  # Missing: vpc_security_group_ids creates implicit dependency
  vpc_security_group_ids = [aws_security_group.web.id]
}

# Issue 2: Unnecessary explicit dependency
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[0].id
  
  # Unnecessary: subnet_id already creates implicit dependency on VPC
  depends_on = [aws_vpc.main]  # Remove this
}

# Issue 3: Race condition
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  # Add explicit dependency to ensure route is ready
  depends_on = [aws_route.public_internet]
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
```

## Advanced Dependency Patterns

### Conditional Dependencies

```hcl
variable "create_database" {
  type    = bool
  default = true
}

variable "create_cache" {
  type    = bool
  default = false
}

resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier = "main-database"
  engine     = "mysql"
  # ... other configuration
}

resource "aws_elasticache_cluster" "main" {
  count = var.create_cache ? 1 : 0
  
  cluster_id = "main-cache"
  engine     = "redis"
  # ... other configuration
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  user_data = templatefile("${path.module}/user_data.sh", {
    database_endpoint = var.create_database ? aws_db_instance.main[0].endpoint : "localhost"
    cache_endpoint    = var.create_cache ? aws_elasticache_cluster.main[0].cache_nodes[0].address : "localhost"
  })
  
  # Conditional dependencies
  depends_on = concat(
    var.create_database ? [aws_db_instance.main[0]] : [],
    var.create_cache ? [aws_elasticache_cluster.main[0]] : []
  )
}
```

### Dynamic Dependencies

```hcl
variable "environments" {
  type = map(object({
    create_monitoring = bool
    create_backup     = bool
  }))
  
  default = {
    dev = {
      create_monitoring = false
      create_backup     = false
    }
    prod = {
      create_monitoring = true
      create_backup     = true
    }
  }
}

# Dynamic resource creation based on environment
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = {
    for env, config in var.environments : env => config
    if config.create_monitoring
  }
  
  alarm_name = "${each.key}-cpu-high"
  # ... alarm configuration
}

resource "aws_backup_vault" "main" {
  for_each = {
    for env, config in var.environments : env => config
    if config.create_backup
  }
  
  name = "${each.key}-backup-vault"
  # ... backup configuration
}

# Application instances with dynamic dependencies
resource "aws_instance" "app" {
  for_each = var.environments
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  tags = {
    Name        = "${each.key}-app"
    Environment = each.key
  }
  
  # Dynamic dependencies based on what was created
  depends_on = concat(
    [for alarm in aws_cloudwatch_metric_alarm.cpu_high : alarm],
    [for vault in aws_backup_vault.main : vault]
  )
}
```

## Best Practices

### 1. Minimize Explicit Dependencies

```hcl
# Good: Use implicit dependencies when possible
resource "aws_instance" "web" {
  subnet_id              = aws_subnet.public.id  # Implicit dependency
  vpc_security_group_ids = [aws_security_group.web.id]  # Implicit dependency
}

# Avoid: Unnecessary explicit dependencies
resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id
  
  depends_on = [aws_vpc.main]  # Unnecessary - subnet already depends on VPC
}
```

### 2. Use Explicit Dependencies for Non-Resource Dependencies

```hcl
# Good: Explicit dependency for setup order
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  # Ensure NAT gateway is ready for outbound connectivity
  depends_on = [aws_nat_gateway.main]
}
```

### 3. Organize Resources by Dependency Layers

```hcl
# Layer 1: Foundation
resource "aws_vpc" "main" { }

# Layer 2: Network Infrastructure  
resource "aws_subnet" "public" { }
resource "aws_internet_gateway" "main" { }

# Layer 3: Security
resource "aws_security_group" "web" { }

# Layer 4: Applications
resource "aws_instance" "web" { }
```

### 4. Document Complex Dependencies

```hcl
resource "aws_instance" "app" {
  # ... configuration
  
  # Explicit dependency required because:
  # 1. App needs database to be fully initialized
  # 2. Database initialization includes custom setup scripts
  # 3. Setup scripts run after RDS instance is available
  depends_on = [
    aws_db_instance.main,
    null_resource.database_setup
  ]
}
```

## Conclusion

Resource dependencies enable:
- **Correct Ordering**: Ensure resources are created in proper sequence
- **Reliability**: Prevent race conditions and incomplete setups
- **Maintainability**: Clear resource relationships
- **Performance**: Optimize parallel resource creation

Key takeaways:
- Prefer implicit dependencies over explicit ones
- Use explicit dependencies for non-obvious relationships
- Avoid circular dependencies
- Organize resources in logical dependency layers
- Debug dependency issues with terraform graph
- Document complex dependency requirements
