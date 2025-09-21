# Lambda - Complete Terraform Guide

## 🎯 Overview

AWS Lambda is a serverless compute service that lets you run code without provisioning or managing servers. Lambda automatically scales your application by running code in response to events and automatically manages the compute resources for you.

### **What is Lambda?**
Lambda is an event-driven, serverless computing platform that runs your code in response to events and automatically manages the underlying compute resources. You pay only for the compute time you consume.

### **Key Concepts**
- **Functions**: Your code packaged as a Lambda function
- **Runtime**: The programming language environment
- **Handler**: The entry point for your function
- **Event Sources**: Services that trigger your function
- **Triggers**: Events that invoke your function
- **Layers**: Shared code and dependencies
- **Environment Variables**: Configuration for your function
- **Dead Letter Queues**: Handle failed invocations
- **VPC Configuration**: Network access for your function
- **Concurrency**: Control function execution limits

### **When to Use Lambda**
- **Event-driven applications** - Process events from various sources
- **Microservices** - Build serverless microservices
- **Data processing** - Transform and process data
- **API backends** - Create RESTful APIs
- **Scheduled tasks** - Run periodic tasks
- **File processing** - Process uploaded files
- **Real-time streaming** - Process streaming data
- **IoT applications** - Process IoT device data

## 🏗️ Architecture Patterns

### **Basic Lambda Structure**
```
Lambda Function
├── Runtime (Python, Node.js, Java, etc.)
├── Handler (Entry Point)
├── Environment Variables
├── Layers (Shared Dependencies)
├── Event Sources (Triggers)
├── VPC Configuration
└── Dead Letter Queue
```

### **Event-Driven Architecture Pattern**
```
Event Sources
├── S3 Bucket → Lambda Function
├── DynamoDB Streams → Lambda Function
├── SNS Topic → Lambda Function
├── SQS Queue → Lambda Function
└── API Gateway → Lambda Function
```

## 📝 Complete Implementation Guide

### **Local Development & Code Examples**

#### **Python Lambda Function Code**
```python
# index.py - Basic Lambda function
import json
import logging
import os
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function handler for basic processing
    
    Args:
        event: Lambda event data
        context: Lambda context object
        
    Returns:
        Response dictionary
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract data from event
        message = event.get('message', 'Hello from Lambda!')
        environment = os.environ.get('ENVIRONMENT', 'development')
        
        # Process the request
        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'environment': environment,
                'timestamp': context.aws_request_id,
                'function_name': context.function_name,
                'memory_limit': context.memory_limit_in_mb,
                'remaining_time': context.get_remaining_time_in_millis()
            })
        }
        
        logger.info(f"Processing successful: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Internal server error'
            })
        }
```

#### **Node.js Lambda Function Code**
```javascript
// index.js - Node.js Lambda function
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Configure AWS SDK
AWS.config.update({ region: process.env.AWS_REGION });

const dynamodb = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

exports.handler = async (event, context) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    try {
        const { message, userId } = event;
        const environment = process.env.ENVIRONMENT || 'development';
        
        // Process the request
        const result = {
            statusCode: 200,
            body: JSON.stringify({
                message: message || 'Hello from Node.js Lambda!',
                userId: userId || uuidv4(),
                environment: environment,
                timestamp: new Date().toISOString(),
                requestId: context.awsRequestId,
                functionName: context.functionName,
                memoryLimit: context.memoryLimitInMB,
                remainingTime: context.getRemainingTimeInMillis()
            })
        };
        
        console.log('Processing successful:', result);
        return result;
        
    } catch (error) {
        console.error('Error processing request:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: error.message,
                message: 'Internal server error'
            })
        };
    }
};
```

#### **Java Lambda Function Code**
```java
// Handler.java - Java Lambda function
package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.util.Map;

public class Handler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent event, Context context) {
        try {
            context.getLogger().log("Received event: " + event.toString());
            
            // Extract data from event
            String message = event.getBody();
            Map<String, String> headers = event.getHeaders();
            String environment = System.getenv("ENVIRONMENT");
            
            // Process the request
            ObjectNode responseBody = objectMapper.createObjectNode();
            responseBody.put("message", message != null ? message : "Hello from Java Lambda!");
            responseBody.put("environment", environment != null ? environment : "development");
            responseBody.put("timestamp", System.currentTimeMillis());
            responseBody.put("requestId", context.getAwsRequestId());
            responseBody.put("functionName", context.getFunctionName());
            responseBody.put("memoryLimit", context.getMemoryLimitInMB());
            responseBody.put("remainingTime", context.getRemainingTimeInMillis());
            
            APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
            response.setStatusCode(200);
            response.setBody(objectMapper.writeValueAsString(responseBody));
            response.setHeaders(Map.of("Content-Type", "application/json"));
            
            context.getLogger().log("Processing successful: " + response.getBody());
            return response;
            
        } catch (Exception e) {
            context.getLogger().log("Error processing request: " + e.getMessage());
            
            APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
            response.setStatusCode(500);
            response.setBody("{\"error\":\"" + e.getMessage() + "\",\"message\":\"Internal server error\"}");
            response.setHeaders(Map.of("Content-Type", "application/json"));
            
            return response;
        }
    }
}
```

