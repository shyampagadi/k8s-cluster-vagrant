# Enterprise CI/CD Patterns

## 🚀 GitOps Pipeline Architecture

### Multi-Environment Pipeline
```yaml
# .github/workflows/terraform-pipeline.yml
name: Enterprise Terraform Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  TF_VERSION: "1.5.0"
  TFLINT_VERSION: "0.47.0"
  CHECKOV_VERSION: "2.3.0"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
          
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Validate
        run: |
          terraform init -backend=false
          terraform validate
          
      - name: TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
          tflint --init
          tflint --recursive
          
      - name: Checkov Security Scan
        run: |
          pip install checkov==${{ env.CHECKOV_VERSION }}
          checkov -d . --framework terraform --output cli --output sarif --output-file-path console,checkov.sarif
          
      - name: Upload Checkov Results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: checkov.sarif

  plan:
    needs: validate
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    environment: ${{ matrix.environment }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
          
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
          
      - name: Terraform Plan
        run: |
          terraform init
          terraform workspace select ${{ matrix.environment }} || terraform workspace new ${{ matrix.environment }}
          terraform plan -var-file="environments/${{ matrix.environment }}.tfvars" -out=tfplan
          
      - name: Cost Estimation
        run: |
          curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
          infracost breakdown --path=tfplan --format=json --out-file=infracost.json
          infracost comment github --path=infracost.json --repo=${{ github.repository }} --github-token=${{ secrets.GITHUB_TOKEN }} --pull-request=${{ github.event.number }}

  deploy:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    environment: ${{ matrix.environment }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
          
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
          
      - name: Terraform Apply
        run: |
          terraform init
          terraform workspace select ${{ matrix.environment }}
          terraform apply -var-file="environments/${{ matrix.environment }}.tfvars" -auto-approve
          
      - name: Post-Deploy Tests
        run: |
          # Run integration tests
          ./scripts/integration-tests.sh ${{ matrix.environment }}
          
      - name: Notify Deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Advanced Security Integration
```hcl
# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name = "GitHubActions-OIDC"
  }
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "GitHubActions-TerraformRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "GitHubActions"
  }
}

# Policy for Terraform operations
resource "aws_iam_role_policy" "terraform_permissions" {
  name = "TerraformPermissions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:*",
          "s3:*",
          "rds:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })
}
```

### Drift Detection and Remediation
```hcl
# Lambda function for drift detection
resource "aws_lambda_function" "drift_detection" {
  filename         = "drift_detector.zip"
  function_name    = "terraform-drift-detector"
  role            = aws_iam_role.drift_detector.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      STATE_BUCKET    = aws_s3_bucket.terraform_state.bucket
      GITHUB_TOKEN    = var.github_token
      GITHUB_REPO     = var.github_repo
      SLACK_WEBHOOK   = var.slack_webhook_url
    }
  }

  tags = {
    Purpose = "DriftDetection"
  }
}

# EventBridge rule for scheduled drift detection
resource "aws_cloudwatch_event_rule" "drift_detection_schedule" {
  name                = "terraform-drift-detection"
  description         = "Trigger drift detection every 6 hours"
  schedule_expression = "rate(6 hours)"

  tags = {
    Purpose = "DriftDetection"
  }
}

resource "aws_cloudwatch_event_target" "drift_detection_lambda" {
  rule      = aws_cloudwatch_event_rule.drift_detection_schedule.name
  target_id = "DriftDetectionLambdaTarget"
  arn       = aws_lambda_function.drift_detection.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.drift_detection.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.drift_detection_schedule.arn
}
```

This provides enterprise-grade CI/CD patterns with security, compliance, and automation.
