# EFS (Elastic File System) - Complete Terraform Guide

## 🎯 Overview

Amazon Elastic File System (EFS) is a fully managed, elastic, cloud-native file system that automatically scales on demand without disrupting applications. EFS provides a simple, scalable, elastic file system for Linux-based workloads.

### **What is EFS?**
EFS is a fully managed NFS (Network File System) that can be mounted on multiple EC2 instances simultaneously, providing a shared file system for applications that need shared access to data.

### **Key Concepts**
- **File Systems**: The primary resource in EFS
- **Mount Targets**: Network endpoints for file systems
- **Access Points**: Application-specific entry points
- **Performance Modes**: General Purpose vs Max I/O
- **Throughput Modes**: Bursting vs Provisioned
- **Lifecycle Management**: Automatic file transitions
- **Encryption**: Data encryption at rest and in transit
- **Backup**: Automated backup policies

### **When to Use EFS**
- **Shared storage** - Multiple instances accessing same data
- **Content management** - Web content, media files
- **Big data analytics** - Shared datasets
- **Container storage** - Persistent volumes for containers
- **Development environments** - Shared code repositories
- **Backup and archiving** - Long-term storage
- **Machine learning** - Shared training data
- **Media processing** - Shared media files

## 🏗️ Architecture Patterns

### **Basic EFS Structure**
```
EFS File System
├── Mount Targets (AZ-specific endpoints)
├── Access Points (Application entry points)
├── Security Groups (Network access control)
├── Performance Mode (General Purpose/Max I/O)
└── Throughput Mode (Bursting/Provisioned)
```

### **Multi-AZ EFS Pattern**
```
EFS File System
├── Mount Target (AZ-1)
├── Mount Target (AZ-2)
├── Mount Target (AZ-3)
└── EC2 Instances (Multiple AZs)
```

## 📝 Terraform Implementation

### **Basic EFS Setup**
```hcl
# EFS file system
resource "aws_efs_file_system" "main" {
  creation_token = "main-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true

  tags = {
    Name        = "Main EFS File System"
    Environment = "production"
  }
}

# EFS mount targets
resource "aws_efs_mount_target" "main" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
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

# EFS access point
resource "aws_efs_access_point" "main" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/app"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Main EFS Access Point"
    Environment = "production"
  }
}
```

### **EFS with Provisioned Throughput**
```hcl
# EFS file system with provisioned throughput
resource "aws_efs_file_system" "provisioned" {
  creation_token = "provisioned-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 100
  encrypted = true

  tags = {
    Name        = "Provisioned EFS File System"
    Environment = "production"
  }
}

# EFS mount targets for provisioned throughput
resource "aws_efs_mount_target" "provisioned" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.provisioned.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

### **EFS with Lifecycle Management**
```hcl
# EFS file system with lifecycle management
resource "aws_efs_file_system" "lifecycle" {
  creation_token = "lifecycle-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "Lifecycle EFS File System"
    Environment = "production"
  }
}

# EFS mount targets for lifecycle management
resource "aws_efs_mount_target" "lifecycle" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.lifecycle.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

### **EFS with Backup Policy**
```hcl
# EFS file system with backup policy
resource "aws_efs_file_system" "backup" {
  creation_token = "backup-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true

  tags = {
    Name        = "Backup EFS File System"
    Environment = "production"
  }
}

# EFS backup policy
resource "aws_efs_backup_policy" "backup" {
  file_system_id = aws_efs_file_system.backup.id

  backup_policy {
    status = "ENABLED"
  }
}

# EFS mount targets for backup
resource "aws_efs_mount_target" "backup" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.backup.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

### **EFS with Multiple Access Points**
```hcl
# EFS file system for multiple access points
resource "aws_efs_file_system" "multi_access" {
  creation_token = "multi-access-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true

  tags = {
    Name        = "Multi Access EFS File System"
    Environment = "production"
  }
}

# Multiple EFS access points
resource "aws_efs_access_point" "multi_access" {
  for_each = {
    "web" = {
      path = "/web"
      uid = 1000
      gid = 1000
    }
    "app" = {
      path = "/app"
      uid = 1001
      gid = 1001
    }
    "data" = {
      path = "/data"
      uid = 1002
      gid = 1002
    }
  }

  file_system_id = aws_efs_file_system.multi_access.id

  posix_user {
    gid = each.value.gid
    uid = each.value.uid
  }

  root_directory {
    path = each.value.path
    creation_info {
      owner_gid   = each.value.gid
      owner_uid   = each.value.uid
      permissions = "755"
    }
  }

  tags = {
    Name        = "Multi Access ${title(each.key)} EFS Access Point"
    Environment = "production"
    Application = each.key
  }
}

# EFS mount targets for multi access
resource "aws_efs_mount_target" "multi_access" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.multi_access.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

## 🔧 Configuration Options