#### **Advanced Python Lambda with Dependencies**
```python
# advanced_handler.py - Advanced Lambda function with external dependencies
import json
import logging
import os
import boto3
import requests
from datetime import datetime
from typing import Dict, Any, List
import pandas as pd
import numpy as np

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')
secrets_manager = boto3.client('secretsmanager')

class LambdaProcessor:
    def __init__(self):
        self.table_name = os.environ.get('DYNAMODB_TABLE')
        self.bucket_name = os.environ.get('S3_BUCKET')
        self.secret_name = os.environ.get('SECRET_NAME')
        
    def get_secret(self) -> Dict[str, str]:
        """Retrieve secrets from AWS Secrets Manager"""
        try:
            response = secrets_manager.get_secret_value(SecretId=self.secret_name)
            return json.loads(response['SecretString'])
        except Exception as e:
            logger.error(f"Error retrieving secret: {str(e)}")
            return {}
    
    def process_data(self, data: List[Dict]) -> Dict[str, Any]:
        """Process data using pandas and numpy"""
        try:
            df = pd.DataFrame(data)
            
            # Perform data analysis
            analysis = {
                'total_records': len(df),
                'mean_values': df.select_dtypes(include=[np.number]).mean().to_dict(),
                'null_counts': df.isnull().sum().to_dict(),
                'data_types': df.dtypes.to_dict()
            }
            
            return analysis
        except Exception as e:
            logger.error(f"Error processing data: {str(e)}")
            return {}
    
    def save_to_dynamodb(self, data: Dict[str, Any]) -> bool:
        """Save processed data to DynamoDB"""
        try:
            table = dynamodb.Table(self.table_name)
            table.put_item(Item=data)
            return True
        except Exception as e:
            logger.error(f"Error saving to DynamoDB: {str(e)}")
            return False
    
    def save_to_s3(self, data: Dict[str, Any], key: str) -> bool:
        """Save processed data to S3"""
        try:
            s3_client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=json.dumps(data),
                ContentType='application/json'
            )
            return True
        except Exception as e:
            logger.error(f"Error saving to S3: {str(e)}")
            return False

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Advanced Lambda function handler with external dependencies
    
    Args:
        event: Lambda event data
        context: Lambda context object
        
    Returns:
        Response dictionary
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Initialize processor
        processor = LambdaProcessor()
        
        # Get secrets
        secrets = processor.get_secret()
        
        # Extract data from event
        data = event.get('data', [])
        operation = event.get('operation', 'process')
        
        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Advanced processing completed',
                'operation': operation,
                'timestamp': datetime.utcnow().isoformat(),
                'requestId': context.aws_request_id,
                'functionName': context.function_name,
                'memoryLimit': context.memory_limit_in_mb,
                'remainingTime': context.get_remaining_time_in_millis()
            })
        }
        
        if operation == 'process' and data:
            # Process data
            analysis = processor.process_data(data)
            result['body'] = json.dumps({
                **json.loads(result['body']),
                'analysis': analysis
            })
            
            # Save results
            processor.save_to_dynamodb(analysis)
            processor.save_to_s3(analysis, f"analysis/{context.aws_request_id}.json")
        
        logger.info(f"Advanced processing successful: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Error in advanced processing: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Advanced processing failed'
            })
        }
```

#### **requirements.txt for Python Dependencies**
```txt
# requirements.txt - Python dependencies
boto3>=1.26.0
requests>=2.28.0
pandas>=1.5.0
numpy>=1.24.0
python-dateutil>=2.8.0
```

#### **package.json for Node.js Dependencies**
```json
{
  "name": "lambda-function",
  "version": "1.0.0",
  "description": "Node.js Lambda function",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "aws-sdk": "^2.1400.0",
    "uuid": "^9.0.0",
    "axios": "^1.4.0",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "@types/aws-lambda": "^8.10.119",
    "@types/node": "^20.4.0",
    "typescript": "^5.1.0"
  }
}
```

#### **pom.xml for Java Dependencies**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>lambda-function</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-lambda-java-core</artifactId>
            <version>1.2.2</version>
        </dependency>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-lambda-java-events</artifactId>
            <version>3.11.0</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.15.2</version>
        </dependency>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-java-sdk-dynamodb</artifactId>
            <version>1.12.470</version>
        </dependency>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-java-sdk-s3</artifactId>
            <version>1.12.470</version>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.4.1</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <createDependencyReducedPom>false</createDependencyReducedPom>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### **Local Development Setup**

#### **Python Development Environment**
```bash
# Create virtual environment
python -m venv lambda-env
source lambda-env/bin/activate  # On Windows: lambda-env\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Test locally (using AWS SAM or local testing tools)
sam local invoke FunctionName --event event.json
```

#### **Node.js Development Environment**
```bash
# Install dependencies
npm install

# Test locally
npm run test
# or using AWS SAM
sam local invoke FunctionName --event event.json
```

#### **Java Development Environment**
```bash
# Compile and package
mvn clean package

# Test locally
sam local invoke FunctionName --event event.json
```

### **Deployment Scripts**

#### **Python Deployment Script**
```bash
#!/bin/bash
# deploy-python.sh - Python Lambda deployment script

FUNCTION_NAME="python-lambda-function"
ZIP_FILE="python-function.zip"
SOURCE_DIR="src"

# Create deployment package
cd $SOURCE_DIR
pip install -r requirements.txt -t .
zip -r ../$ZIP_FILE .
cd ..

# Deploy using Terraform
terraform apply -target=aws_lambda_function.python_function

echo "Python Lambda function deployed successfully!"
```

#### **Node.js Deployment Script**
```bash
#!/bin/bash
# deploy-nodejs.sh - Node.js Lambda deployment script

FUNCTION_NAME="nodejs-lambda-function"
ZIP_FILE="nodejs-function.zip"

# Install dependencies
npm install --production

# Create deployment package
zip -r $ZIP_FILE . -x "*.git*" "*.test*" "test/*"

# Deploy using Terraform
terraform apply -target=aws_lambda_function.nodejs_function

echo "Node.js Lambda function deployed successfully!"
```

#### **Java Deployment Script**
```bash
#!/bin/bash
# deploy-java.sh - Java Lambda deployment script

FUNCTION_NAME="java-lambda-function"
JAR_FILE="target/lambda-function-1.0.0.jar"

# Build the project
mvn clean package

# Deploy using Terraform
terraform apply -target=aws_lambda_function.java_function

echo "Java Lambda function deployed successfully!"
```

### **Local Testing & Development Workflows**

#### **Event Testing Files**
```json
// event.json - Sample event for local testing
{
  "message": "Hello from local testing!",
  "userId": "test-user-123",
  "data": [
    {"id": 1, "name": "John", "age": 30},
    {"id": 2, "name": "Jane", "age": 25},
    {"id": 3, "name": "Bob", "age": 35}
  ],
  "operation": "process",
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer test-token"
  }
}
```

```json
// s3-event.json - S3 event for testing
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-west-2",
      "eventTime": "2023-01-01T00:00:00.000Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "EXAMPLE"
      },
      "requestParameters": {
        "sourceIPAddress": "127.0.0.1"
      },
      "responseElements": {
        "x-amz-request-id": "EXAMPLE123456789",
        "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "testConfigRule",
        "bucket": {
          "name": "test-bucket",
          "ownerIdentity": {
            "principalId": "EXAMPLE"
          },
          "arn": "arn:aws:s3:::test-bucket"
        },
        "object": {
          "key": "test-file.json",
          "size": 1024,
          "eTag": "0123456789abcdef0123456789abcdef",
          "sequencer": "0A1B2C3D4E5F678901"
        }
      }
    }
  ]
}
```

```json
// dynamodb-event.json - DynamoDB event for testing
{
  "Records": [
    {
      "eventID": "1",
      "eventName": "INSERT",
      "eventVersion": "1.1",
      "eventSource": "aws:dynamodb",
      "awsRegion": "us-west-2",
      "dynamodb": {
        "ApproximateCreationDateTime": 1640995200,
        "Keys": {
          "id": {
            "S": "123"
          }
        },
        "NewImage": {
          "id": {
            "S": "123"
          },
          "name": {
            "S": "John Doe"
          },
          "email": {
            "S": "john@example.com"
          }
        },
        "SequenceNumber": "111",
        "SizeBytes": 26,
        "StreamViewType": "NEW_AND_OLD_IMAGES"
      },
      "eventSourceARN": "arn:aws:dynamodb:us-west-2:123456789012:table/TestTable/stream/2021-01-01T00:00:00.000"
    }
  ]
}
```

