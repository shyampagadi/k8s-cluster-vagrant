# Production Deployment Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for production deployment implementations, blue-green deployment issues, canary release problems, and zero-downtime deployment challenges.

## 📋 Table of Contents

1. [Blue-Green Deployment Issues](#blue-green-deployment-issues)
2. [Canary Release Problems](#canary-release-problems)
3. [Zero-Downtime Deployment Challenges](#zero-downtime-deployment-challenges)
4. [Traffic Management Issues](#traffic-management-issues)
5. [Health Check Problems](#health-check-problems)
6. [Rollback and Recovery Issues](#rollback-and-recovery-issues)
7. [Monitoring and Alerting Problems](#monitoring-and-alerting-problems)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 🔵🟢 Blue-Green Deployment Issues

### Problem: Blue-Green Deployment Failures

**Symptoms:**
```
Error: blue-green deployment failed: traffic switch timeout
```

**Root Causes:**
- Incorrect traffic switching configuration
- Missing health checks
- Insufficient capacity
- Network connectivity issues

**Solutions:**

#### Solution 1: Fix Blue-Green Configuration
```hcl
# ✅ Comprehensive blue-green deployment configuration
locals {
  blue_green_config = {
    # Environment configuration
    environments = {
      blue = {
        color = "blue"
        traffic_percentage = 100
        active = true
      }
      green = {
        color = "green"
        traffic_percentage = 0
        active = false
      }
    }
    
    # Health check configuration
    health_check = {
      enabled = true
      interval = 30
      timeout = 5
      healthy_threshold = 2
      unhealthy_threshold = 3
      path = "/health"
    }
    
    # Traffic switching configuration
    traffic_switch = {
      gradual_shift = true
      shift_interval = 300
      shift_percentage = 10
      validation_timeout = 600
    }
  }
}

# Blue environment
resource "aws_instance" "blue" {
  count = var.environment == "blue" ? var.instance_count : 0
  
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = "blue"
    version = var.app_version
  }))
  
  tags = {
    Name = "blue-instance-${count.index + 1}"
    Environment = "blue"
    Version = var.app_version
  }
}

# Green environment
resource "aws_instance" "green" {
  count = var.environment == "green" ? var.instance_count : 0
  
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = "green"
    version = var.app_version
  }))
  
  tags = {
    Name = "green-instance-${count.index + 1}"
    Environment = "green"
    Version = var.app_version
  }
}

# Load balancer with blue-green support
resource "aws_lb" "blue_green" {
  name               = "blue-green-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id
  
  tags = {
    Name = "blue-green-lb"
  }
}

# Target groups for blue and green
resource "aws_lb_target_group" "blue" {
  name     = "blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = local.blue_green_config.health_check.healthy_threshold
    unhealthy_threshold = local.blue_green_config.health_check.unhealthy_threshold
    timeout             = local.blue_green_config.health_check.timeout
    interval            = local.blue_green_config.health_check.interval
    path                = local.blue_green_config.health_check.path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = {
    Name = "blue-target-group"
  }
}

resource "aws_lb_target_group" "green" {
  name     = "green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = local.blue_green_config.health_check.healthy_threshold
    unhealthy_threshold = local.blue_green_config.health_check.unhealthy_threshold
    timeout             = local.blue_green_config.health_check.timeout
    interval            = local.blue_green_config.health_check.interval
    path                = local.blue_green_config.health_check.path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = {
    Name = "green-target-group"
  }
}

# Target group attachments
resource "aws_lb_target_group_attachment" "blue" {
  count = length(aws_instance.blue)
  
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "green" {
  count = length(aws_instance.green)
  
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.green[count.index].id
  port             = 80
}

# Listener with blue-green traffic switching
resource "aws_lb_listener" "blue_green" {
  load_balancer_arn = aws_lb.blue_green.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  
  # Blue-green traffic switching action
  dynamic "action" {
    for_each = var.environment == "green" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.green.arn
    }
  }
}
```

#### Solution 2: Implement Traffic Switching Automation
```hcl
# ✅ Traffic switching automation
resource "aws_lambda_function" "traffic_switch" {
  filename         = "traffic_switch.zip"
  function_name    = "traffic-switch"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      BLUE_TARGET_GROUP = aws_lb_target_group.blue.arn
      GREEN_TARGET_GROUP = aws_lb_target_group.green.arn
      LISTENER_ARN = aws_lb_listener.blue_green.arn
    }
  }
  
  tags = {
    Name = "traffic-switch-function"
  }
}

# Traffic switching CloudWatch event
resource "aws_cloudwatch_event_rule" "traffic_switch" {
  name        = "traffic-switch-rule"
  description = "Trigger traffic switching"
  
  event_pattern = jsonencode({
    source      = ["aws.codedeploy"]
    detail-type = ["CodeDeploy Deployment State Change"]
    detail = {
      state = ["SUCCESS"]
    }
  })
}

resource "aws_cloudwatch_event_target" "traffic_switch" {
  rule      = aws_cloudwatch_event_rule.traffic_switch.name
  target_id = "TrafficSwitchTarget"
  arn       = aws_lambda_function.traffic_switch.arn
}
```

---

## 🐦 Canary Release Problems

### Problem: Canary Release Failures

**Symptoms:**
```
Error: canary release failed: traffic shift validation failed
```

**Root Causes:**
- Incorrect traffic shifting configuration
- Insufficient canary validation
- Missing performance monitoring
- Inadequate rollback triggers

**Solutions:**

#### Solution 1: Fix Canary Release Configuration
```hcl
# ✅ Comprehensive canary release configuration
locals {
  canary_config = {
    # Canary stages
    stages = {
      stage1 = {
        traffic_percentage = 5
        duration = 300
        validation_metrics = ["error_rate", "response_time"]
      }
      stage2 = {
        traffic_percentage = 25
        duration = 600
        validation_metrics = ["error_rate", "response_time", "throughput"]
      }
      stage3 = {
        traffic_percentage = 50
        duration = 900
        validation_metrics = ["error_rate", "response_time", "throughput", "cpu_utilization"]
      }
      stage4 = {
        traffic_percentage = 100
        duration = 1200
        validation_metrics = ["error_rate", "response_time", "throughput", "cpu_utilization", "memory_utilization"]
      }
    }
    
    # Validation thresholds
    validation_thresholds = {
      error_rate = 0.01
      response_time = 1000
      throughput = 1000
      cpu_utilization = 80
      memory_utilization = 80
    }
    
    # Rollback triggers
    rollback_triggers = {
      error_rate_threshold = 0.05
      response_time_threshold = 2000
      cpu_utilization_threshold = 90
      memory_utilization_threshold = 90
    }
  }
}

# Canary target group
resource "aws_lb_target_group" "canary" {
  name     = "canary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = {
    Name = "canary-target-group"
  }
}

# Canary instances
resource "aws_instance" "canary" {
  count = var.enable_canary ? var.canary_instance_count : 0
  
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = "canary"
    version = var.canary_version
  }))
  
  tags = {
    Name = "canary-instance-${count.index + 1}"
    Environment = "canary"
    Version = var.canary_version
  }
}

# Canary target group attachments
resource "aws_lb_target_group_attachment" "canary" {
  count = length(aws_instance.canary)
  
  target_group_arn = aws_lb_target_group.canary.arn
  target_id        = aws_instance.canary[count.index].id
  port             = 80
}

# Canary listener rule
resource "aws_lb_listener_rule" "canary" {
  count = var.enable_canary ? 1 : 0
  
  listener_arn = aws_lb_listener.blue_green.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.canary.arn
  }
  
  condition {
    path_pattern {
      values = ["/canary/*"]
    }
  }
}
```

#### Solution 2: Implement Canary Validation
```hcl
# ✅ Canary validation implementation
resource "aws_cloudwatch_metric_alarm" "canary_error_rate" {
  count = var.enable_canary ? 1 : 0
  
  alarm_name          = "canary-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = local.canary_config.rollback_triggers.error_rate_threshold
  alarm_description   = "Canary error rate exceeded threshold"
  
  dimensions = {
    TargetGroup = aws_lb_target_group.canary.arn_suffix
    LoadBalancer = aws_lb.blue_green.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  
  tags = {
    Name = "canary-error-rate-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "canary_response_time" {
  count = var.enable_canary ? 1 : 0
  
  alarm_name          = "canary-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = local.canary_config.rollback_triggers.response_time_threshold
  alarm_description   = "Canary response time exceeded threshold"
  
  dimensions = {
    TargetGroup = aws_lb_target_group.canary.arn_suffix
    LoadBalancer = aws_lb.blue_green.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  
  tags = {
    Name = "canary-response-time-alarm"
  }
}

# Canary alerts
resource "aws_sns_topic" "canary_alerts" {
  count = var.enable_canary ? 1 : 0
  
  name = "canary-alerts"
  
  tags = {
    Name = "canary-alerts"
  }
}

resource "aws_sns_topic_subscription" "canary_alerts" {
  count = var.enable_canary ? 1 : 0
  
  topic_arn = aws_sns_topic.canary_alerts[0].arn
  protocol  = "email"
  endpoint  = var.canary_team_email
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Deployment State Inspection
```bash
# ✅ Inspect deployment state
aws codedeploy list-deployments --application-name $APP_NAME
aws codedeploy get-deployment --deployment-id $DEPLOYMENT_ID
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

### Technique 2: Traffic Analysis
```bash
# ✅ Analyze traffic patterns
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-02T00:00:00Z \
  --period 300 \
  --statistics Sum
```

### Technique 3: Health Check Validation
```bash
# ✅ Validate health checks
curl -f http://$LOAD_BALANCER_DNS/health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Deployment Testing
```hcl
# ✅ Test deployment in isolation
resource "aws_instance" "test_deployment" {
  ami           = data.aws_ami.example.id
  instance_type = "t3.micro"
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = "test"
    version = "test"
  }))
  
  tags = {
    Name = "test-deployment-instance"
    Test = "true"
  }
}
```

### Strategy 2: Deployment Monitoring
```bash
# ✅ Monitor deployment performance
aws codedeploy list-deployments --application-name $APP_NAME
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

---

## 📞 Getting Help

### Internal Resources
- Review deployment documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review deployment documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Design for Zero-Downtime**: Plan deployment strategies before implementation
- **Implement Health Checks**: Apply comprehensive health monitoring
- **Automate Traffic Switching**: Implement automated traffic management
- **Monitor Continuously**: Monitor deployment processes continuously
- **Test Thoroughly**: Test deployment strategies regularly
- **Document Everything**: Maintain clear deployment documentation
- **Handle Errors**: Implement robust error handling and rollback
- **Scale Appropriately**: Design for enterprise scale

Remember: Production deployment requires careful planning, comprehensive implementation, and continuous monitoring. Proper implementation ensures reliable, scalable, and maintainable deployment processes.
