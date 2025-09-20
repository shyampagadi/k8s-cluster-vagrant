# Production Deployment Strategies - Complete Implementation Guide

## Overview

This comprehensive guide covers production deployment patterns including blue-green deployments, canary releases, automated rollbacks, and production-grade infrastructure management for enterprise environments.

## Deployment Strategy Fundamentals

### Blue-Green Deployment

**Concept**: Maintain two identical production environments (blue and green), switching traffic between them for zero-downtime deployments.

**Architecture:**
```hcl
# Blue-Green Infrastructure
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  
  tags = {
    Name = "main-load-balancer"
  }
}

# Blue Environment
resource "aws_lb_target_group" "blue" {
  name     = "blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
  
  tags = {
    Name        = "blue-target-group"
    Environment = "blue"
  }
}

# Green Environment
resource "aws_lb_target_group" "green" {
  name     = "green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
  
  tags = {
    Name        = "green-target-group"
    Environment = "green"
  }
}

# Active Environment Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }
}
```

### Canary Deployment

**Concept**: Gradually roll out changes to a small percentage of users before full deployment.

```hcl
# Canary Deployment with Weighted Routing
resource "aws_lb_listener_rule" "canary" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100
  
  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.production.arn
        weight = var.canary_enabled ? 90 : 100
      }
      
      dynamic "target_group" {
        for_each = var.canary_enabled ? [1] : []
        content {
          arn    = aws_lb_target_group.canary.arn
          weight = 10
        }
      }
    }
  }
  
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Canary Target Group
resource "aws_lb_target_group" "canary" {
  count = var.canary_enabled ? 1 : 0
  
  name     = "canary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}
```

## Auto Scaling Groups for Deployment

### Blue-Green ASG Configuration

```hcl
# Launch Template for Blue Environment
resource "aws_launch_template" "blue" {
  name_prefix   = "blue-template-"
  image_id      = var.blue_ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = "blue"
    app_version = var.blue_app_version
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "blue-instance"
      Environment = "blue"
      Version     = var.blue_app_version
    }
  }
}

# Auto Scaling Group for Blue Environment
resource "aws_autoscaling_group" "blue" {
  name                = "blue-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.blue.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.active_environment == "blue" ? var.min_capacity : 0
  max_size         = var.active_environment == "blue" ? var.max_capacity : 0
  desired_capacity = var.active_environment == "blue" ? var.desired_capacity : 0
  
  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "blue-asg"
    propagate_at_launch = false
  }
  
  tag {
    key                 = "Environment"
    value               = "blue"
    propagate_at_launch = true
  }
}

# Launch Template for Green Environment
resource "aws_launch_template" "green" {
  name_prefix   = "green-template-"
  image_id      = var.green_ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = "green"
    app_version = var.green_app_version
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "green-instance"
      Environment = "green"
      Version     = var.green_app_version
    }
  }
}

# Auto Scaling Group for Green Environment
resource "aws_autoscaling_group" "green" {
  name                = "green-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.green.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.active_environment == "green" ? var.min_capacity : 0
  max_size         = var.active_environment == "green" ? var.max_capacity : 0
  desired_capacity = var.active_environment == "green" ? var.desired_capacity : 0
  
  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "green-asg"
    propagate_at_launch = false
  }
  
  tag {
    key                 = "Environment"
    value               = "green"
    propagate_at_launch = true
  }
}
```

## Health Checks and Monitoring

### Application Health Checks

```hcl
# CloudWatch Alarms for Health Monitoring
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors application error rate"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_healthy_hosts" {
  alarm_name          = "low-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors healthy host count"
  
  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Custom Health Check Endpoint

```bash
#!/bin/bash
# user_data.sh - Health check endpoint setup

# Install application
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Create health check endpoint
cat > /opt/health-check.sh << 'EOF'
#!/bin/bash
# Simple health check script

# Check application process
if pgrep -f "myapp" > /dev/null; then
    echo "OK"
    exit 0