#### **Local Testing with AWS SAM**
```yaml
# template.yaml - AWS SAM template for local development
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Lambda function for local development

Globals:
  Function:
    Timeout: 30
    MemorySize: 256
    Environment:
      Variables:
        ENVIRONMENT: development
        LOG_LEVEL: DEBUG

Resources:
  LambdaFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: src/
      Handler: index.handler
      Runtime: python3.9
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /lambda
            Method: post
        S3Event:
          Type: S3
          Properties:
            Bucket: !Ref S3Bucket
            Events: s3:ObjectCreated:*
        DynamoDBEvent:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt DynamoDBTable.StreamArn
            StartingPosition: LATEST
            BatchSize: 10

  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: test-lambda-bucket

  DynamoDBTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: test-lambda-table
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES

Outputs:
  LambdaFunction:
    Description: "Lambda Function ARN"
    Value: !GetAtt LambdaFunction.Arn
  LambdaFunctionIamRole:
    Description: "Implicit IAM Role created for function"
    Value: !GetAtt LambdaFunctionRole.Arn
```

#### **Local Development Commands**
```bash
# Initialize SAM project
sam init --runtime python3.9 --name my-lambda-function

# Build the application
sam build

# Test locally with different events
sam local invoke LambdaFunction --event events/s3-event.json
sam local invoke LambdaFunction --event events/dynamodb-event.json
sam local invoke LambdaFunction --event events/api-event.json

# Start local API Gateway
sam local start-api

# Start local DynamoDB
sam local start-dynamodb

# Test with local DynamoDB
sam local invoke LambdaFunction --event events/dynamodb-event.json --env-vars env.json
```

#### **Environment Configuration**
```json
// env.json - Environment variables for local testing
{
  "LambdaFunction": {
    "ENVIRONMENT": "development",
    "LOG_LEVEL": "DEBUG",
    "DYNAMODB_TABLE": "test-lambda-table",
    "S3_BUCKET": "test-lambda-bucket",
    "SECRET_NAME": "test-secret"
  }
}
```

#### **Docker Compose for Local Development**
```yaml
# docker-compose.yml - Local development environment
version: '3.8'

services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    command: ["-jar", "DynamoDBLocal.jar", "-sharedDb", "-inMemory"]
    environment:
      - AWS_ACCESS_KEY_ID=dummy
      - AWS_SECRET_ACCESS_KEY=dummy
      - AWS_DEFAULT_REGION=us-west-2

  s3-local:
    image: localstack/localstack:latest
    container_name: s3-local
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3
      - AWS_ACCESS_KEY_ID=dummy
      - AWS_SECRET_ACCESS_KEY=dummy
      - AWS_DEFAULT_REGION=us-west-2

  lambda-local:
    build: .
    container_name: lambda-local
    ports:
      - "3000:3000"
    environment:
      - AWS_ACCESS_KEY_ID=dummy
      - AWS_SECRET_ACCESS_KEY=dummy
      - AWS_DEFAULT_REGION=us-west-2
      - DYNAMODB_ENDPOINT=http://dynamodb-local:8000
      - S3_ENDPOINT=http://s3-local:4566
    depends_on:
      - dynamodb-local
      - s3-local
```

#### **Dockerfile for Lambda Development**
```dockerfile
# Dockerfile - For local Lambda development
FROM public.ecr.aws/lambda/python:3.9

# Copy function code
COPY src/ ${LAMBDA_TASK_ROOT}/

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Set the CMD to your handler
CMD ["index.handler"]
```

#### **Testing Scripts**
```bash
#!/bin/bash
# test-lambda.sh - Comprehensive testing script

echo "🧪 Starting Lambda function tests..."

# Test 1: Basic functionality
echo "📝 Test 1: Basic functionality"
sam local invoke LambdaFunction --event events/basic-event.json

# Test 2: S3 event processing
echo "📝 Test 2: S3 event processing"
sam local invoke LambdaFunction --event events/s3-event.json

# Test 3: DynamoDB event processing
echo "📝 Test 3: DynamoDB event processing"
sam local invoke LambdaFunction --event events/dynamodb-event.json

# Test 4: Error handling
echo "📝 Test 4: Error handling"
sam local invoke LambdaFunction --event events/error-event.json

# Test 5: Performance testing
echo "📝 Test 5: Performance testing"
for i in {1..10}; do
  echo "Run $i:"
  time sam local invoke LambdaFunction --event events/basic-event.json
done

echo "✅ All tests completed!"
```

#### **CI/CD Pipeline Configuration**
```yaml
# .github/workflows/lambda-deploy.yml - GitHub Actions workflow
name: Deploy Lambda Function

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest boto3 moto
    
    - name: Run tests
      run: |
        pytest tests/ -v
    
    - name: Lint code
      run: |
        flake8 src/
        black --check src/

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy with Terraform
      run: |
        terraform init
        terraform plan
        terraform apply -auto-approve
```

#### **Unit Testing Examples**
```python
# tests/test_lambda.py - Unit tests for Lambda function
import json
import pytest
from unittest.mock import Mock, patch
from src.index import handler

class TestLambdaFunction:
    
    def test_basic_handler_success(self):
        """Test basic handler functionality"""
        event = {
            "message": "Test message",
            "userId": "test-user"
        }
        context = Mock()
        context.aws_request_id = "test-request-id"
        context.function_name = "test-function"
        context.memory_limit_in_mb = 256
        context.get_remaining_time_in_millis.return_value = 30000
        
        result = handler(event, context)
        
        assert result["statusCode"] == 200
        body = json.loads(result["body"])
        assert body["message"] == "Test message"
        assert body["userId"] == "test-user"
    
    def test_handler_with_missing_data(self):
        """Test handler with missing data"""
        event = {}
        context = Mock()
        context.aws_request_id = "test-request-id"
        context.function_name = "test-function"
        context.memory_limit_in_mb = 256
        context.get_remaining_time_in_millis.return_value = 30000
        
        result = handler(event, context)
        
        assert result["statusCode"] == 200
        body = json.loads(result["body"])
        assert body["message"] == "Hello from Lambda!"
    
    def test_handler_error_handling(self):
        """Test error handling"""
        event = {"invalid": "data"}
        context = Mock()
        context.aws_request_id = "test-request-id"
        context.function_name = "test-function"
        context.memory_limit_in_mb = 256
        context.get_remaining_time_in_millis.return_value = 30000
        
        with patch('src.index.logger') as mock_logger:
            result = handler(event, context)
            
            assert result["statusCode"] == 200  # Should handle gracefully
    
    @patch('src.index.boto3.resource')
    def test_advanced_handler_with_dependencies(self, mock_dynamodb):
        """Test advanced handler with AWS dependencies"""
        event = {
            "data": [{"id": 1, "name": "John", "age": 30}],
            "operation": "process"
        }
        context = Mock()
        context.aws_request_id = "test-request-id"
        context.function_name = "test-function"
        context.memory_limit_in_mb = 512
        context.get_remaining_time_in_millis.return_value = 30000
        
        # Mock DynamoDB table
        mock_table = Mock()
        mock_dynamodb.return_value.Table.return_value = mock_table
        
        result = handler(event, context)
        
        assert result["statusCode"] == 200
        body = json.loads(result["body"])
        assert body["operation"] == "process"
        assert "analysis" in body
```

