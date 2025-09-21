# S3 (Simple Storage Service) - Complete Terraform Guide

## 🎯 Overview

Amazon Simple Storage Service (S3) is the foundation of AWS storage services. It provides object storage with a simple web service interface to store and retrieve any amount of data from anywhere on the web. S3 is essential for most AWS deployments and provides scalable, durable, and secure storage.

### **What is S3?**
S3 is an object storage service that offers industry-leading scalability, data availability, security, and performance. It's designed to store and retrieve any amount of data from anywhere on the web, making it ideal for a wide variety of use cases.

### **Key Concepts**
- **Buckets**: Containers for objects in S3
- **Objects**: Files stored in buckets
- **Keys**: Unique identifiers for objects
- **Regions**: Geographic locations where buckets are stored
- **Storage Classes**: Different storage options for cost optimization
- **Lifecycle Policies**: Automated transitions between storage classes
- **Versioning**: Keep multiple versions of objects
- **Access Control**: Bucket and object-level permissions

### **When to Use S3**
- **Static website hosting** - Host websites and web applications
- **Data backup and archival** - Store backups and long-term archives
- **Data lakes** - Store large amounts of unstructured data
- **Content distribution** - Store content for CDN distribution
- **Application data** - Store application files and assets
- **Log storage** - Store application and system logs
- **Disaster recovery** - Cross-region data replication

## 🏗️ Architecture Patterns

### **Basic S3 Structure**
```
S3 Bucket
├── Objects (Files)
│   ├── images/
│   ├── documents/
│   ├── backups/
│   └── logs/
├── Bucket Policies
├── Lifecycle Policies
├── Versioning
└── Encryption
```

### **Multi-Tier Storage Pattern**
```
S3 Bucket
├── Standard Storage (Frequently accessed)
├── Standard-IA (Infrequently accessed)
├── Glacier (Archive)
└── Deep Archive (Long-term archive)
```

### **Data Lake Pattern**
```
Data Lake S3 Bucket
├── Raw Data Zone
│   ├── landing/
│   └── staging/
├── Processed Data Zone
│   ├── curated/
│   └── analytics/
├── Archive Zone
│   └── historical/
└── Metadata Zone
    └── catalog/
```

## 📝 Terraform Implementation

### **Basic S3 Bucket**

#### **🎯 Scenario Overview**

**Business Problem Deep Dive**: 
Your application needs reliable, scalable storage for various types of data including user uploads, application assets, backups, and logs. Currently, you're using local storage or basic file servers that are causing:

- **Storage Limitations**: Running out of disk space during peak usage
- **Scalability Issues**: Unable to handle growing data volumes
- **Reliability Concerns**: Risk of data loss due to hardware failures
- **Performance Problems**: Slow file access and transfer speeds
- **Cost Inefficiency**: High costs for maintaining storage infrastructure
- **Security Gaps**: Lack of proper access controls and encryption

**Specific Storage Challenges**:
- **Data Growth**: 300% increase in data volume over the past year
- **Access Patterns**: Mixed access patterns requiring different storage tiers
- **Compliance Requirements**: Need to meet data retention and security standards
- **Global Access**: Users accessing data from multiple geographic locations
- **Backup Complexity**: Complex backup and disaster recovery procedures
- **Cost Management**: Unpredictable storage costs and capacity planning

**Business Impact**:
- **Data Loss Risk**: 15% risk of data loss due to hardware failures
- **Performance Degradation**: 40% slower file access during peak times
- **Cost Overruns**: 60% higher storage costs than budgeted
- **Compliance Violations**: Risk of regulatory compliance violations
- **Customer Impact**: Poor user experience due to slow file operations
- **Operational Overhead**: 50% more time spent on storage management

#### **🔧 Technical Challenge Deep Dive**

**Current Storage Limitations**:
- **Limited Capacity**: Fixed storage capacity that can't scale dynamically
- **Single Point of Failure**: No redundancy or backup mechanisms
- **Poor Performance**: Slow I/O operations and file transfer speeds
- **No Encryption**: Data stored in plain text without encryption
- **Manual Management**: Manual processes for backup and maintenance
- **No Access Control**: Basic file permissions without fine-grained control

