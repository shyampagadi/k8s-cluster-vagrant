# SNS (Simple Notification Service) - Complete Terraform Guide

## 🎯 Overview

Amazon Simple Notification Service (SNS) is a fully managed messaging service for both application-to-application (A2A) and application-to-person (A2P) communication. It provides a highly available, durable, secure, fully managed pub/sub messaging service.

### **What is SNS?**
SNS is a web service that coordinates and manages the delivery or sending of messages to subscribing endpoints or clients. It enables you to decouple microservices, distributed systems, and serverless applications.

### **Key Concepts**
- **Topics**: Communication channels for messages
- **Subscriptions**: Endpoints that receive messages
- **Publishers**: Applications that send messages
- **Subscribers**: Applications that receive messages
- **Message Attributes**: Metadata for messages
- **Message Filtering**: Filter messages based on attributes
- **Dead Letter Queues**: Handle failed message deliveries
- **Cross-Region Replication**: Replicate topics across regions

### **When to Use SNS**
- **Application notifications** - Send notifications to users
- **System alerts** - Alert administrators about system events
- **Event-driven architecture** - Decouple applications
- **Mobile push notifications** - Send push notifications to mobile devices
- **Email notifications** - Send email alerts
- **SMS notifications** - Send text messages
- **Webhook notifications** - Send HTTP notifications
- **Microservices communication** - Inter-service messaging

## 🏗️ Architecture Patterns

### **Basic SNS Structure**
```
SNS Topic
├── Publishers (Applications, Services)
├── Subscriptions
│   ├── Email Subscriptions
│   ├── SMS Subscriptions
│   ├── HTTP/HTTPS Subscriptions
│   ├── Lambda Subscriptions
│   └── SQS Subscriptions
├── Message Filtering
└── Dead Letter Queues
```

### **Event-Driven Architecture Pattern**
```
Application Events
├── User Registration → SNS Topic
├── Order Placed → SNS Topic
├── Payment Processed → SNS Topic
└── System Alerts → SNS Topic
```

## 📝 Terraform Implementation

### **Basic SNS Setup**
```hcl
# SNS topic
resource "aws_sns_topic" "main" {
  name = "main-topic"

  tags = {
    Name        = "Main SNS Topic"
    Environment = "production"
  }
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}

# SMS subscription
resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sms"
  endpoint  = "+1234567890"
}

# HTTP subscription
resource "aws_sns_topic_subscription" "http" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "https"
  endpoint  = "https://webhook.example.com/sns"
}
```

### **SNS with Message Filtering**
```hcl
# SNS topic with message filtering
resource "aws_sns_topic" "filtered" {
  name = "filtered-topic"

  tags = {
    Name        = "Filtered SNS Topic"
    Environment = "production"
  }
}

# Subscription with message filtering
resource "aws_sns_topic_subscription" "filtered_email" {
  topic_arn = aws_sns_topic.filtered.arn
  protocol  = "email"
  endpoint  = "admin@example.com"

  filter_policy = jsonencode({
    environment = ["production"]
    severity    = ["high", "critical"]
  })
}

# Lambda subscription with filtering
resource "aws_sns_topic_subscription" "filtered_lambda" {
  topic_arn = aws_sns_topic.filtered.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notification.arn

  filter_policy = jsonencode({
    service = ["user-service", "payment-service"]
    event_type = ["error", "warning"]
  })
}

# Lambda function for notifications
resource "aws_lambda_function" "notification" {
  filename         = "notification.zip"
  function_name    = "notification-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  tags = {
    Name        = "Notification Handler"
    Environment = "production"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-notification-role"

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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda permission for SNS
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.filtered.arn
}
```