## 📝 Terraform Implementation

### **Basic Lambda Setup**
```hcl
# Lambda function
resource "aws_lambda_function" "main" {
  filename         = "main.zip"
  function_name    = "main-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "INFO"
    }
  }

  tags = {
    Name        = "Main Lambda Function"
    Environment = "production"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

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
```

### **Lambda with VPC Configuration**
```hcl
# Lambda function with VPC
resource "aws_lambda_function" "vpc_function" {
  filename         = "vpc_function.zip"
  function_name    = "vpc-function"
  role            = aws_iam_role.lambda_vpc_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
      VPC_ENABLED = "true"
    }
  }

  tags = {
    Name        = "VPC Lambda Function"
    Environment = "production"
  }
}

# IAM role for Lambda VPC
resource "aws_iam_role" "lambda_vpc_role" {
  name = "lambda-vpc-execution-role"

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

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy" {
  role       = aws_iam_role.lambda_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "lambda-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Lambda Security Group"
    Environment = "production"
  }
}
```

### **Lambda with Layers - Comprehensive Dependency Management**

#### **Small Dependencies (< 1MB) - Inline Dependencies**
```hcl
# Lambda function with small inline dependencies
resource "aws_lambda_function" "small_deps" {
  filename         = "small_deps.zip"
  function_name    = "small-deps-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  # Small dependencies packaged with function code
  environment {
    variables = {
      ENVIRONMENT = "production"
      DEP_SIZE    = "small"
    }
  }

  tags = {
    Name        = "Small Dependencies Lambda Function"
    Environment = "production"
  }
}
```

#### **Medium Dependencies (1-50MB) - Layer Management**
```hcl
# Lambda layer for medium dependencies
resource "aws_lambda_layer_version" "medium_deps" {
  filename   = "medium_deps_layer.zip"
  layer_name = "medium-deps-layer"

  compatible_runtimes = [
    "python3.9",
    "python3.10",
    "python3.11"
  ]

  description = "Medium dependencies layer for common libraries"

  tags = {
    Name        = "Medium Dependencies Layer"
    Environment = "production"
  }
}

# Lambda function with medium dependencies
resource "aws_lambda_function" "medium_deps" {
  filename         = "medium_deps_function.zip"
  function_name    = "medium-deps-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  layers = [aws_lambda_layer_version.medium_deps.arn]

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEP_SIZE    = "medium"
      LAYER_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Medium Dependencies Lambda Function"
    Environment = "production"
  }
}
```

#### **Large Dependencies (50MB+) - EFS Integration**
```hcl
# EFS file system for large dependencies
resource "aws_efs_file_system" "lambda_deps" {
  creation_token = "lambda-deps-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100

  tags = {
    Name        = "Lambda Dependencies EFS"
    Environment = "production"
  }
}

# EFS mount targets
resource "aws_efs_mount_target" "lambda_deps" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.lambda_deps.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# EFS access point for Lambda
resource "aws_efs_access_point" "lambda_deps" {
  file_system_id = aws_efs_file_system.lambda_deps.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/lambda-deps"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Lambda Dependencies EFS Access Point"
    Environment = "production"
  }
}

# Lambda function with large dependencies via EFS
resource "aws_lambda_function" "large_deps" {
  filename         = "large_deps_function.zip"
  function_name    = "large-deps-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 1024

  # File system configuration for large dependencies
  file_system_config {
    arn              = aws_efs_access_point.lambda_deps.arn
    local_mount_path = "/mnt/lambda-deps"
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEP_SIZE    = "large"
      EFS_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Large Dependencies Lambda Function"
    Environment = "production"
  }
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "efs-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EFS Security Group"
    Environment = "production"
  }
}
```

#### **Container Image for Lambda - Ultra Large Dependencies**
```hcl
# ECR repository for Lambda container images
resource "aws_ecr_repository" "lambda_container" {
  name                 = "lambda-container"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Lambda Container Repository"
    Environment = "production"
  }
}

# Lambda function using container image
resource "aws_lambda_function" "container_function" {
  function_name = "container-function"
  role         = aws_iam_role.lambda_role.arn
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.lambda_container.repository_url}:latest"

  timeout     = 900
  memory_size = 2048

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEP_SIZE    = "ultra-large"
      CONTAINER_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Container Lambda Function"
    Environment = "production"
  }
}
```

#### **Multi-Layer Architecture for Complex Dependencies**
```hcl
# Base layer for common utilities
resource "aws_lambda_layer_version" "base_layer" {
  filename   = "base_layer.zip"
  layer_name = "base-layer"

  compatible_runtimes = ["python3.9"]

  description = "Base utilities layer"

  tags = {
    Name        = "Base Layer"
    Environment = "production"
  }
}

# Data processing layer
resource "aws_lambda_layer_version" "data_layer" {
  filename   = "data_layer.zip"
  layer_name = "data-layer"

  compatible_runtimes = ["python3.9"]

  description = "Data processing libraries layer"

  tags = {
    Name        = "Data Layer"
    Environment = "production"
  }
}

# ML/AI layer
resource "aws_lambda_layer_version" "ml_layer" {
  filename   = "ml_layer.zip"
  layer_name = "ml-layer"

  compatible_runtimes = ["python3.9"]

  description = "Machine learning libraries layer"

  tags = {
    Name        = "ML Layer"
    Environment = "production"
  }
}

# Lambda function with multiple layers
resource "aws_lambda_function" "multi_layer_function" {
  filename         = "multi_layer_function.zip"
  function_name    = "multi-layer-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 1024

  # Multiple layers for complex dependencies
  layers = [
    aws_lambda_layer_version.base_layer.arn,
    aws_lambda_layer_version.data_layer.arn,
    aws_lambda_layer_version.ml_layer.arn
  ]

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEP_SIZE    = "complex"
      MULTI_LAYER_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Multi-Layer Lambda Function"
    Environment = "production"
  }
}
```