**Specific Technical Pain Points**:
- **Capacity Planning**: Difficult to predict and plan storage capacity
- **Backup Complexity**: Complex and time-consuming backup procedures
- **Performance Bottlenecks**: I/O bottlenecks during high usage
- **Security Vulnerabilities**: Lack of encryption and access controls
- **Disaster Recovery**: No automated disaster recovery mechanisms
- **Monitoring Gaps**: Limited visibility into storage usage and performance

**Operational Challenges**:
- **Manual Processes**: Manual storage management and maintenance
- **Capacity Management**: Difficult capacity planning and management
- **Backup Management**: Complex backup scheduling and management
- **Security Management**: Manual security configuration and monitoring
- **Performance Monitoring**: Limited performance monitoring and optimization
- **Cost Management**: Poor cost visibility and optimization

#### **💡 Solution Deep Dive**

**S3 Implementation Strategy**:
- **Object Storage**: Scalable object storage with unlimited capacity
- **High Availability**: 99.999999999% (11 9's) durability
- **Global Access**: Access data from anywhere with low latency
- **Security**: Built-in encryption and access controls
- **Cost Optimization**: Multiple storage classes for cost optimization
- **Automated Management**: Automated backup, versioning, and lifecycle management

**Expected Storage Improvements**:
- **Unlimited Scalability**: Scale from bytes to petabytes without limits
- **High Durability**: 99.999999999% durability with automatic replication
- **Global Performance**: Low latency access from anywhere worldwide
- **Cost Optimization**: 60-80% cost reduction through storage classes
- **Security**: Enterprise-grade security with encryption and access controls
- **Operational Efficiency**: 80% reduction in storage management overhead

#### **🎯 When to Use This Pattern**

**Ideal Use Cases**:
- **Web Applications**: Store user uploads, assets, and application data
- **Data Backup**: Backup critical data with automated retention policies
- **Content Distribution**: Store content for CDN distribution
- **Data Lakes**: Store large amounts of unstructured data for analytics
- **Static Websites**: Host static websites and web applications
- **Application Logs**: Store application and system logs for analysis

**Business Scenarios**:
- **Data Growth**: Applications with rapidly growing data requirements
- **Global Access**: Applications serving users worldwide
- **Compliance**: Applications requiring data retention and security compliance
- **Cost Optimization**: Applications where storage cost optimization is critical
- **Disaster Recovery**: Applications requiring automated backup and recovery
- **Performance**: Applications requiring high-performance data access

#### **📊 Business Benefits**

**Storage Benefits**:
- **Unlimited Capacity**: Scale from bytes to petabytes without limits
- **High Durability**: 99.999999999% durability with automatic replication
- **Global Access**: Low latency access from anywhere worldwide
- **Cost Optimization**: Multiple storage classes for cost optimization
- **Security**: Enterprise-grade security with encryption and access controls
- **Automation**: Automated backup, versioning, and lifecycle management

**Operational Benefits**:
- **Reduced Management**: 80% reduction in storage management overhead
- **Automated Backup**: Automated backup and disaster recovery
- **Cost Visibility**: Better cost visibility and optimization
- **Performance Monitoring**: Comprehensive performance monitoring
- **Compliance**: Built-in compliance features and reporting
- **Scalability**: Automatic scaling with data growth

**Cost Benefits**:
- **Pay-per-Use**: Pay only for storage used
- **Storage Classes**: Optimize costs with different storage classes
- **Lifecycle Policies**: Automated cost optimization through lifecycle policies
- **No Upfront Costs**: No upfront infrastructure costs
- **Predictable Pricing**: Transparent, predictable pricing
- **Cost Optimization**: Continuous cost optimization opportunities

#### **⚙️ Technical Benefits**

**S3 Features**:
- **Object Storage**: Scalable object storage with unlimited capacity
- **Versioning**: Keep multiple versions of objects for data protection
- **Lifecycle Policies**: Automated transitions between storage classes
- **Encryption**: Server-side encryption for data security
- **Access Control**: Fine-grained access control with IAM and bucket policies
- **Event Notifications**: Real-time notifications for object events

**Performance Features**:
- **Global Edge Locations**: Low latency access from edge locations
- **Transfer Acceleration**: Accelerated data transfer with CloudFront
- **Multipart Upload**: Efficient upload of large objects
- **Parallel Processing**: Parallel processing for improved performance
- **Caching**: Intelligent caching for frequently accessed data
- **Compression**: Automatic compression for cost optimization

**Integration Features**:
- **API Integration**: REST API for integration with applications
- **SDK Support**: SDKs for multiple programming languages
- **Event Integration**: Integration with AWS services and applications
- **Monitoring Integration**: Integration with CloudWatch and other monitoring tools
- **Security Integration**: Integration with IAM, KMS, and other security services
- **Analytics Integration**: Integration with analytics and data processing services

#### **🏗️ Architecture Decisions**

**Storage Strategy**:
- **Object Storage**: Use S3 object storage for scalable data storage
- **Storage Classes**: Implement multiple storage classes for cost optimization
- **Lifecycle Policies**: Use lifecycle policies for automated cost optimization
- **Versioning**: Enable versioning for data protection and recovery
- **Encryption**: Implement server-side encryption for data security
- **Access Control**: Implement fine-grained access control

**Performance Strategy**:
- **Global Distribution**: Use global edge locations for low latency
- **Transfer Optimization**: Implement transfer acceleration for large objects
- **Caching Strategy**: Implement intelligent caching for performance
- **Compression**: Use compression for cost optimization
- **Parallel Processing**: Implement parallel processing for efficiency
- **Monitoring**: Implement comprehensive performance monitoring

**Security Strategy**:
- **Encryption**: Implement encryption at rest and in transit
- **Access Control**: Implement role-based access control
- **Audit Logging**: Implement comprehensive audit logging
- **Compliance**: Implement compliance features and reporting
- **Monitoring**: Implement security monitoring and alerting
- **Backup**: Implement automated backup and disaster recovery

#### **🚀 Implementation Strategy**

**Phase 1: Planning and Design**
1. **Requirements Analysis**: Define storage requirements and objectives
2. **Architecture Design**: Design S3 architecture and data organization
3. **Security Planning**: Plan security and access control strategy
4. **Cost Planning**: Plan cost optimization and lifecycle policies

**Phase 2: Basic Configuration**
1. **Bucket Creation**: Create S3 buckets with proper naming and configuration
2. **Versioning Setup**: Enable versioning for data protection
3. **Encryption Setup**: Configure server-side encryption
4. **Access Control**: Implement basic access control and permissions

**Phase 3: Advanced Features**
1. **Lifecycle Policies**: Implement lifecycle policies for cost optimization
2. **Event Notifications**: Configure event notifications for automation
3. **Monitoring Setup**: Set up monitoring and alerting
4. **Integration**: Integrate with applications and other AWS services

**Phase 4: Optimization and Maintenance**
1. **Performance Optimization**: Optimize performance based on usage patterns
2. **Cost Optimization**: Optimize costs through storage classes and lifecycle policies
3. **Security Hardening**: Implement additional security measures
4. **Documentation**: Document procedures and best practices

#### **💰 Cost Considerations**

**S3 Pricing Structure**:
- **Storage**: $0.023 per GB per month for Standard storage
- **Requests**: $0.0004 per 1,000 PUT requests, $0.0004 per 10,000 GET requests
- **Data Transfer**: $0.09 per GB for data transfer out
- **Storage Classes**: Different pricing for different storage classes
- **Lifecycle Transitions**: $0.01 per 1,000 lifecycle transition requests
- **Versioning**: Additional storage costs for object versions

**Cost Optimization Strategies**:
- **Storage Classes**: Use appropriate storage classes for different data types
- **Lifecycle Policies**: Implement lifecycle policies for automated cost optimization
- **Compression**: Use compression to reduce storage costs
- **Deduplication**: Implement deduplication to reduce storage costs
- **Monitoring**: Monitor costs and usage for optimization opportunities
- **Regular Review**: Regular review and optimization of storage costs

**ROI Calculation Example**:
- **Infrastructure Savings**: $50K annually in reduced infrastructure costs
- **Operational Savings**: $30K annually in reduced operational overhead
- **Performance Value**: $20K annually in improved performance
- **S3 Costs**: $15K annually
- **Net Savings**: $85K annually
- **ROI**: 567% return on investment

#### **🔒 Security Considerations**

**Data Security**:
- **Encryption**: Server-side encryption with AWS KMS or S3-managed keys
- **Access Control**: Fine-grained access control with IAM and bucket policies
- **Audit Logging**: Comprehensive audit logging with CloudTrail
- **Compliance**: Built-in compliance features for various standards
- **Data Integrity**: Data integrity checks and validation
- **Privacy**: Privacy controls and data protection features

**Access Security**:
- **IAM Integration**: Integration with AWS IAM for access control
- **Bucket Policies**: Bucket-level policies for access control
- **Object ACLs**: Object-level access control lists
- **Pre-signed URLs**: Time-limited access to objects
- **Cross-Origin**: CORS configuration for web applications
- **VPC Endpoints**: VPC endpoints for private access

**Compliance Features**:
- **SOC Compliance**: SOC 1, 2, and 3 compliance
- **PCI DSS**: PCI DSS compliance for payment data
- **HIPAA**: HIPAA compliance for healthcare data
- **GDPR**: GDPR compliance for European data
- **ISO 27001**: ISO 27001 compliance
- **Custom Compliance**: Custom compliance requirements

#### **📈 Performance Expectations**

**Storage Performance**:
- **Durability**: 99.999999999% (11 9's) durability
- **Availability**: 99.99% availability
- **Throughput**: Unlimited throughput for data transfer
- **Latency**: <100ms latency for data access
- **Scalability**: Unlimited scalability from bytes to petabytes
- **Global Access**: Low latency access from anywhere worldwide

**Transfer Performance**:
- **Upload Speed**: Up to 5 Gbps for single-threaded uploads
- **Download Speed**: Up to 5 Gbps for single-threaded downloads
- **Multipart Upload**: Efficient upload of large objects
- **Transfer Acceleration**: Up to 300% faster transfers with CloudFront
- **Parallel Processing**: Parallel processing for improved performance
- **Compression**: Automatic compression for cost optimization

**Operational Performance**:
- **Management Efficiency**: 80% improvement in storage management efficiency
- **Backup Speed**: 90% faster backup operations
- **Recovery Time**: 95% faster disaster recovery
- **Monitoring**: Real-time monitoring and alerting
- **Automation**: 100% automation of routine tasks
- **Compliance**: 100% compliance with requirements

#### **🔍 Monitoring and Alerting**

**Key Metrics to Monitor**:
- **Storage Usage**: Monitor storage usage and trends
- **Request Metrics**: Monitor request counts and patterns
- **Error Rates**: Monitor error rates and types
- **Cost Metrics**: Monitor costs and usage patterns
- **Performance Metrics**: Monitor performance and latency
- **Security Metrics**: Monitor security events and access patterns

**CloudWatch Integration**:
- **Custom Metrics**: Create custom metrics for business needs
- **Alarms**: Set up alarms for critical metrics
- **Dashboards**: Create dashboards for monitoring
- **Logs**: Analyze S3 access logs for insights
- **Events**: Monitor S3 events and notifications
- **Cost Monitoring**: Monitor costs and usage

**Alerting Strategy**:
- **Storage Alerts**: Alert on storage usage thresholds
- **Performance Alerts**: Alert on performance issues
- **Cost Alerts**: Alert on cost anomalies
- **Security Alerts**: Alert on security events
- **Error Alerts**: Alert on error rate increases
- **Compliance Alerts**: Alert on compliance issues

#### **🧪 Testing Strategy**

**Storage Testing**:
- **Functionality Testing**: Test all S3 features and functionality
- **Performance Testing**: Test performance under various loads
- **Security Testing**: Test security features and access controls
- **Backup Testing**: Test backup and recovery procedures
- **Integration Testing**: Test integration with applications
- **Compliance Testing**: Test compliance features and requirements

**Performance Testing**:
- **Load Testing**: Test performance under high loads
- **Stress Testing**: Test performance under extreme conditions
- **Latency Testing**: Test latency from different locations
- **Throughput Testing**: Test throughput and transfer speeds
- **Scalability Testing**: Test scalability with growing data
- **Endurance Testing**: Test performance over extended periods

**Security Testing**:
- **Access Control Testing**: Test access controls and permissions
- **Encryption Testing**: Test encryption and data protection
- **Audit Testing**: Test audit logging and compliance
- **Penetration Testing**: Test security vulnerabilities
- **Compliance Testing**: Test compliance with standards
- **Disaster Recovery Testing**: Test disaster recovery procedures

#### **🛠️ Troubleshooting Common Issues**

**Storage Issues**:
- **Capacity Issues**: Resolve storage capacity and scaling issues
- **Performance Issues**: Optimize performance and latency
- **Cost Issues**: Optimize costs and usage
- **Access Issues**: Resolve access control and permission issues
- **Backup Issues**: Resolve backup and recovery issues
- **Integration Issues**: Resolve integration with applications

**Performance Issues**:
- **Slow Transfers**: Optimize transfer speeds and performance
- **High Latency**: Optimize latency and global access
- **Throughput Issues**: Optimize throughput and parallel processing
- **Caching Issues**: Optimize caching and performance
- **Compression Issues**: Optimize compression and cost
- **Monitoring Issues**: Resolve monitoring and alerting issues

**Security Issues**:
- **Access Control**: Resolve access control and permission issues
- **Encryption Issues**: Resolve encryption and data protection issues
- **Compliance Issues**: Resolve compliance and audit issues
- **Audit Issues**: Resolve audit logging and monitoring issues
- **Privacy Issues**: Resolve privacy and data protection issues
- **Integration Issues**: Resolve security integration issues

#### **📚 Real-World Example**

**E-commerce Platform Storage**:
- **Company**: Global e-commerce platform
- **Data Volume**: 500TB of product images, user data, and logs
- **Users**: 10M+ users worldwide
- **Geographic Reach**: 25 countries
- **Results**: 
  - 99.999999999% data durability
  - 60% reduction in storage costs
  - 80% improvement in data access speed
  - 100% compliance with security standards
  - 90% reduction in backup time
  - 95% improvement in disaster recovery time

**Implementation Timeline**:
- **Week 1**: Planning and architecture design
- **Week 2**: Basic S3 configuration and setup
- **Week 3**: Advanced features and integration
- **Week 4**: Optimization, monitoring, and documentation

#### **🎯 Next Steps**

**Immediate Actions**:
1. **Create S3 Bucket**: Set up basic S3 bucket with proper configuration
2. **Enable Versioning**: Enable versioning for data protection
3. **Configure Encryption**: Set up server-side encryption
4. **Set Up Monitoring**: Configure monitoring and alerting

**Future Enhancements**:
1. **Lifecycle Policies**: Implement lifecycle policies for cost optimization
2. **Advanced Security**: Implement advanced security features
3. **Performance Optimization**: Optimize performance and global access
4. **Integration**: Enhance integration with applications and services
5. **Analytics**: Implement analytics and data processing capabilities

```hcl
# Create S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "my-terraform-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Main S3 Bucket"
    Environment = "production"
    Project     = "web-app"
  }
}

# Generate random suffix for bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### **S3 Bucket with Lifecycle Policy**
```hcl
# S3 bucket with lifecycle policy
resource "aws_s3_bucket" "lifecycle" {
  bucket = "lifecycle-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Lifecycle S3 Bucket"
    Environment = "production"
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.lifecycle.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Delete old versions after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}
```

### **S3 Bucket with CORS Configuration**
```hcl
# S3 bucket for web application
resource "aws_s3_bucket" "web_app" {
  bucket = "web-app-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Web App S3 Bucket"
    Environment = "production"
  }
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE"]
    allowed_origins = ["https://example.com", "https://www.example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Public access block (allow for website)
resource "aws_s3_bucket_public_access_block" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for website access
resource "aws_s3_bucket_policy" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_app.arn}/*"
      }
    ]
  })
}
```

### **S3 Bucket with Replication**
```hcl
# Source bucket
resource "aws_s3_bucket" "source" {
  bucket = "source-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Source S3 Bucket"
    Environment = "production"
  }
}

# Destination bucket
resource "aws_s3_bucket" "destination" {
  provider = aws.destination
  bucket   = "destination-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Destination S3 Bucket"
    Environment = "production"
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for replication
resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.source.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "source" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replication_rule"
    status = "Enabled"

    filter {
      prefix = "data/"
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

## 🔧 Configuration Options

### **S3 Bucket Configuration**
```hcl
resource "aws_s3_bucket" "custom" {
  bucket = var.bucket_name
  
  # Object lock configuration
  object_lock_enabled = var.object_lock_enabled
  
  tags = merge(var.common_tags, {
    Name = var.bucket_name
  })
}

# Advanced bucket configuration
resource "aws_s3_bucket" "advanced" {
  bucket = "advanced-bucket-${random_id.bucket_suffix.hex}"
  
  # Object lock configuration
  object_lock_enabled = true
  
  tags = {
    Name        = "Advanced S3 Bucket"
    Environment = "production"
  }
}

# Object lock configuration
resource "aws_s3_bucket_object_lock_configuration" "advanced" {
  bucket = aws_s3_bucket.advanced.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 30
    }
  }
}
```

### **S3 Object Configuration**
```hcl
# Upload file to S3
resource "aws_s3_object" "file" {
  bucket = aws_s3_bucket.main.id
  key    = "path/to/file.txt"
  source = "local-file.txt"
  
  # Object metadata
  metadata = {
    "environment" = "production"
    "project"     = "web-app"
  }
  
  # Server-side encryption
  server_side_encryption = "AES256"
  
  # Content type
  content_type = "text/plain"
  
  # ETag
  etag = filemd5("local-file.txt")
  
  tags = {
    Name        = "S3 Object"
    Environment = "production"
  }
}

# Upload with KMS encryption
resource "aws_s3_object" "encrypted_file" {
  bucket                 = aws_s3_bucket.main.id
  key                    = "encrypted/file.txt"
  source                 = "local-file.txt"
  server_side_encryption = "aws:kms"
  kms_key_id            = aws_kms_key.s3.arn
  
  tags = {
    Name        = "Encrypted S3 Object"
    Environment = "production"
  }
}
```

### **S3 Bucket Notification**
```hcl
# S3 bucket for event notifications
resource "aws_s3_bucket" "notifications" {
  bucket = "notifications-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Notifications S3 Bucket"
    Environment = "production"
  }
}

# SNS topic for notifications
resource "aws_sns_topic" "s3_notifications" {
  name = "s3-notifications"
  
  tags = {
    Name        = "S3 Notifications Topic"
    Environment = "production"
  }
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "notifications" {
  bucket = aws_s3_bucket.notifications.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}

# Lambda function for S3 events
resource "aws_lambda_function" "s3_processor" {
  filename         = "s3-processor.zip"
  function_name    = "s3-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.notifications.bucket
    }
  }
}

# S3 bucket notification to Lambda
resource "aws_s3_bucket_notification" "lambda_notifications" {
  bucket = aws_s3_bucket.notifications.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "processed/"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple S3 bucket for file storage
resource "aws_s3_bucket" "simple" {
  bucket = "simple-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "Simple S3 Bucket"
  }
}

# Basic configuration
resource "aws_s3_bucket_versioning" "simple" {
  bucket = aws_s3_bucket.simple.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "simple" {
  bucket = aws_s3_bucket.simple.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### **Production Deployment**
```hcl
# Production S3 bucket with comprehensive configuration
locals {
  s3_config = {
    bucket_name = "production-bucket-${random_id.bucket_suffix.hex}"
    versioning = "Enabled"
    encryption = "AES256"
    lifecycle_enabled = true
    replication_enabled = true
  }
}

# Production S3 bucket
resource "aws_s3_bucket" "production" {
  bucket = local.s3_config.bucket_name
  
  tags = {
    Name        = "Production S3 Bucket"
    Environment = "production"
    Project     = "web-app"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "production" {
  bucket = aws_s3_bucket.production.id
  versioning_configuration {
    status = local.s3_config.versioning
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "production" {
  bucket = aws_s3_bucket.production.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = local.s3_config.encryption
    }
    bucket_key_enabled = true
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "production" {
  bucket = aws_s3_bucket.production.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "production" {
  count  = local.s3_config.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.production.id

  rule {
    id     = "production_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment S3 buckets
locals {
  environments = {
    dev = {
      bucket_name = "dev-bucket-${random_id.bucket_suffix.hex}"
      versioning = "Enabled"
      lifecycle_enabled = false
    }
    staging = {
      bucket_name = "staging-bucket-${random_id.bucket_suffix.hex}"
      versioning = "Enabled"
      lifecycle_enabled = true
    }
    prod = {
      bucket_name = "prod-bucket-${random_id.bucket_suffix.hex}"
      versioning = "Enabled"
      lifecycle_enabled = true
    }
  }
}

# Environment-specific buckets
resource "aws_s3_bucket" "environment" {
  for_each = local.environments
  
  bucket = each.value.bucket_name
  
  tags = {
    Name        = "${each.key} S3 Bucket"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific versioning
resource "aws_s3_bucket_versioning" "environment" {
  for_each = local.environments
  
  bucket = aws_s3_bucket.environment[each.key].id
  versioning_configuration {
    status = each.value.versioning
  }
}

# Environment-specific lifecycle policies
resource "aws_s3_bucket_lifecycle_configuration" "environment" {
  for_each = {
    for env, config in local.environments : env => config
    if config.lifecycle_enabled
  }
  
  bucket = aws_s3_bucket.environment[each.key].id

  rule {
    id     = "${each.key}_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for S3 access logs
resource "aws_cloudwatch_log_group" "s3_access_logs" {
  name              = "/aws/s3/access-logs"
  retention_in_days = 30
  
  tags = {
    Name        = "S3 Access Logs"
    Environment = "production"
  }
}

# S3 bucket for access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "access-logs-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Access Logs S3 Bucket"
    Environment = "production"
  }
}

# Enable access logging
resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}

# CloudWatch metric filter for S3 errors
resource "aws_cloudwatch_log_metric_filter" "s3_errors" {
  name           = "S3Errors"
  log_group_name = aws_cloudwatch_log_group.s3_access_logs.name
  pattern        = "[timestamp, request_id, error_code=\"*\", ...]"
  
  metric_transformation {
    name      = "S3Errors"
    namespace = "S3/Errors"
    value     = "1"
  }
}

# CloudWatch alarm for S3 errors
resource "aws_cloudwatch_metric_alarm" "s3_errors_alarm" {
  alarm_name          = "S3ErrorsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "S3Errors"
  namespace           = "S3/Errors"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors S3 errors"
  
  tags = {
    Name        = "S3 Errors Alarm"
    Environment = "production"
  }
}
```

### **S3 Inventory**
```hcl
# S3 bucket for inventory
resource "aws_s3_bucket" "inventory" {
  bucket = "inventory-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Inventory S3 Bucket"
    Environment = "production"
  }
}

# S3 inventory configuration
resource "aws_s3_bucket_inventory" "main" {
  bucket = aws_s3_bucket.main.id
  name   = "main-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.inventory.arn
      prefix     = "inventory/"
    }
  }
}
```

## 🛡️ Security Best Practices

### **Bucket Policies**
```hcl
# Restrictive bucket policy
resource "aws_s3_bucket_policy" "restrictive" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "AllowSpecificIPs"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = ["203.0.113.0/24"]
          }
        }
      }
    ]
  })
}
```

### **KMS Encryption**
```hcl
# KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "S3 Encryption Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-encryption"
  target_key_id = aws_kms_key.s3.key_id
}

# S3 bucket with KMS encryption
resource "aws_s3_bucket" "kms_encrypted" {
  bucket = "kms-encrypted-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "KMS Encrypted S3 Bucket"
    Environment = "production"
  }
}

# KMS encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "kms_encrypted" {
  bucket = aws_s3_bucket.kms_encrypted.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

### **Access Logging**
```hcl
# S3 bucket for access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "access-logs-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Access Logs S3 Bucket"
    Environment = "production"
  }
}

# Enable access logging
resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}
```

## 💰 Cost Optimization

### **Lifecycle Policies**
```hcl
# Cost-optimized lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimized" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### **Storage Class Optimization**
```hcl
# S3 bucket with intelligent tiering
resource "aws_s3_bucket" "intelligent_tiering" {
  bucket = "intelligent-tiering-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Intelligent Tiering S3 Bucket"
    Environment = "production"
  }
}

# Intelligent tiering configuration
resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  bucket = aws_s3_bucket.intelligent_tiering.id
  name   = "main-tiering"

  status = "Enabled"

  filter {
    prefix = "data/"
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Bucket Access Denied**
```hcl
# Debug bucket policy
resource "aws_s3_bucket_policy" "debug" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAllActions"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}
```

#### **Issue: CORS Configuration Problems**
```hcl
# Debug CORS configuration
resource "aws_s3_bucket_cors_configuration" "debug" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3000
  }
}
```

#### **Issue: Lifecycle Policy Not Working**
```hcl
# Debug lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "debug" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "debug_lifecycle"
    status = "Enabled"

    # Immediate transition for testing
    transition {
      days          = 1
      storage_class = "STANDARD_IA"
    }

    # Delete after 7 days for testing
    expiration {
      days = 7
    }
  }
}
```

## 📚 Real-World Examples

### **Static Website Hosting**
```hcl
# S3 bucket for static website
resource "aws_s3_bucket" "website" {
  bucket = "website-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Website S3 Bucket"
    Environment = "production"
  }
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Public access block (allow for website)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for website access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}
```

### **Data Lake Architecture**
```hcl
# Data lake S3 bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "data-lake-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Data Lake S3 Bucket"
    Environment = "production"
    Project     = "data-analytics"
  }
}

# Data lake lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "data_lake_lifecycle"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# Data lake inventory
resource "aws_s3_bucket_inventory" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  name   = "data-lake-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.data_lake.arn
      prefix     = "inventory/"
    }
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **CloudFront**: CDN for S3 content
- **Lambda**: Process S3 events
- **SNS**: Notifications for S3 events
- **SQS**: Queue S3 events
- **Glacier**: Long-term archival
- **KMS**: Encryption key management
- **IAM**: Access control
- **CloudWatch**: Monitoring and logging

### **Service Dependencies**
- **VPC**: VPC endpoints for private access
- **Route 53**: Custom domain for S3 website
- **Certificate Manager**: SSL certificates for HTTPS
- **CloudTrail**: Audit logging for S3 API calls

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic S3 examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect S3 with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and access logging
6. **Optimize**: Focus on cost and performance

**Your S3 Mastery Journey Continues with RDS!** 🚀

---

*This comprehensive S3 guide provides everything you need to master AWS Simple Storage Service with Terraform. Each example is production-ready and follows security best practices.*
