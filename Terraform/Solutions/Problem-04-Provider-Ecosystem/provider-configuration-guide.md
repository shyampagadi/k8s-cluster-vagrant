# Terraform Provider Configuration Guide

## Overview

This guide provides comprehensive instructions for configuring Terraform providers, including version management, authentication, aliases, and best practices. Proper provider configuration is essential for reliable Terraform operations.

## Provider Configuration Basics

### Provider Block Structure

```hcl
provider "provider_name" {
  # Provider-specific configuration
  argument1 = "value1"
  argument2 = "value2"
  
  # Nested blocks
  nested_block {
    nested_argument = "value"
  }
}
```

### Required Providers Block

```hcl
terraform {
  required_providers {
    provider_name = {
      source  = "namespace/provider"
      version = "version_constraint"
    }
  }
}
```

## AWS Provider Configuration

### Basic Configuration

```hcl
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
```

### Advanced Configuration

```hcl
provider "aws" {
  region = var.aws_region
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
  
  # Assume role configuration
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/TerraformRole"
    session_name = "terraform-session"
    external_id = var.external_id
  }
  
  # Endpoint configuration
  endpoints {
    s3 = "https://s3.us-west-2.amazonaws.com"
    ec2 = "https://ec2.us-west-2.amazonaws.com"
  }
  
  # Ignore tags
  ignore_tags {
    keys = ["LastModified", "LastModifiedBy"]
  }
}
```

### AWS Authentication Methods

#### 1. Environment Variables
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
export AWS_SESSION_TOKEN="your-session-token"  # For temporary credentials
```

#### 2. AWS Credentials File
```ini
# ~/.aws/credentials
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

```ini
# ~/.aws/config
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

#### 3. IAM Roles
```hcl
provider "aws" {
  region = "us-west-2"
  # No credentials needed when running on EC2 with IAM role
}
```

#### 4. AWS SSO
```bash
# Configure AWS SSO
aws configure sso

# Login to SSO
aws sso login --profile production
```

```hcl
provider "aws" {
  region  = "us-west-2"
  profile = "production"
}
```

### AWS Provider Aliases

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

# Cross-account provider
provider "aws" {
  alias = "cross_account"
  region = "us-west-2"
  
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/CrossAccountRole"
  }
}
```

## Azure Provider Configuration

### Basic Configuration

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### Advanced Configuration

```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  
  # Subscription ID
  subscription_id = var.subscription_id
  
  # Client ID and Secret (for service principal)
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  
  # Environment
  environment = "public"  # or "usgovernment", "china", "german"
  
  # Skip provider registration
  skip_provider_registration = false
  
  # Storage use Azure AD
  storage_use_azuread = true
}
```

### Azure Authentication Methods

#### 1. Service Principal
```hcl
provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
```

#### 2. Managed Identity
```hcl
provider "azurerm" {
  features {}
  # Uses managed identity when running in Azure
}
```

#### 3. Azure CLI
```bash
# Login to Azure CLI
az login

# Set subscription
az account set --subscription "your-subscription-id"
```

```hcl
provider "azurerm" {
  features {}
  # Uses Azure CLI credentials
}
```

### Azure Provider Aliases

```hcl
# Default provider
provider "azurerm" {
  features {}
}

# Production provider
provider "azurerm" {
  alias = "production"
  features {}
  
  subscription_id = var.production_subscription_id
  client_id       = var.production_client_id
  client_secret   = var.production_client_secret
  tenant_id       = var.production_tenant_id
}

# Development provider
provider "azurerm" {
  alias = "development"
  features {}
  
  subscription_id = var.development_subscription_id
  client_id       = var.development_client_id
  client_secret   = var.development_client_secret
  tenant_id       = var.development_tenant_id
}
```

## Google Cloud Provider Configuration

### Basic Configuration

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

### Advanced Configuration

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  
  # Credentials
  credentials = file(var.service_account_key_path)
  
  # Billing project
  billing_project = var.billing_project
  
  # User project override
  user_project_override = true
  
  # Request timeout
  request_timeout = "60s"
  
  # Request reason
  request_reason = "Terraform deployment"
}
```

### GCP Authentication Methods

#### 1. Service Account Key
```hcl
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.service_account_key_path)
}
```

#### 2. Application Default Credentials
```bash
# Set application default credentials
gcloud auth application-default login

# Set project
gcloud config set project your-project-id
```

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  # Uses application default credentials
}
```

#### 3. Workload Identity
```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  
  # Uses workload identity when running in GKE
}
```

### GCP Provider Aliases

```hcl
# Default provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Production provider
provider "google" {
  alias   = "production"
  project = var.production_project_id
  region  = var.production_region
}

# Development provider
provider "google" {
  alias   = "development"
  project = var.development_project_id
  region  = var.development_region
}
```

## Community Provider Configuration