### **SNS with Dead Letter Queue**
```hcl
# SNS topic with DLQ
resource "aws_sns_topic" "dlq_topic" {
  name = "dlq-topic"

  tags = {
    Name        = "DLQ SNS Topic"
    Environment = "production"
  }
}

# SQS queue for dead letter
resource "aws_sqs_queue" "dlq" {
  name = "sns-dlq"

  tags = {
    Name        = "SNS Dead Letter Queue"
    Environment = "production"
  }
}

# SNS subscription with DLQ
resource "aws_sns_topic_subscription" "dlq_subscription" {
  topic_arn = aws_sns_topic.dlq_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.dlq.arn
}

# SQS queue policy for SNS
resource "aws_sqs_queue_policy" "dlq_policy" {
  queue_url = aws_sqs_queue.dlq.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.dlq_topic.arn
          }
        }
      }
    ]
  })
}
```

### **Cross-Region SNS Replication**
```hcl
# Primary SNS topic
resource "aws_sns_topic" "primary" {
  name = "primary-topic"

  tags = {
    Name        = "Primary SNS Topic"
    Environment = "production"
  }
}

# Cross-region replication
resource "aws_sns_topic_subscription" "cross_region" {
  provider = aws.us_west_2

  topic_arn = aws_sns_topic.primary.arn
  protocol  = "https"
  endpoint  = "https://webhook.us-west-2.example.com/sns"
}
```

## 🔧 Configuration Options

### **SNS Topic Configuration**
```hcl
resource "aws_sns_topic" "custom" {
  name = var.topic_name

  # Delivery status logging
  delivery_policy = var.delivery_policy

  # KMS encryption
  kms_master_key_id = var.kms_key_id

  # Content-based deduplication
  content_based_deduplication = var.content_based_deduplication

  # FIFO topic
  fifo_topic = var.fifo_topic

  tags = merge(var.common_tags, {
    Name = var.topic_name
  })
}
```

### **Advanced SNS Configuration**
```hcl
# Advanced SNS topic
resource "aws_sns_topic" "advanced" {
  name = "advanced-topic"

  # KMS encryption
  kms_master_key_id = aws_kms_key.sns.arn

  # Delivery policy
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numMinDelayRetries = 0
        numNoDelayRetries  = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = {
    Name        = "Advanced SNS Topic"
    Environment = "production"
  }
}

# KMS key for SNS
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "SNS Encryption Key"
    Environment = "production"
  }
}

# Advanced subscription with retry policy
resource "aws_sns_topic_subscription" "advanced" {
  topic_arn = aws_sns_topic.advanced.arn
  protocol  = "https"
  endpoint  = "https://webhook.example.com/sns"

  # Retry policy
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numMinDelayRetries = 0
        numNoDelayRetries  = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple SNS topic
resource "aws_sns_topic" "simple" {
  name = "simple-topic"

  tags = {
    Name = "Simple SNS Topic"
  }
}

# Simple email subscription
resource "aws_sns_topic_subscription" "simple" {
  topic_arn = aws_sns_topic.simple.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}
```

### **Production Deployment**
```hcl
# Production SNS setup
locals {
  sns_config = {
    topics = ["alerts", "notifications", "events"]
    protocols = ["email", "sms", "https", "lambda"]
    enable_encryption = true
    enable_dlq = true
  }
}

# Production SNS topics
resource "aws_sns_topic" "production" {
  for_each = toset(local.sns_config.topics)

  name = each.value

  # KMS encryption
  kms_master_key_id = local.sns_config.enable_encryption ? aws_kms_key.sns.arn : null

  tags = {
    Name        = "Production ${title(each.value)} Topic"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production subscriptions
resource "aws_sns_topic_subscription" "production" {
  for_each = {
    for topic in local.sns_config.topics : topic => {
      protocol = "email"
      endpoint = "admin@example.com"
    }
  }

  topic_arn = aws_sns_topic.production[each.key].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment SNS setup
locals {
  environments = {
    dev = {
      topics = ["dev-alerts"]
      enable_encryption = false
    }
    staging = {
      topics = ["staging-alerts", "staging-notifications"]
      enable_encryption = true
    }
    prod = {
      topics = ["prod-alerts", "prod-notifications", "prod-events"]
      enable_encryption = true
    }
  }
}

# Environment-specific SNS topics
resource "aws_sns_topic" "environment" {
  for_each = {
    for env, config in local.environments : env => config.topics
  }

  name = "${each.key}-${each.value}"

  # KMS encryption
  kms_master_key_id = local.environments[each.key].enable_encryption ? aws_kms_key.sns.arn : null

  tags = {
    Name        = "${title(each.key)} ${title(each.value)} Topic"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for SNS
resource "aws_cloudwatch_log_group" "sns_logs" {
  name              = "/aws/sns/topics"
  retention_in_days = 30

  tags = {
    Name        = "SNS Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for SNS messages
resource "aws_cloudwatch_log_metric_filter" "sns_messages" {
  name           = "SNSMessages"
  log_group_name = aws_cloudwatch_log_group.sns_logs.name
  pattern        = "[timestamp, request_id, event_name=\"Publish\", ...]"

  metric_transformation {
    name      = "SNSMessages"
    namespace = "SNS/Messages"
    value     = "1"
  }
}

# CloudWatch alarm for SNS message failures
resource "aws_cloudwatch_metric_alarm" "sns_failures" {
  alarm_name          = "SNSMessageFailures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors SNS message failures"

  dimensions = {
    TopicName = aws_sns_topic.main.name
  }

  tags = {
    Name        = "SNS Message Failures Alarm"
    Environment = "production"
  }
}
```