### **EFS File System Configuration**
```hcl
resource "aws_efs_file_system" "custom" {
  creation_token = var.creation_token
  performance_mode = var.performance_mode
  throughput_mode = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  encrypted = var.encrypted
  kms_key_id = var.kms_key_id

  # Lifecycle policies
  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policies
    content {
      transition_to_ia = lifecycle_policy.value.transition_to_ia
    }
  }

  tags = merge(var.common_tags, {
    Name = var.name
  })
}
```

### **Advanced EFS Configuration**
```hcl
# Advanced EFS file system
resource "aws_efs_file_system" "advanced" {
  creation_token = "advanced-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 200
  encrypted = true
  kms_key_id = aws_kms_key.efs.arn

  # Multiple lifecycle policies
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "Advanced EFS File System"
    Environment = "production"
  }
}

# KMS key for EFS encryption
resource "aws_kms_key" "efs" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "EFS Encryption Key"
    Environment = "production"
  }
}

# Advanced EFS access point
resource "aws_efs_access_point" "advanced" {
  file_system_id = aws_efs_file_system.advanced.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/advanced"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Advanced EFS Access Point"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple EFS setup
resource "aws_efs_file_system" "simple" {
  creation_token = "simple-efs"

  tags = {
    Name = "Simple EFS File System"
  }
}

# Simple mount target
resource "aws_efs_mount_target" "simple" {
  file_system_id  = aws_efs_file_system.simple.id
  subnet_id       = aws_subnet.private[0].id
  security_groups = [aws_security_group.efs.id]
}
```

### **Production Deployment**
```hcl
# Production EFS setup
locals {
  efs_config = {
    creation_token = "production-efs"
    performance_mode = "generalPurpose"
    throughput_mode = "provisioned"
    provisioned_throughput = 100
    encrypted = true
    enable_backup = true
  }
}

# Production EFS file system
resource "aws_efs_file_system" "production" {
  creation_token = local.efs_config.creation_token
  performance_mode = local.efs_config.performance_mode
  throughput_mode = local.efs_config.throughput_mode
  provisioned_throughput_in_mibps = local.efs_config.provisioned_throughput
  encrypted = local.efs_config.encrypted

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "Production EFS File System"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production EFS backup policy
resource "aws_efs_backup_policy" "production" {
  count = local.efs_config.enable_backup ? 1 : 0

  file_system_id = aws_efs_file_system.production.id

  backup_policy {
    status = "ENABLED"
  }
}

# Production EFS mount targets
resource "aws_efs_mount_target" "production" {
  count = length(aws_subnet.private)

  file_system_id  = aws_efs_file_system.production.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment EFS setup
locals {
  environments = {
    dev = {
      creation_token = "dev-efs"
      performance_mode = "generalPurpose"
      throughput_mode = "bursting"
      encrypted = false
    }
    staging = {
      creation_token = "staging-efs"
      performance_mode = "generalPurpose"
      throughput_mode = "provisioned"
      provisioned_throughput = 50
      encrypted = true
    }
    prod = {
      creation_token = "prod-efs"
      performance_mode = "generalPurpose"
      throughput_mode = "provisioned"
      provisioned_throughput = 200
      encrypted = true
    }
  }
}

# Environment-specific EFS file systems
resource "aws_efs_file_system" "environment" {
  for_each = local.environments

  creation_token = each.value.creation_token
  performance_mode = each.value.performance_mode
  throughput_mode = each.value.throughput_mode
  provisioned_throughput_in_mibps = each.value.provisioned_throughput
  encrypted = each.value.encrypted

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${title(each.key)} EFS File System"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific EFS mount targets
resource "aws_efs_mount_target" "environment" {
  for_each = {
    for env, config in local.environments : env => config
  }

  file_system_id  = aws_efs_file_system.environment[each.key].id
  subnet_id       = aws_subnet.private[0].id
  security_groups = [aws_security_group.efs.id]
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for EFS
resource "aws_cloudwatch_log_group" "efs_logs" {
  name              = "/aws/efs/file-systems"
  retention_in_days = 30

  tags = {
    Name        = "EFS Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for EFS
resource "aws_cloudwatch_log_metric_filter" "efs_usage" {
  name           = "EFSUsage"
  log_group_name = aws_cloudwatch_log_group.efs_logs.name
  pattern        = "[timestamp, request_id, event_name=\"CreateFileSystem\", ...]"

  metric_transformation {
    name      = "EFSUsage"
    namespace = "EFS/Usage"
    value     = "1"
  }
}

# CloudWatch alarm for EFS
resource "aws_cloudwatch_metric_alarm" "efs_alarm" {
  alarm_name          = "EFSAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DataReadIOBytes"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000000000"
  alarm_description   = "This metric monitors EFS data read"

  dimensions = {
    FileSystemId = aws_efs_file_system.main.id
  }

  tags = {
    Name        = "EFS Alarm"
    Environment = "production"
  }
}
```

### **EFS Metrics**
```hcl
# CloudWatch alarm for EFS throughput
resource "aws_cloudwatch_metric_alarm" "efs_throughput" {
  alarm_name          = "EFSThroughputAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PercentIOLimit"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EFS throughput"

  dimensions = {
    FileSystemId = aws_efs_file_system.main.id
  }

  tags = {
    Name        = "EFS Throughput Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Access Control**
```hcl
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

