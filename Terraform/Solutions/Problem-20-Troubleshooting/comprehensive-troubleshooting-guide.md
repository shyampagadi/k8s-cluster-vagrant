# Terraform Troubleshooting - Complete Diagnostic and Resolution Guide

## Overview

This comprehensive guide covers systematic Terraform troubleshooting approaches, common issues, debugging techniques, and resolution strategies. Mastering these skills is essential for maintaining reliable infrastructure operations.

## Systematic Troubleshooting Methodology

### The TRACE Method

**T**rack the problem
**R**eproduce the issue
**A**nalyze the logs
**C**heck the configuration
**E**xecute the solution

### Problem Classification

1. **Configuration Errors**: Syntax, logic, or structural issues
2. **State Issues**: State corruption, drift, or locking problems
3. **Provider Issues**: Authentication, API limits, or resource conflicts
4. **Infrastructure Issues**: Network, permissions, or resource constraints
5. **Performance Issues**: Slow operations, timeouts, or resource limits

## Configuration Troubleshooting

### Syntax Errors

**Common Syntax Issues:**
```hcl
# Error: Missing quotes
resource "aws_instance" "web" {
  ami = ami-12345678  # Should be "ami-12345678"
}

# Error: Invalid block structure
resource "aws_instance" "web" 
  ami = "ami-12345678"  # Missing opening brace
}

# Error: Invalid attribute name
resource "aws_instance" "web" {
  ami-id = "ami-12345678"  # Should be ami
}
```

**Debugging Commands:**
```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -check
terraform fmt -diff

# Check configuration
terraform plan -detailed-exitcode
```

### Logic Errors

**Circular Dependencies:**
```hcl
# Problem: Circular dependency
resource "aws_security_group" "web" {
  ingress {
    security_groups = [aws_security_group.db.id]
  }
}

resource "aws_security_group" "db" {
  ingress {
    security_groups = [aws_security_group.web.id]  # Circular reference
  }
}

# Solution: Use security group rules
resource "aws_security_group" "web" {
  # Base security group
}

resource "aws_security_group" "db" {
  # Base security group
}

resource "aws_security_group_rule" "web_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.web.id
}
```

**Variable Type Mismatches:**
```hcl
# Problem: Type mismatch
variable "instance_count" {
  type    = string
  default = 3  # Number assigned to string
}

# Solution: Correct type
variable "instance_count" {
  type    = number
  default = 3
}
```

### Resource Configuration Issues

**Missing Required Arguments:**
```hcl
# Problem: Missing required argument
resource "aws_instance" "web" {
  instance_type = "t3.micro"
  # Missing required 'ami' argument
}

# Solution: Add required arguments
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}
```

**Invalid Argument Values:**
```hcl
# Problem: Invalid instance type
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "invalid-type"
}

# Solution: Use valid instance type
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}
```

## State Troubleshooting

### State File Corruption

**Symptoms:**
```bash
terraform plan
# Error: Failed to load state: state file is corrupted
```

**Diagnosis:**
```bash
# Check state file integrity
terraform state list
terraform show

# Validate state file format
cat terraform.tfstate | jq .
```

**Resolution:**
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Or restore from remote state
terraform state pull > terraform.tfstate

# Verify restoration
terraform plan
```

### State Drift Issues

**Detection:**
```bash
# Check for drift
terraform plan -refresh-only

# Example output showing drift
# aws_instance.web: Refreshing state... [id=i-1234567890abcdef0]
# 
# Note: Objects have changed outside of Terraform
# 
# Terraform detected the following changes made outside of Terraform:
# 
#   # aws_instance.web has been changed
#   ~ resource "aws_instance" "web" {
#         id            = "i-1234567890abcdef0"
#       ~ instance_type = "t3.micro" -> "t3.small"
#     }
```

**Resolution Strategies:**
```bash
# Option 1: Accept the drift
terraform apply -refresh-only

# Option 2: Revert the drift
terraform apply

# Option 3: Update configuration to match
# Edit .tf files to match actual state
```

### State Locking Issues

**Symptoms:**
```bash
terraform apply
# Error: Error acquiring the state lock
```

**Diagnosis:**
```bash
# Check lock information
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"path/to/state"}}'

# Check who has the lock
aws dynamodb scan \
  --table-name terraform-locks \
  --filter-expression "attribute_exists(LockID)"
```

**Resolution:**
```bash
# Wait for lock to be released naturally
# Or force unlock (use with extreme caution)
terraform force-unlock <lock-id>

# Verify lock is released
terraform plan
```

### Import Issues

**Resource Already Exists:**
```bash
# Problem
terraform apply
# Error: resource already exists

