# AWS Provider Setup Guide

## Overview

This guide provides comprehensive instructions for setting up AWS authentication and configuring the AWS provider in Terraform. Proper AWS configuration is essential for Terraform to manage AWS resources.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed (optional but recommended)
- Terraform installed and working

## AWS Authentication Methods

### 1. AWS CLI Configuration (Recommended)

The AWS CLI provides a simple way to configure credentials and is the most common method for development environments.

#### Install AWS CLI

**Windows:**
```powershell
# Using Chocolatey
choco install awscli

# Using Scoop
scoop install awscli

# Manual installation
# Download from https://aws.amazon.com/cli/
```

**macOS:**
```bash
# Using Homebrew
brew install awscli

# Manual installation
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install awscli

# CentOS/RHEL
sudo yum install awscli

# Manual installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### Configure AWS CLI

```bash
# Configure AWS CLI
aws configure

# You'll be prompted for:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: [us-west-2]
# Default output format: [json]
```

#### Verify Configuration

```bash
# Test AWS CLI configuration
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

### 2. Environment Variables

Environment variables are useful for CI/CD pipelines and automated deployments.

#### Set Environment Variables

**Windows (PowerShell):**
```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="us-west-2"
```

**Windows (Command Prompt):**
```cmd
set AWS_ACCESS_KEY_ID=your-access-key
set AWS_SECRET_ACCESS_KEY=your-secret-key
set AWS_DEFAULT_REGION=us-west-2
```

**macOS/Linux:**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

#### Make Environment Variables Permanent

**Windows:**
```powershell
# Set system environment variables
[Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "your-access-key", "User")
[Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "your-secret-key", "User")
[Environment]::SetEnvironmentVariable("AWS_DEFAULT_REGION", "us-west-2", "User")
```

**macOS/Linux:**
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export AWS_ACCESS_KEY_ID="your-access-key"' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-key"' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION="us-west-2"' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc
```

### 3. AWS Credentials File

The AWS credentials file provides a way to store multiple AWS profiles.

#### Create Credentials File

**Windows:**
```
C:\Users\YourUsername\.aws\credentials
```

**macOS/Linux:**
```
~/.aws/credentials
```

#### Credentials File Format

```ini
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key

[production]
aws_access_key_id = your-production-access-key
aws_secret_access_key = your-production-secret-key

[development]
aws_access_key_id = your-development-access-key
aws_secret_access_key = your-development-secret-key
```

#### Create Config File

**Windows:**
```
C:\Users\YourUsername\.aws\config
```

**macOS/Linux:**
```
~/.aws/config
```

#### Config File Format

```ini
[default]
region = us-west-2
output = json

[profile production]
region = us-east-1
output = json

[profile development]
region = us-west-2
output = json
```

### 4. IAM Roles (for EC2 instances)

IAM roles are the most secure method for EC2 instances and are recommended for production environments.

#### Create IAM Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Attach Policies to Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "ec2:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Create Instance Profile

```bash
# Create instance profile
aws iam create-instance-profile --instance-profile-name TerraformInstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile --instance-profile-name TerraformInstanceProfile --role-name TerraformRole
```

## Terraform Provider Configuration

### Basic Provider Configuration

```hcl
provider "aws" {
  region = "us-west-2"
}
```

### Advanced Provider Configuration

```hcl
provider "aws" {
  region = var.aws_region
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
  
  # Assume role configuration (optional)
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
  
  # Profile configuration (optional)
  profile = "production"
  
  # Endpoint configuration (optional)
  endpoints {
    s3 = "https://s3.us-west-2.amazonaws.com"
  }
}
```

### Multiple Provider Configurations

```hcl
# Default provider
provider "aws" {
  region = "us-west-2"
}

# Production provider
provider "aws" {
  alias  = "production"
  region = "us-east-1"
  profile = "production"
}

# Development provider
provider "aws" {
  alias  = "development"
  region = "us-west-2"
  profile = "development"
}
```

### Using Multiple Providers

```hcl
# Use default provider
resource "aws_s3_bucket" "default_bucket" {
  bucket = "default-bucket"
}

# Use production provider
resource "aws_s3_bucket" "production_bucket" {
  provider = aws.production
  bucket   = "production-bucket"
}

# Use development provider
resource "aws_s3_bucket" "development_bucket" {
  provider = aws.development
  bucket   = "development-bucket"
}
```

## Security Best Practices

### 1. IAM Permissions

#### Principle of Least Privilege

Create IAM policies that grant only the minimum permissions required:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-terraform-bucket*",
        "arn:aws:s3:::my-terraform-bucket*/*"
      ]
    }
  ]
}
```

#### Terraform-Specific Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-bucket",
        "arn:aws:s3:::terraform-state-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-west-2:123456789012:table/terraform-locks"
    }
  ]
}
```

### 2. Credential Management

#### Never Commit Credentials

```bash
# Add to .gitignore
echo "*.tfvars" >> .gitignore
echo ".aws/" >> .gitignore
echo "*.pem" >> .gitignore
```

#### Use AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret" "db_password" {
  name = "database-password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### 3. Network Security

#### VPC Configuration

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "private-subnet"
  }
}
```

#### Security Groups

```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

**Error:** `NoCredentialProviders: no valid providers in chain`
**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
```

#### 2. Permission Denied

**Error:** `AccessDenied: User is not authorized to perform: s3:CreateBucket`
**Solution:**
- Check IAM permissions
- Verify resource ARNs in policy
- Ensure user has required permissions

#### 3. Region Issues

**Error:** `InvalidParameterValue: The specified region is not valid`
**Solution:**
```bash
# Check available regions
aws ec2 describe-regions

# Verify region configuration
aws configure get region
```

#### 4. Profile Issues

**Error:** `NoSuchProfile: The config profile (production) could not be found`
**Solution:**
```bash
# Check available profiles
aws configure list-profiles

# Verify profile configuration
aws configure list --profile production
```

### Debugging Commands

```bash
# Check AWS CLI configuration
aws configure list

# Test AWS connectivity
aws sts get-caller-identity

# Check available regions
aws ec2 describe-regions

# List S3 buckets
aws s3 ls

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

## Testing Configuration

### Test AWS Provider

```hcl
# Create a simple test configuration
resource "aws_s3_bucket" "test" {
  bucket = "terraform-test-bucket-${random_id.test.hex}"
}

resource "random_id" "test" {
  byte_length = 4
}
```

### Run Test

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Clean up
terraform destroy
```

## Next Steps

After successful AWS provider setup:

1. **Test Configuration:** Create a simple S3 bucket
2. **Set Up State Backend:** Configure remote state storage
3. **Create IAM Policies:** Set up proper permissions
4. **Implement Security:** Follow security best practices

## Additional Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Conclusion

Proper AWS provider setup is essential for Terraform success. Choose the authentication method that best fits your environment:

- **Development:** Use AWS CLI configuration
- **CI/CD:** Use environment variables or IAM roles
- **Production:** Use IAM roles with least privilege

Remember to follow security best practices and never commit credentials to version control. Test your configuration thoroughly before proceeding to more complex infrastructure.