### **Lambda with Dead Letter Queue**
```hcl
# SQS queue for dead letter
resource "aws_sqs_queue" "lambda_dlq" {
  name = "lambda-dlq"

  tags = {
    Name        = "Lambda Dead Letter Queue"
    Environment = "production"
  }
}

# Lambda function with DLQ
resource "aws_lambda_function" "dlq_function" {
  filename         = "dlq_function.zip"
  function_name    = "dlq-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
      DLQ_ENABLED = "true"
    }
  }

  tags = {
    Name        = "DLQ Lambda Function"
    Environment = "production"
  }
}
```

### **Lambda with Event Sources**
```hcl
# S3 bucket for Lambda trigger
resource "aws_s3_bucket" "lambda_trigger" {
  bucket = "lambda-trigger-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Lambda Trigger Bucket"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Lambda function for S3 trigger
resource "aws_lambda_function" "s3_function" {
  filename         = "s3_function.zip"
  function_name    = "s3-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = "production"
      S3_ENABLED = "true"
    }
  }

  tags = {
    Name        = "S3 Lambda Function"
    Environment = "production"
  }
}

# Lambda permission for S3
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda_trigger.arn
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.lambda_trigger.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_function.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3]
}
```

### **Lambda with DynamoDB Streams**
```hcl
# DynamoDB table with streams
resource "aws_dynamodb_table" "lambda_streams" {
  name           = "lambda-streams-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name        = "Lambda Streams Table"
    Environment = "production"
  }
}

# Lambda function for DynamoDB streams
resource "aws_lambda_function" "dynamodb_function" {
  filename         = "dynamodb_function.zip"
  function_name    = "dynamodb-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = "production"
      DYNAMODB_ENABLED = "true"
    }
  }

  tags = {
    Name        = "DynamoDB Lambda Function"
    Environment = "production"
  }
}

# Lambda event source mapping for DynamoDB streams
resource "aws_lambda_event_source_mapping" "dynamodb_streams" {
  event_source_arn  = aws_dynamodb_table.lambda_streams.stream_arn
  function_name     = aws_lambda_function.dynamodb_function.arn
  starting_position = "LATEST"
  batch_size        = 10
}
```

## 🔧 Configuration Options

### **Multi-Runtime Support - Production Ready**

#### **Python Runtime (3.9, 3.10, 3.11, 3.12)**
```hcl
# Python 3.9 Lambda function
resource "aws_lambda_function" "python39" {
  filename         = "python39.zip"
  function_name    = "python39-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "python3.9"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Python 3.9 Lambda Function"
    Environment = "production"
  }
}

# Python 3.12 Lambda function
resource "aws_lambda_function" "python312" {
  filename         = "python312.zip"
  function_name    = "python312-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "python3.12"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Python 3.12 Lambda Function"
    Environment = "production"
  }
}
```

#### **Node.js Runtime (18, 20, 22)**
```hcl
# Node.js 18 Lambda function
resource "aws_lambda_function" "nodejs18" {
  filename         = "nodejs18.zip"
  function_name    = "nodejs18-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "nodejs18.x"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Node.js 18 Lambda Function"
    Environment = "production"
  }
}

# Node.js 22 Lambda function
resource "aws_lambda_function" "nodejs22" {
  filename         = "nodejs22.zip"
  function_name    = "nodejs22-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "nodejs22.x"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Node.js 22 Lambda Function"
    Environment = "production"
  }
}
```

#### **Java Runtime (11, 17, 21)**
```hcl
# Java 11 Lambda function
resource "aws_lambda_function" "java11" {
  filename         = "java11.jar"
  function_name    = "java11-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "com.example.Handler::handleRequest"
  runtime         = "java11"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      RUNTIME = "java11"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Java 11 Lambda Function"
    Environment = "production"
  }
}

# Java 21 Lambda function
resource "aws_lambda_function" "java21" {
  filename         = "java21.jar"
  function_name    = "java21-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "com.example.Handler::handleRequest"
  runtime         = "java21"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      RUNTIME = "java21"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Java 21 Lambda Function"
    Environment = "production"
  }
}
```

#### **.NET Runtime (6, 7, 8)**
```hcl
# .NET 6 Lambda function
resource "aws_lambda_function" "dotnet6" {
  filename         = "dotnet6.zip"
  function_name    = "dotnet6-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "MyFunction::MyFunction.Function::FunctionHandler"
  runtime         = "dotnet6"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      RUNTIME = "dotnet6"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = ".NET 6 Lambda Function"
    Environment = "production"
  }
}

# .NET 8 Lambda function
resource "aws_lambda_function" "dotnet8" {
  filename         = "dotnet8.zip"
  function_name    = "dotnet8-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "MyFunction::MyFunction.Function::FunctionHandler"
  runtime         = "dotnet8"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      RUNTIME = "dotnet8"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = ".NET 8 Lambda Function"
    Environment = "production"
  }
}
```

#### **Go Runtime (1.x)**
```hcl
# Go Lambda function
resource "aws_lambda_function" "go" {
  filename         = "go.zip"
  function_name    = "go-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "main"
  runtime         = "go1.x"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "go1.x"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Go Lambda Function"
    Environment = "production"
  }
}
```

#### **Ruby Runtime (3.2, 3.3)**
```hcl
# Ruby 3.2 Lambda function
resource "aws_lambda_function" "ruby32" {
  filename         = "ruby32.zip"
  function_name    = "ruby32-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "ruby3.2"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "ruby3.2"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Ruby 3.2 Lambda Function"
    Environment = "production"
  }
}

# Ruby 3.3 Lambda function
resource "aws_lambda_function" "ruby33" {
  filename         = "ruby33.zip"
  function_name    = "ruby33-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "ruby3.3"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      RUNTIME = "ruby3.3"
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name        = "Ruby 3.3 Lambda Function"
    Environment = "production"
  }
}
```

### **Lambda Function Configuration**
```hcl
resource "aws_lambda_function" "custom" {
  filename         = var.filename
  function_name    = var.function_name
  role            = var.role_arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  description     = var.description

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Environment variables
  dynamic "environment" {
    for_each = var.environment_variables != null ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  # Layers
  layers = var.layers

  # Dead letter configuration
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  tags = merge(var.common_tags, {
    Name = var.function_name
  })
}
```