### **Encryption**
```hcl
# KMS key for EFS encryption
resource "aws_kms_key" "efs_encryption" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "EFS Encryption Key"
    Environment = "production"
  }
}

# Encrypted EFS file system
resource "aws_efs_file_system" "encrypted" {
  creation_token = "encrypted-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true
  kms_key_id = aws_kms_key.efs_encryption.arn

  tags = {
    Name        = "Encrypted EFS File System"
    Environment = "production"
  }
}
```

### **Access Points**
```hcl
# EFS access point with restricted access
resource "aws_efs_access_point" "restricted" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/restricted"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "700"
    }
  }

  tags = {
    Name        = "Restricted EFS Access Point"
    Environment = "production"
  }
}
```

## 💰 Cost Optimization

### **Lifecycle Management**
```hcl
# Cost-optimized EFS file system
resource "aws_efs_file_system" "cost_optimized" {
  creation_token = "cost-optimized-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true

  # Aggressive lifecycle policies
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "Cost Optimized EFS File System"
    Environment = "production"
  }
}
```

### **Throughput Optimization**
```hcl
# EFS file system with optimized throughput
resource "aws_efs_file_system" "throughput_optimized" {
  creation_token = "throughput-optimized-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 50

  tags = {
    Name        = "Throughput Optimized EFS File System"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Mount Target Creation Failed**
```hcl
# Debug EFS file system
resource "aws_efs_file_system" "debug" {
  creation_token = "debug-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"

  tags = {
    Name        = "Debug EFS File System"
    Environment = "production"
  }
}

# Debug mount target
resource "aws_efs_mount_target" "debug" {
  file_system_id  = aws_efs_file_system.debug.id
  subnet_id       = aws_subnet.private[0].id
  security_groups = [aws_security_group.efs.id]
}
```

#### **Issue: Access Point Problems**
```hcl
# Debug EFS access point
resource "aws_efs_access_point" "debug" {
  file_system_id = aws_efs_file_system.debug.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/debug"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Debug EFS Access Point"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce EFS Setup**
```hcl
# E-commerce EFS setup
locals {
  ecommerce_config = {
    creation_token = "ecommerce-efs"
    performance_mode = "generalPurpose"
    throughput_mode = "provisioned"
    provisioned_throughput = 100
    encrypted = true
    enable_backup = true
  }
}

# E-commerce EFS file system
resource "aws_efs_file_system" "ecommerce" {
  creation_token = local.ecommerce_config.creation_token
  performance_mode = local.ecommerce_config.performance_mode
  throughput_mode = local.ecommerce_config.throughput_mode
  provisioned_throughput_in_mibps = local.ecommerce_config.provisioned_throughput
  encrypted = local.ecommerce_config.encrypted

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "E-commerce EFS File System"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce EFS backup policy
resource "aws_efs_backup_policy" "ecommerce" {
  count = local.ecommerce_config.enable_backup ? 1 : 0

  file_system_id = aws_efs_file_system.ecommerce.id

  backup_policy {
    status = "ENABLED"
  }
}

# E-commerce EFS access points
resource "aws_efs_access_point" "ecommerce" {
  for_each = {
    "web" = {
      path = "/web"
      uid = 1000
      gid = 1000
    }
    "media" = {
      path = "/media"
      uid = 1001
      gid = 1001
    }
    "uploads" = {
      path = "/uploads"
      uid = 1002
      gid = 1002
    }
  }

  file_system_id = aws_efs_file_system.ecommerce.id

  posix_user {
    gid = each.value.gid
    uid = each.value.uid
  }

  root_directory {
    path = each.value.path
    creation_info {
      owner_gid   = each.value.gid
      owner_uid   = each.value.uid
      permissions = "755"
    }
  }

  tags = {
    Name        = "E-commerce ${title(each.key)} EFS Access Point"
    Environment = "production"
    Project     = "ecommerce"
    Application = each.key
  }
}
```

### **Microservices EFS Setup**
```hcl
# Microservices EFS setup
resource "aws_efs_file_system" "microservices" {
  creation_token = "microservices-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 200
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "Microservices EFS File System"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices EFS access points
resource "aws_efs_access_point" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  file_system_id = aws_efs_file_system.microservices.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/${each.value}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "Microservices ${title(each.value)} EFS Access Point"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **ECS**: Container storage
- **EC2**: Instance storage
- **Lambda**: Function storage
- **CloudWatch**: Monitoring
- **KMS**: Encryption
- **S3**: Data transfer
- **VPC**: Networking
- **IAM**: Access control

### **Service Dependencies**
- **VPC**: Networking
- **Subnets**: Mount targets
- **Security Groups**: Network access
- **KMS**: Encryption
- **CloudWatch**: Monitoring

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic EFS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect EFS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your EFS Mastery Journey Continues with DynamoDB!** 🚀

---

*This comprehensive EFS guide provides everything you need to master AWS Elastic File System with Terraform. Each example is production-ready and follows security best practices.*
