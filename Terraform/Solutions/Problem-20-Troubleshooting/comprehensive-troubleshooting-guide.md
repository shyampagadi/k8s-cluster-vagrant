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
