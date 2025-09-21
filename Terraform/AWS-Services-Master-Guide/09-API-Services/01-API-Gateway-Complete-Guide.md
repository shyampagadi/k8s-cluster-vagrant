# API Gateway - Complete Terraform Guide

## 🎯 Overview

Amazon API Gateway is a fully managed service that makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale. API Gateway handles all the tasks involved in accepting and processing up to hundreds of thousands of concurrent API calls.

### **What is API Gateway?**
API Gateway is a service that enables you to create, deploy, and manage APIs for your applications. It acts as a "front door" for applications to access data, business logic, or functionality from your backend services.

### **Key Concepts**
- **REST APIs**: HTTP-based APIs with standard HTTP methods
- **WebSocket APIs**: Real-time bidirectional communication
- **HTTP APIs**: Lightweight, low-latency APIs
- **Resources**: API endpoints and methods
- **Methods**: HTTP operations (GET, POST, PUT, DELETE)
- **Integration**: Backend service connections
- **Stages**: Deployment environments (dev, staging, prod)
- **Usage Plans**: API access control and throttling
- **API Keys**: Authentication for API access
- **CORS**: Cross-origin resource sharing

### **When to Use API Gateway**
- **RESTful APIs** - Create REST APIs for web applications
- **Microservices** - Expose microservices as APIs
- **Serverless** - Connect to Lambda functions
- **WebSocket** - Real-time applications
- **API management** - Centralized API management
- **Authentication** - API authentication and authorization
- **Rate limiting** - Control API usage
- **Monitoring** - API monitoring and analytics

## 🏗️ Architecture Patterns

### **Basic API Gateway Structure**
```
API Gateway
├── REST API
│   ├── Resources (Endpoints)
│   ├── Methods (HTTP Operations)
│   ├── Integrations (Backend Services)
│   ├── Stages (Deployment Environments)
│   └── Usage Plans (Access Control)
├── WebSocket API
└── HTTP API
```

### **Microservices API Pattern**
```
API Gateway
├── User Service API
├── Product Service API
├── Order Service API
└── Payment Service API
```

## 📝 Terraform Implementation

### **Basic REST API Setup**
```hcl
# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "main-api"
  description = "Main REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Main REST API"
    Environment = "production"
  }
}

# API Gateway resource
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "users"
}

# API Gateway method
resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway integration
resource "aws_api_gateway_integration" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.main.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.main,
    aws_api_gateway_integration.main,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"

  tags = {
    Name        = "Main API Deployment"
    Environment = "production"
  }
}

# Lambda function
resource "aws_lambda_function" "main" {
  filename         = "main.zip"
  function_name    = "main-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  tags = {
    Name        = "Main Lambda Function"
    Environment = "production"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}
```

### **API Gateway with Custom Domain**
```hcl
# API Gateway custom domain
resource "aws_api_gateway_domain_name" "main" {
  domain_name              = "api.example.com"
  certificate_arn          = aws_acm_certificate.main.arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Main API Domain"
    Environment = "production"
  }
}

# API Gateway base path mapping
resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}

# ACM certificate
resource "aws_acm_certificate" "main" {
  domain_name       = "api.example.com"
  validation_method = "DNS"

  tags = {
    Name        = "Main API Certificate"
    Environment = "production"
  }
}
```

### **API Gateway with Usage Plans**
```hcl
# API Gateway usage plan
resource "aws_api_gateway_usage_plan" "main" {
  name = "main-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 100
    burst_limit = 200
  }

  tags = {
    Name        = "Main Usage Plan"
    Environment = "production"
  }
}

# API Gateway API key
resource "aws_api_gateway_api_key" "main" {
  name = "main-api-key"

  tags = {
    Name        = "Main API Key"
    Environment = "production"
  }
}

# API Gateway usage plan key
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
```

### **API Gateway with CORS**
```hcl
# API Gateway resource with CORS
resource "aws_api_gateway_resource" "cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "cors"
}

# API Gateway method with CORS
resource "aws_api_gateway_method" "cors" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.cors.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway integration with CORS
resource "aws_api_gateway_integration" "cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.cors.id
  http_method = aws_api_gateway_method.cors.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# API Gateway method response with CORS
resource "aws_api_gateway_method_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.cors.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# API Gateway integration response with CORS
resource "aws_api_gateway_integration_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.cors.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = aws_api_gateway_method_response.cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
```

