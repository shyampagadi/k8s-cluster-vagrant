# Terraform Installation and Setup - Comprehensive Guide

## Installation Methods

### 1. Package Manager Installation

#### macOS (Homebrew)
```bash
# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

#### Ubuntu/Debian
```bash
# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Install Terraform
sudo apt-get update && sudo apt-get install terraform

# Verify installation
terraform version
```

#### CentOS/RHEL/Fedora
```bash
# Add HashiCorp repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# Verify installation
terraform version
```

### 2. Binary Installation

#### Download and Install
```bash
# Download latest version (replace with current version)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Unzip
unzip terraform_1.6.0_linux_amd64.zip

# Move to PATH
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### 3. Docker Installation
```bash
# Run Terraform in Docker
docker run --rm -it -v $(pwd):/workspace -w /workspace hashicorp/terraform:latest version

# Create alias for convenience
alias terraform='docker run --rm -it -v $(pwd):/workspace -w /workspace hashicorp/terraform:latest'
```

## AWS CLI Setup

### Installation
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### Configuration
```bash
# Configure AWS credentials
aws configure

# Enter your credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-west-2
# Default output format: json
```

### Alternative: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

## IDE Setup and Extensions

### VS Code Extensions
- **HashiCorp Terraform**: Official extension with syntax highlighting
- **Terraform**: Community extension with additional features
- **AWS Toolkit**: AWS resource management

### IntelliJ/PyCharm
- **Terraform and HCL**: JetBrains plugin

### Vim/Neovim
```bash
# Install vim-terraform
git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
```

## Version Management

### tfenv (Terraform Version Manager)
```bash
# Install tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc

# Install specific Terraform version
tfenv install 1.6.0
tfenv use 1.6.0

# List available versions
tfenv list-remote
```

## Verification and Testing

### Basic Verification
```bash
# Check Terraform version
terraform version

# Check available commands
terraform help

# Validate installation with simple config
terraform init
terraform plan
```

### AWS Provider Test
```bash
# Test AWS connectivity
aws sts get-caller-identity

# Test Terraform with AWS
terraform init
terraform plan
```

## Troubleshooting Common Issues

### Permission Issues
```bash
# Fix binary permissions
chmod +x /usr/local/bin/terraform

# Fix AWS credentials
chmod 600 ~/.aws/credentials
```

### PATH Issues
```bash
# Add to PATH permanently
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### AWS Authentication Issues
```bash
# Check credentials
aws configure list

# Test authentication
aws sts get-caller-identity
```

## Best Practices

1. **Version Pinning**: Use specific Terraform versions in CI/CD
2. **Credential Security**: Never commit AWS credentials to version control
3. **Regular Updates**: Keep Terraform and providers updated
4. **Backup**: Backup state files and configurations
5. **Testing**: Test installations in isolated environments
