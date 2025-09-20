# CI/CD Integration with Terraform - Comprehensive Guide

## Overview
This guide covers comprehensive CI/CD integration patterns for Terraform, including GitHub Actions workflows, automated testing, deployment automation, and security scanning.

## CI/CD Architecture Patterns

### Multi-Environment Pipeline
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

## Advanced CI/CD Patterns

### Blue-Green Deployment
```yaml
# .github/workflows/blue-green.yml
name: Blue-Green Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  blue-green-deploy:
    name: Blue-Green Deployment
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Determine Current Color
        id: current-color
        run: |
          CURRENT_COLOR=$(terraform output -raw current_color 2>/dev/null || echo "blue")
          NEW_COLOR=$([ "$CURRENT_COLOR" = "blue" ] && echo "green" || echo "blue")
          echo "current_color=$CURRENT_COLOR" >> $GITHUB_OUTPUT
          echo "new_color=$NEW_COLOR" >> $GITHUB_OUTPUT

      - name: Deploy New Environment
        run: |
          terraform init
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}" \
            -var="color=${{ steps.current-color.outputs.new_color }}"

      - name: Health Check
        run: |
          # Wait for new environment to be healthy
          sleep 300
          # Perform health checks
          curl -f https://${{ steps.current-color.outputs.new_color }}-${{ github.event.inputs.environment }}.example.com/health

      - name: Switch Traffic
        run: |
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}" \
            -var="current_color=${{ steps.current-color.outputs.new_color }}"

      - name: Cleanup Old Environment
        run: |
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}" \
            -var="color=${{ steps.current-color.outputs.current_color }}" \
            -var="enabled=false"
```

### Canary Deployment
```yaml
# .github/workflows/canary.yml
name: Canary Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
      canary_percentage:
        description: 'Canary traffic percentage'
        required: true
        default: '10'
        type: string

jobs:
  canary-deploy:
    name: Canary Deployment
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Deploy Canary
        run: |
          terraform init
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}" \
            -var="canary_percentage=${{ github.event.inputs.canary_percentage }}" \
            -var="deployment_type=canary"

      - name: Monitor Canary
        run: |
          # Monitor canary for 10 minutes
          for i in {1..20}; do
            # Check error rates, response times, etc.
            ERROR_RATE=$(curl -s https://api.example.com/metrics | jq '.error_rate')
            if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
              echo "Canary deployment failed - error rate too high"
              exit 1
            fi
            sleep 30
          done

      - name: Promote Canary
        run: |
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}" \
            -var="canary_percentage=100" \
            -var="deployment_type=canary"
```

## Automated Testing Strategies

### Infrastructure Testing
```yaml
# .github/workflows/test.yml
name: Infrastructure Testing

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Run Terratest
        run: |
          go test -v -timeout 30m ./tests/...

  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Run Integration Tests
        run: |
          terraform init
          terraform apply -auto-approve -var="environment=test"
          # Run integration tests
          terraform destroy -auto-approve -var="environment=test"
```

### Security Testing
```yaml
# .github/workflows/security.yml
name: Security Testing

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run TFSec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: ./terraform
          soft_fail: true

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: ./terraform
          framework: terraform
          soft_fail: true

      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: './terraform'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

## Deployment Automation

### Automated Rollback
```yaml
# .github/workflows/rollback.yml
name: Automated Rollback

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  rollback:
    name: Rollback Deployment
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Get Previous State
        run: |
          terraform init
          terraform state pull > current.tfstate
          # Get previous state from S3
          aws s3 cp s3://terraform-state-bucket/backups/${{ github.event.inputs.environment }}/previous.tfstate ./previous.tfstate

      - name: Rollback to Previous State
        run: |
          terraform state push previous.tfstate
          terraform apply -auto-approve \
            -var="environment=${{ github.event.inputs.environment }}"

      - name: Verify Rollback
        run: |
          # Verify that rollback was successful
          curl -f https://${{ github.event.inputs.environment }}.example.com/health
```

### Infrastructure Drift Detection
```yaml
# .github/workflows/drift-detection.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 2 * * *'  # Run daily at 2 AM
  workflow_dispatch:

jobs:
  drift-detection:
    name: Detect Infrastructure Drift
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Check for Drift
        run: |
          terraform init
          terraform plan -detailed-exitcode
          DRIFT_EXIT_CODE=$?
          
          if [ $DRIFT_EXIT_CODE -eq 2 ]; then
            echo "Infrastructure drift detected!"
            # Send notification
            curl -X POST -H 'Content-type: application/json' \
              --data '{"text":"Infrastructure drift detected in production!"}' \
              ${{ secrets.SLACK_WEBHOOK_URL }}
            exit 1
          elif [ $DRIFT_EXIT_CODE -eq 1 ]; then
            echo "Terraform plan failed!"
            exit 1
          else
            echo "No drift detected"
          fi
```

## Monitoring and Alerting

### Deployment Monitoring
```yaml
# .github/workflows/monitor.yml
name: Deployment Monitoring

on:
  workflow_run:
    workflows: ["Terraform CI/CD Pipeline"]
    types: [completed]

jobs:
  monitor-deployment:
    name: Monitor Deployment
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Monitor Deployment Health
        run: |
          # Wait for deployment to stabilize
          sleep 300
          
          # Check application health
          HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" https://production.example.com/health)
          
          if [ $HEALTH_CHECK -ne 200 ]; then
            echo "Deployment health check failed!"
            # Send alert
            curl -X POST -H 'Content-type: application/json' \
              --data '{"text":"Deployment health check failed!"}' \
              ${{ secrets.SLACK_WEBHOOK_URL }}
            exit 1
          fi
          
          # Check CloudWatch metrics
          aws cloudwatch get-metric-statistics \
            --namespace AWS/ApplicationELB \
            --metric-name TargetResponseTime \
            --dimensions Name=LoadBalancer,Value=production-lb \
            --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
            --period 300 \
            --statistics Average
```

## Best Practices

### CI/CD Best Practices
- **Automation**: Automate all deployment processes
- **Testing**: Implement comprehensive testing strategies
- **Security**: Integrate security scanning and validation
- **Monitoring**: Monitor deployments and infrastructure health
- **Documentation**: Document all CI/CD processes

### Security Best Practices
- **Secrets Management**: Use secure secrets management
- **Access Control**: Implement proper access controls
- **Audit Logging**: Enable comprehensive audit logging
- **Vulnerability Scanning**: Regular vulnerability scanning
- **Compliance**: Ensure regulatory compliance

## Conclusion

CI/CD integration with Terraform enables automated, reliable, and secure infrastructure deployment. By implementing comprehensive CI/CD patterns, organizations can achieve efficient infrastructure management and deployment automation.

Regular review and updates of CI/CD processes ensure continued effectiveness and adaptation to evolving requirements and technology landscapes.
