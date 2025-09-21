# CloudWatch - Complete Terraform Guide

## 🎯 Overview

Amazon CloudWatch is a monitoring and observability service that provides data and actionable insights to monitor applications, respond to system-wide performance changes, optimize resource utilization, and get a unified view of operational health.

### **What is CloudWatch?**
CloudWatch collects monitoring and operational data in the form of logs, metrics, and events, providing you with a unified view of AWS resources, applications, and services that run on AWS and on-premises servers.

### **Key Concepts**
- **Metrics**: Time-ordered sets of data points
- **Logs**: Log data from applications and services
- **Alarms**: Monitor metrics and send notifications
- **Dashboards**: Visualize metrics and logs
- **Events**: Real-time stream of system events
- **Insights**: Query and analyze log data
- **Synthetics**: Monitor endpoints and APIs

### **When to Use CloudWatch**
- **Application monitoring** - Monitor application performance
- **Infrastructure monitoring** - Monitor AWS resources
- **Log aggregation** - Centralize log collection
- **Alerting** - Set up automated alerts
- **Dashboards** - Visualize system health
- **Troubleshooting** - Debug application issues
- **Capacity planning** - Optimize resource usage

## 🏗️ Architecture Patterns

### **Basic CloudWatch Structure**
```
CloudWatch
├── Metrics (CPU, Memory, Disk, Custom)
├── Logs (Application, System, Access)
├── Alarms (Thresholds, Notifications)
├── Dashboards (Visualizations)
└── Events (System Events)
```

### **Centralized Monitoring Pattern**
```
Applications
├── EC2 Instances → CloudWatch Agent → CloudWatch Logs
├── Lambda Functions → CloudWatch Logs
├── RDS Databases → CloudWatch Metrics
├── Load Balancers → CloudWatch Metrics
└── Custom Applications → Custom Metrics
```

## 📝 Terraform Implementation

### **Basic CloudWatch Setup**
```hcl
# CloudWatch log group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/app-logs"
  retention_in_days = 30

  tags = {
    Name        = "App Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "ErrorFilter"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Application/Errors"
    value     = "1"
  }
}

# CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "ErrorCountAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "Application/Errors"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors error count"

  tags = {
    Name        = "Error Count Alarm"
    Environment = "production"
  }
}

# CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "MainDashboard"

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
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = "us-west-2"
          title  = "EC2 Metrics"
        }
      }
    ]
  })
}
```

### **CloudWatch Agent Configuration**
```hcl
# SSM parameter for CloudWatch agent config
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "/aws/ec2/cloudwatch-agent/config"
  type  = "String"
  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/app.log"
              log_group_name = "/aws/ec2/app-logs"
              log_stream_name = "{instance_id}"
            },
            {
              file_path = "/var/log/nginx/access.log"
              log_group_name = "/aws/ec2/nginx-logs"
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        cpu = {
          measurement = ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"]
          metrics_collection_interval = 60
        }
        disk = {
          measurement = ["used_percent"]
          metrics_collection_interval = 60
          resources = ["*"]
        }
        diskio = {
          measurement = ["io_time"]
          metrics_collection_interval = 60
          resources = ["*"]
        }
        mem = {
          measurement = ["mem_used_percent"]
          metrics_collection_interval = 60
        }
        netstat = {
          measurement = ["tcp_established", "tcp_time_wait"]
          metrics_collection_interval = 60
        }
        swap = {
          measurement = ["swap_used_percent"]
          metrics_collection_interval = 60
        }
      }
    }
  })

  tags = {
    Name        = "CloudWatch Agent Config"
    Environment = "production"
  }
}

# IAM role for CloudWatch agent
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
  name = "cloudwatch-agent-profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}
```

### **Custom Metrics**
```hcl
# Custom metric for application performance
resource "aws_cloudwatch_metric_alarm" "custom_metric" {
  alarm_name          = "CustomMetricAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CustomMetric"
  namespace           = "Custom/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors custom application metric"

  dimensions = {
    InstanceId = "i-1234567890abcdef0"
  }

  tags = {
    Name        = "Custom Metric Alarm"
    Environment = "production"
  }
}

# CloudWatch log group for custom metrics
resource "aws_cloudwatch_log_group" "custom_metrics" {
  name              = "/aws/custom/metrics"
  retention_in_days = 30

  tags = {
    Name        = "Custom Metrics Logs"
    Environment = "production"
  }
}
```

