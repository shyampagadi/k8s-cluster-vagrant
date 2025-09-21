# DynamoDB - Complete Terraform Guide

## 🎯 Overview

Amazon DynamoDB is a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. DynamoDB lets you offload the administrative burdens of operating and scaling a distributed database.

### **What is DynamoDB?**
DynamoDB is a key-value and document database that delivers single-digit millisecond performance at any scale. It's a fully managed, multiregion, multimaster database with built-in security, backup and restore, and in-memory caching.

### **Key Concepts**
- **Tables**: Collections of items
- **Items**: Individual records in a table
- **Attributes**: Individual data elements
- **Primary Key**: Uniquely identifies each item
- **Sort Key**: Secondary key for composite primary keys
- **Global Secondary Index (GSI)**: Index with different partition and sort keys
- **Local Secondary Index (LSI)**: Index with same partition key but different sort key
- **DynamoDB Streams**: Change data capture
- **Global Tables**: Multi-region replication
- **Point-in-Time Recovery**: Automated backups

### **When to Use DynamoDB**
- **Web applications** - User sessions, shopping carts
- **Mobile applications** - User profiles, game data
- **IoT applications** - Device data, sensor readings
- **Real-time analytics** - Clickstream data, metrics
- **Content management** - User-generated content
- **Gaming applications** - Player data, leaderboards
- **Serverless applications** - Lambda function data
- **Microservices** - Service-specific data storage

## 🏗️ Architecture Patterns

### **Basic DynamoDB Structure**
```
DynamoDB Table
├── Primary Key (Partition Key + Sort Key)
├── Attributes (Data Fields)
├── Global Secondary Indexes (GSI)
├── Local Secondary Indexes (LSI)
├── DynamoDB Streams (Change Capture)
└── Global Tables (Multi-Region)
```

### **Single Table Design Pattern**
```
DynamoDB Table
├── User Items (PK: USER#123, SK: PROFILE)
├── Order Items (PK: USER#123, SK: ORDER#456)
├── Product Items (PK: PRODUCT#789, SK: INFO)
└── GSI: OrderDate (PK: ORDER_DATE, SK: ORDER#456)
```

## 📝 Terraform Implementation

### **Basic DynamoDB Setup**
```hcl
# DynamoDB table
resource "aws_dynamodb_table" "main" {
  name           = "main-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Main DynamoDB Table"
    Environment = "production"
  }
}

# DynamoDB table with sort key
resource "aws_dynamodb_table" "main_with_sort" {
  name           = "main-with-sort-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Name        = "Main with Sort DynamoDB Table"
    Environment = "production"
  }
}
```

### **DynamoDB with Global Secondary Index**
```hcl
# DynamoDB table with GSI
resource "aws_dynamodb_table" "gsi_table" {
  name           = "gsi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = "timestamp"
  }

  tags = {
    Name        = "GSI DynamoDB Table"
    Environment = "production"
  }
}
```

### **DynamoDB with Local Secondary Index**
```hcl
# DynamoDB table with LSI
resource "aws_dynamodb_table" "lsi_table" {
  name           = "lsi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "status"
    type = "S"
  }

  local_secondary_index {
    name     = "StatusIndex"
    range_key = "status"
  }

  tags = {
    Name        = "LSI DynamoDB Table"
    Environment = "production"
  }
}
```

### **DynamoDB with Provisioned Capacity**
```hcl
# DynamoDB table with provisioned capacity
resource "aws_dynamodb_table" "provisioned" {
  name           = "provisioned-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = "timestamp"
    read_capacity  = 5
    write_capacity = 5
  }

  tags = {
    Name        = "Provisioned DynamoDB Table"
    Environment = "production"
  }
}
```

### **DynamoDB with Streams**
```hcl
# DynamoDB table with streams
resource "aws_dynamodb_table" "streams_table" {
  name           = "streams-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name        = "Streams DynamoDB Table"
    Environment = "production"
  }
}

# Lambda function for DynamoDB streams
resource "aws_lambda_function" "dynamodb_streams" {
  filename         = "dynamodb_streams.zip"
  function_name    = "dynamodb-streams-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  tags = {
    Name        = "DynamoDB Streams Processor"
    Environment = "production"
  }
}

# Lambda event source mapping for DynamoDB streams
resource "aws_lambda_event_source_mapping" "dynamodb_streams" {
  event_source_arn  = aws_dynamodb_table.streams_table.stream_arn
  function_name     = aws_lambda_function.dynamodb_streams.arn
  starting_position = "LATEST"
  batch_size        = 10
}
```

