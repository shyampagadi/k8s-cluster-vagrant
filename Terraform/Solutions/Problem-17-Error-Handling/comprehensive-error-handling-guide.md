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
