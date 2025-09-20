# Problem 19: Terraform Performance Optimization

## Performance Optimization Strategies

### State Management Optimization
```hcl
# Use for_each instead of count for better performance
resource "aws_instance" "web" {
  for_each = var.instance_configs
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id
  
  tags = {
    Name = each.key
  }
}

# Optimize data sources with caching
locals {
  # Cache frequently used data sources
  availability_zones = data.aws_availability_zones.available.names
  vpc_id            = data.aws_vpc.main.id
}

# Use locals to avoid repeated calculations
locals {
  subnet_configs = {
    for i, az in local.availability_zones : 
    "subnet-${i}" => {
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, i)
      availability_zone = az
    }
  }
}
```

### Resource Parallelization
```hcl
# Independent resources for parallel creation
resource "aws_subnet" "public" {
  for_each = local.subnet_configs
  
  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  
  # All subnets can be created in parallel
  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

# Minimize dependencies for better parallelization
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = local.vpc_id
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_security_group_rule" "web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
}
```

### Cost Optimization Patterns
```hcl
# Environment-based cost optimization
locals {
  cost_optimization = {
    development = {
      instance_type    = "t3.micro"
      use_spot        = true
      backup_enabled  = false
      monitoring      = "basic"
    }
    production = {
      instance_type    = "t3.large"
      use_spot        = false
      backup_enabled  = true
      monitoring      = "detailed"
    }
  }
  
  current_optimization = local.cost_optimization[var.environment]
}

# Spot instances for cost savings
resource "aws_spot_instance_request" "web" {
  count = local.current_optimization.use_spot ? var.instance_count : 0
  
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = local.current_optimization.instance_type
  spot_price          = "0.05"
  wait_for_fulfillment = true
  
  tags = {
    Name = "${var.project_name}-spot-${count.index}"
  }
}

# Regular instances when spot not suitable
resource "aws_instance" "web" {
  count = local.current_optimization.use_spot ? 0 : var.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_optimization.instance_type
  
  tags = {
    Name = "${var.project_name}-web-${count.index}"
  }
}
```

This guide covers performance optimization techniques for efficient and cost-effective Terraform deployments.