### Datadog Provider

```hcl
terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  
  # API URL (for EU)
  api_url = "https://api.datadoghq.eu/"
  
  # Validate SSL
  validate_ssl = true
}
```

### GitHub Provider

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  
  # Base URL for GitHub Enterprise
  base_url = "https://github.company.com/api/v3/"
  
  # Owner (organization or user)
  owner = var.github_owner
}
```

### Kubernetes Provider

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  
  # Or use cluster info
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.cluster_token
}
```

## Provider Version Management

### Version Constraints

```hcl
terraform {
  required_providers {
    # Allow any 4.x version
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    
    # Allow 3.x but not 4.x
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    
    # Exact version
    google = {
      source  = "hashicorp/google"
      version = "= 4.50.0"
    }
    
    # Allow any version
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
```

### Version Update Strategies

#### 1. Conservative Updates
```hcl
# Pin to specific version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.67.0"
    }
  }
}
```

#### 2. Minor Updates Only
```hcl
# Allow minor updates
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}
```

#### 3. Major Updates
```hcl
# Allow major updates
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
```

## Provider Aliases and Multiple Configurations

### Multi-Region Configuration

```hcl
# US West provider
provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

# US East provider
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

# Use providers
resource "aws_s3_bucket" "west_bucket" {
  provider = aws.us_west
  bucket   = "west-bucket"
}

resource "aws_s3_bucket" "east_bucket" {
  provider = aws.us_east
  bucket   = "east-bucket"
}
```

### Multi-Account Configuration

```hcl
# Production account
provider "aws" {
  alias = "production"
  region = "us-west-2"
  
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}

# Development account
provider "aws" {
  alias = "development"
  region = "us-west-2"
  
  assume_role {
    role_arn = "arn:aws:iam::987654321098:role/TerraformRole"
  }
}
```

### Multi-Environment Configuration

```hcl
# Production environment
provider "aws" {
  alias  = "production"
  region = "us-east-1"
  profile = "production"
}

# Staging environment
provider "aws" {
  alias  = "staging"
  region = "us-west-2"
  profile = "staging"
}

# Development environment
provider "aws" {
  alias  = "development"
  region = "us-west-2"
  profile = "development"
}
```

## Provider Best Practices

### 1. Security Best Practices

#### Use Least Privilege
```hcl
# Use specific IAM policies
provider "aws" {
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/TerraformRole"
  }
}
```

#### Secure Credential Management
```hcl
# Use environment variables
provider "aws" {
  region = var.aws_region
  # Credentials from environment variables
}

# Use AWS Secrets Manager
data "aws_secretsmanager_secret" "terraform_credentials" {
  name = "terraform/credentials"
}

data "aws_secretsmanager_secret_version" "terraform_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_credentials.id
}

provider "aws" {
  region = var.aws_region
  # Use credentials from Secrets Manager
}
```

### 2. Performance Best Practices

#### Use Provider Aliases
```hcl
# Enable parallel operations
provider "aws" {
  alias  = "region1"
  region = "us-west-2"
}

provider "aws" {
  alias  = "region2"
  region = "us-east-1"
}
```

#### Optimize API Calls
```hcl
# Use data sources efficiently
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Reuse data source
resource "aws_instance" "web1" {
  ami = data.aws_ami.ubuntu.id
  # ...
}

resource "aws_instance" "web2" {
  ami = data.aws_ami.ubuntu.id
  # ...
}
```

### 3. Maintenance Best Practices

#### Regular Updates
```bash
# Check for provider updates
terraform init -upgrade

# Update provider versions
terraform providers lock -platform=linux_amd64
```

#### Version Pinning
```hcl
# Pin provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Azure credentials
az account show

# Check GCP credentials
gcloud auth list
```

#### 2. Version Conflicts
```bash
# Update provider versions
terraform init -upgrade

# Check provider versions
terraform providers
```

#### 3. Resource Not Found
```bash
# Check provider documentation
terraform providers schema

# Verify resource availability
terraform plan
```

#### 4. Rate Limiting
```hcl
# Add retry configuration
provider "aws" {
  region = var.aws_region
  
  retry_mode = "adaptive"
  max_retries = 10
}
```

### Debugging Commands

```bash
# Check provider configuration
terraform providers

# Check provider schema
terraform providers schema

# Check provider lock file
terraform providers lock -platform=linux_amd64

# Validate configuration
terraform validate

# Check for updates
terraform init -upgrade
```

## Conclusion

Proper provider configuration is essential for reliable Terraform operations. By following these guidelines:

1. **Choose appropriate providers** for your needs
2. **Configure authentication** securely
3. **Use provider aliases** for complex scenarios
4. **Manage versions** carefully
5. **Follow best practices** for security and performance

You'll be able to create robust, maintainable, and secure Terraform configurations that work reliably across different environments and use cases.