# Solution: Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Verify import
terraform plan
```

**Import ID Format Issues:**
```bash
# Problem: Wrong import ID format
terraform import aws_s3_bucket.example my-bucket
# Error: Invalid import ID

# Solution: Check provider documentation for correct format
terraform import aws_s3_bucket.example my-bucket
# Some resources need different ID formats
```

## Provider Troubleshooting

### Authentication Issues

**AWS Authentication Problems:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check AWS configuration
aws configure list

# Test AWS access
aws ec2 describe-instances --max-items 1
```

**Common Authentication Errors:**
```bash
# Error: NoCredentialProviders
# Solution: Configure AWS credentials
aws configure

# Error: AccessDenied
# Solution: Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>
```

### API Rate Limiting

**Symptoms:**
```bash
terraform apply
# Error: Rate exceeded
# Error: Throttling
```

**Solutions:**
```hcl
# Add retry configuration
provider "aws" {
  region = "us-west-2"
  
  retry_mode      = "adaptive"
  max_retries     = 10
}

# Use parallelism control
# terraform apply -parallelism=5
```

### Provider Version Issues

**Version Conflicts:**
```bash
# Problem: Provider version conflict
terraform init
# Error: version constraint conflict

# Solution: Update version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Updated version
    }
  }
}

# Update providers
terraform init -upgrade
```

## Infrastructure Troubleshooting

### Network Connectivity Issues

**VPC Configuration Problems:**
```hcl
# Problem: Instance can't reach internet
resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id  # Private subnet
  associate_public_ip_address = true  # Won't work in private subnet
}

# Solution: Use public subnet or NAT gateway
resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
}
```

**Security Group Issues:**
```hcl
# Problem: Overly restrictive security group
resource "aws_security_group" "web" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24"]  # Too restrictive
  }
}

# Solution: Appropriate CIDR blocks
resource "aws_security_group" "web" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from internet
  }
}
```

### Resource Quota Issues

**EC2 Instance Limits:**
```bash
# Check current limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A

# Request limit increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 100
```

### Permission Issues

**IAM Permission Problems:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

**Debugging Permissions:**
```bash
# Check effective permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/terraform \
  --action-names ec2:RunInstances \
  --resource-arns "*"
```

## Performance Troubleshooting

### Slow Terraform Operations

**Enable Debug Logging:**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply

# Analyze logs for bottlenecks
grep -i "slow\|timeout\|retry" terraform.log
```

**Optimize Resource Creation:**
```hcl
# Problem: Sequential resource creation
resource "aws_instance" "web" {
  count = 10
  
  ami           = data.aws_ami.ubuntu.id  # Data source called 10 times
  instance_type = "t3.micro"
}

# Solution: Use locals for shared values
locals {
  ami_id = data.aws_ami.ubuntu.id
}

resource "aws_instance" "web" {
  count = 10
  
  ami           = local.ami_id
  instance_type = "t3.micro"
}
```

### Memory and CPU Issues

**Large State Files:**
```bash
# Check state file size
ls -lh terraform.tfstate

# Split large configurations
# Use separate state files for different components
```

**Resource Limits:**
```bash
# Monitor Terraform process
top -p $(pgrep terraform)

# Increase system limits if needed
ulimit -n 4096  # Increase file descriptor limit
```

## Advanced Debugging Techniques

### Debug Logging Analysis

**Log Levels:**
```bash
export TF_LOG=TRACE  # Most verbose
export TF_LOG=DEBUG  # Debug information
export TF_LOG=INFO   # General information
export TF_LOG=WARN   # Warnings only
export TF_LOG=ERROR  # Errors only
```

**Provider-Specific Logging:**
```bash
export TF_LOG_PROVIDER=DEBUG
export TF_LOG_CORE=INFO
terraform apply
```

### State Inspection

**Detailed State Analysis:**
```bash
# List all resources
terraform state list

# Show resource details
terraform state show aws_instance.web

# Export state for analysis
terraform state pull > state_backup.json
jq '.resources[] | select(.type=="aws_instance")' state_backup.json
```

### Configuration Analysis

**Dependency Graph:**
```bash
# Generate dependency graph
terraform graph | dot -Tpng > graph.png

# Analyze dependencies
terraform graph | grep -E "(aws_instance|aws_subnet)"
```

**Plan Analysis:**
```bash
# Detailed plan output
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# Analyze plan
jq '.resource_changes[] | select(.change.actions[] == "create")' plan.json
```

## Automated Troubleshooting

### Health Check Scripts

```bash
#!/bin/bash
# terraform-health-check.sh

echo "Checking Terraform configuration..."

# Check syntax
if ! terraform validate; then
    echo "❌ Configuration validation failed"
    exit 1
fi

# Check formatting
if ! terraform fmt -check; then
    echo "⚠️  Code formatting issues found"
