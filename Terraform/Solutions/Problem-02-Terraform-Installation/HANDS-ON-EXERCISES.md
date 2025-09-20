# Problem 2: Terraform Installation - Hands-On Exercises

## Exercise 1: Multi-Platform Installation (30 minutes)
**Objective**: Install Terraform using different methods and verify functionality

### Requirements
- Install Terraform using package manager
- Verify installation with version check
- Test basic Terraform commands
- Configure shell completion

### Step-by-Step Implementation

#### Step 1: Package Manager Installation
```bash
# For macOS users
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# For Ubuntu/Debian users
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# For CentOS/RHEL users
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

#### Step 2: Verification Tests
```bash
# Check version
terraform version

# Verify help system
terraform help

# Test command completion
terraform -install-autocomplete

# Create test directory
mkdir terraform-install-test
cd terraform-install-test

# Test initialization
terraform init

# Test basic commands
terraform fmt
terraform validate
```

### Validation Checklist
- [ ] Terraform version displays correctly
- [ ] Help command shows available options
- [ ] Tab completion works in shell
- [ ] Basic commands execute without errors

## Exercise 2: AWS CLI Configuration (45 minutes)
**Objective**: Set up AWS CLI with multiple profiles and test connectivity

### Requirements
- Install AWS CLI v2
- Configure multiple AWS profiles
- Test authentication with different profiles
- Verify Terraform can use AWS credentials

### Implementation Tasks

#### Task 1: AWS CLI Installation
```bash
# Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Clean up
rm -rf awscliv2.zip aws/
```

#### Task 2: Multi-Profile Configuration
```bash
# Configure default profile
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output (json)

# Configure additional profiles
aws configure --profile development
aws configure --profile production

# Verify profiles
aws configure list-profiles
```

#### Task 3: Test Authentication
```bash
# Test default profile
aws sts get-caller-identity

# Test specific profiles
aws sts get-caller-identity --profile development
aws sts get-caller-identity --profile production

# List S3 buckets (if permissions allow)
aws s3 ls --profile development
```

#### Task 4: Terraform Integration Test
```bash
# Create test configuration
cat > aws-test.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "development"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "account_info" {
  value = {
    account_id = data.aws_caller_identity.current.account_id
    user_id    = data.aws_caller_identity.current.user_id
    arn        = data.aws_caller_identity.current.arn
    region     = data.aws_region.current.name
  }
}
EOF

# Test Terraform with AWS
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```

### Challenge Tasks
1. Set up cross-account role assumption
2. Configure MFA-enabled profiles
3. Test with environment variables
4. Set up credential rotation

## Exercise 3: IDE Integration Setup (60 minutes)
**Objective**: Configure development environment with Terraform support

### Requirements
- Install and configure VS Code with Terraform extension
- Set up syntax highlighting and formatting
- Configure auto-completion and validation
- Test debugging capabilities

### Implementation Steps

#### Step 1: VS Code Setup
```bash
# Install VS Code (if not already installed)
# Download from https://code.visualstudio.com/

# Install Terraform extension
code --install-extension hashicorp.terraform

# Install supporting extensions
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension amazonwebservices.aws-toolkit-vscode
```

#### Step 2: Configure VS Code Settings
```json
// Create .vscode/settings.json in your workspace
{
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.experimentalFeatures.prefillRequiredFields": true,
  "terraform.format.enable": true,
  "terraform.lint.enable": true,
  "files.associations": {
    "*.tf": "terraform",
    "*.tfvars": "terraform"
  },
  "editor.formatOnSave": true,
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.formatDocument": true
    }
  }
}
```

#### Step 3: Test IDE Features
```hcl
# Create test.tf file to test IDE features
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2"
    ], var.aws_region)
    error_message = "AWS region must be a valid US region."
  }
}