### **DynamoDB Global Tables**
```hcl
# DynamoDB global table
resource "aws_dynamodb_table" "global_table" {
  provider = aws.us_east_1

  name           = "global-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Global DynamoDB Table"
    Environment = "production"
  }
}

# DynamoDB global table replica
resource "aws_dynamodb_table" "global_table_replica" {
  provider = aws.us_west_2

  name           = "global-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Global DynamoDB Table Replica"
    Environment = "production"
  }
}

# DynamoDB global table
resource "aws_dynamodb_global_table" "global_table" {
  name = "global-table"

  replica {
    region_name = "us-east-1"
  }

  replica {
    region_name = "us-west-2"
  }

  tags = {
    Name        = "Global DynamoDB Table"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **DynamoDB Table Configuration**
```hcl
resource "aws_dynamodb_table" "custom" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = var.hash_key
  range_key      = var.range_key

  # Attributes
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global secondary indexes
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name     = global_secondary_index.value.name
      hash_key = global_secondary_index.value.hash_key
      range_key = global_secondary_index.value.range_key
      read_capacity  = global_secondary_index.value.read_capacity
      write_capacity = global_secondary_index.value.write_capacity
    }
  }

  # Local secondary indexes
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name     = local_secondary_index.value.name
      range_key = local_secondary_index.value.range_key
    }
  }

  tags = merge(var.common_tags, {
    Name = var.table_name
  })
}
```

### **Advanced DynamoDB Configuration**
```hcl
# Advanced DynamoDB table
resource "aws_dynamodb_table" "advanced" {
  name           = "advanced-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global secondary index
  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = "timestamp"
  }

  # Local secondary index
  local_secondary_index {
    name     = "StatusIndex"
    range_key = "status"
  }

  # Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
    kms_key_id = aws_kms_key.dynamodb.arn
  }

  tags = {
    Name        = "Advanced DynamoDB Table"
    Environment = "production"
  }
}

# KMS key for DynamoDB encryption
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "DynamoDB Encryption Key"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple DynamoDB table
resource "aws_dynamodb_table" "simple" {
  name           = "simple-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "Simple DynamoDB Table"
  }
}
```

### **Production Deployment**
```hcl
# Production DynamoDB setup
locals {
  dynamodb_config = {
    table_name = "production-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"
    range_key = "timestamp"
    enable_streams = true
    enable_encryption = true
    enable_backup = true
  }
}

