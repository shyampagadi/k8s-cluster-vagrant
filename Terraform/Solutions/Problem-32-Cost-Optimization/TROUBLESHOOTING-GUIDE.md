# Cost Optimization Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for cost optimization implementations, resource efficiency issues, cost monitoring problems, and budget management challenges.

## 📋 Table of Contents

1. [Resource Rightsizing Issues](#resource-rightsizing-issues)
2. [Cost Monitoring Problems](#cost-monitoring-problems)
3. [Budget Management Challenges](#budget-management-challenges)
4. [Automated Optimization Failures](#automated-optimization-failures)
5. [Performance vs. Cost Issues](#performance-vs-cost-issues)
6. [Cost Allocation Problems](#cost-allocation-problems)
7. [Reserved Instance Management Issues](#reserved-instance-management-issues)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 📊 Resource Rightsizing Issues

### Problem: Resource Rightsizing Failures

**Symptoms:**
```
Error: resource rightsizing failed: insufficient capacity
```

**Root Causes:**
- Incorrect utilization thresholds
- Missing capacity planning
- Insufficient monitoring data
- Incorrect instance type selection

**Solutions:**

#### Solution 1: Fix Resource Rightsizing Configuration
```hcl
# ✅ Comprehensive resource rightsizing configuration
locals {
  rightsizing_config = {
    # CPU utilization thresholds
    cpu_thresholds = {
      scale_up_threshold = 70
      scale_down_threshold = 30
      scale_up_cooldown = 300
      scale_down_cooldown = 300
      evaluation_periods = 2
    }
    
    # Memory utilization thresholds
    memory_thresholds = {
      scale_up_threshold = 80
      scale_down_threshold = 40
      scale_up_cooldown = 300
      scale_down_cooldown = 300
      evaluation_periods = 2
    }
    
    # Instance type recommendations
    instance_recommendations = {
      t3_micro = { 
        min_cpu = 0, max_cpu = 20, 
        min_memory = 0, max_memory = 1,
        cost_per_hour = 0.0104
      }
      t3_small = { 
        min_cpu = 20, max_cpu = 40, 
        min_memory = 1, max_memory = 2,
        cost_per_hour = 0.0208
      }
      t3_medium = { 
        min_cpu = 40, max_cpu = 60, 
        min_memory = 2, max_memory = 4,
        cost_per_hour = 0.0416
      }
      t3_large = { 
        min_cpu = 60, max_cpu = 80, 
        min_memory = 4, max_memory = 8,
        cost_per_hour = 0.0832
      }
      t3_xlarge = { 
        min_cpu = 80, max_cpu = 100, 
        min_memory = 8, max_memory = 16,
        cost_per_hour = 0.1664
      }
    }
  }
}

# Auto Scaling Group with proper rightsizing
resource "aws_autoscaling_group" "rightsized" {
  name                = "rightsized-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = 1
  max_size         = 10
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.rightsized.id
    version = "$Latest"
  }
  
  # Enable detailed monitoring
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances"
  ]
  
  tag {
    key                 = "Name"
    value               = "rightsized-instance"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "CostOptimization"
    value               = "enabled"
    propagate_at_launch = true
  }
}

# Rightsizing scaling policies
resource "aws_autoscaling_policy" "scale_up_cpu" {
  name                   = "rightsized-scale-up-cpu"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = local.rightsizing_config.cpu_thresholds.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.rightsized.name
}

resource "aws_autoscaling_policy" "scale_down_cpu" {
  name                   = "rightsized-scale-down-cpu"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = local.rightsizing_config.cpu_thresholds.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.rightsized.name
}

# CloudWatch alarms for rightsizing
resource "aws_cloudwatch_metric_alarm" "cpu_high_rightsized" {
  alarm_name          = "rightsized-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.rightsizing_config.cpu_thresholds.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = local.rightsizing_config.cpu_thresholds.scale_up_threshold
  alarm_description   = "CPU utilization is high - scale up"
  
  alarm_actions = [aws_autoscaling_policy.scale_up_cpu.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.rightsized.name
  }
  
  tags = {
    Name = "rightsized-cpu-high-alarm"
    Purpose = "cost-optimization"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_rightsized" {
  alarm_name          = "rightsized-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.rightsizing_config.cpu_thresholds.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = local.rightsizing_config.cpu_thresholds.scale_down_threshold
  alarm_description   = "CPU utilization is low - scale down"
  
  alarm_actions = [aws_autoscaling_policy.scale_down_cpu.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.rightsized.name
  }
  
  tags = {
    Name = "rightsized-cpu-low-alarm"
    Purpose = "cost-optimization"
  }
}
```

#### Solution 2: Implement Instance Type Recommendations
```hcl
# ✅ Instance type recommendations based on utilization
locals {
  # Calculate recommended instance type based on utilization
  instance_recommendations = {
    for instance_id, metrics in var.instance_metrics : instance_id => {
      current_type = metrics.instance_type
      cpu_utilization = metrics.cpu_utilization
      memory_utilization = metrics.memory_utilization
      
      # Calculate recommended type
      recommended_type = (
        cpu_utilization > 80 || memory_utilization > 80 ? "larger" :
        cpu_utilization < 20 && memory_utilization < 20 ? "smaller" :
        "optimal"
      )
      
      # Calculate cost savings
      current_cost = local.rightsizing_config.instance_recommendations[metrics.instance_type].cost_per_hour
      recommended_cost = (
        recommended_type == "larger" ? local.rightsizing_config.instance_recommendations["t3_large"].cost_per_hour :
        recommended_type == "smaller" ? local.rightsizing_config.instance_recommendations["t3_small"].cost_per_hour :
        current_cost
      )
      
      cost_savings = current_cost - recommended_cost
      cost_savings_percentage = (cost_savings / current_cost) * 100
    }
  }
}

# Output recommendations
output "instance_recommendations" {
  description = "Instance type recommendations for cost optimization"
  value = {
    for instance_id, recommendation in local.instance_recommendations : instance_id => {
      current_type = recommendation.current_type
      recommended_type = recommendation.recommended_type
      cost_savings = recommendation.cost_savings
      cost_savings_percentage = recommendation.cost_savings_percentage
    }
  }
}
```

---

## 💰 Cost Monitoring Problems

### Problem: Cost Monitoring Failures

**Symptoms:**
```
Error: cost monitoring failed: unable to retrieve cost data
```

**Root Causes:**
- Missing cost monitoring permissions
- Incorrect cost data configuration
- Insufficient monitoring coverage
- Missing cost data sources

**Solutions:**

#### Solution 1: Fix Cost Monitoring Configuration
```hcl
# ✅ Comprehensive cost monitoring configuration
locals {
  cost_monitoring_config = {
    # Cost data sources
    data_sources = {
      enable_cur = true
      enable_billing_alerts = true
      enable_cost_explorer = true
      enable_budget_alerts = true
    }
    
    # Monitoring intervals
    monitoring_intervals = {
      real_time = 300
      hourly = 3600
      daily = 86400
      monthly = 2592000
    }
    
    # Alert thresholds
    alert_thresholds = {
      warning_threshold = 80
      critical_threshold = 100
      overrun_threshold = 120
    }
  }
}

# Cost and Usage Report
resource "aws_cur_report_definition" "cost_monitoring" {
  report_name                = "cost-monitoring-report"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cost_reports.bucket
  s3_prefix                  = "cost-monitoring/"
  s3_region                  = var.aws_region
  
  additional_artifacts = [
    "REDSHIFT",
    "QUICKSIGHT"
  ]
  
  refresh_closed_reports = true
  report_versioning      = "OVERWRITE_REPORT"
}

# Cost monitoring dashboard
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "cost-monitoring-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges"],
            ["AWS/EC2", "CPUUtilization"],
            ["AWS/EBS", "VolumeReadBytes"],
            ["AWS/S3", "BucketSizeBytes"]
          ]
          period = local.cost_monitoring_config.monitoring_intervals.real_time
          stat   = "Average"
          region = var.aws_region
          title  = "Real-time Cost and Utilization Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn"],
            ["AWS/EC2", "NetworkOut"],
            ["AWS/RDS", "DatabaseConnections"],
            ["AWS/ELB", "RequestCount"]
          ]
          period = local.cost_monitoring_config.monitoring_intervals.real_time
          stat   = "Sum"
          region = var.aws_region
          title  = "Network and Connection Metrics"
        }
      }
    ]
  })
}

# Cost monitoring alarms
resource "aws_cloudwatch_metric_alarm" "cost_warning" {
  alarm_name          = "cost-warning-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # Daily
  statistic           = "Maximum"
  threshold           = var.monthly_budget_limit * (local.cost_monitoring_config.alert_thresholds.warning_threshold / 100)
  alarm_description   = "Cost warning threshold exceeded"
  
  alarm_actions = [aws_sns_topic.cost_alerts.arn]
  
  tags = {
    Name = "cost-warning-alarm"
    Purpose = "cost-optimization"
  }
}

resource "aws_cloudwatch_metric_alarm" "cost_critical" {
  alarm_name          = "cost-critical-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # Daily
  statistic           = "Maximum"
  threshold           = var.monthly_budget_limit * (local.cost_monitoring_config.alert_thresholds.critical_threshold / 100)
  alarm_description   = "Cost critical threshold exceeded"
  
  alarm_actions = [aws_sns_topic.cost_alerts.arn]
  
  tags = {
    Name = "cost-critical-alarm"
    Purpose = "cost-optimization"
  }
}
```

#### Solution 2: Implement Cost Anomaly Detection
```hcl
# ✅ Cost anomaly detection
resource "aws_cloudwatch_anomaly_detector" "cost_anomaly" {
  metric_name = "EstimatedCharges"
  namespace   = "AWS/Billing"
  stat        = "Maximum"
  
  configuration {
    metric_timezone = "UTC"
  }
  
  tags = {
    Name = "cost-anomaly-detector"
    Purpose = "cost-optimization"
  }
}

# Cost anomaly alarm
resource "aws_cloudwatch_metric_alarm" "cost_anomaly" {
  alarm_name          = "cost-anomaly-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # Daily
  statistic           = "Maximum"
  threshold           = var.monthly_budget_limit * 1.5  # 150% of budget
  alarm_description   = "Cost anomaly detected"
  
  alarm_actions = [aws_sns_topic.cost_alerts.arn]
  
  tags = {
    Name = "cost-anomaly-alarm"
    Purpose = "cost-optimization"
  }
}
```

---

## 💳 Budget Management Challenges

### Problem: Budget Management Failures

**Symptoms:**
```
Error: budget management failed: unable to create budget
```

**Root Causes:**
- Missing budget permissions
- Incorrect budget configuration
- Insufficient budget data
- Missing budget notifications

**Solutions:**

#### Solution 1: Fix Budget Configuration
```hcl
# ✅ Comprehensive budget configuration
locals {
  budget_config = {
    # Budget thresholds
    thresholds = {
      warning_threshold = 80
      critical_threshold = 100
      overrun_threshold = 120
    }
    
    # Budget categories
    categories = {
      compute = "EC2-Instances"
      storage = "S3-Storage"
      database = "RDS-Database"
      network = "DataTransfer"
    }
    
    # Alert recipients
    alert_recipients = [
      var.cost_team_email,
      var.finance_team_email,
      var.engineering_team_email
    ]
  }
}

# AWS Budget
resource "aws_budgets_budget" "cost_optimization" {
  name         = "cost-optimization-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = [
      "CostOptimization:enabled"
    ]
  }
  
  # Budget notifications
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = local.budget_config.thresholds.warning_threshold
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = local.budget_config.alert_recipients
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = local.budget_config.thresholds.critical_threshold
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_email_addresses = local.budget_config.alert_recipients
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = local.budget_config.thresholds.overrun_threshold
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = local.budget_config.alert_recipients
  }
}

# Budget alerts
resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts"
  
  tags = {
    Name = "budget-alerts"
    Purpose = "cost-optimization"
  }
}

resource "aws_sns_topic_subscription" "budget_alerts" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_team_email
}

# Budget dashboard
resource "aws_cloudwatch_dashboard" "budget_monitoring" {
  dashboard_name = "budget-monitoring-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges"],
            ["AWS/Billing", "BudgetUtilization"]
          ]
          period = 86400  # Daily
          stat   = "Maximum"
          region = var.aws_region
          title  = "Budget Utilization"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          query   = "SOURCE '/aws/budgets/alerts' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Budget Alerts"
        }
      }
    ]
  })
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Cost Optimization State Inspection
```bash
# ✅ Inspect cost optimization state
terraform console
> local.cost_optimization_config
> local.rightsizing_config
> local.budget_config
```

### Technique 2: Cost Optimization Debug Outputs
```hcl
# ✅ Add cost optimization debug outputs
output "cost_optimization_debug" {
  description = "Cost optimization configuration debug information"
  value = {
    rightsizing_config = local.rightsizing_config
    budget_config = local.budget_config
    cost_monitoring_config = local.cost_monitoring_config
    instance_recommendations = local.instance_recommendations
  }
}
```

### Technique 3: Cost Optimization Validation
```hcl
# ✅ Add cost optimization validation
locals {
  cost_optimization_validation = {
    # Validate rightsizing configuration
    rightsizing_valid = (
      local.rightsizing_config.cpu_thresholds.scale_up_threshold > local.rightsizing_config.cpu_thresholds.scale_down_threshold &&
      local.rightsizing_config.memory_thresholds.scale_up_threshold > local.rightsizing_config.memory_thresholds.scale_down_threshold
    )
    
    # Validate budget configuration
    budget_valid = (
      local.budget_config.thresholds.warning_threshold < local.budget_config.thresholds.critical_threshold &&
      local.budget_config.thresholds.critical_threshold < local.budget_config.thresholds.overrun_threshold
    )
    
    # Validate cost monitoring configuration
    monitoring_valid = (
      local.cost_monitoring_config.data_sources.enable_cur &&
      local.cost_monitoring_config.data_sources.enable_billing_alerts &&
      local.cost_monitoring_config.data_sources.enable_cost_explorer
    )
    
    # Overall validation
    overall_valid = (
      local.cost_optimization_validation.rightsizing_valid &&
      local.cost_optimization_validation.budget_valid &&
      local.cost_optimization_validation.monitoring_valid
    )
  }
}
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Cost Optimization Testing
```hcl
# ✅ Test cost optimization in isolation
# tests/test_cost_optimization.tf
resource "aws_instance" "test_cost_optimized" {
  ami           = data.aws_ami.example.id
  instance_type = "t3.micro"
  
  tags = {
    Name = "test-cost-optimized-instance"
    Test = "true"
    CostOptimization = "enabled"
  }
}
```

### Strategy 2: Cost Optimization Monitoring
```bash
# ✅ Monitor cost optimization performance
aws budgets describe-budgets
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31 --granularity MONTHLY --metrics BlendedCost
```

### Strategy 3: Cost Optimization Documentation
```markdown
# ✅ Document cost optimization patterns
## Cost Optimization Pattern: Resource Rightsizing

### Purpose
Implements automated resource rightsizing for cost optimization.

### Configuration
```hcl
locals {
  rightsizing_config = {
    cpu_thresholds = {
      scale_up_threshold = 70
      scale_down_threshold = 30
    }
  }
}
```

### Usage
```hcl
resource "aws_autoscaling_group" "rightsized" {
  # Auto scaling group configuration...
}
```
```

---

## 📞 Getting Help

### Internal Resources
- Review cost optimization documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [AWS Cost Optimization Documentation](https://docs.aws.amazon.com/whitepapers/latest/cost-optimization-resource-rightsizing/)
- [AWS Well-Architected Framework - Cost Optimization](https://aws.amazon.com/architecture/well-architected/)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review cost optimization documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Monitor Continuously**: Implement comprehensive cost monitoring
- **Right-size Resources**: Apply resource rightsizing strategies
- **Automate Optimization**: Implement automated cost optimization
- **Manage Budgets**: Set up budget controls and alerts
- **Analyze Trends**: Analyze cost trends and optimization opportunities
- **Test Regularly**: Test cost optimization strategies regularly
- **Document Everything**: Maintain clear cost optimization documentation
- **Scale Appropriately**: Design cost optimization for enterprise scale

Remember: Cost optimization requires continuous monitoring, regular analysis, and proactive management. Proper implementation ensures efficient resource utilization and cost-effective infrastructure.