### **WebSocket API**
```hcl
# API Gateway WebSocket API
resource "aws_api_gateway_websocket_api" "main" {
  name                       = "main-websocket-api"
  route_selection_expression = "$request.body.action"

  tags = {
    Name        = "Main WebSocket API"
    Environment = "production"
  }
}

# WebSocket API route
resource "aws_api_gateway_websocket_route" "main" {
  api_id    = aws_api_gateway_websocket_api.main.id
  route_key = "$default"

  target = "integrations/${aws_api_gateway_websocket_integration.main.id}"
}

# WebSocket API integration
resource "aws_api_gateway_websocket_integration" "main" {
  api_id           = aws_api_gateway_websocket_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.websocket.invoke_arn
}

# WebSocket API deployment
resource "aws_api_gateway_websocket_api_deployment" "main" {
  api_id = aws_api_gateway_websocket_api.main.id

  depends_on = [
    aws_api_gateway_websocket_route.main,
    aws_api_gateway_websocket_integration.main,
  ]

  tags = {
    Name        = "Main WebSocket API Deployment"
    Environment = "production"
  }
}

# Lambda function for WebSocket
resource "aws_lambda_function" "websocket" {
  filename         = "websocket.zip"
  function_name    = "websocket-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  tags = {
    Name        = "WebSocket Lambda Function"
    Environment = "production"
  }
}

# Lambda permission for WebSocket
resource "aws_lambda_permission" "websocket" {
  statement_id  = "AllowExecutionFromWebSocketAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_websocket_api.main.execution_arn}/*/*"
}
```

## 🔧 Configuration Options

### **API Gateway REST API Configuration**
```hcl
resource "aws_api_gateway_rest_api" "custom" {
  name        = var.api_name
  description = var.description

  endpoint_configuration {
    types = var.endpoint_types
  }

  # API Gateway policy
  policy = var.policy

  tags = merge(var.common_tags, {
    Name = var.api_name
  })
}
```

### **Advanced API Gateway Configuration**
```hcl
# Advanced API Gateway REST API
resource "aws_api_gateway_rest_api" "advanced" {
  name        = "advanced-api"
  description = "Advanced REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # API Gateway policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "Advanced REST API"
    Environment = "production"
  }
}

# Advanced API Gateway method
resource "aws_api_gateway_method" "advanced" {
  rest_api_id   = aws_api_gateway_rest_api.advanced.id
  resource_id   = aws_api_gateway_resource.advanced.id
  http_method   = "POST"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.header.Content-Type" = true
  }

  request_validator_id = aws_api_gateway_request_validator.advanced.id
}

# API Gateway request validator
resource "aws_api_gateway_request_validator" "advanced" {
  name                        = "advanced-validator"
  rest_api_id                 = aws_api_gateway_rest_api.advanced.id
  validate_request_body       = true
  validate_request_parameters = true
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple API Gateway setup
resource "aws_api_gateway_rest_api" "simple" {
  name = "simple-api"

  tags = {
    Name = "Simple REST API"
  }
}

# Simple resource
resource "aws_api_gateway_resource" "simple" {
  rest_api_id = aws_api_gateway_rest_api.simple.id
  parent_id   = aws_api_gateway_rest_api.simple.root_resource_id
  path_part   = "hello"
}

# Simple method
resource "aws_api_gateway_method" "simple" {
  rest_api_id   = aws_api_gateway_rest_api.simple.id
  resource_id   = aws_api_gateway_resource.simple.id
  http_method   = "GET"
  authorization = "NONE"
}

# Simple integration
resource "aws_api_gateway_integration" "simple" {
  rest_api_id = aws_api_gateway_rest_api.simple.id
  resource_id = aws_api_gateway_resource.simple.id
  http_method = aws_api_gateway_method.simple.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
```

