# Problem 09: Data Sources - AWS and External

## Overview

This solution provides comprehensive understanding of Terraform data sources, focusing on AWS data sources, external data sources, and best practices for data source usage. Data sources are essential for retrieving information about existing infrastructure and external systems.

## Learning Objectives

- Understand Terraform data source concepts and purposes
- Master AWS data sources for infrastructure discovery
- Learn external data sources for API integration
- Understand data source filtering and querying
- Learn data source dependencies and lifecycle
- Master data source best practices and performance
- Understand troubleshooting data source issues

## Problem Statement

You've mastered outputs and complex variable usage. Now your team lead wants you to become proficient in Terraform data sources, starting with AWS data sources and progressing to external data sources. You need to understand how to discover existing infrastructure and integrate with external systems.

## Solution Components

This solution includes:
1. **Data Source Fundamentals** - Understanding what data sources are and why they're important
2. **AWS Data Sources** - Infrastructure discovery and resource information
3. **External Data Sources** - API integration and external system data
4. **Data Source Filtering** - Querying and filtering data sources
5. **Data Source Dependencies** - Managing data source lifecycle
6. **Best Practices** - Performance, security, and maintenance
7. **Troubleshooting** - Common issues and solutions

## Implementation Guide

### Step 1: Understanding Data Source Fundamentals

#### What are Data Sources?
Data sources in Terraform are read-only resources that retrieve information about existing infrastructure or external systems. They serve several purposes:
- **Infrastructure Discovery**: Find existing resources in your cloud provider
- **Resource Information**: Get details about existing resources
- **External Integration**: Retrieve data from external APIs or systems
- **Configuration Data**: Access configuration data from external sources

#### Data Source Benefits
- **Resource Discovery**: Find existing resources without importing them
- **Dynamic Configuration**: Use existing resource information in configurations
- **External Integration**: Integrate with external systems and APIs
- **Configuration Flexibility**: Access external configuration data

### Step 2: AWS Data Sources

#### Infrastructure Discovery Data Sources
```hcl
# Get information about available AMIs
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Get information about availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get information about current AWS account
data "aws_caller_identity" "current" {}

# Get information about current AWS region
data "aws_region" "current" {}
```

#### VPC and Networking Data Sources
```hcl
# Get information about existing VPCs
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["existing-vpc"]
  }
}

# Get information about existing subnets
data "aws_subnet" "existing" {
  filter {
    name   = "tag:Name"
    values = ["existing-subnet"]
  }
}

# Get information about existing security groups
data "aws_security_group" "existing" {
  filter {
    name   = "tag:Name"
    values = ["existing-sg"]
  }
}
```

#### Resource Information Data Sources
```hcl
# Get information about existing instances
data "aws_instance" "existing" {
  filter {
    name   = "tag:Name"
    values = ["existing-instance"]
  }
}

# Get information about existing S3 buckets
data "aws_s3_bucket" "existing" {
  bucket = "existing-bucket"
}

# Get information about existing RDS instances
data "aws_db_instance" "existing" {
  db_instance_identifier = "existing-db"
}
```

### Step 3: External Data Sources

#### HTTP Data Sources
```hcl
# Get data from external API
data "http" "external_api" {
  url = "https://api.example.com/data"
  
  request_headers = {
    Authorization = "Bearer ${var.api_token}"
    Content-Type  = "application/json"
  }
}

# Get data from external service
data "http" "external_service" {
  url = "https://service.example.com/status"
  
  request_headers = {
    User-Agent = "Terraform"
  }
}
```

#### External Data Sources
```hcl
# Get data from external command
data "external" "external_command" {
  program = ["bash", "-c", "echo '{\"result\":\"success\"}'"]
}

# Get data from external script
data "external" "external_script" {
  program = ["python", "${path.module}/scripts/get_data.py"]
}
```

#### Local File Data Sources
```hcl
# Get data from local file
data "local_file" "config_file" {
  filename = "${path.module}/config/app.conf"
}

# Get data from local JSON file
data "local_file" "json_file" {
  filename = "${path.module}/data/config.json"
}
```

### Step 4: Data Source Filtering

#### Advanced Filtering
```hcl
# Filter AMIs by multiple criteria
data "aws_ami" "filtered" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Filter subnets by multiple criteria
data "aws_subnet" "filtered" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["public"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

#### Dynamic Filtering
```hcl
# Dynamic filtering based on variables
data "aws_ami" "dynamic" {
  most_recent = true
  owners      = var.ami_owners
  
  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
  
  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}
```

### Step 5: Data Source Dependencies

#### Implicit Dependencies
```hcl
# Data source depends on other data sources
data "aws_subnet" "dependent" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]  # Implicit dependency
  }
}

