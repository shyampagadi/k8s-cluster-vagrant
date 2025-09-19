# Problem 02: Terraform Installation and First Steps

## Overview

This solution provides comprehensive guidance for installing Terraform CLI, understanding the Terraform workflow, and creating your first infrastructure resource. This hands-on experience is essential for building confidence with Terraform.

## Learning Objectives

- Install Terraform CLI on your system
- Understand Terraform's file structure and naming conventions
- Learn the Terraform workflow: init, plan, apply, destroy
- Create your first `main.tf` file with proper structure
- Configure AWS provider with authentication setup
- Create a simple S3 bucket resource
- Understand what happens during each command execution

## Problem Statement

You've completed your foundational learning about Infrastructure as Code and Terraform concepts. Now it's time to get your hands dirty with actual Terraform installation and your first resource creation. Your team lead has assigned you the task of setting up a development environment where you'll create your first AWS S3 bucket using Terraform.

## Solution Components

This solution includes:
1. **Installation Guide** - Step-by-step Terraform installation
2. **File Structure Guide** - Understanding Terraform file organization
3. **Workflow Documentation** - Complete Terraform workflow explanation
4. **AWS Provider Setup** - Authentication and configuration
5. **First Resource** - Creating an S3 bucket
6. **Command Execution** - Understanding what happens during each command

## Implementation Guide

### Step 1: Install Terraform CLI

#### Windows Installation

**Method 1: Using Chocolatey**
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform
```

**Method 2: Manual Installation**
```powershell
# Download Terraform
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_windows_amd64.zip" -OutFile "terraform.zip"

# Extract and install
Expand-Archive -Path "terraform.zip" -DestinationPath "C:\terraform"
$env:PATH += ";C:\terraform"
```

**Method 3: Using Scoop**
```powershell
# Install Scoop (if not already installed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Terraform
scoop install terraform
```

#### macOS Installation

**Method 1: Using Homebrew**
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Terraform
brew install terraform
```

**Method 2: Manual Installation**
```bash
# Download Terraform
curl -O https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_darwin_amd64.zip

# Extract and install
unzip terraform_1.5.0_darwin_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### Linux Installation

**Method 1: Using Package Manager**
```bash
# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# CentOS/RHEL
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

**Method 2: Manual Installation**
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip

# Extract and install
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### Verify Installation
```bash
# Check Terraform version
terraform version

# Expected output:
# Terraform v1.5.0
# on linux_amd64
```

### Step 2: Understand Terraform File Structure

#### File Extensions
- **`.tf`** - Terraform configuration files
- **`.tfvars`** - Variable definition files
- **`.tfstate`** - State files (generated)
- **`.tfstate.backup`** - State backup files (generated)

#### Common File Names
- **`main.tf`** - Primary configuration file
- **`variables.tf`** - Variable definitions
- **`outputs.tf`** - Output definitions
- **`terraform.tf`** - Terraform and provider configuration
- **`terraform.tfvars`** - Variable values

#### Directory Structure
```
my-terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf
├── terraform.tfvars
├── terraform.tfstate
└── terraform.tfstate.backup
```

### Step 3: Learn the Terraform Workflow

#### 1. Initialize (terraform init)
**Purpose:** Downloads providers and initializes backend
**What happens:**
- Downloads required provider plugins
- Initializes backend configuration
- Sets up working directory
- Validates configuration syntax

**Example:**
```bash
$ terraform init

Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Installing hashicorp/aws v4.67.0...
- Installed hashicorp/aws v4.67.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

#### 2. Plan (terraform plan)
**Purpose:** Creates execution plan without making changes
**What happens:**
- Reads current state
- Compares with desired configuration
- Creates execution plan
- Shows what changes will be made

**Example:**
```bash
$ terraform plan

Terraform will perform the following actions:

  # aws_s3_bucket.my_bucket will be created
  + resource "aws_s3_bucket" "my_bucket" {
      + bucket = "my-unique-bucket-name-12345"
      + id     = "my-unique-bucket-name-12345"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

#### 3. Apply (terraform apply)
**Purpose:** Executes the plan and makes changes
**What happens:**
- Validates the plan
- Executes changes in dependency order
- Updates state file
- Reports results

**Example:**
```bash
$ terraform apply

Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.

Enter a value: yes

aws_s3_bucket.my_bucket: Creating...
aws_s3_bucket.my_bucket: Creation complete after 2s [id=my-unique-bucket-name-12345]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

#### 4. Destroy (terraform destroy)
**Purpose:** Destroys all managed resources
**What happens:**
- Reads current state
- Creates destruction plan
- Executes destruction in reverse dependency order
- Updates state file

**Example:**
```bash
$ terraform destroy

Terraform will perform the following actions:

  # aws_s3_bucket.my_bucket will be destroyed
  - resource "aws_s3_bucket" "my_bucket" {
      - bucket = "my-unique-bucket-name-12345"
      - id     = "my-unique-bucket-name-12345"
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
Enter a value: yes

aws_s3_bucket.my_bucket: Destroying... [id=my-unique-bucket-name-12345]
aws_s3_bucket.my_bucket: Destruction complete after 1s

Destroy complete! Resources: 0 added, 0 changed, 1 destroyed.
```

### Step 4: Create Your First Configuration

#### Create main.tf
```hcl
# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "My S3 Bucket"
    Environment = "Development"
  }
}

# Generate a random suffix for bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

