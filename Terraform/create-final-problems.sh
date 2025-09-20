#!/bin/bash

cd /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions

# Create Problem 17: Error Handling
cat > "Problem-17-Error-Handling/COMPREHENSIVE-ERROR-HANDLING-GUIDE.md" << 'EOF'
# Problem 17: Terraform Error Handling and Debugging

## Error Types and Debugging

### Common Terraform Errors
1. **Syntax Errors** - HCL syntax issues
2. **Validation Errors** - Variable and resource validation failures
3. **Provider Errors** - API and authentication issues
4. **State Errors** - State file corruption or conflicts
5. **Resource Errors** - Resource creation or modification failures

### Debugging Techniques
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run with detailed logging
terraform plan
terraform apply

# Analyze the log file
grep -i error terraform-debug.log
grep -i "http response" terraform-debug.log
```

### Error Prevention Patterns
```hcl
# Variable validation to prevent errors
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 instance type."
  }
}

# Resource validation with preconditions
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  lifecycle {
    precondition {
      condition     = data.aws_ami.amazon_linux.state == "available"
      error_message = "Selected AMI is not available."
    }
    
    postcondition {
      condition     = self.instance_state == "running"
      error_message = "Instance failed to reach running state."
    }
  }
  
  tags = {
    Name = "web-server"
  }
}
```

### Error Recovery Strategies
```hcl
# Graceful error handling with try function
locals {
  # Safe CIDR calculation with error handling
  subnet_cidrs = try(
    [for i in range(var.subnet_count) : cidrsubnet(var.vpc_cidr, 8, i)],
    ["10.0.1.0/24", "10.0.2.0/24"]  # Fallback values
  )
  
  # Safe data source access
  vpc_id = try(
    data.aws_vpc.existing[0].id,
    aws_vpc.main.id
  )
}

# Conditional resource creation with error handling
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0
  
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  
  filter {
    name   = "tag:Name"
    values = [var.existing_vpc_name]
  }
}
```

This guide provides comprehensive error handling and debugging strategies for robust Terraform deployments.
EOF

# Create Problem 19: Performance Optimization
cat > "Problem-19-Performance-Optimization/COMPREHENSIVE-PERFORMANCE-GUIDE.md" << 'EOF'
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
EOF

# Create Problem 20: Troubleshooting
cat > "Problem-20-Troubleshooting/COMPREHENSIVE-TROUBLESHOOTING-GUIDE.md" << 'EOF'
# Problem 20: Terraform Troubleshooting Mastery

## Systematic Troubleshooting Approach

### Troubleshooting Methodology
1. **Identify the Problem** - Understand what's failing
2. **Gather Information** - Collect logs and error messages
3. **Isolate the Issue** - Narrow down the root cause
4. **Implement Solution** - Apply the fix
5. **Verify Resolution** - Confirm the issue is resolved
6. **Document Solution** - Record for future reference

### Common Issues and Solutions

#### State File Issues
```bash
# State lock issues
terraform force-unlock LOCK_ID

# State drift detection
terraform plan -detailed-exitcode
terraform refresh

# Import existing resources
terraform import aws_instance.web i-1234567890abcdef0

# Remove resources from state
terraform state rm aws_instance.old_web

# Move resources in state
terraform state mv aws_instance.web aws_instance.web_server
```

#### Provider Issues
```bash
# Provider authentication debugging
aws sts get-caller-identity
aws configure list

# Provider version conflicts
terraform init -upgrade
terraform providers

# Clear provider cache
rm -rf .terraform/
terraform init
```

#### Resource Conflicts
```hcl
# Handle resource naming conflicts
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${random_id.suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Resolve circular dependencies
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group_rule" "web_to_app" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.web.id
}
```

### Debugging Tools and Techniques
```bash
# Enable comprehensive logging
export TF_LOG=TRACE
export TF_LOG_PATH=terraform-trace.log

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -diff

# Plan with detailed output
terraform plan -out=tfplan
terraform show tfplan

# Graph visualization
terraform graph | dot -Tpng > graph.png

# State inspection
terraform state list
terraform state show aws_instance.web
```

### Recovery Procedures
```bash
# Backup state before operations
cp terraform.tfstate terraform.tfstate.backup

# Recover from corrupted state
terraform state pull > terraform.tfstate.backup
# Edit state file if needed
terraform state push terraform.tfstate.backup

# Force resource recreation
terraform taint aws_instance.web
terraform apply

# Partial apply for large configurations
terraform apply -target=aws_vpc.main
terraform apply -target=module.networking
```

This comprehensive troubleshooting guide provides systematic approaches to identifying, diagnosing, and resolving common Terraform issues.
EOF

echo "✅ Created comprehensive guides for Problems 17, 19, 20"
EOF

chmod +x /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/create-final-problems.sh