fi

# Check state
if ! terraform state list > /dev/null 2>&1; then
    echo "❌ State file issues detected"
    exit 1
fi

# Check for drift
if ! terraform plan -detailed-exitcode > /dev/null 2>&1; then
    echo "⚠️  Configuration drift detected"
fi

echo "✅ Health check completed"
```

### Monitoring and Alerting

```bash
#!/bin/bash
# terraform-monitor.sh

# Check for failed applies
if grep -q "Error:" terraform.log; then
    echo "Terraform apply failed" | mail -s "Terraform Alert" admin@company.com
fi

# Check state lock duration
LOCK_TIME=$(aws dynamodb get-item --table-name terraform-locks --key '{"LockID":{"S":"path/to/state"}}' --query 'Item.Info.S' --output text | jq -r '.Created')

if [ -n "$LOCK_TIME" ]; then
    CURRENT_TIME=$(date +%s)
    LOCK_DURATION=$((CURRENT_TIME - $(date -d "$LOCK_TIME" +%s)))
    
    if [ $LOCK_DURATION -gt 3600 ]; then  # 1 hour
        echo "State locked for over 1 hour" | mail -s "Terraform Lock Alert" admin@company.com
    fi
fi
```

## Recovery Procedures

### Disaster Recovery

**Complete State Loss:**
```bash
# 1. Recreate state file structure
terraform init

# 2. Import all existing resources
terraform import aws_vpc.main vpc-12345678
terraform import aws_subnet.public subnet-12345678
terraform import aws_instance.web i-1234567890abcdef0

# 3. Verify state
terraform plan
```

**Partial State Corruption:**
```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.corrupted

# 2. Remove corrupted resources from state
terraform state rm aws_instance.corrupted

# 3. Reimport clean resources
terraform import aws_instance.corrupted i-1234567890abcdef0

# 4. Verify recovery
terraform plan
```

### Rollback Procedures

**Configuration Rollback:**
```bash
# 1. Revert to previous configuration
git checkout HEAD~1 -- *.tf

# 2. Plan the rollback
terraform plan

# 3. Apply rollback
terraform apply

# 4. Verify rollback
terraform plan
```

**State Rollback:**
```bash
# 1. Restore from backup
terraform state push terraform.tfstate.backup

# 2. Verify restoration
terraform plan

# 3. Apply if needed
terraform apply
```

## Prevention Strategies

### Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate Terraform
terraform validate
if [ $? -ne 0 ]; then
    echo "Terraform validation failed"
    exit 1
fi

# Format check
terraform fmt -check
if [ $? -ne 0 ]; then
    echo "Terraform formatting issues found"
    exit 1
fi

# Security scan
tfsec .
if [ $? -ne 0 ]; then
    echo "Security issues found"
    exit 1
fi
```

### CI/CD Integration

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Terraform Init
      run: terraform init
      
    - name: Terraform Validate
      run: terraform validate
      
    - name: Terraform Plan
      run: terraform plan -detailed-exitcode
      
    - name: Security Scan
      run: tfsec .
```

### Monitoring and Observability

```hcl
# CloudWatch alarms for Terraform operations
resource "aws_cloudwatch_log_group" "terraform" {
  name              = "/aws/lambda/terraform-operations"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "terraform_failures" {
  alarm_name          = "terraform-apply-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors terraform apply failures"
  
  dimensions = {
    FunctionName = "terraform-operations"
  }
}
```

## Troubleshooting Checklist

### Pre-Apply Checklist
- [ ] Configuration validated (`terraform validate`)
- [ ] Code formatted (`terraform fmt -check`)
- [ ] Plan reviewed (`terraform plan`)
- [ ] Security scan passed (`tfsec`)
- [ ] State backup created
- [ ] Permissions verified

### Post-Error Checklist
- [ ] Error message analyzed
- [ ] Logs reviewed (`TF_LOG=DEBUG`)
- [ ] State integrity checked
- [ ] Provider authentication verified
- [ ] Resource quotas checked
- [ ] Network connectivity tested

### Recovery Checklist
- [ ] Issue root cause identified
- [ ] Recovery plan documented
- [ ] Backups verified
- [ ] Recovery tested in non-production
- [ ] Rollback plan prepared
- [ ] Team notified

## Conclusion

Effective Terraform troubleshooting requires:
- **Systematic approach**: Use the TRACE methodology
- **Comprehensive logging**: Enable debug logging for analysis
- **State management**: Understand state operations and recovery
- **Provider knowledge**: Know common provider issues and solutions
- **Prevention focus**: Implement checks and monitoring
- **Documentation**: Maintain troubleshooting runbooks

Master these techniques to become proficient at diagnosing and resolving Terraform issues quickly and effectively.