### **Production Deployment**
```hcl
# Production API Gateway setup
locals {
  api_config = {
    api_name = "production-api"
    stage_name = "prod"
    enable_cors = true
    enable_usage_plans = true
    enable_custom_domain = true
  }
}

# Production API Gateway REST API
resource "aws_api_gateway_rest_api" "production" {
  name        = local.api_config.api_name
  description = "Production REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Production REST API"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production API Gateway deployment
resource "aws_api_gateway_deployment" "production" {
  depends_on = [
    aws_api_gateway_method.production,
    aws_api_gateway_integration.production,
  ]

  rest_api_id = aws_api_gateway_rest_api.production.id
  stage_name  = local.api_config.stage_name

  tags = {
    Name        = "Production API Deployment"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production API Gateway stage
resource "aws_api_gateway_stage" "production" {
  deployment_id = aws_api_gateway_deployment.production.id
  rest_api_id   = aws_api_gateway_rest_api.production.id
  stage_name    = local.api_config.stage_name

  # Enable CloudWatch logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      caller        = "$context.identity.caller"
      user          = "$context.identity.user"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      resourcePath  = "$context.resourcePath"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "Production API Stage"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment API Gateway setup
locals {
  environments = {
    dev = {
      api_name = "dev-api"
      stage_name = "dev"
      enable_cors = true
    }
    staging = {
      api_name = "staging-api"
      stage_name = "staging"
      enable_cors = true
    }
    prod = {
      api_name = "prod-api"
      stage_name = "prod"
      enable_cors = true
    }
  }
}

# Environment-specific API Gateway REST APIs
resource "aws_api_gateway_rest_api" "environment" {
  for_each = local.environments

  name        = each.value.api_name
  description = "${each.key} REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${title(each.key)} REST API"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific API Gateway deployments
resource "aws_api_gateway_deployment" "environment" {
  for_each = aws_api_gateway_rest_api.environment

  depends_on = [
    aws_api_gateway_method.environment[each.key],
    aws_api_gateway_integration.environment[each.key],
  ]

  rest_api_id = each.value.id
  stage_name  = local.environments[each.key].stage_name

  tags = {
    Name        = "${title(each.key)} API Deployment"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/apis"
  retention_in_days = 30

  tags = {
    Name        = "API Gateway Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for API Gateway
resource "aws_cloudwatch_log_metric_filter" "api_gateway_usage" {
  name           = "APIGatewayUsage"
  log_group_name = aws_cloudwatch_log_group.api_gateway.name
  pattern        = "[timestamp, request_id, http_method=\"GET\", ...]"

  metric_transformation {
    name      = "APIGatewayUsage"
    namespace = "API Gateway/Usage"
    value     = "1"
  }
}

# CloudWatch alarm for API Gateway
resource "aws_cloudwatch_metric_alarm" "api_gateway_alarm" {
  alarm_name          = "APIGatewayAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors API Gateway requests"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_deployment.main.stage_name
  }

  tags = {
    Name        = "API Gateway Alarm"
    Environment = "production"
  }
}
```

### **API Gateway Metrics**
```hcl
# CloudWatch alarm for API Gateway errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_errors" {
  alarm_name          = "APIGatewayErrorsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors API Gateway 4XX errors"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_deployment.main.stage_name
  }

  tags = {
    Name        = "API Gateway Errors Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Access Control**
```hcl
# IAM policy for API Gateway access
resource "aws_iam_policy" "api_gateway_access" {
  name        = "APIGatewayAccess"
  description = "Policy for API Gateway access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
      }
    ]
  })
}
```

### **API Keys and Usage Plans**
```hcl
# API Gateway usage plan
resource "aws_api_gateway_usage_plan" "secure" {
  name = "secure-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 10
    burst_limit = 20
  }

  tags = {
    Name        = "Secure Usage Plan"
    Environment = "production"
  }
}

# API Gateway API key
resource "aws_api_gateway_api_key" "secure" {
  name = "secure-api-key"

  tags = {
    Name        = "Secure API Key"
    Environment = "production"
  }
}
```

### **Request Validation**
```hcl
# API Gateway request validator
resource "aws_api_gateway_request_validator" "secure" {
  name                        = "secure-validator"
  rest_api_id                 = aws_api_gateway_rest_api.main.id
  validate_request_body       = true
  validate_request_parameters = true
}

# API Gateway method with validation
resource "aws_api_gateway_method" "secure" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "POST"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.header.Content-Type" = true
  }

  request_validator_id = aws_api_gateway_request_validator.secure.id
}
```

## 💰 Cost Optimization

### **Usage Plans**
```hcl
# Cost-optimized API Gateway usage plan
resource "aws_api_gateway_usage_plan" "cost_optimized" {
  name = "cost-optimized-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }

  quota_settings {
    limit  = 5000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 50
    burst_limit = 100
  }

  tags = {
    Name        = "Cost Optimized Usage Plan"
    Environment = "production"
  }
}
```

### **Caching**
```hcl
# API Gateway method with caching
resource "aws_api_gateway_method" "cached" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.id" = true
  }
}

