# Final Project - Deployment Guide

## Overview
This guide provides comprehensive deployment instructions for the final Terraform project, covering multi-environment deployment, CI/CD integration, and production best practices.

## Prerequisites

### Required Tools
- **Terraform**: Version 1.5.0 or later
- **AWS CLI**: Version 2.0 or later
- **Git**: Version 2.0 or later
- **Docker**: Version 20.0 or later (for testing)

### Required Permissions
- **AWS IAM**: Administrative access to AWS account
- **GitHub**: Repository access and secrets management
- **Docker Hub**: Container registry access

### Environment Setup
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
```

## Environment Configuration

### Development Environment
```bash
# Navigate to development environment
cd environments/dev

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### Staging Environment
```bash
# Navigate to staging environment
cd environments/staging

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### Production Environment
```bash
# Navigate to production environment
cd environments/prod

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes (with confirmation)
terraform apply -var-file="terraform.tfvars"
```

## CI/CD Pipeline Setup

### GitHub Actions Workflow
```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD Pipeline

on:
  push:
    branches: [main, develop]
    paths: ['terraform/**']
  pull_request:
    branches: [main]
    paths: ['terraform/**']

env:
  TF_VERSION: '1.5.0'
  AWS_REGION: 'us-west-2'

jobs:
  validate:
    name: Validate Terraform
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: ./terraform

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Validate
        run: terraform validate
        working-directory: ./terraform

      - name: Terraform Security Scan
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: ./terraform

  plan:
    name: Plan Terraform Changes
    runs-on: ubuntu-latest
    needs: validate
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: terraform-plan
          path: ./terraform/tfplan

  deploy-development:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: [validate, plan]
    if: github.ref == 'refs/heads/develop'
    environment: development
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_environment: development

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [validate, plan]
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_environment: staging

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [validate, plan]
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_environment: production
```

## Deployment Strategies

### Blue-Green Deployment
```bash
# Blue-Green deployment script
#!/bin/bash

ENVIRONMENT=$1
CURRENT_COLOR=$(terraform output -raw current_color 2>/dev/null || echo "blue")
NEW_COLOR=$([ "$CURRENT_COLOR" = "blue" ] && echo "green" || echo "blue")

echo "Current color: $CURRENT_COLOR"
echo "New color: $NEW_COLOR"

# Deploy new environment
terraform apply -auto-approve \
  -var="environment=$ENVIRONMENT" \
  -var="color=$NEW_COLOR"

# Wait for health check
sleep 300
curl -f https://$NEW_COLOR-$ENVIRONMENT.example.com/health

# Switch traffic
terraform apply -auto-approve \
  -var="environment=$ENVIRONMENT" \
  -var="current_color=$NEW_COLOR"

# Cleanup old environment
terraform apply -auto-approve \
  -var="environment=$ENVIRONMENT" \
  -var="color=$CURRENT_COLOR" \
  -var="enabled=false"
```

### Canary Deployment
```bash
# Canary deployment script
#!/bin/bash

ENVIRONMENT=$1
CANARY_PERCENTAGE=$2

echo "Deploying canary to $ENVIRONMENT with $CANARY_PERCENTAGE% traffic"

# Deploy canary
terraform apply -auto-approve \
  -var="environment=$ENVIRONMENT" \
  -var="canary_percentage=$CANARY_PERCENTAGE" \
  -var="deployment_type=canary"

# Monitor canary
for i in {1..20}; do
  ERROR_RATE=$(curl -s https://api.example.com/metrics | jq '.error_rate')
  if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
    echo "Canary deployment failed - error rate too high"
    exit 1
  fi
  sleep 30
done

# Promote canary
terraform apply -auto-approve \
  -var="environment=$ENVIRONMENT" \
  -var="canary_percentage=100" \
  -var="deployment_type=canary"
```

## Testing and Validation

### Infrastructure Testing
```bash
# Run Terratest
go test -v -timeout 30m ./tests/...

# Run security scans
tfsec ./terraform
checkov -d ./terraform --framework terraform

# Run compliance checks
terraform-compliance -p ./terraform -f ./compliance/
```

### Health Checks
```bash
# Application health check
curl -f https://$ENVIRONMENT.example.com/health

# Database health check
aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER

# Load balancer health check
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

## Monitoring and Alerting

### CloudWatch Setup
```bash
# Create CloudWatch dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "$PROJECT_NAME-dashboard" \
  --dashboard-body file://dashboard.json

# Create CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "$PROJECT_NAME-high-cpu" \
  --alarm-description "High CPU utilization" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### SNS Notifications
```bash
# Create SNS topic
aws sns create-topic --name "$PROJECT_NAME-alerts"

# Subscribe to topic
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol email \
  --notification-endpoint $ALERT_EMAIL
```

## Troubleshooting

### Common Issues
1. **State Lock Issues**: Resolve with `terraform force-unlock <lock-id>`
2. **Resource Conflicts**: Check for naming conflicts
3. **Permission Issues**: Verify IAM permissions
4. **Network Issues**: Check security groups and NACLs
5. **Dependency Issues**: Verify resource dependencies

### Debugging Commands
```bash
# Debug Terraform
terraform plan -debug

# Check state
terraform state list
terraform state show <resource>

# Validate configuration
terraform validate

# Check for drift
terraform plan -detailed-exitcode
```

## Rollback Procedures

### Automated Rollback
```bash
# Rollback script
#!/bin/bash

ENVIRONMENT=$1

echo "Rolling back $ENVIRONMENT environment"

# Get previous state
terraform state pull > current.tfstate
aws s3 cp s3://terraform-state-bucket/backups/$ENVIRONMENT/previous.tfstate ./previous.tfstate

# Rollback to previous state
terraform state push previous.tfstate
terraform apply -auto-approve -var="environment=$ENVIRONMENT"

# Verify rollback
curl -f https://$ENVIRONMENT.example.com/health
```

### Manual Rollback
```bash
# Manual rollback steps
1. Identify the issue
2. Stop new deployments
3. Restore from backup
4. Verify functionality
5. Resume normal operations
```

## Best Practices

### Deployment Best Practices
- **Automation**: Automate all deployment processes
- **Testing**: Test in development before production
- **Monitoring**: Monitor deployments and infrastructure
- **Documentation**: Document all deployment procedures
- **Backup**: Maintain regular backups

### Security Best Practices
- **Secrets Management**: Use secure secrets management
- **Access Control**: Implement proper access controls
- **Audit Logging**: Enable comprehensive audit logging
- **Vulnerability Scanning**: Regular security scans
- **Compliance**: Ensure regulatory compliance

## Conclusion

This deployment guide provides comprehensive instructions for deploying the final Terraform project across multiple environments. By following these procedures, you can achieve reliable, secure, and efficient infrastructure deployment.

Regular review and updates of deployment procedures ensure continued effectiveness and adaptation to evolving requirements and technology landscapes.