### **Advanced Lambda Configuration**
```hcl
# Advanced Lambda function
resource "aws_lambda_function" "advanced" {
  filename         = "advanced.zip"
  function_name    = "advanced-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 1024
  description     = "Advanced Lambda function with comprehensive configuration"

  # VPC configuration
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "INFO"
      DEBUG_MODE  = "false"
    }
  }

  # Layers
  layers = [aws_lambda_layer_version.common.arn]

  # Dead letter configuration
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # File system configuration
  file_system_config {
    arn              = aws_efs_access_point.lambda.arn
    local_mount_path = "/mnt/efs"
  }

  tags = {
    Name        = "Advanced Lambda Function"
    Environment = "production"
  }
}

# EFS access point for Lambda
resource "aws_efs_access_point" "lambda" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/lambda"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Lambda EFS Access Point"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple Lambda function
resource "aws_lambda_function" "simple" {
  filename         = "simple.zip"
  function_name    = "simple-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  tags = {
    Name = "Simple Lambda Function"
  }
}
```

### **Production Deployment**
```hcl
# Production Lambda setup
locals {
  lambda_config = {
    function_name = "production-function"
    runtime = "python3.9"
    timeout = 300
    memory_size = 256
    enable_vpc = true
    enable_layers = true
    enable_dlq = true
  }
}

# Production Lambda function
resource "aws_lambda_function" "production" {
  filename         = "production.zip"
  function_name    = local.lambda_config.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = local.lambda_config.runtime
  timeout         = local.lambda_config.timeout
  memory_size     = local.lambda_config.memory_size
  description     = "Production Lambda function"

  # VPC configuration
  dynamic "vpc_config" {
    for_each = local.lambda_config.enable_vpc ? [1] : []
    content {
      subnet_ids         = aws_subnet.private[*].id
      security_group_ids = [aws_security_group.lambda.id]
    }
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "INFO"
    }
  }

  # Layers
  layers = local.lambda_config.enable_layers ? [aws_lambda_layer_version.common.arn] : []

  # Dead letter configuration
  dynamic "dead_letter_config" {
    for_each = local.lambda_config.enable_dlq ? [1] : []
    content {
      target_arn = aws_sqs_queue.lambda_dlq.arn
    }
  }

  tags = {
    Name        = "Production Lambda Function"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment Lambda setup
locals {
  environments = {
    dev = {
      function_name = "dev-function"
      runtime = "python3.9"
      timeout = 300
      memory_size = 128
      enable_vpc = false
    }
    staging = {
      function_name = "staging-function"
      runtime = "python3.9"
      timeout = 300
      memory_size = 256
      enable_vpc = true
    }
    prod = {
      function_name = "prod-function"
      runtime = "python3.9"
      timeout = 300
      memory_size = 512
      enable_vpc = true
    }
  }
}

# Environment-specific Lambda functions
resource "aws_lambda_function" "environment" {
  for_each = local.environments

  filename         = "${each.key}.zip"
  function_name    = each.value.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = each.value.runtime
  timeout         = each.value.timeout
  memory_size     = each.value.memory_size

  # VPC configuration
  dynamic "vpc_config" {
    for_each = each.value.enable_vpc ? [1] : []
    content {
      subnet_ids         = aws_subnet.private[*].id
      security_group_ids = [aws_security_group.lambda.id]
    }
  }

  environment {
    variables = {
      ENVIRONMENT = each.key
      LOG_LEVEL   = "INFO"
    }
  }

  tags = {
    Name        = "${title(each.key)} Lambda Function"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Advanced Monitoring & Observability

### **Comprehensive CloudWatch Integration**
```hcl
# CloudWatch log group for Lambda with custom retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/functions"
  retention_in_days = 30

  tags = {
    Name        = "Lambda Logs"
    Environment = "production"
  }
}

# CloudWatch log group for specific function
resource "aws_cloudwatch_log_group" "function_logs" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "Function Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for Lambda errors
resource "aws_cloudwatch_log_metric_filter" "lambda_errors" {
  name           = "LambdaErrors"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "LambdaErrors"
    namespace = "Lambda/Errors"
    value     = "1"
  }
}

# CloudWatch metric filter for Lambda warnings
resource "aws_cloudwatch_log_metric_filter" "lambda_warnings" {
  name           = "LambdaWarnings"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name
  pattern        = "[timestamp, request_id, level=\"WARNING\", ...]"

  metric_transformation {
    name      = "LambdaWarnings"
    namespace = "Lambda/Warnings"
    value     = "1"
  }
}

# CloudWatch alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "LambdaErrorsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda errors"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]

  tags = {
    Name        = "Lambda Errors Alarm"
    Environment = "production"
  }
}

# CloudWatch alarm for Lambda duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "LambdaDurationAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors Lambda duration"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]

  tags = {
    Name        = "Lambda Duration Alarm"
    Environment = "production"
  }
}

# CloudWatch alarm for Lambda throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "LambdaThrottlesAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Lambda throttles"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]

  tags = {
    Name        = "Lambda Throttles Alarm"
    Environment = "production"
  }
}

# SNS topic for Lambda alerts
resource "aws_sns_topic" "lambda_alerts" {
  name = "lambda-alerts"

  tags = {
    Name        = "Lambda Alerts Topic"
    Environment = "production"
  }
}
```

### **X-Ray Tracing Integration**
```hcl
# Lambda function with X-Ray tracing
resource "aws_lambda_function" "xray_function" {
  filename         = "xray_function.zip"
  function_name    = "xray-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
      XRAY_ENABLED = "true"
    }
  }

  tags = {
    Name        = "X-Ray Lambda Function"
    Environment = "production"
  }
}

# IAM policy for X-Ray tracing
resource "aws_iam_policy" "xray_tracing" {
  name        = "XRayTracingPolicy"
  description = "Policy for X-Ray tracing"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "xray_tracing" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.xray_tracing.arn
}
```

### **Custom Metrics & Dashboards**
```hcl
# CloudWatch custom metric
resource "aws_cloudwatch_log_metric_filter" "custom_metric" {
  name           = "CustomMetric"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name
  pattern        = "[timestamp, request_id, custom_metric, value]"

  metric_transformation {
    name      = "CustomMetric"
    namespace = "Lambda/Custom"
    value     = "$value"
  }
}

# CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "lambda_dashboard" {
  dashboard_name = "Lambda-Dashboard"

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
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.main.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            [".", "Throttles", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Lambda Function Metrics"
          period  = 300
        }
      }
    ]
  })
}

data "aws_region" "current" {}
```

### **Performance Insights**
```hcl
# Lambda function with performance insights
resource "aws_lambda_function" "performance_function" {
  filename         = "performance_function.zip"
  function_name    = "performance-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      ENVIRONMENT = "production"
      PERFORMANCE_INSIGHTS = "enabled"
    }
  }

  tags = {
    Name        = "Performance Lambda Function"
    Environment = "production"
  }
}