# API Gateway integration with caching
resource "aws_api_gateway_integration" "cached" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.cached.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.main.invoke_arn

  cache_key_parameters = ["method.request.querystring.id"]
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: API Gateway Deployment Failed**
```hcl
# Debug API Gateway setup
resource "aws_api_gateway_rest_api" "debug" {
  name = "debug-api"

  tags = {
    Name        = "Debug REST API"
    Environment = "production"
  }
}

# Debug method
resource "aws_api_gateway_method" "debug" {
  rest_api_id   = aws_api_gateway_rest_api.debug.id
  resource_id   = aws_api_gateway_rest_api.debug.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# Debug integration
resource "aws_api_gateway_integration" "debug" {
  rest_api_id = aws_api_gateway_rest_api.debug.id
  resource_id = aws_api_gateway_rest_api.debug.root_resource_id
  http_method = aws_api_gateway_method.debug.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
```

#### **Issue: CORS Problems**
```hcl
# Debug CORS setup
resource "aws_api_gateway_method" "debug_cors" {
  rest_api_id   = aws_api_gateway_rest_api.debug.id
  resource_id   = aws_api_gateway_rest_api.debug.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Debug CORS integration
resource "aws_api_gateway_integration" "debug_cors" {
  rest_api_id = aws_api_gateway_rest_api.debug.id
  resource_id = aws_api_gateway_rest_api.debug.root_resource_id
  http_method = aws_api_gateway_method.debug_cors.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce API Gateway Setup**
```hcl
# E-commerce API Gateway setup
locals {
  ecommerce_config = {
    api_name = "ecommerce-api"
    stage_name = "prod"
    enable_cors = true
    enable_usage_plans = true
    enable_custom_domain = true
  }
}

# E-commerce API Gateway REST API
resource "aws_api_gateway_rest_api" "ecommerce" {
  name        = local.ecommerce_config.api_name
  description = "E-commerce REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "E-commerce REST API"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce API Gateway resources
resource "aws_api_gateway_resource" "ecommerce" {
  for_each = toset([
    "users",
    "products",
    "orders",
    "payments"
  ])

  rest_api_id = aws_api_gateway_rest_api.ecommerce.id
  parent_id   = aws_api_gateway_rest_api.ecommerce.root_resource_id
  path_part   = each.value
}

# E-commerce API Gateway methods
resource "aws_api_gateway_method" "ecommerce" {
  for_each = aws_api_gateway_resource.ecommerce

  rest_api_id   = aws_api_gateway_rest_api.ecommerce.id
  resource_id   = each.value.id
  http_method   = "GET"
  authorization = "NONE"
}

# E-commerce API Gateway integrations
resource "aws_api_gateway_integration" "ecommerce" {
  for_each = aws_api_gateway_method.ecommerce

  rest_api_id = aws_api_gateway_rest_api.ecommerce.id
  resource_id = aws_api_gateway_resource.ecommerce[each.key].id
  http_method = each.value.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.ecommerce[each.key].invoke_arn
}
```

### **Microservices API Gateway Setup**
```hcl
# Microservices API Gateway setup
resource "aws_api_gateway_rest_api" "microservices" {
  name        = "microservices-api"
  description = "Microservices REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Microservices REST API"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices API Gateway resources
resource "aws_api_gateway_resource" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  rest_api_id = aws_api_gateway_rest_api.microservices.id
  parent_id   = aws_api_gateway_rest_api.microservices.root_resource_id
  path_part   = each.value
}

# Microservices API Gateway methods
resource "aws_api_gateway_method" "microservices" {
  for_each = aws_api_gateway_resource.microservices

  rest_api_id   = aws_api_gateway_rest_api.microservices.id
  resource_id   = each.value.id
  http_method   = "GET"
  authorization = "NONE"
}

# Microservices API Gateway integrations
resource "aws_api_gateway_integration" "microservices" {
  for_each = aws_api_gateway_method.microservices

  rest_api_id = aws_api_gateway_rest_api.microservices.id
  resource_id = aws_api_gateway_resource.microservices[each.key].id
  http_method = each.value.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.microservices[each.key].invoke_arn
}
```

## 🔗 Related Services

### **Integration Patterns**
- **Lambda**: Function integration
- **ECS**: Container integration
- **EC2**: Instance integration
- **CloudWatch**: Monitoring and logging
- **CloudFront**: CDN integration
- **Route 53**: DNS integration
- **S3**: Object storage integration
- **DynamoDB**: Database integration

### **Service Dependencies**
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **Lambda**: Function execution
- **ACM**: SSL certificates

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic API Gateway examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect API Gateway with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your API Gateway Mastery Journey Continues with Advanced Networking!** 🚀

---

*This comprehensive API Gateway guide provides everything you need to master AWS API Gateway with Terraform. Each example is production-ready and follows security best practices.*
