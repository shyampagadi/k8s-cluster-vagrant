# Problem 32: Cost Optimization - Hands-On Exercises

## 🎯 Exercise 1: Cost-Aware Resource Sizing (45 min)

### Objective
Implement intelligent resource sizing based on environment and usage patterns.

### Step 1: Environment-Based Sizing
```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# locals.tf
locals {
  cost_optimized_config = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
      storage_size = 20
      backup_retention = 1
    }
    staging = {
      instance_type = "t3.small"
      min_size     = 1
      max_size     = 3
      storage_size = 50
      backup_retention = 7
    }
    prod = {
      instance_type = "m5.large"
      min_size     = 2
      max_size     = 10
      storage_size = 100
      backup_retention = 30
    }
  }
  
  config = local.cost_optimized_config[var.environment]
}
```

### Step 2: Spot Instance Integration
```hcl
# spot-instances.tf
resource "aws_launch_template" "spot" {
  name_prefix   = "${var.project_name}-spot-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.config.instance_type
  
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.max_spot_price
    }
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-spot-instance"
      CostOptimized = "true"
    }
  }
}

resource "aws_autoscaling_group" "spot" {
  name                = "${var.project_name}-spot-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size           = local.config.min_size
  max_size           = local.config.max_size
  desired_capacity   = local.config.min_size
  
  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage                = var.environment == "prod" ? 50 : 0
      spot_allocation_strategy           = "diversified"
    }
    
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.spot.id
        version           = "$Latest"
      }
      
      override {
        instance_type = "t3.micro"
      }
      override {
        instance_type = "t3.small"
      }
    }
  }
}
```

## 🎯 Exercise 2: Automated Cost Monitoring (60 min)

### Step 1: Budget Creation with Alerts
```hcl
# budgets.tf
resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = {
      "Project" = [var.project_name]
    }
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
```

### Step 2: Cost Anomaly Detection
```hcl
# cost-anomaly.tf
resource "aws_ce_anomaly_detector" "service_monitor" {
  name         = "${var.project_name}-service-anomaly"
  monitor_type = "DIMENSIONAL"
  
  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["Amazon Elastic Compute Cloud - Compute"]
  })
  
  tags = {
    Project = var.project_name
  }
}

resource "aws_ce_anomaly_subscription" "alerts" {
  name      = "${var.project_name}-anomaly-alerts"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.service_monitor.arn
  ]
  
  subscriber {
    type    = "EMAIL"
    address = var.cost_alert_email
  }
  
  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = ["100"]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
}
```

## 🎯 Exercise 3: Resource Lifecycle Management (75 min)

### Step 1: Automated Shutdown Scheduling
```hcl
# lambda-scheduler.tf
resource "aws_lambda_function" "instance_scheduler" {
  filename         = "instance_scheduler.zip"
  function_name    = "${var.project_name}-instance-scheduler"
  role            = aws_iam_role.scheduler_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      PROJECT_TAG = var.project_name
      ENVIRONMENT = var.environment
    }
  }
}

# EventBridge rules for scheduling
resource "aws_cloudwatch_event_rule" "stop_instances" {
  name                = "${var.project_name}-stop-instances"
  description         = "Stop non-production instances at night"
  schedule_expression = "cron(0 22 * * MON-FRI)"
  
  is_enabled = var.environment != "prod"
}

resource "aws_cloudwatch_event_rule" "start_instances" {
  name                = "${var.project_name}-start-instances"
  description         = "Start non-production instances in morning"
  schedule_expression = "cron(0 8 * * MON-FRI)"
  
  is_enabled = var.environment != "prod"
}
```

### Step 2: Storage Lifecycle Policies
```hcl
# s3-lifecycle.tf
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimization" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    id     = "cost_optimization"
    status = "Enabled"
    
    transition {
      days          = var.environment == "prod" ? 30 : 7
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = var.environment == "prod" ? 90 : 30
      storage_class = "GLACIER"
    }
    
    transition {
      days          = var.environment == "prod" ? 365 : 90
      storage_class = "DEEP_ARCHIVE"
    }
    
    expiration {
      days = var.environment == "prod" ? 2555 : 365  # 7 years vs 1 year
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

## 🎯 Exercise 4: Cost Reporting Dashboard (90 min)

### Step 1: CloudWatch Cost Metrics
```hcl
# cost-dashboard.tf
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.project_name}-cost-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Estimated Monthly Charges"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.main[0].id],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Resource Utilization"
        }
      }
    ]
  })
}
```

### Step 2: Cost Allocation Tags
```hcl
# cost-allocation.tf
resource "aws_ce_cost_category" "project_categories" {
  name         = "${var.project_name}-cost-categories"
  rule_version = "CostCategoryExpression.v1"
  
  rule {
    value = "Development"
    rule {
      dimension {
        key           = "TAG"
        values        = ["dev"]
        match_options = ["EQUALS"]
      }
    }
  }
  
  rule {
    value = "Production"
    rule {
      dimension {
        key           = "TAG"
        values        = ["prod"]
        match_options = ["EQUALS"]
      }
    }
  }
  
  default_value = "Unallocated"
}
```

## 🎯 Exercise 5: Reserved Instance Optimization (60 min)

### Step 1: RI Recommendation Analysis
```bash
#!/bin/bash
# scripts/ri-analysis.sh

echo "Analyzing Reserved Instance opportunities..."

# Get RI recommendations
aws ce get-reservation-purchase-recommendation \
  --service "Amazon Elastic Compute Cloud - Compute" \
  --lookback-period-in-days 60 \
  --term-in-years 1 \
  --payment-option "PARTIAL_UPFRONT" > ri_recommendations.json

# Parse and display recommendations
python3 << EOF
import json
with open('ri_recommendations.json', 'r') as f:
    data = json.load(f)
    
recommendations = data.get('Recommendations', [])
for rec in recommendations:
    details = rec.get('RecommendationDetails', {})
    print(f"Instance Type: {details.get('InstanceDetails', {}).get('EC2InstanceDetails', {}).get('InstanceType')}")
    print(f"Estimated Monthly Savings: ${details.get('EstimatedMonthlySavingsAmount')}")
    print(f"Upfront Cost: ${details.get('UpfrontCost')}")
    print("---")
EOF
```

### Step 2: Automated RI Management
```hcl
# ri-management.tf
data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "location"
    values = [var.aws_region]
  }
}

# Lambda for RI utilization monitoring
resource "aws_lambda_function" "ri_monitor" {
  filename         = "ri_monitor.zip"
  function_name    = "${var.project_name}-ri-monitor"
  role            = aws_iam_role.ri_monitor_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.cost_alerts.arn
    }
  }
}

# Schedule RI utilization checks
resource "aws_cloudwatch_event_rule" "ri_utilization_check" {
  name                = "${var.project_name}-ri-check"
  description         = "Check RI utilization weekly"
  schedule_expression = "cron(0 9 ? * MON *)"
}
```

## 📊 Success Validation

### Validation Checklist
- [ ] Cost budgets configured with alerts
- [ ] Spot instances implemented for non-critical workloads
- [ ] Automated shutdown scheduling for dev/staging
- [ ] Storage lifecycle policies configured
- [ ] Cost monitoring dashboard created
- [ ] Reserved instance analysis completed

### Cost Optimization Metrics
```bash
# Measure cost optimization impact
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-02-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

This comprehensive exercise set provides hands-on experience with real-world cost optimization scenarios and enterprise FinOps practices.