#### Create variables.tf
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "my-terraform-bucket"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}
```

#### Create outputs.tf
```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.bucket_domain_name
}
```

#### Create terraform.tfvars
```hcl
aws_region         = "us-west-2"
bucket_name_prefix = "my-terraform-bucket"
environment        = "development"
```

### Step 5: Configure AWS Provider

#### AWS Authentication Methods

**Method 1: AWS CLI Configuration**
```bash
# Install AWS CLI
# Windows: choco install awscli
# macOS: brew install awscli
# Linux: sudo apt-get install awscli

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-west-2)
# Enter your default output format (e.g., json)
```

**Method 2: Environment Variables**
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

**Method 3: IAM Roles (for EC2 instances)**
```hcl
provider "aws" {
  region = "us-west-2"
  # No credentials needed when running on EC2 with IAM role
}
```

**Method 4: AWS Credentials File**
```ini
# ~/.aws/credentials
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key

[production]
aws_access_key_id = your-production-access-key
aws_secret_access_key = your-production-secret-key
```

```ini
# ~/.aws/config
[default]
region = us-west-2
output = json

[profile production]
region = us-east-1
output = json
```

### Step 6: Execute Your First Terraform Commands

#### Complete Workflow
```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan the deployment
terraform plan

# 4. Apply the configuration
terraform apply

# 5. View outputs
terraform output

# 6. Destroy resources (when done)
terraform destroy
```

#### Understanding Command Outputs

**terraform init output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Installing hashicorp/aws v4.67.0...
- Installed hashicorp/aws v4.67.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

**terraform plan output:**
```
Terraform will perform the following actions:

  # aws_s3_bucket.my_bucket will be created
  + resource "aws_s3_bucket" "my_bucket" {
      + bucket = "my-terraform-bucket-a1b2c3d4"
      + id     = "my-terraform-bucket-a1b2c3d4"
    }

  # random_id.bucket_suffix will be created
  + resource "random_id" "bucket_suffix" {
      + byte_length = 4
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**terraform apply output:**
```
Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.

Enter a value: yes

random_id.bucket_suffix: Creating...
random_id.bucket_suffix: Creation complete after 0s [id=a1b2c3d4]
aws_s3_bucket.my_bucket: Creating...
aws_s3_bucket.my_bucket: Creation complete after 2s [id=my-terraform-bucket-a1b2c3d4]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::my-terraform-bucket-a1b2c3d4"
bucket_domain_name = "my-terraform-bucket-a1b2c3d4.s3.amazonaws.com"
bucket_name = "my-terraform-bucket-a1b2c3d4"
```

## Expected Deliverables

### 1. Working Terraform Installation
- Terraform CLI successfully installed and accessible
- Version verification output showing installed version
- Documentation of installation method and any issues encountered

### 2. First Terraform Configuration
- Complete `main.tf` file with proper structure
- Terraform block with version constraints
- Provider configuration with appropriate settings
- S3 bucket resource definition with proper syntax
- Comments explaining each section

### 3. Understanding of Terraform Workflow
- Step-by-step documentation of each Terraform command
- Explanation of what happens internally during each command
- Understanding of command dependencies and execution order
- Documentation of common command-line options and flags

### 4. AWS Provider Configuration
- AWS credentials configured using appropriate method
- Provider block properly configured in Terraform
- Understanding of AWS authentication methods
- Documentation of security considerations and best practices

## Knowledge Check

Answer these questions to validate your understanding:

1. **What does `terraform init` do internally, and why is it necessary before other commands?**
   - Downloads provider plugins
   - Initializes backend configuration
   - Sets up working directory
   - Validates configuration syntax

2. **What's the difference between `terraform plan` and `terraform apply`, and when should you use each?**
   - `plan` shows what changes will be made without making them
   - `apply` actually makes the changes
   - Use `plan` to review changes before applying
   - Use `apply` to implement the changes

3. **How does Terraform authenticate with AWS, and what are the different authentication methods?**
   - AWS CLI configuration
   - Environment variables
   - IAM roles
   - AWS credentials file

4. **What happens when you run `terraform destroy`, and how can you prevent accidental destruction?**
   - Destroys all managed resources
   - Creates destruction plan
   - Executes destruction in reverse dependency order
   - Use `-target` flag to destroy specific resources

5. **What are the key components of a properly structured Terraform configuration file?**
   - Terraform block with provider requirements
   - Provider configuration
   - Resource definitions
   - Proper syntax and formatting

6. **How do you verify that your Terraform installation and AWS provider configuration are working correctly?**
   - Run `terraform version` to check installation
   - Run `terraform init` to verify provider configuration
   - Run `terraform plan` to test configuration

7. **What are the different Terraform file types and their purposes, and how do you organize them effectively?**
   - `.tf` files for configuration
   - `.tfvars` files for variables
   - `.tfstate` files for state
   - Organize by functionality and environment

## Troubleshooting

### Common Issues

#### 1. Terraform Not Found
```bash
# Check if Terraform is in PATH
which terraform
# or
where terraform

# Add Terraform to PATH
export PATH=$PATH:/path/to/terraform
```

#### 2. AWS Authentication Issues
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify AWS region
aws configure get region
```

#### 3. Provider Download Issues
```bash
# Clear provider cache
rm -rf .terraform
terraform init
```

#### 4. State File Issues
```bash
# Check state file
terraform state list
terraform state show aws_s3_bucket.my_bucket
```

## Next Steps

After completing this problem, you should have:
- Terraform CLI installed and working
- Understanding of Terraform workflow
- First AWS resource created
- Basic configuration file structure

Proceed to [Problem 03: HCL Syntax Deep Dive](../Problem-03-HCL-Syntax/) to learn advanced HCL syntax and features.