# CloudWatch alarm for performance insights
resource "aws_cloudwatch_metric_alarm" "performance_alarm" {
  alarm_name          = "PerformanceAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000"
  alarm_description   = "This metric monitors Lambda performance"

  dimensions = {
    FunctionName = aws_lambda_function.performance_function.function_name
  }

  tags = {
    Name        = "Performance Alarm"
    Environment = "production"
  }
}
```

## 🚀 CI/CD & Deployment Strategies

### **Blue-Green Deployment**
```hcl
# Blue Lambda function
resource "aws_lambda_function" "blue_function" {
  filename         = "blue_function.zip"
  function_name    = "blue-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEPLOYMENT = "blue"
    }
  }

  tags = {
    Name        = "Blue Lambda Function"
    Environment = "production"
    Deployment  = "blue"
  }
}

# Green Lambda function
resource "aws_lambda_function" "green_function" {
  filename         = "green_function.zip"
  function_name    = "green-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEPLOYMENT = "green"
    }
  }

  tags = {
    Name        = "Green Lambda Function"
    Environment = "production"
    Deployment  = "green"
  }
}

# Lambda alias for blue-green deployment
resource "aws_lambda_alias" "blue_alias" {
  name             = "blue"
  description      = "Blue deployment alias"
  function_name    = aws_lambda_function.blue_function.function_name
  function_version = aws_lambda_function.blue_function.version
}

resource "aws_lambda_alias" "green_alias" {
  name             = "green"
  description      = "Green deployment alias"
  function_name    = aws_lambda_function.green_function.function_name
  function_version = aws_lambda_function.green_function.version
}
```

### **Canary Deployment**
```hcl
# Lambda function with canary deployment
resource "aws_lambda_function" "canary_function" {
  filename         = "canary_function.zip"
  function_name    = "canary-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      DEPLOYMENT = "canary"
    }
  }

  tags = {
    Name        = "Canary Lambda Function"
    Environment = "production"
    Deployment  = "canary"
  }
}

# Lambda alias for canary deployment
resource "aws_lambda_alias" "canary_alias" {
  name             = "canary"
  description      = "Canary deployment alias"
  function_name    = aws_lambda_function.canary_function.function_name
  function_version = aws_lambda_function.canary_function.version
}

# Lambda alias for production
resource "aws_lambda_alias" "production_alias" {
  name             = "production"
  description      = "Production deployment alias"
  function_name    = aws_lambda_function.canary_function.function_name
  function_version = aws_lambda_function.canary_function.version
}
```

### **Feature Flags Integration**
```hcl
# Lambda function with feature flags
resource "aws_lambda_function" "feature_flag_function" {
  filename         = "feature_flag_function.zip"
  function_name    = "feature-flag-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      FEATURE_FLAGS_ENABLED = "true"
      FEATURE_FLAG_URL = "https://api.featureflags.com"
    }
  }

  tags = {
    Name        = "Feature Flag Lambda Function"
    Environment = "production"
  }
}
```

### **Infrastructure as Code Modules**
```hcl
# Lambda module for reusable functions
module "lambda_function" {
  source = "./modules/lambda"

  function_name    = "module-function"
  runtime         = "python3.9"
  handler         = "index.handler"
  timeout         = 300
  memory_size     = 256
  environment_variables = {
    ENVIRONMENT = "production"
    MODULE_ENABLED = "true"
  }

  vpc_config = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  layers = [aws_lambda_layer_version.common.arn]

