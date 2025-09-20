# Policy as Code Mastery - Complete Enterprise Guide

## 🏛️ Policy Framework Architecture

### Multi-Layer Policy Enforcement
```rego
# policies/security/encryption.rego
package terraform.security.encryption

import future.keywords.if
import future.keywords.in

# Deny unencrypted S3 buckets
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.address])
}

# Deny unencrypted RDS instances
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    not resource.change.after.storage_encrypted
    msg := sprintf("RDS instance '%s' must have storage encryption enabled", [resource.address])
}

# Helper function to check S3 encryption
has_encryption(resource) if {
    resource.change.after.server_side_encryption_configuration[_]
}

# Deny unencrypted EBS volumes
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    not resource.change.after.encrypted
    msg := sprintf("EBS volume '%s' must be encrypted", [resource.address])
}
```

### Compliance Framework Integration
```rego
# policies/compliance/soc2.rego
package terraform.compliance.soc2

# SOC2 Type II - Security Principle
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port == 22
    "0.0.0.0/0" in resource.change.after.cidr_blocks
    msg := sprintf("SOC2 Violation: SSH access from 0.0.0.0/0 not allowed in '%s'", [resource.address])
}

# SOC2 - Availability Principle
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not has_backup_strategy(resource)
    msg := sprintf("SOC2 Violation: Instance '%s' must have backup strategy", [resource.address])
}

# SOC2 - Confidentiality Principle
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls == false
    msg := sprintf("SOC2 Violation: S3 bucket '%s' must block public ACLs", [resource.address])
}

has_backup_strategy(resource) if {
    resource.change.after.tags.BackupSchedule
}
```

## 🔒 Advanced Security Policies

### Zero Trust Network Policies
```rego
# policies/security/zero_trust.rego
package terraform.security.zero_trust

# Deny default VPC usage
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_default_vpc"
    msg := "Zero Trust: Default VPC usage is prohibited"
}

# Require explicit security group rules
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    count(resource.change.after.ingress) == 0
    count(resource.change.after.egress) == 0
    msg := sprintf("Zero Trust: Security group '%s' must have explicit rules", [resource.address])
}

# Deny overly permissive IAM policies
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf("Zero Trust: IAM policy '%s' grants excessive permissions", [resource.address])
}
```

### Data Classification Policies
```rego
# policies/data/classification.rego
package terraform.data.classification

# Require data classification tags
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type in data_storage_resources
    not resource.change.after.tags.DataClassification
    msg := sprintf("Data resource '%s' must have DataClassification tag", [resource.address])
}

# Enforce encryption for sensitive data
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type in data_storage_resources
    resource.change.after.tags.DataClassification in ["Sensitive", "Confidential"]
    not is_encrypted(resource)
    msg := sprintf("Sensitive data resource '%s' must be encrypted", [resource.address])
}

data_storage_resources := {
    "aws_s3_bucket",
    "aws_db_instance",
    "aws_ebs_volume",
    "aws_efs_file_system"
}

is_encrypted(resource) if {
    resource.type == "aws_s3_bucket"
    resource.change.after.server_side_encryption_configuration[_]
}

is_encrypted(resource) if {
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == true
}
```

## 🏢 Enterprise Governance Policies

### Cost Control Policies
```rego
# policies/cost/budget_control.rego
package terraform.cost.budget_control

# Deny expensive instance types in non-production
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    environment := resource.change.after.tags.Environment
    environment != "production"
    resource.change.after.instance_type in expensive_instances
    msg := sprintf("Cost Control: Instance type '%s' not allowed in %s environment", 
                   [resource.change.after.instance_type, environment])
}

# Limit RDS instance sizes
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    instance_class := resource.change.after.instance_class
    not startswith(instance_class, "db.t3")
    not startswith(instance_class, "db.t4g")
    environment := resource.change.after.tags.Environment
    environment in ["development", "staging"]
    msg := sprintf("Cost Control: RDS instance class '%s' too large for %s", 
                   [instance_class, environment])
}

expensive_instances := {
    "m5.4xlarge", "m5.8xlarge", "m5.12xlarge",
    "c5.4xlarge", "c5.9xlarge", "c5.18xlarge",
    "r5.4xlarge", "r5.8xlarge", "r5.12xlarge"
}
```