### **SNS Delivery Status Logging**
```hcl
# SNS topic with delivery status logging
resource "aws_sns_topic" "logged" {
  name = "logged-topic"

  # Delivery status logging
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numMinDelayRetries = 0
        numNoDelayRetries  = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = {
    Name        = "Logged SNS Topic"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Access Control**
```hcl
# SNS topic policy
resource "aws_sns_topic_policy" "main" {
  arn = aws_sns_topic.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "SNS:Publish",
          "SNS:GetTopicAttributes"
        ]
        Resource = aws_sns_topic.main.arn
      },
      {
        Sid    = "AllowSubscribe"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "SNS:Subscribe",
          "SNS:Unsubscribe"
        ]
        Resource = aws_sns_topic.main.arn
      }
    ]
  })
}
```

### **Encryption**
```hcl
# KMS key for SNS encryption
resource "aws_kms_key" "sns_encryption" {
  description             = "KMS key for SNS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "SNS Encryption Key"
    Environment = "production"
  }
}

# Encrypted SNS topic
resource "aws_sns_topic" "encrypted" {
  name = "encrypted-topic"

  # KMS encryption
  kms_master_key_id = aws_kms_key.sns_encryption.arn

  tags = {
    Name        = "Encrypted SNS Topic"
    Environment = "production"
  }
}
```

### **Message Filtering**
```hcl
# SNS topic with message filtering
resource "aws_sns_topic" "filtered" {
  name = "filtered-topic"

  tags = {
    Name        = "Filtered SNS Topic"
    Environment = "production"
  }
}

# Subscription with message filtering
resource "aws_sns_topic_subscription" "filtered" {
  topic_arn = aws_sns_topic.filtered.arn
  protocol  = "email"
  endpoint  = "admin@example.com"

  filter_policy = jsonencode({
    environment = ["production"]
    severity    = ["high", "critical"]
    service     = ["user-service", "payment-service"]
  })
}
```

## 💰 Cost Optimization

### **Message Filtering Optimization**
```hcl
# Cost-optimized SNS topic
resource "aws_sns_topic" "cost_optimized" {
  name = "cost-optimized-topic"

  tags = {
    Name        = "Cost Optimized SNS Topic"
    Environment = "production"
  }
}

# Cost-optimized subscription with filtering
resource "aws_sns_topic_subscription" "cost_optimized" {
  topic_arn = aws_sns_topic.cost_optimized.arn
  protocol  = "email"
  endpoint  = "admin@example.com"

  # Filter to reduce unnecessary messages
  filter_policy = jsonencode({
    environment = ["production"]
    priority    = ["high", "critical"]
  })
}
```

### **Subscription Management**
```hcl
# SNS topic with subscription management
resource "aws_sns_topic" "managed" {
  name = "managed-topic"

  tags = {
    Name        = "Managed SNS Topic"
    Environment = "production"
  }
}