else
    echo "FAIL"
    exit 1
fi
EOF

chmod +x /opt/health-check.sh

# Setup health check service
cat > /etc/systemd/system/health-check.service << 'EOF'
[Unit]
Description=Health Check Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/health-check.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl enable health-check
systemctl start health-check
```

## Automated Rollback Mechanisms

### CloudWatch-Based Rollback

```hcl
# Lambda function for automated rollback
resource "aws_lambda_function" "rollback" {
  filename         = "rollback.zip"
  function_name    = "automated-rollback"
  role            = aws_iam_role.rollback_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      LOAD_BALANCER_ARN = aws_lb.main.arn
      BLUE_TARGET_GROUP = aws_lb_target_group.blue.arn
      GREEN_TARGET_GROUP = aws_lb_target_group.green.arn
    }
  }
}

# CloudWatch Event Rule for Rollback Trigger
resource "aws_cloudwatch_event_rule" "rollback_trigger" {
  name        = "rollback-trigger"
  description = "Trigger rollback on high error rate"
  
  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
      alarmName = [aws_cloudwatch_metric_alarm.high_error_rate.alarm_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "rollback_lambda" {
  rule      = aws_cloudwatch_event_rule.rollback_trigger.name
  target_id = "RollbackLambdaTarget"
  arn       = aws_lambda_function.rollback.arn
}
```

### Rollback Lambda Function

```python
# rollback.py
import boto3
import json
import os

def handler(event, context):
    """
    Automated rollback function triggered by CloudWatch alarms
    """
    
    elbv2 = boto3.client('elbv2')
    
    load_balancer_arn = os.environ['LOAD_BALANCER_ARN']
    blue_target_group = os.environ['BLUE_TARGET_GROUP']
    green_target_group = os.environ['GREEN_TARGET_GROUP']
    
    try:
        # Get current listener configuration
        listeners = elbv2.describe_listeners(LoadBalancerArn=load_balancer_arn)
        
        for listener in listeners['Listeners']:
            current_target_group = listener['DefaultActions'][0]['TargetGroupArn']
            
            # Switch to the other environment
            if current_target_group == blue_target_group:
                new_target_group = green_target_group
                environment = "green"
            else:
                new_target_group = blue_target_group
                environment = "blue"
            
            # Update listener to point to rollback environment
            elbv2.modify_listener(
                ListenerArn=listener['ListenerArn'],
                DefaultActions=[
                    {
                        'Type': 'forward',
                        'TargetGroupArn': new_target_group
                    }
                ]
            )
            
            print(f"Rolled back to {environment} environment")
            
            # Send notification
            sns = boto3.client('sns')
            sns.publish(
                TopicArn=os.environ.get('SNS_TOPIC_ARN'),
                Subject='Automated Rollback Executed',
                Message=f'Application rolled back to {environment} environment due to high error rate'
            )
            
        return {
            'statusCode': 200,
            'body': json.dumps('Rollback completed successfully')
        }
        
    except Exception as e:
        print(f"Rollback failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Rollback failed: {str(e)}')
        }
```

## Database Migration Strategies

### Blue-Green Database Approach

```hcl
# Read Replica for Blue-Green Database
resource "aws_db_instance" "replica" {
  count = var.create_replica ? 1 : 0
  
  identifier             = "app-db-replica"
  replicate_source_db    = aws_db_instance.main.id
  instance_class         = aws_db_instance.main.instance_class
  publicly_accessible    = false
  auto_minor_version_upgrade = false
  
  tags = {
    Name = "app-database-replica"
    Type = "replica"
  }
}

# Database migration Lambda
resource "aws_lambda_function" "db_migration" {
  filename         = "db_migration.zip"
  function_name    = "database-migration"
  role            = aws_iam_role.db_migration_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900  # 15 minutes
  
  environment {
    variables = {
      DB_HOST = aws_db_instance.main.endpoint
      DB_NAME = aws_db_instance.main.db_name
    }
  }
}
```

## Traffic Management

### Weighted Routing for Gradual Rollout

```hcl
# Route 53 Weighted Routing
resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "blue"
  weighted_routing_policy {
    weight = var.blue_weight
  }
  
  alias {
    name                   = aws_lb.blue.dns_name
    zone_id                = aws_lb.blue.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "green"
  weighted_routing_policy {
    weight = var.green_weight
  }
  
  alias {
    name                   = aws_lb.green.dns_name
    zone_id                = aws_lb.green.zone_id
    evaluate_target_health = true
  }
}
```

## Deployment Automation

### CI/CD Pipeline Integration

```yaml
# .github/workflows/deploy.yml
name: Production Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
    
    - name: Determine Target Environment
      id: target
      run: |
        CURRENT=$(terraform output -raw active_environment)
        if [ "$CURRENT" = "blue" ]; then
          echo "::set-output name=target::green"
          echo "::set-output name=current::blue"
        else
          echo "::set-output name=target::blue"
          echo "::set-output name=current::green"
        fi
    
    - name: Deploy to Target Environment
      run: |
        terraform apply -auto-approve \
          -var="deploy_environment=${{ steps.target.outputs.target }}" \
          -var="app_version=${{ github.sha }}"
    
    - name: Run Health Checks
      run: |
        ./scripts/health-check.sh ${{ steps.target.outputs.target }}
    
    - name: Switch Traffic
      if: success()
      run: |
        terraform apply -auto-approve \
          -var="active_environment=${{ steps.target.outputs.target }}"
    
    - name: Rollback on Failure
      if: failure()
      run: |
        terraform apply -auto-approve \
          -var="active_environment=${{ steps.target.outputs.current }}"
```

## Monitoring and Observability

### Deployment Metrics

```hcl
# Custom CloudWatch Metrics
resource "aws_cloudwatch_log_group" "deployment" {
  name              = "/aws/deployment/app"
  retention_in_days = 30
}

# Deployment Success Rate
resource "aws_cloudwatch_metric_alarm" "deployment_success_rate" {
  alarm_name          = "deployment-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DeploymentSuccessRate"
  namespace           = "Custom/Deployment"
  period              = "300"
  statistic           = "Average"
  threshold           = "95"
  alarm_description   = "This metric monitors deployment success rate"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Deployment Duration
resource "aws_cloudwatch_metric_alarm" "deployment_duration" {
  alarm_name          = "deployment-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DeploymentDuration"
  namespace           = "Custom/Deployment"
  period              = "300"
  statistic           = "Average"
  threshold           = "600"  # 10 minutes
  alarm_description   = "This metric monitors deployment duration"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Security Considerations

### Deployment Security

```hcl
# IAM Role for Deployment
resource "aws_iam_role" "deployment" {
  name = "deployment-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Deployment Policy
resource "aws_iam_role_policy" "deployment" {
  name = "deployment-policy"
  role = aws_iam_role.deployment.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elbv2:ModifyListener",
          "elbv2:DescribeListeners",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Best Practices Summary

### Deployment Strategy Selection

1. **Blue-Green**: Best for zero-downtime requirements
2. **Canary**: Best for gradual rollouts and risk mitigation
3. **Rolling**: Best for resource-constrained environments
4. **Feature Flags**: Best for runtime feature control

### Monitoring Requirements

- Health check endpoints on all services
- Comprehensive logging and metrics
- Automated alerting on failures
- Performance monitoring during deployments

### Rollback Criteria

- Error rate exceeds threshold (>5%)
- Response time degrades significantly (>2x baseline)
- Health check failures exceed threshold
- Manual rollback trigger available

### Security Best Practices

- Least privilege IAM policies
- Encrypted communication between services
- Secure credential management
- Audit logging for all deployment actions

This comprehensive guide provides the foundation for implementing production-grade deployment strategies with Terraform, ensuring reliable, secure, and automated infrastructure deployments.