# Data source depends on resources
data "aws_instance" "dependent" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]  # Implicit dependency
  }
}
```

#### Explicit Dependencies
```hcl
# Explicit dependency declaration
data "aws_instance" "explicit" {
  filter {
    name   = "tag:Name"
    values = ["existing-instance"]
  }
  
  depends_on = [aws_vpc.main, aws_subnet.public]
}
```

### Step 6: Data Source Usage Patterns

#### Resource Configuration
```hcl
# Use data source in resource configuration
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.existing.id
  
  tags = {
    Name = "web-instance"
  }
}
```

#### Local Values
```hcl
# Use data source in local values
locals {
  ami_id = data.aws_ami.ubuntu.id
  vpc_id = data.aws_vpc.existing.id
  subnet_ids = data.aws_subnet.existing[*].id
}
```

#### Outputs
```hcl
# Use data source in outputs
output "ami_id" {
  description = "ID of the Ubuntu AMI"
  value       = data.aws_ami.ubuntu.id
}

output "vpc_id" {
  description = "ID of the existing VPC"
  value       = data.aws_vpc.existing.id
}
```

### Step 7: Best Practices

#### Performance Best Practices
```hcl
# Use specific filters to reduce data source queries
data "aws_ami" "specific" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Cache data source results in locals
locals {
  ami_id = data.aws_ami.ubuntu.id
  vpc_id = data.aws_vpc.existing.id
}
```

#### Security Best Practices
```hcl
# Use sensitive data sources appropriately
data "aws_ssm_parameter" "sensitive" {
  name = "/app/database/password"
}

# Validate data source results
data "aws_ami" "validated" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Validate AMI exists
locals {
  ami_id = data.aws_ami.validated.id != "" ? data.aws_ami.validated.id : "ami-0c55b159cbfafe1d0"
}
```

#### Error Handling
```hcl
# Handle data source errors gracefully
data "aws_ami" "fallback" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Use try function for error handling
locals {
  ami_id = try(data.aws_ami.fallback.id, "ami-0c55b159cbfafe1d0")
}
```

## Expected Deliverables

### 1. AWS Data Source Definitions
- Complete data source definitions for AWS resources
- Infrastructure discovery data sources
- Resource information data sources
- Filtering and querying examples

### 2. External Data Source Integration
- HTTP data sources for API integration
- External data sources for command execution
- Local file data sources for configuration
- External system integration patterns

### 3. Data Source Filtering
- Advanced filtering techniques
- Dynamic filtering based on variables
- Multiple criteria filtering
- Performance optimization

### 4. Data Source Dependencies
- Implicit dependency management
- Explicit dependency declaration
- Data source lifecycle management
- Dependency optimization

### 5. Best Practices Implementation
- Performance optimization techniques
- Security considerations
- Error handling patterns
- Maintenance guidelines

## Knowledge Check

Answer these questions to validate your understanding:

1. **What are Terraform data sources, and why are they important?**
   - Data sources are read-only resources that retrieve information about existing infrastructure
   - They enable infrastructure discovery, resource information access, and external integration

2. **What are the main types of AWS data sources?**
   - Infrastructure discovery: aws_ami, aws_availability_zones, aws_caller_identity
   - VPC and networking: aws_vpc, aws_subnet, aws_security_group
   - Resource information: aws_instance, aws_s3_bucket, aws_db_instance

3. **How do you filter data sources effectively?**
   - Use specific filter criteria to reduce queries
   - Combine multiple filters for precise results
   - Use dynamic filtering based on variables

4. **What are external data sources, and when would you use them?**
   - HTTP data sources for API integration
   - External data sources for command execution
   - Local file data sources for configuration

5. **How do you manage data source dependencies?**
   - Implicit dependencies through resource references
   - Explicit dependencies with depends_on
   - Consider data source lifecycle and timing

6. **What are the best practices for data source performance?**
   - Use specific filters to reduce queries
   - Cache results in local values
   - Avoid unnecessary data source calls

7. **How do you handle data source errors?**
   - Use try function for error handling
   - Provide fallback values
   - Validate data source results

## Troubleshooting

### Common Data Source Issues

#### 1. Data Source Not Found
```bash
# Error: Data source not found
# Solution: Check data source name and provider
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}
```

#### 2. Filter Issues
```bash
# Error: No matching data source found
# Solution: Check filter criteria
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

#### 3. Dependency Issues
```bash
# Error: Data source dependency issues
# Solution: Check dependencies
data "aws_subnet" "dependent" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}
```

## Next Steps

After completing this problem, you should have:
- Deep understanding of Terraform data sources
- Knowledge of AWS data sources and filtering
- Understanding of external data source integration
- Ability to optimize data source performance

Proceed to [Problem 10: Loops and Iteration - Count and For Each](../Problem-10-Loops-Iteration/) to learn about Terraform loops and iteration patterns.