# Production DynamoDB table
resource "aws_dynamodb_table" "production" {
  name           = local.dynamodb_config.table_name
  billing_mode   = local.dynamodb_config.billing_mode
  hash_key       = local.dynamodb_config.hash_key
  range_key      = local.dynamodb_config.range_key

  attribute {
    name = local.dynamodb_config.hash_key
    type = "S"
  }

  attribute {
    name = local.dynamodb_config.range_key
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  # Global secondary index
  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = local.dynamodb_config.range_key
  }

  # Streams
  stream_enabled   = local.dynamodb_config.enable_streams
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = local.dynamodb_config.enable_backup
  }

  # Server-side encryption
  server_side_encryption {
    enabled = local.dynamodb_config.enable_encryption
    kms_key_id = aws_kms_key.dynamodb.arn
  }

  tags = {
    Name        = "Production DynamoDB Table"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment DynamoDB setup
locals {
  environments = {
    dev = {
      table_name = "dev-table"
      billing_mode = "PAY_PER_REQUEST"
      enable_streams = false
      enable_encryption = false
    }
    staging = {
      table_name = "staging-table"
      billing_mode = "PAY_PER_REQUEST"
      enable_streams = true
      enable_encryption = true
    }
    prod = {
      table_name = "prod-table"
      billing_mode = "PROVISIONED"
      read_capacity = 10
      write_capacity = 10
      enable_streams = true
      enable_encryption = true
    }
  }
}

# Environment-specific DynamoDB tables
resource "aws_dynamodb_table" "environment" {
  for_each = local.environments

  name           = each.value.table_name
  billing_mode   = each.value.billing_mode
  read_capacity  = each.value.read_capacity
  write_capacity = each.value.write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Streams
  stream_enabled   = each.value.enable_streams
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Server-side encryption
  server_side_encryption {
    enabled = each.value.enable_encryption
    kms_key_id = aws_kms_key.dynamodb.arn
  }

  tags = {
    Name        = "${title(each.key)} DynamoDB Table"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for DynamoDB
resource "aws_cloudwatch_log_group" "dynamodb_logs" {
  name              = "/aws/dynamodb/tables"
  retention_in_days = 30

  tags = {
    Name        = "DynamoDB Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for DynamoDB
resource "aws_cloudwatch_log_metric_filter" "dynamodb_usage" {
  name           = "DynamoDBUsage"
  log_group_name = aws_cloudwatch_log_group.dynamodb_logs.name
  pattern        = "[timestamp, request_id, event_name=\"PutItem\", ...]"

  metric_transformation {
    name      = "DynamoDBUsage"
    namespace = "DynamoDB/Usage"
    value     = "1"
  }
}

# CloudWatch alarm for DynamoDB
resource "aws_cloudwatch_metric_alarm" "dynamodb_alarm" {
  alarm_name          = "DynamoDBAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors DynamoDB read capacity"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  tags = {
    Name        = "DynamoDB Alarm"
    Environment = "production"
  }
}
```

### **DynamoDB Metrics**
```hcl
# CloudWatch alarm for DynamoDB throttling
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "DynamoDBThrottlingAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors DynamoDB throttling"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  tags = {
    Name        = "DynamoDB Throttling Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Access Control**
```hcl
# IAM policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "DynamoDBAccess"
  description = "Policy for DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "${aws_dynamodb_table.main.arn}/index/*"
      }
    ]
  })
}
```

### **Encryption**
```hcl
# KMS key for DynamoDB encryption
resource "aws_kms_key" "dynamodb_encryption" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "DynamoDB Encryption Key"
    Environment = "production"
  }
}

# Encrypted DynamoDB table
resource "aws_dynamodb_table" "encrypted" {
  name           = "encrypted-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
    kms_key_id = aws_kms_key.dynamodb_encryption.arn
  }

  tags = {
    Name        = "Encrypted DynamoDB Table"
    Environment = "production"
  }
}
```

### **Backup and Recovery**
```hcl
# DynamoDB table with backup
resource "aws_dynamodb_table" "backup" {
  name           = "backup-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "Backup DynamoDB Table"
    Environment = "production"
  }
}
```

## 💰 Cost Optimization

### **On-Demand vs Provisioned**
```hcl
# Cost-optimized DynamoDB table
resource "aws_dynamodb_table" "cost_optimized" {
  name           = "cost-optimized-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Lifecycle management
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "Cost Optimized DynamoDB Table"
    Environment = "production"
  }
}
```

### **Global Secondary Index Optimization**
```hcl
# DynamoDB table with optimized GSI
resource "aws_dynamodb_table" "optimized_gsi" {
  name           = "optimized-gsi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  # Optimized GSI
  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = "timestamp"
  }

  tags = {
    Name        = "Optimized GSI DynamoDB Table"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Table Creation Failed**
```hcl
# Debug DynamoDB table
resource "aws_dynamodb_table" "debug" {
  name           = "debug-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Debug DynamoDB Table"
    Environment = "production"
  }
}
```

#### **Issue: GSI Creation Problems**
```hcl
# Debug DynamoDB table with GSI
resource "aws_dynamodb_table" "debug_gsi" {
  name           = "debug-gsi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = "timestamp"
  }

  tags = {
    Name        = "Debug GSI DynamoDB Table"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce DynamoDB Setup**
```hcl
# E-commerce DynamoDB setup
locals {
  ecommerce_config = {
    table_name = "ecommerce-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"
    range_key = "timestamp"
    enable_streams = true
    enable_encryption = true
  }
}

# E-commerce DynamoDB table
resource "aws_dynamodb_table" "ecommerce" {
  name           = local.ecommerce_config.table_name
  billing_mode   = local.ecommerce_config.billing_mode
  hash_key       = local.ecommerce_config.hash_key
  range_key      = local.ecommerce_config.range_key

  attribute {
    name = local.ecommerce_config.hash_key
    type = "S"
  }

  attribute {
    name = local.ecommerce_config.range_key
    type = "N"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global secondary index for categories
  global_secondary_index {
    name     = "CategoryIndex"
    hash_key = "category"
    range_key = local.ecommerce_config.range_key
  }

  # Global secondary index for status
  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
    range_key = local.ecommerce_config.range_key
  }

  # Streams
  stream_enabled   = local.ecommerce_config.enable_streams
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Server-side encryption
  server_side_encryption {
    enabled = local.ecommerce_config.enable_encryption
    kms_key_id = aws_kms_key.dynamodb.arn
  }

  tags = {
    Name        = "E-commerce DynamoDB Table"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices DynamoDB Setup**
```hcl
# Microservices DynamoDB setup
resource "aws_dynamodb_table" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  name           = "${each.value}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global secondary index for status
  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
    range_key = "timestamp"
  }

  # Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Server-side encryption
  server_side_encryption {
    enabled = true
    kms_key_id = aws_kms_key.dynamodb.arn
  }

  tags = {
    Name        = "Microservices ${title(each.value)} DynamoDB Table"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **Lambda**: Function data storage
- **API Gateway**: API data storage
- **ECS**: Container data storage
- **CloudWatch**: Monitoring and logging
- **KMS**: Encryption
- **S3**: Data transfer
- **SNS**: Notifications
- **SQS**: Message queuing

### **Service Dependencies**
- **IAM**: Access control
- **KMS**: Encryption
- **CloudWatch**: Monitoring
- **Lambda**: Stream processing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic DynamoDB examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect DynamoDB with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your DynamoDB Mastery Journey Continues with API Gateway!** 🚀

---

*This comprehensive DynamoDB guide provides everything you need to master AWS DynamoDB with Terraform. Each example is production-ready and follows security best practices.*