### **CloudWatch Events**
```hcl
# CloudWatch event rule
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "ec2-state-change"
  description = "Capture EC2 state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "stopped"]
    }
  })

  tags = {
    Name        = "EC2 State Change Rule"
    Environment = "production"
  }
}

# CloudWatch event target
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.notifications.arn
}

# SNS topic for notifications
resource "aws_sns_topic" "notifications" {
  name = "ec2-notifications"

  tags = {
    Name        = "EC2 Notifications Topic"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **CloudWatch Log Group Configuration**
```hcl
resource "aws_cloudwatch_log_group" "custom" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = var.log_group_name
  })
}
```

### **CloudWatch Alarm Configuration**
```hcl
resource "aws_cloudwatch_metric_alarm" "custom" {
  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = var.alarm_description

  dimensions = var.dimensions

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(var.common_tags, {
    Name = var.alarm_name
  })
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple CloudWatch setup
resource "aws_cloudwatch_log_group" "simple" {
  name              = "/aws/simple/logs"
  retention_in_days = 7

  tags = {
    Name = "Simple Log Group"
  }
}

resource "aws_cloudwatch_metric_alarm" "simple" {
  alarm_name          = "SimpleAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU utilization"

  tags = {
    Name = "Simple Alarm"
  }
}
```

### **Production Deployment**
```hcl
# Production CloudWatch setup
locals {
  cloudwatch_config = {
    log_retention_days = 30
    alarm_evaluation_periods = 2
    alarm_period = 300
    enable_detailed_monitoring = true
  }
}

# Production log groups
resource "aws_cloudwatch_log_group" "production" {
  for_each = toset([
    "/aws/ec2/app-logs",
    "/aws/ec2/nginx-logs",
    "/aws/lambda/function-logs",
    "/aws/rds/database-logs"
  ])

  name              = each.value
  retention_in_days = local.cloudwatch_config.log_retention_days

  tags = {
    Name        = each.value
    Environment = "production"
    Project     = "web-app"
  }
}

# Production alarms
resource "aws_cloudwatch_metric_alarm" "production" {
  for_each = {
    "CPUUtilization" = {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      threshold   = 80
    }
    "MemoryUtilization" = {
      metric_name = "MemoryUtilization"
      namespace   = "CWAgent"
      threshold   = 85
    }
    "DiskUtilization" = {
      metric_name = "DiskSpaceUtilization"
      namespace   = "CWAgent"
      threshold   = 90
    }
  }

  alarm_name          = "${each.key}Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.cloudwatch_config.alarm_evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = local.cloudwatch_config.alarm_period
  statistic           = "Average"
  threshold           = each.value.threshold
  alarm_description   = "This metric monitors ${each.key}"

  tags = {
    Name        = "${each.key} Alarm"
    Environment = "production"
    Project     = "web-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Insights**
```hcl
# CloudWatch log group for insights
resource "aws_cloudwatch_log_group" "insights" {
  name              = "/aws/insights/application"
  retention_in_days = 30

  tags = {
    Name        = "Insights Log Group"
    Environment = "production"
  }
}

# CloudWatch insights query
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "ErrorAnalysis"

  log_group_names = [
    aws_cloudwatch_log_group.insights.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}
```

### **CloudWatch Synthetics**
```hcl
# CloudWatch synthetics canary
resource "aws_synthetics_canary" "api_monitor" {
  name                 = "api-monitor"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics.bucket}/canary/"
  execution_role_arn   = aws_iam_role.synthetics_role.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics.zip"
  runtime_version      = "syn-nodejs-puppeteer-3.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    active_tracing = true
  }

  tags = {
    Name        = "API Monitor Canary"
    Environment = "production"
  }
}

# S3 bucket for synthetics
resource "aws_s3_bucket" "synthetics" {
  bucket = "synthetics-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Synthetics Bucket"
    Environment = "production"
  }
}

# IAM role for synthetics
resource "aws_iam_role" "synthetics_role" {
  name = "synthetics-role"

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

resource "aws_iam_role_policy_attachment" "synthetics_policy" {
  role       = aws_iam_role.synthetics_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSSyntheticsRole"
}
```

## 🛡️ Security Best Practices

### **Log Encryption**
```hcl
# KMS key for log encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch logs"
  deletion_window_in_days = 7

  tags = {
    Name        = "CloudWatch Logs KMS Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# Encrypted log group
resource "aws_cloudwatch_log_group" "encrypted" {
  name              = "/aws/encrypted/logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = {
    Name        = "Encrypted Log Group"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for CloudWatch access
resource "aws_iam_policy" "cloudwatch_access" {
  name        = "CloudWatchAccess"
  description = "Policy for CloudWatch access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **Log Retention Optimization**
```hcl
# Cost-optimized log groups
resource "aws_cloudwatch_log_group" "cost_optimized" {
  for_each = {
    "debug"    = 1
    "info"     = 7
    "warning"  = 14
    "error"    = 30
    "critical" = 90
  }

  name              = "/aws/cost-optimized/${each.key}-logs"
  retention_in_days = each.value

  tags = {
    Name        = "${each.key} Log Group"
    Environment = "production"
    LogLevel    = each.key
  }
}
```

### **Metric Filter Optimization**
```hcl
# Optimized metric filter
resource "aws_cloudwatch_log_metric_filter" "optimized" {
  name           = "OptimizedFilter"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", error_code=\"*\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Application/Errors"
    value     = "1"
    default_value = "0"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Logs Not Appearing**
```hcl
# Debug log group
resource "aws_cloudwatch_log_group" "debug" {
  name              = "/aws/debug/logs"
  retention_in_days = 1

  tags = {
    Name        = "Debug Log Group"
    Environment = "production"
  }
}
```

#### **Issue: Alarms Not Triggering**
```hcl
# Debug alarm
resource "aws_cloudwatch_metric_alarm" "debug" {
  alarm_name          = "DebugAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "Debug alarm"

  tags = {
    Name        = "Debug Alarm"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Monitoring**
```hcl
# E-commerce CloudWatch setup
locals {
  ecommerce_config = {
    log_retention_days = 30
    enable_detailed_monitoring = true
    alarm_thresholds = {
      cpu_threshold = 80
      memory_threshold = 85
      disk_threshold = 90
    }
  }
}

# E-commerce log groups
resource "aws_cloudwatch_log_group" "ecommerce" {
  for_each = toset([
    "/aws/ecommerce/web-logs",
    "/aws/ecommerce/api-logs",
    "/aws/ecommerce/database-logs",
    "/aws/ecommerce/payment-logs"
  ])

  name              = each.value
  retention_in_days = local.ecommerce_config.log_retention_days

  tags = {
    Name        = each.value
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce alarms
resource "aws_cloudwatch_metric_alarm" "ecommerce" {
  for_each = local.ecommerce_config.alarm_thresholds

  alarm_name          = "Ecommerce${title(each.key)}Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${title(each.key)}Utilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = each.value
  alarm_description   = "This metric monitors ${each.key} utilization"

  tags = {
    Name        = "E-commerce ${title(each.key)} Alarm"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Monitoring**
```hcl
# Microservices CloudWatch setup
resource "aws_cloudwatch_log_group" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name              = "/aws/microservices/${each.value}/logs"
  retention_in_days = 30

  tags = {
    Name        = "${each.value} Log Group"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}

# Microservices alarms
resource "aws_cloudwatch_metric_alarm" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  alarm_name          = "${each.value}ErrorAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "Microservices/${each.value}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors ${each.value} errors"

  tags = {
    Name        = "${each.value} Error Alarm"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **EC2**: Instance monitoring
- **RDS**: Database monitoring
- **Lambda**: Function monitoring
- **ECS**: Container monitoring
- **EKS**: Kubernetes monitoring
- **S3**: Storage monitoring
- **ALB**: Load balancer monitoring
- **SNS**: Notification integration
- **SQS**: Queue monitoring

### **Service Dependencies**
- **IAM**: Access control
- **KMS**: Log encryption
- **S3**: Log storage
- **SNS**: Notifications
- **Lambda**: Custom processing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic CloudWatch examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect CloudWatch with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up comprehensive monitoring
6. **Optimize**: Focus on cost and performance

**Your CloudWatch Mastery Journey Continues with KMS!** 🚀

---

*This comprehensive CloudWatch guide provides everything you need to master AWS CloudWatch with Terraform. Each example is production-ready and follows security best practices.*