### Resource Tagging Policies
```rego
# policies/governance/tagging.rego
package terraform.governance.tagging

required_tags := {
    "Environment",
    "Owner",
    "CostCenter",
    "Project"
}

# Require mandatory tags on all resources
deny[msg] if {
    resource := input.resource_changes[_]
    resource.type in taggable_resources
    tag := required_tags[_]
    not resource.change.after.tags[tag]
    msg := sprintf("Resource '%s' missing required tag: %s", [resource.address, tag])
}

# Validate tag values
deny[msg] if {
    resource := input.resource_changes[_]
    environment := resource.change.after.tags.Environment
    not environment in valid_environments
    msg := sprintf("Invalid Environment tag '%s' in resource '%s'", 
                   [environment, resource.address])
}

valid_environments := {
    "development",
    "staging", 
    "production"
}

taggable_resources := {
    "aws_instance",
    "aws_s3_bucket",
    "aws_db_instance",
    "aws_vpc",
    "aws_security_group"
}
```

## 🚀 CI/CD Policy Integration

### Terraform Policy Validation
```hcl
# policy-validation.tf
data "external" "policy_validation" {
  program = ["bash", "${path.module}/scripts/validate_policies.sh"]
  
  query = {
    terraform_plan = "tfplan.json"
    policy_dir     = "${path.module}/policies"
  }
}

resource "null_resource" "policy_check" {
  triggers = {
    plan_hash = filemd5("tfplan.json")
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      # Run OPA policy validation
      opa eval -d policies/ -i tfplan.json "data.terraform.deny[x]" > policy_violations.json
      
      # Check for violations
      if [ -s policy_violations.json ]; then
        echo "Policy violations found:"
        cat policy_violations.json
        exit 1
      fi
    EOT
  }
}
```

### GitHub Actions Policy Pipeline
```yaml
# .github/workflows/policy-validation.yml
name: Policy Validation Pipeline

on:
  pull_request:
    paths: ['infrastructure/**', 'policies/**']

jobs:
  policy-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/v0.55.0/opa_linux_amd64_static
          chmod +x opa
          sudo mv opa /usr/local/bin/
          
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
          
      - name: Generate Terraform Plan
        run: |
          terraform init
          terraform plan -out=tfplan
          terraform show -json tfplan > plan.json
          
      - name: Validate Security Policies
        run: |
          opa eval -d policies/security/ -i plan.json \
            "data.terraform.security.deny[x]" --format pretty
            
      - name: Validate Compliance Policies
        run: |
          opa eval -d policies/compliance/ -i plan.json \
            "data.terraform.compliance.deny[x]" --format pretty
            
      - name: Validate Cost Policies
        run: |
          opa eval -d policies/cost/ -i plan.json \
            "data.terraform.cost.deny[x]" --format pretty
            
      - name: Generate Policy Report
        run: |
          ./scripts/generate_policy_report.sh plan.json > policy_report.md
          
      - name: Comment PR with Policy Results
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('policy_report.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: report
            });
```

## 📊 Policy Testing and Validation

### Policy Unit Testing
```rego
# policies/security/encryption_test.rego
package terraform.security.encryption

test_s3_bucket_encryption_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "aws_s3_bucket.test",
            "type": "aws_s3_bucket",
            "change": {
                "after": {
                    "bucket": "test-bucket"
                }
            }
        }]
    }
}

test_s3_bucket_encryption_allowed if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "aws_s3_bucket.test",
            "type": "aws_s3_bucket", 
            "change": {
                "after": {
                    "bucket": "test-bucket",
                    "server_side_encryption_configuration": [{
                        "rule": [{
                            "apply_server_side_encryption_by_default": [{
                                "sse_algorithm": "AES256"
                            }]
                        }]
                    }]
                }
            }
        }]
    }
}
```

### Policy Performance Testing
```bash
#!/bin/bash
# scripts/policy_performance_test.sh

echo "Running policy performance tests..."

# Generate large test plan
terraform plan -out=large_plan.tfplan
terraform show -json large_plan.tfplan > large_plan.json

# Measure policy evaluation time
start_time=$(date +%s%N)
opa eval -d policies/ -i large_plan.json "data.terraform.deny[x]" > /dev/null
end_time=$(date +%s%N)

duration=$((($end_time - $start_time) / 1000000))
echo "Policy evaluation took: ${duration}ms"

# Performance threshold check
if [ $duration -gt 5000 ]; then
    echo "ERROR: Policy evaluation too slow (>${duration}ms)"
    exit 1
fi

echo "Policy performance test passed"
```

This comprehensive guide provides enterprise-grade policy as code patterns for governance, security, and compliance automation.
