# Problem 38: Policy as Code with OPA and AWS Config

## Overview

This solution implements governance and compliance through code using AWS Config rules and policy validation patterns.

## Key Concepts

- **AWS Config**: Continuous compliance monitoring
- **Policy Rules**: Automated compliance checking
- **Resource Compliance**: Ensuring resources meet organizational policies
- **Governance Automation**: Policy enforcement through infrastructure code

## Features

- AWS Config setup with delivery channel
- Multiple compliance rules (S3, EBS, IAM)
- Compliant resource examples
- Policy validation using locals
- Automated compliance reporting

## Compliance Rules Implemented

1. **S3 Bucket Public Access Prohibited**
2. **Encrypted Volumes Required**
3. **Root Access Key Check**
4. **Resource Tagging Compliance**

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Policy Extensions

This can be extended with:
- Open Policy Agent (OPA) integration
- Sentinel policies for Terraform Cloud
- Custom Config rules
- Integration with security scanning tools
