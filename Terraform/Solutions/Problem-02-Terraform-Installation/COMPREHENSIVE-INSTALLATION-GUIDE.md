# Problem 2: Terraform Installation - Complete Setup Guide

## Overview

This comprehensive guide covers all aspects of Terraform installation, configuration, and verification across different platforms and environments. You'll master multiple installation methods, AWS provider setup, IDE configuration, and troubleshooting techniques.

## Installation Methods Mastery

### 1. Package Manager Installation (Recommended)

#### macOS with Homebrew
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add HashiCorp tap
brew tap hashicorp/tap

# Install Terraform
brew install hashicorp/tap/terraform

# Verify installation
terraform version
# Expected output: Terraform v1.6.x

# Enable tab completion
terraform -install-autocomplete
```

#### Ubuntu/Debian Systems
```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify key fingerprint
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package index
sudo apt-get update

# Install Terraform
sudo apt-get install terraform

# Verify installation
terraform version
```

#### CentOS/RHEL/Fedora Systems
```bash
# Install yum-utils
sudo yum install -y yum-utils

# Add HashiCorp repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# For Fedora, use dnf instead
sudo dnf -y install terraform

# Verify installation
terraform version
```

### 2. Binary Installation (Manual)

#### Download and Install Process
```bash
# Set Terraform version
TERRAFORM_VERSION="1.6.0"

# Detect system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

# Detect operating system
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Download Terraform
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"

# Verify download (optional but recommended)
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig"

# Verify signature (requires GPG setup)
gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS

# Check SHA256 sum
sha256sum -c terraform_${TERRAFORM_VERSION}_SHA256SUMS 2>/dev/null | grep OK

# Extract binary
unzip terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip

# Make executable
chmod +x terraform

# Move to PATH
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version

# Clean up
rm terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip
rm terraform_${TERRAFORM_VERSION}_SHA256SUMS*
```

### 3. Docker-Based Installation

#### Using Official Terraform Docker Image
```bash
# Pull latest Terraform image
docker pull hashicorp/terraform:latest

# Create alias for convenience
echo 'alias terraform="docker run --rm -it -v $(pwd):/workspace -w /workspace hashicorp/terraform:latest"' >> ~/.bashrc
source ~/.bashrc

# Test installation
terraform version

# For persistent data and AWS credentials
docker run --rm -it \
  -v $(pwd):/workspace \
  -v ~/.aws:/root/.aws \
  -w /workspace \
  hashicorp/terraform:latest version
```

#### Custom Dockerfile for Team Use
```dockerfile
FROM hashicorp/terraform:1.6.0

# Install additional tools
RUN apk add --no-cache \
    aws-cli \
    curl \
    jq \
    git

# Set working directory
WORKDIR /workspace

# Copy common configuration
COPY .terraformrc /root/.terraformrc

# Set entrypoint
ENTRYPOINT ["terraform"]
```

## AWS CLI Setup and Configuration

### AWS CLI Installation

#### Using pip (Python)
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
# Expected: aws-cli/2.x.x

# Clean up
rm -rf awscliv2.zip aws/
```

#### Using Package Managers
```bash
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt-get install awscli

# CentOS/RHEL
sudo yum install awscli
```

### AWS Credentials Configuration

#### Method 1: AWS Configure Command
```bash
# Interactive configuration
aws configure

# You'll be prompted for:
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: us-west-2
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

#### Method 2: Environment Variables
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-west-2"
export AWS_DEFAULT_OUTPUT="json"

# Make permanent by adding to ~/.bashrc or ~/.zshrc
echo 'export AWS_ACCESS_KEY_ID="your-access-key-id"' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-access-key"' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION="us-west-2"' >> ~/.bashrc
```

#### Method 3: AWS Credentials File
```bash
# Create credentials file
mkdir -p ~/.aws

# Edit credentials file
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key

[production]
aws_access_key_id = prod-access-key-id
aws_secret_access_key = prod-secret-access-key

[development]
aws_access_key_id = dev-access-key-id
aws_secret_access_key = dev-secret-access-key
EOF

# Edit config file
cat > ~/.aws/config << EOF
[default]
region = us-west-2
output = json

[profile production]
region = us-east-1
output = json

[profile development]
region = us-west-2
output = table
EOF

# Set appropriate permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

## IDE Setup and Extensions

### Visual Studio Code Setup

#### Essential Extensions
```bash
# Install VS Code extensions via command line
code --install-extension hashicorp.terraform
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension amazonwebservices.aws-toolkit-vscode
```

#### VS Code Settings for Terraform
```json
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

