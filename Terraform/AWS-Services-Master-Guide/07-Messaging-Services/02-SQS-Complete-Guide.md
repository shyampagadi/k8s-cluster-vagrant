# SQS (Simple Queue Service) - Complete Terraform Guide

## 🎯 Overview

Amazon Simple Queue Service (SQS) is a fully managed message queuing service that enables you to decouple and scale microservices, distributed systems, and serverless applications. SQS eliminates the complexity and overhead associated with managing and operating message-oriented middleware.

### **What is SQS?**
SQS is a distributed message queuing service that enables web service applications to quickly and reliably queue messages that one component in the application generates to be consumed by another component.

### **Key Concepts**
- **Queues**: Message containers that store messages
- **Messages**: Data sent between applications
- **Visibility Timeout**: Time messages are hidden after being received
- **Dead Letter Queues**: Queues for failed messages
- **FIFO Queues**: First-in, first-out message ordering
- **Standard Queues**: High-throughput message processing
- **Message Attributes**: Metadata for messages
- **Batch Operations**: Process multiple messages at once

### **When to Use SQS**
- **Decouple applications** - Separate components for scalability
- **Asynchronous processing** - Handle tasks in the background
- **Load balancing** - Distribute work across multiple workers
- **Fault tolerance** - Handle failures gracefully
- **Message buffering** - Smooth out traffic spikes
- **Microservices communication** - Inter-service messaging
- **Event-driven architecture** - Process events asynchronously
- **Task queues** - Queue background jobs

## 🏗️ Architecture Patterns

### **Basic SQS Structure**
```
SQS Queue
├── Producers (Applications sending messages)
├── Messages (Data being queued)
├── Consumers (Applications processing messages)
├── Dead Letter Queue (Failed messages)
└── Visibility Timeout (Message hiding)
```

### **Producer-Consumer Pattern**
```
Producer Application
├── Send Message → SQS Queue
├── Send Message → SQS Queue
└── Send Message → SQS Queue

Consumer Application
├── Receive Message ← SQS Queue
├── Process Message
└── Delete Message
```

## 📝 Terraform Implementation

### **Basic SQS Setup**
```hcl
# Standard SQS queue
resource "aws_sqs_queue" "main" {
  name = "main-queue"

  tags = {
    Name        = "Main SQS Queue"
    Environment = "production"
  }
}

# FIFO SQS queue
resource "aws_sqs_queue" "fifo" {
  name                        = "fifo-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  tags = {
    Name        = "FIFO SQS Queue"
    Environment = "production"
  }
}

# Dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "dlq-queue"

  tags = {
    Name        = "Dead Letter Queue"
    Environment = "production"
  }
}

# Main queue with DLQ
resource "aws_sqs_queue" "main_with_dlq" {
  name = "main-with-dlq"

  # Dead letter queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "Main Queue with DLQ"
    Environment = "production"
  }
}
```

### **SQS with Lambda Integration**
```hcl
# SQS queue for Lambda
resource "aws_sqs_queue" "lambda_queue" {
  name = "lambda-queue"

  # Visibility timeout
  visibility_timeout_seconds = 300

  # Message retention
  message_retention_seconds = 1209600

  # Receive message wait time
  receive_wait_time_seconds = 20

  tags = {
    Name        = "Lambda SQS Queue"
    Environment = "production"
  }
}

# Lambda function for SQS processing
resource "aws_lambda_function" "sqs_processor" {
  filename         = "sqs_processor.zip"
  function_name    = "sqs-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.lambda_queue.url
    }
  }

  tags = {
    Name        = "SQS Processor"
    Environment = "production"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-sqs-role"

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

# Lambda permission for SQS
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = aws_lambda_function.sqs_processor.arn
  batch_size       = 10
}
```

### **SQS with Message Filtering**
```hcl
# SQS queue with message filtering
resource "aws_sqs_queue" "filtered" {
  name = "filtered-queue"

  # Message filtering
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20

  tags = {
    Name        = "Filtered SQS Queue"
    Environment = "production"
  }
}

# SQS queue policy for filtering
resource "aws_sqs_queue_policy" "filtered" {
  queue_url = aws_sqs_queue.filtered.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.filtered.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.main.arn
          }
        }
      }
    ]
  })
}
```