resource "aws_s3_bucket" "test" {
  bucket = "test-bucket-${random_id.suffix.hex}"
  
  tags = {
    Name        = "Test Bucket"
    Environment = "development"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.test.bucket
}
```

#### Step 4: Test IDE Functionality
- Syntax highlighting should work
- Auto-completion should suggest resources
- Format on save should work
- Validation errors should be highlighted
- Hover should show documentation

### Advanced IDE Configuration
```json
// Additional VS Code tasks (.vscode/tasks.json)
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "terraform-init",
      "type": "shell",
      "command": "terraform",
      "args": ["init"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "terraform-plan",
      "type": "shell",
      "command": "terraform",
      "args": ["plan"],
      "group": "build",
      "dependsOn": "terraform-init"
    },
    {
      "label": "terraform-apply",
      "type": "shell",
      "command": "terraform",
      "args": ["apply", "-auto-approve"],
      "group": "build",
      "dependsOn": "terraform-plan"
    }
  ]
}
```

## Exercise 4: Version Management with tfenv (45 minutes)
**Objective**: Set up and use tfenv for managing multiple Terraform versions

### Requirements
- Install tfenv
- Install multiple Terraform versions
- Switch between versions
- Test version-specific features

### Implementation Guide

#### Step 1: Install tfenv
```bash
# Clone tfenv repository
git clone https://github.com/tfutils/tfenv.git ~/.tfenv

# Add to PATH
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
tfenv --version
```

#### Step 2: Manage Terraform Versions
```bash
# List available versions
tfenv list-remote

# Install specific versions
tfenv install 1.6.0
tfenv install 1.5.7
tfenv install 1.4.6

# List installed versions
tfenv list

# Use specific version
tfenv use 1.6.0
terraform version

# Switch to different version
tfenv use 1.5.7
terraform version
```

#### Step 3: Version-Specific Testing
```bash
# Create version constraint test
mkdir version-test
cd version-test

# Test with version constraint
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.5.0, < 1.7.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

# Test with compatible version
tfenv use 1.6.0
terraform init

# Test with incompatible version (should fail)
tfenv use 1.4.6
terraform init  # This should show version constraint error

# Return to compatible version
tfenv use 1.6.0
```

#### Step 4: Automatic Version Selection
```bash
# Create .terraform-version file
echo "1.6.0" > .terraform-version

# tfenv will automatically use this version
cd version-test
terraform version  # Should show 1.6.0

# Test in different directory
cd ..
echo "1.5.7" > .terraform-version
terraform version  # Should show 1.5.7
```

## Exercise 5: Complete Environment Validation (30 minutes)
**Objective**: Comprehensive testing of entire Terraform setup

### Requirements
- Create a complete test project
- Test all installation components
- Validate AWS integration
- Verify IDE functionality

### Comprehensive Test Project
```bash
# Create test project
mkdir terraform-complete-test
cd terraform-complete-test

# Create main configuration
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "terraform-installation-test"
      Environment = "test"
      ManagedBy   = "terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "terraform-test"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "test" {
  bucket = "${var.bucket_prefix}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "test" {
  bucket = aws_s3_bucket.test.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test" {
  bucket = aws_s3_bucket.test.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "test_results" {
  description = "Installation test results"
  value = {
    terraform_version = "Terraform installation successful"
    aws_account_id    = data.aws_caller_identity.current.account_id
    aws_region        = data.aws_region.current.name
    bucket_name       = aws_s3_bucket.test.bucket
    bucket_arn        = aws_s3_bucket.test.arn
  }
}
EOF

# Create variables file
cat > terraform.tfvars << 'EOF'
aws_region    = "us-west-2"
bucket_prefix = "terraform-install-test"
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl

# IDE files
.vscode/
.idea/
EOF
```

### Complete Test Execution
```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Initialize
terraform init

# Plan deployment
terraform plan

# Apply (creates real resources - be careful!)
terraform apply

# Verify outputs
terraform output

# Clean up
terraform destroy

# Final verification
echo "✅ Terraform installation and configuration complete!"
```

### Validation Checklist
- [ ] Terraform commands execute without errors
- [ ] AWS authentication works correctly
- [ ] Provider downloads successfully
- [ ] Resources can be planned and applied
- [ ] IDE integration functions properly
- [ ] Version management works as expected

## Solutions and Explanations

### Exercise 1 Solution
The package manager installation provides the most reliable and maintainable approach. Key benefits include automatic updates and dependency management.

### Exercise 2 Solution
Multi-profile AWS configuration enables secure management of different environments and accounts. The profile-based approach prevents accidental resource creation in wrong accounts.

### Exercise 3 Solution
IDE integration significantly improves productivity with features like syntax highlighting, auto-completion, and real-time validation.

### Exercise 4 Solution
Version management with tfenv allows testing different Terraform versions and ensures compatibility with team environments.

### Exercise 5 Solution
The comprehensive test validates the entire installation stack and ensures all components work together correctly.

This hands-on approach ensures mastery of Terraform installation and configuration across all platforms and use cases.