  tags = {
    Name        = "Module Lambda Function"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **IAM Roles and Policies**
```hcl
# IAM role for Lambda
resource "aws_iam_role" "lambda_secure" {
  name = "lambda-secure-role"

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

# IAM policy for Lambda
resource "aws_iam_policy" "lambda_secure" {
  name        = "LambdaSecurePolicy"
  description = "Policy for secure Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secure" {
  role       = aws_iam_role.lambda_secure.name
  policy_arn = aws_iam_policy.lambda_secure.arn
}
```

### **VPC Security**
```hcl
# Security group for Lambda
resource "aws_security_group" "lambda_secure" {
  name_prefix = "lambda-secure-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Lambda Secure Security Group"
    Environment = "production"
  }
}
```

### **Secrets Management**
```hcl
# Secrets Manager secret for Lambda
resource "aws_secretsmanager_secret" "lambda_secret" {
  name = "lambda-secret"

  tags = {
    Name        = "Lambda Secret"
    Environment = "production"
  }
}

# Lambda function with secrets
resource "aws_lambda_function" "secure_function" {
  filename         = "secure_function.zip"
  function_name    = "secure-function"
  role            = aws_iam_role.lambda_secure.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = "production"
      SECRET_ARN  = aws_secretsmanager_secret.lambda_secret.arn
    }
  }

  tags = {
    Name        = "Secure Lambda Function"
    Environment = "production"
  }
}
```

## 🚀 Advanced Event Sources & Integration Patterns

### **API Gateway Integration**
```hcl
# API Gateway REST API
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "lambda-api"
  description = "API Gateway for Lambda functions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Lambda API Gateway"
    Environment = "production"
  }
}

# API Gateway resource
resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "lambda"
}

# API Gateway method
resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.api_function.invoke_arn
}

# Lambda function for API Gateway
resource "aws_lambda_function" "api_function" {
  filename         = "api_function.zip"
  function_name    = "api-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      API_ENABLED = "true"
    }
  }

  tags = {
    Name        = "API Lambda Function"
    Environment = "production"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}
```

### **Kinesis Data Streams Integration**
```hcl
# Kinesis Data Stream
resource "aws_kinesis_stream" "lambda_stream" {
  name             = "lambda-stream"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingRecords",
    "OutgoingRecords",
  ]

  tags = {
    Name        = "Lambda Kinesis Stream"
    Environment = "production"
  }
}

# Lambda function for Kinesis
resource "aws_lambda_function" "kinesis_function" {
  filename         = "kinesis_function.zip"
  function_name    = "kinesis-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      KINESIS_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Kinesis Lambda Function"
    Environment = "production"
  }
}

# Lambda event source mapping for Kinesis
resource "aws_lambda_event_source_mapping" "kinesis_stream" {
  event_source_arn  = aws_kinesis_stream.lambda_stream.arn
  function_name    = aws_lambda_function.kinesis_function.arn
  starting_position = "LATEST"
  batch_size       = 100
  maximum_batching_window_in_seconds = 5
}
```

### **EventBridge Integration**
```hcl
# EventBridge custom bus
resource "aws_cloudwatch_event_bus" "lambda_bus" {
  name = "lambda-custom-bus"

  tags = {
    Name        = "Lambda EventBridge Bus"
    Environment = "production"
  }
}

# EventBridge rule
resource "aws_cloudwatch_event_rule" "lambda_rule" {
  name        = "lambda-rule"
  description = "Rule for Lambda function"

  event_pattern = jsonencode({
    source      = ["custom.lambda"]
    detail-type = ["Lambda Event"]
  })

  tags = {
    Name        = "Lambda EventBridge Rule"
    Environment = "production"
  }
}

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_rule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.eventbridge_function.arn
}

# Lambda function for EventBridge
resource "aws_lambda_function" "eventbridge_function" {
  filename         = "eventbridge_function.zip"
  function_name    = "eventbridge-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      EVENTBRIDGE_ENABLED = "true"
    }
  }

  tags = {
    Name        = "EventBridge Lambda Function"
    Environment = "production"
  }
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_rule.arn
}
```

## 💰 Cost Optimization & Performance

### **Concurrency Management**
```hcl
# Lambda function with reserved concurrency
resource "aws_lambda_function" "reserved_concurrency" {
  filename         = "reserved_concurrency.zip"
  function_name    = "reserved-concurrency-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  reserved_concurrent_executions = 10

  environment {
    variables = {
      ENVIRONMENT = "production"
      CONCURRENCY_TYPE = "reserved"
    }
  }

  tags = {
    Name        = "Reserved Concurrency Lambda Function"
    Environment = "production"
  }
}

# Lambda function with provisioned concurrency
resource "aws_lambda_function" "provisioned_concurrency" {
  filename         = "provisioned_concurrency.zip"
  function_name    = "provisioned-concurrency-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = "production"
      CONCURRENCY_TYPE = "provisioned"
    }
  }

  tags = {
    Name        = "Provisioned Concurrency Lambda Function"
    Environment = "production"
  }
}

# Provisioned concurrency configuration
resource "aws_lambda_provisioned_concurrency_config" "provisioned_concurrency" {
  function_name                     = aws_lambda_function.provisioned_concurrency.function_name
  provisioned_concurrency_config_name = "provisioned-concurrency-config"
  provisioned_concurrency_count      = 5
}
```

### **Memory & CPU Optimization**
```hcl
# Lambda function with optimized memory allocation
resource "aws_lambda_function" "memory_optimized" {
  filename         = "memory_optimized.zip"
  function_name    = "memory-optimized-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512  # Optimized for CPU-intensive tasks

  environment {
    variables = {
      ENVIRONMENT = "production"
      MEMORY_SIZE = "512"
      OPTIMIZATION = "memory"
    }
  }

  tags = {
    Name        = "Memory Optimized Lambda Function"
    Environment = "production"
  }
}

# Lambda function with burst concurrency
resource "aws_lambda_function" "burst_concurrency" {
  filename         = "burst_concurrency.zip"
  function_name    = "burst-concurrency-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = "production"
      CONCURRENCY_TYPE = "burst"
    }
  }

  tags = {
    Name        = "Burst Concurrency Lambda Function"
    Environment = "production"
  }
}
```

### **Cost Optimization Strategies**
```hcl
# Lambda function with cost optimization
resource "aws_lambda_function" "cost_optimized" {
  filename         = "cost_optimized.zip"
  function_name    = "cost-optimized-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60  # Minimize timeout
  memory_size     = 128  # Start with minimum memory

  environment {
    variables = {
      ENVIRONMENT = "production"
      COST_OPTIMIZATION = "enabled"
    }
  }

  tags = {
    Name        = "Cost Optimized Lambda Function"
    Environment = "production"
  }
}

# Lambda function with ARM64 architecture for cost savings
resource "aws_lambda_function" "arm64_function" {
  filename         = "arm64_function.zip"
  function_name    = "arm64-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128
  architectures   = ["arm64"]  # ARM64 for cost savings

  environment {
    variables = {
      ENVIRONMENT = "production"
      ARCHITECTURE = "arm64"
    }
  }

  tags = {
    Name        = "ARM64 Lambda Function"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Lambda Function Not Invoking**
```hcl
# Debug Lambda function
resource "aws_lambda_function" "debug" {
  filename         = "debug.zip"
  function_name    = "debug-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      DEBUG = "true"
    }
  }

  tags = {
    Name        = "Debug Lambda Function"
    Environment = "production"
  }
}
```

#### **Issue: VPC Configuration Problems**
```hcl
# Debug Lambda function with VPC
resource "aws_lambda_function" "debug_vpc" {
  filename         = "debug_vpc.zip"
  function_name    = "debug-vpc-function"
  role            = aws_iam_role.lambda_vpc_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 128

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DEBUG = "true"
      VPC_ENABLED = "true"
    }
  }

  tags = {
    Name        = "Debug VPC Lambda Function"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce Lambda Setup**
```hcl
# E-commerce Lambda setup
locals {
  ecommerce_config = {
    function_name = "ecommerce-function"
    runtime = "python3.9"
    timeout = 300
    memory_size = 256
    enable_vpc = true
    enable_layers = true
  }
}

# E-commerce Lambda function
resource "aws_lambda_function" "ecommerce" {
  filename         = "ecommerce.zip"
  function_name    = local.ecommerce_config.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = local.ecommerce_config.runtime
  timeout         = local.ecommerce_config.timeout
  memory_size     = local.ecommerce_config.memory_size

  # VPC configuration
  dynamic "vpc_config" {
    for_each = local.ecommerce_config.enable_vpc ? [1] : []
    content {
      subnet_ids         = aws_subnet.private[*].id
      security_group_ids = [aws_security_group.lambda.id]
    }
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "INFO"
    }
  }

  # Layers
  layers = local.ecommerce_config.enable_layers ? [aws_lambda_layer_version.common.arn] : []

  tags = {
    Name        = "E-commerce Lambda Function"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices Lambda Setup**
```hcl
# Microservices Lambda setup
resource "aws_lambda_function" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  filename         = "${each.value}.zip"
  function_name    = "${each.value}-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      SERVICE_NAME = each.value
      ENVIRONMENT  = "production"
      LOG_LEVEL    = "INFO"
    }
  }

  tags = {
    Name        = "Microservices ${title(each.value)} Lambda Function"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **API Gateway**: HTTP APIs
- **S3**: Object storage
- **DynamoDB**: NoSQL database
- **SNS**: Notifications
- **SQS**: Message queuing
- **CloudWatch**: Monitoring and logging
- **ECS**: Container orchestration
- **EFS**: File storage

### **Service Dependencies**
- **IAM**: Access control
- **VPC**: Networking
- **CloudWatch**: Monitoring
- **Secrets Manager**: Secret management

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic Lambda examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect Lambda with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your Lambda Mastery Journey Continues with ElastiCache!** 🚀

---

*This comprehensive Lambda guide provides everything you need to master AWS Lambda with Terraform. Each example is production-ready and follows security best practices.*