### IntelliJ IDEA / PyCharm Setup

#### Plugin Installation
1. Go to File → Settings → Plugins
2. Search for "Terraform and HCL"
3. Install the plugin by JetBrains
4. Restart IDE

#### Configuration
```xml
<!-- .idea/terraform.xml -->
<component name="TerraformSettings">
  <option name="terraformPath" value="/usr/local/bin/terraform" />
  <option name="enableAutoFormat" value="true" />
  <option name="enableValidation" value="true" />
</component>
```

### Vim/Neovim Setup

#### Plugin Installation with vim-plug
```vim
" Add to ~/.vimrc or ~/.config/nvim/init.vim
Plug 'hashivim/vim-terraform'
Plug 'vim-syntastic/syntastic'
Plug 'juliosueiras/vim-terraform-completion'

" Terraform-specific settings
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1

" Syntastic configuration
let g:syntastic_terraform_tffilter_plan = 1
```

## Version Management with tfenv

### tfenv Installation
```bash
# Clone tfenv repository
git clone https://github.com/tfutils/tfenv.git ~/.tfenv

# Add to PATH
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Or create symlinks
sudo ln -s ~/.tfenv/bin/* /usr/local/bin/
```

### tfenv Usage
```bash
# List available Terraform versions
tfenv list-remote

# Install specific version
tfenv install 1.6.0
tfenv install 1.5.7
tfenv install latest

# List installed versions
tfenv list

# Use specific version
tfenv use 1.6.0

# Set default version
tfenv use default 1.6.0

# Install and use latest version
tfenv install latest
tfenv use latest
```

## Verification and Testing

### Basic Verification Steps
```bash
# Check Terraform version
terraform version

# Check available commands
terraform help

# Verify AWS CLI
aws --version
aws sts get-caller-identity

# Test basic Terraform functionality
mkdir terraform-test
cd terraform-test

# Create simple test configuration
cat > main.tf << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
EOF

# Initialize and test
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve

# Clean up
cd ..
rm -rf terraform-test
```

### Advanced Verification
```bash
# Test provider download
terraform init -upgrade

# Validate configuration
terraform validate

# Format check
terraform fmt -check

# Security scan (if tfsec is installed)
tfsec .

# Plan with detailed output
terraform plan -detailed-exitcode
```

## Troubleshooting Common Issues

### Permission Issues
```bash
# Fix binary permissions
sudo chmod +x /usr/local/bin/terraform

# Fix AWS credentials permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config

# Fix directory permissions
sudo chown -R $USER:$USER ~/.terraform.d/
```

### PATH Issues
```bash
# Check current PATH
echo $PATH

# Add Terraform to PATH permanently
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify Terraform is in PATH
which terraform
```

### AWS Authentication Issues
```bash
# Debug AWS credentials
aws configure list
aws configure list-profiles

# Test different profiles
aws sts get-caller-identity --profile production

# Debug with verbose output
aws sts get-caller-identity --debug
```

### Provider Download Issues
```bash
# Clear provider cache
rm -rf .terraform/

# Reinitialize with debug
TF_LOG=DEBUG terraform init

# Use alternative registry
terraform init -plugin-dir=/path/to/plugins
```

## Security Best Practices

### Credential Security
- Never commit AWS credentials to version control
- Use IAM roles when possible (EC2, Lambda, etc.)
- Rotate access keys regularly
- Use least privilege principle for IAM policies
- Enable MFA for AWS accounts

### Terraform Security
- Pin provider versions
- Use remote state with encryption
- Enable state locking
- Scan configurations with security tools
- Use .gitignore for sensitive files

### Example .gitignore
```gitignore
# Terraform files
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl

# Crash log files
crash.log

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
```

This comprehensive guide ensures successful Terraform installation and configuration across all platforms and use cases.
