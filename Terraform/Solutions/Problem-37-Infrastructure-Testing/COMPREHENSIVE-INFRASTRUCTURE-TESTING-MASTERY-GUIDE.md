# Infrastructure Testing Mastery - Complete Guide

## 🧪 Testing Framework Architecture

### Multi-Layer Testing Strategy
```hcl
# Testing pyramid for infrastructure
terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Unit tests - Module validation
resource "test_assertions" "vpc_unit_tests" {
  component = "vpc_module"

  check "subnet_count_validation" {
    assertion = length(var.private_subnets) >= 2
    error_message = "VPC must have at least 2 private subnets for HA"
  }

  check "cidr_validation" {
    assertion = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be valid IPv4 CIDR block"
  }
}

# Integration tests - Cross-module validation
resource "test_assertions" "integration_tests" {
  component = "module_integration"

  check "database_connectivity" {
    assertion = can(module.database.endpoint)
    error_message = "Database must be accessible from application subnets"
  }

  check "security_group_rules" {
    assertion = length([
      for rule in module.security_group.ingress_rules : rule
      if rule.from_port == 443
    ]) > 0
    error_message = "HTTPS access must be configured"
  }
}
```

### Terratest Integration
```go
// test/terraform_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    t.Parallel()

    // Configure Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr": "10.0.0.0/16",
            "availability_zones": []string{"us-west-2a", "us-west-2b"},
        },
    }

    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)

    // Deploy infrastructure
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)

    // Validate AWS resources
    vpc := aws.GetVpcById(t, vpcId, "us-west-2")
    assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)
}

func TestSecurityCompliance(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Test security group rules
    sgId := terraform.Output(t, terraformOptions, "security_group_id")
    sg := aws.GetSecurityGroupById(t, sgId, "us-west-2")
    
    // Ensure no SSH from 0.0.0.0/0
    for _, rule := range sg.IngressRules {
        if rule.FromPort == 22 {
            assert.NotContains(t, rule.CidrBlocks, "0.0.0.0/0")
        }
    }
}
```

## 🔒 Security Testing Patterns

### Policy Validation with OPA
```rego
# policies/security.rego
package terraform.security

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port == 22
    "0.0.0.0/0" in resource.change.after.cidr_blocks
    msg := sprintf("Security group rule '%s' allows SSH from anywhere", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    not resource.change.after.storage_encrypted
    msg := sprintf("RDS instance '%s' must have encryption enabled", [resource.address])
}
```

### Compliance Testing Framework
```hcl
# compliance/main.tf
data "external" "compliance_check" {
  program = ["python3", "${path.module}/scripts/compliance_checker.py"]
  
  query = {
    terraform_plan = var.terraform_plan_file
    compliance_framework = var.compliance_framework
  }
}

resource "test_assertions" "compliance_validation" {
  component = "compliance"

  check "soc2_compliance" {
    assertion = data.external.compliance_check.result.soc2_compliant == "true"
    error_message = "Infrastructure must be SOC2 compliant"
  }

  check "pci_compliance" {
    assertion = data.external.compliance_check.result.pci_compliant == "true"
    error_message = "Infrastructure must be PCI DSS compliant"
  }
}
```

## 📊 Performance Testing

### Load Testing Infrastructure
```hcl
# Load testing with Terraform
resource "aws_instance" "load_generator" {
  count = var.load_test_enabled ? var.load_generator_count : 0
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "c5.xlarge"
  subnet_id     = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  
  vpc_security_group_ids = [aws_security_group.load_generator.id]
  
  user_data = base64encode(templatefile("${path.module}/templates/load_generator.sh", {
    target_url = var.target_application_url
    test_duration = var.load_test_duration
    concurrent_users = var.concurrent_users
  }))
  
  tags = {
    Name = "load-generator-${count.index + 1}"
    Purpose = "performance-testing"
  }
}

# CloudWatch metrics for performance monitoring
resource "aws_cloudwatch_metric_alarm" "response_time" {
  count = var.load_test_enabled ? 1 : 0
  
  alarm_name          = "high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.max_response_time_ms
  alarm_description   = "Response time is too high"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
```

## 🚀 CI/CD Testing Integration

### GitHub Actions Testing Pipeline
```yaml
# .github/workflows/infrastructure-test.yml
name: Infrastructure Testing Pipeline

on:
  pull_request:
    paths: ['infrastructure/**']
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
          
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Validate
        run: |
          terraform init -backend=false
          terraform validate
          
      - name: Security Scan with Checkov
        run: |
          pip install checkov
          checkov -d . --framework terraform --check CKV_AWS_*
          
      - name: Policy Validation with OPA
        run: |
          terraform plan -out=tfplan
          terraform show -json tfplan > plan.json
          opa eval -d policies/ -i plan.json "data.terraform.security.deny[x]"

  test:
    needs: validate
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-suite: [unit, integration, security, performance]
        
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v3
        with:
          go-version: 1.19
          
      - name: Run Terratest Suite
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          cd test
          go test -v -timeout 30m -run Test${{ matrix.test-suite }}
          
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results-${{ matrix.test-suite }}
          path: test/results/

  deploy-test-env:
    needs: test
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy Test Environment
        run: |
          terraform init
          terraform workspace select test || terraform workspace new test
          terraform apply -auto-approve -var-file="test.tfvars"
          
      - name: Run Integration Tests
        run: |
          ./scripts/integration-tests.sh
          
      - name: Cleanup Test Environment
        if: always()
        run: |
          terraform destroy -auto-approve -var-file="test.tfvars"
```

## 🔍 Advanced Testing Patterns

### Contract Testing for APIs
```hcl
# API contract testing
resource "null_resource" "api_contract_tests" {
  count = var.enable_contract_testing ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      # Install Pact CLI
      npm install -g @pact-foundation/pact-cli
      
      # Run contract tests
      pact-broker publish \
        --consumer-app-version=${var.app_version} \
        --broker-base-url=${var.pact_broker_url} \
        --broker-username=${var.pact_broker_username} \
        --broker-password=${var.pact_broker_password} \
        contracts/
    EOT
  }
  
  depends_on = [aws_api_gateway_deployment.main]
}
```

### Chaos Engineering Integration
```hcl
# Chaos engineering with Terraform
resource "aws_lambda_function" "chaos_monkey" {
  count = var.enable_chaos_testing ? 1 : 0
  
  filename         = "chaos_monkey.zip"
  function_name    = "chaos-monkey"
  role            = aws_iam_role.chaos_monkey[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      TARGET_ASG = aws_autoscaling_group.main.name
      CHAOS_PROBABILITY = var.chaos_probability
      SLACK_WEBHOOK = var.slack_webhook_url
    }
  }
}

# Schedule chaos experiments
resource "aws_cloudwatch_event_rule" "chaos_schedule" {
  count = var.enable_chaos_testing ? 1 : 0
  
  name                = "chaos-monkey-schedule"
  description         = "Trigger chaos experiments"
  schedule_expression = var.chaos_schedule
}
```

This comprehensive guide provides enterprise-grade infrastructure testing patterns for production environments.