# Multiple subscriptions with different filters
resource "aws_sns_topic_subscription" "managed" {
  for_each = {
    "admin" = {
      protocol = "email"
      endpoint = "admin@example.com"
      filter   = { severity = ["high", "critical"] }
    }
    "dev" = {
      protocol = "email"
      endpoint = "dev@example.com"
      filter   = { environment = ["dev", "staging"] }
    }
  }

  topic_arn = aws_sns_topic.managed.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  filter_policy = jsonencode(each.value.filter)
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Messages Not Delivered**
```hcl
# Debug SNS topic
resource "aws_sns_topic" "debug" {
  name = "debug-topic"

  tags = {
    Name        = "Debug SNS Topic"
    Environment = "production"
  }
}

# Debug subscription
resource "aws_sns_topic_subscription" "debug" {
  topic_arn = aws_sns_topic.debug.arn
  protocol  = "email"
  endpoint  = "debug@example.com"
}
```

#### **Issue: Subscription Problems**
```hcl
# Debug subscription with retry policy
resource "aws_sns_topic_subscription" "debug_retry" {
  topic_arn = aws_sns_topic.debug.arn
  protocol  = "https"
  endpoint  = "https://webhook.example.com/sns"

  # Debug retry policy
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 5
        numMaxDelayRetries = 0
        numMinDelayRetries = 0
        numNoDelayRetries  = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })
}
```

## 📚 Real-World Examples

### **E-Commerce Notifications**
```hcl
# E-commerce SNS setup
locals {
  ecommerce_config = {
    topics = ["order-alerts", "payment-notifications", "user-events", "system-alerts"]
    enable_encryption = true
    enable_dlq = true
  }
}

# E-commerce SNS topics
resource "aws_sns_topic" "ecommerce" {
  for_each = toset(local.ecommerce_config.topics)

  name = each.value

  # KMS encryption
  kms_master_key_id = local.ecommerce_config.enable_encryption ? aws_kms_key.sns.arn : null

  tags = {
    Name        = "E-commerce ${title(each.value)} Topic"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce subscriptions
resource "aws_sns_topic_subscription" "ecommerce" {
  for_each = {
    "order-alerts" = {
      protocol = "email"
      endpoint = "orders@example.com"
    }
    "payment-notifications" = {
      protocol = "sms"
      endpoint = "+1234567890"
    }
    "user-events" = {
      protocol = "lambda"
      endpoint = aws_lambda_function.user_events.arn
    }
    "system-alerts" = {
      protocol = "https"
      endpoint = "https://webhook.example.com/alerts"
    }
  }

  topic_arn = aws_sns_topic.ecommerce[each.key].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}
```

### **Microservices Notifications**
```hcl
# Microservices SNS setup
resource "aws_sns_topic" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name = "${each.value}-events"

  tags = {
    Name        = "Microservices ${title(each.value)} Events Topic"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}

# Microservices subscriptions
resource "aws_sns_topic_subscription" "microservices" {
  for_each = aws_sns_topic.microservices

  topic_arn = each.value.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.event_processor.arn

  filter_policy = jsonencode({
    service = [each.key]
    event_type = ["error", "warning", "info"]
  })
}
```

## 🔗 Related Services

### **Integration Patterns**
- **Lambda**: Function notifications
- **SQS**: Queue integration
- **CloudWatch**: Monitoring and alerts
- **SES**: Email notifications
- **SMS**: Text notifications
- **API Gateway**: HTTP notifications
- **ECS**: Container notifications
- **EKS**: Kubernetes notifications

### **Service Dependencies**
- **IAM**: Access control
- **KMS**: Message encryption
- **CloudWatch**: Monitoring
- **Lambda**: Event processing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic SNS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect SNS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your SNS Mastery Journey Continues with SQS!** 🚀

---

*This comprehensive SNS guide provides everything you need to master AWS Simple Notification Service with Terraform. Each example is production-ready and follows security best practices.*