### **SQS with Encryption**
```hcl
# KMS key for SQS encryption
resource "aws_kms_key" "sqs" {
  description             = "KMS key for SQS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "SQS Encryption Key"
    Environment = "production"
  }
}

# Encrypted SQS queue
resource "aws_sqs_queue" "encrypted" {
  name = "encrypted-queue"

  # KMS encryption
  kms_master_key_id                 = aws_kms_key.sqs.arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name        = "Encrypted SQS Queue"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **SQS Queue Configuration**
```hcl
resource "aws_sqs_queue" "custom" {
  name = var.queue_name

  # FIFO configuration
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  # Visibility timeout
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Message retention
  message_retention_seconds = var.message_retention_seconds

  # Receive wait time
  receive_wait_time_seconds = var.receive_wait_time_seconds

  # Delay seconds
  delay_seconds = var.delay_seconds

  # Max message size
  max_message_size = var.max_message_size

  # KMS encryption
  kms_master_key_id                 = var.kms_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  # Dead letter queue
  redrive_policy = var.redrive_policy

  tags = merge(var.common_tags, {
    Name = var.queue_name
  })
}
```

### **Advanced SQS Configuration**
```hcl
# Advanced SQS queue
resource "aws_sqs_queue" "advanced" {
  name = "advanced-queue"

  # FIFO configuration
  fifo_queue                  = false
  content_based_deduplication = false

  # Visibility timeout
  visibility_timeout_seconds = 300

  # Message retention
  message_retention_seconds = 1209600

  # Receive wait time
  receive_wait_time_seconds = 20

  # Delay seconds
  delay_seconds = 0

  # Max message size
  max_message_size = 262144

  # KMS encryption
  kms_master_key_id                 = aws_kms_key.sqs.arn
  kms_data_key_reuse_period_seconds = 300

  # Dead letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "Advanced SQS Queue"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple SQS queue
resource "aws_sqs_queue" "simple" {
  name = "simple-queue"

  tags = {
    Name = "Simple SQS Queue"
  }
}
```

### **Production Deployment**
```hcl
# Production SQS setup
locals {
  sqs_config = {
    queues = ["orders", "payments", "notifications", "events"]
    enable_dlq = true
    enable_encryption = true
    visibility_timeout = 300
    message_retention = 1209600
  }
}

# Production SQS queues
resource "aws_sqs_queue" "production" {
  for_each = toset(local.sqs_config.queues)

  name = each.value

  # Visibility timeout
  visibility_timeout_seconds = local.sqs_config.visibility_timeout

  # Message retention
  message_retention_seconds = local.sqs_config.message_retention

  # KMS encryption
  kms_master_key_id = local.sqs_config.enable_encryption ? aws_kms_key.sqs.arn : null

  # Dead letter queue
  redrive_policy = local.sqs_config.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  }) : null

  tags = {
    Name        = "Production ${title(each.value)} Queue"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "production-dlq"

  tags = {
    Name        = "Production Dead Letter Queue"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment SQS setup
locals {
  environments = {
    dev = {
      queues = ["dev-orders"]
      enable_dlq = false
      enable_encryption = false
    }
    staging = {
      queues = ["staging-orders", "staging-payments"]
      enable_dlq = true
      enable_encryption = true
    }
    prod = {
      queues = ["prod-orders", "prod-payments", "prod-notifications"]
      enable_dlq = true
      enable_encryption = true
    }
  }
}

# Environment-specific SQS queues
resource "aws_sqs_queue" "environment" {
  for_each = {
    for env, config in local.environments : env => config.queues
  }

  name = "${each.key}-${each.value}"

  # KMS encryption
  kms_master_key_id = local.environments[each.key].enable_encryption ? aws_kms_key.sqs.arn : null

  # Dead letter queue
  redrive_policy = local.environments[each.key].enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  }) : null

  tags = {
    Name        = "${title(each.key)} ${title(each.value)} Queue"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for SQS
resource "aws_cloudwatch_log_group" "sqs_logs" {
  name              = "/aws/sqs/queues"
  retention_in_days = 30

  tags = {
    Name        = "SQS Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for SQS messages
resource "aws_cloudwatch_log_metric_filter" "sqs_messages" {
  name           = "SQSMessages"
  log_group_name = aws_cloudwatch_log_group.sqs_logs.name
  pattern        = "[timestamp, request_id, event_name=\"ReceiveMessage\", ...]"

  metric_transformation {
    name      = "SQSMessages"
    namespace = "SQS/Messages"
    value     = "1"
  }
}

# CloudWatch alarm for SQS queue depth
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "SQSQueueDepth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors SQS queue depth"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = {
    Name        = "SQS Queue Depth Alarm"
    Environment = "production"
  }
}
```

### **SQS Metrics**
```hcl
# CloudWatch alarm for SQS message age
resource "aws_cloudwatch_metric_alarm" "sqs_message_age" {
  alarm_name          = "SQSMessageAge"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "300"
  alarm_description   = "This metric monitors SQS message age"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = {
    Name        = "SQS Message Age Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Access Control**
```hcl
# SQS queue policy
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSendMessage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Sid    = "AllowReceiveMessage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}
```

### **Encryption**
```hcl
# KMS key for SQS encryption
resource "aws_kms_key" "sqs_encryption" {
  description             = "KMS key for SQS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "SQS Encryption Key"
    Environment = "production"
  }
}

# Encrypted SQS queue
resource "aws_sqs_queue" "encrypted" {
  name = "encrypted-queue"

  # KMS encryption
  kms_master_key_id                 = aws_kms_key.sqs_encryption.arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name        = "Encrypted SQS Queue"
    Environment = "production"
  }
}
```

### **Dead Letter Queue**
```hcl
# Dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "dlq-queue"

  tags = {
    Name        = "Dead Letter Queue"
    Environment = "production"
  }
}

# Main queue with DLQ
resource "aws_sqs_queue" "main_with_dlq" {
  name = "main-with-dlq"

  # Dead letter queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "Main Queue with DLQ"
    Environment = "production"
  }
}
```

## 💰 Cost Optimization

### **Queue Optimization**
```hcl
# Cost-optimized SQS queue
resource "aws_sqs_queue" "cost_optimized" {
  name = "cost-optimized-queue"

  # Optimized settings
  visibility_timeout_seconds = 300
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  delay_seconds = 0

  tags = {
    Name        = "Cost Optimized SQS Queue"
    Environment = "production"
  }
}
```

### **Batch Processing**
```hcl
# SQS queue for batch processing
resource "aws_sqs_queue" "batch" {
  name = "batch-queue"

  # Batch processing settings
  visibility_timeout_seconds = 300
  receive_wait_time_seconds = 20

  tags = {
    Name        = "Batch SQS Queue"
    Environment = "production"
  }
}

# Lambda function for batch processing
resource "aws_lambda_function" "batch_processor" {
  filename         = "batch_processor.zip"
  function_name    = "batch-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  tags = {
    Name        = "Batch Processor"
    Environment = "production"
  }
}

# Lambda event source mapping for batch processing
resource "aws_lambda_event_source_mapping" "batch" {
  event_source_arn = aws_sqs_queue.batch.arn
  function_name    = aws_lambda_function.batch_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Messages Not Being Processed**
```hcl
# Debug SQS queue
resource "aws_sqs_queue" "debug" {
  name = "debug-queue"

  # Debug settings
  visibility_timeout_seconds = 300
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20

  tags = {
    Name        = "Debug SQS Queue"
    Environment = "production"
  }
}
```

#### **Issue: Message Visibility Problems**
```hcl
# Debug visibility timeout
resource "aws_sqs_queue" "debug_visibility" {
  name = "debug-visibility-queue"

  # Debug visibility timeout
  visibility_timeout_seconds = 60

  tags = {
    Name        = "Debug Visibility SQS Queue"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Queue Setup**
```hcl
# E-commerce SQS setup
locals {
  ecommerce_config = {
    queues = ["orders", "payments", "notifications", "inventory"]
    enable_dlq = true
    enable_encryption = true
    visibility_timeout = 300
  }
}

# E-commerce SQS queues
resource "aws_sqs_queue" "ecommerce" {
  for_each = toset(local.ecommerce_config.queues)

  name = each.value

  # Visibility timeout
  visibility_timeout_seconds = local.ecommerce_config.visibility_timeout

  # KMS encryption
  kms_master_key_id = local.ecommerce_config.enable_encryption ? aws_kms_key.sqs.arn : null

  # Dead letter queue
  redrive_policy = local.ecommerce_config.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  }) : null

  tags = {
    Name        = "E-commerce ${title(each.value)} Queue"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "ecommerce-dlq"

  tags = {
    Name        = "E-commerce Dead Letter Queue"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Queue Setup**
```hcl
# Microservices SQS setup
resource "aws_sqs_queue" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name = "${each.value}-queue"

  # Visibility timeout
  visibility_timeout_seconds = 300

  # Message retention
  message_retention_seconds = 1209600

  # Dead letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.microservices_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "Microservices ${title(each.value)} Queue"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}

# Microservices dead letter queue
resource "aws_sqs_queue" "microservices_dlq" {
  name = "microservices-dlq"

  tags = {
    Name        = "Microservices Dead Letter Queue"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **Lambda**: Function processing
- **SNS**: Topic integration
- **CloudWatch**: Monitoring and logging
- **ECS**: Container processing
- **EKS**: Kubernetes processing
- **API Gateway**: HTTP integration
- **S3**: Object processing
- **RDS**: Database processing

### **Service Dependencies**
- **IAM**: Access control
- **KMS**: Message encryption
- **CloudWatch**: Monitoring
- **Lambda**: Event processing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic SQS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect SQS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your SQS Mastery Journey Continues with Advanced Services!** 🚀

---

*This comprehensive SQS guide provides everything you need to master AWS Simple Queue Service with Terraform. Each example is production-ready and follows security best practices.*
