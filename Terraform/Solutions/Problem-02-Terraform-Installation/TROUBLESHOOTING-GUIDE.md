# Problem 2: Terraform Installation - Troubleshooting Guide

## Common Installation Issues

### Issue 1: Terraform Command Not Found
**Problem**: `terraform: command not found` after installation
**Symptoms**: 
- Shell cannot find terraform binary
- PATH environment variable issues
- Installation completed but command unavailable

**Root Causes**:
- Binary not in PATH
- Incorrect installation location
- Shell not reloaded after installation
- Permission issues with binary

**Solutions**:
```bash
# Check if terraform is installed
which terraform
whereis terraform

# Add to PATH manually
export PATH="/usr/local/bin:$PATH"

# Make permanent
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Fix permissions
sudo chmod +x /usr/local/bin/terraform

# Verify installation
terraform version
```

**Prevention**:
- Use package managers when possible
- Verify PATH after installation
- Test in new shell session
- Document installation steps

### Issue 2: AWS CLI Authentication Failures
**Problem**: AWS authentication errors during terraform operations
**Symptoms**:
```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found
```

**Root Causes**:
- Missing AWS credentials
- Incorrect credential configuration
- Expired access keys
- Wrong AWS profile selected

**Solutions**:
```bash
# Check current credentials
aws configure list
aws sts get-caller-identity

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Test specific profile
aws sts get-caller-identity --profile production

# Debug credential chain
export AWS_PROFILE=development
aws sts get-caller-identity

# Environment variable method
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-west-2"
```

**Prevention**:
- Regular credential rotation
- Use IAM roles when possible
- Proper profile management
- Credential validation testing

### Issue 3: Provider Download Failures
**Problem**: Terraform cannot download required providers
**Symptoms**:
```
Error: Failed to install provider from shared cache
Error: Could not retrieve the list of available versions
```

**Root Causes**:
- Network connectivity issues
- Corporate firewall restrictions
- Registry access problems
- Disk space limitations

**Solutions**:
```bash
# Clear provider cache
rm -rf .terraform/
rm .terraform.lock.hcl

# Reinitialize with debug
TF_LOG=DEBUG terraform init

# Use alternative registry
terraform init -plugin-dir=/path/to/plugins

# Manual provider download
mkdir -p .terraform/providers/
# Download and extract providers manually

# Check network connectivity
curl -I https://registry.terraform.io/

# Proxy configuration
export HTTPS_PROXY=http://proxy.company.com:8080
terraform init
```

**Prevention**:
- Configure corporate proxy settings
- Use local provider mirrors
- Pre-download providers for offline use
- Monitor network connectivity

## Advanced Troubleshooting

### Issue 4: Version Compatibility Problems
**Problem**: Terraform version conflicts with providers or configurations
**Symptoms**:
```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version 1.x.x
```

**Root Causes**:
- Version constraints in configuration
- Provider compatibility issues
- Team using different versions
- Legacy configuration requirements

**Solutions**:
```bash
# Check current version
terraform version

# Install specific version with tfenv
tfenv install 1.5.7
tfenv use 1.5.7

# Update version constraints
# In versions.tf:
terraform {
  required_version = ">= 1.5.0"
}

# Check provider compatibility
terraform providers

# Upgrade providers
terraform init -upgrade
```

**Prevention**:
- Use version constraints in configurations
- Standardize team Terraform versions
- Regular version updates and testing
- Document version requirements

### Issue 5: IDE Integration Problems
**Problem**: VS Code or other IDE not recognizing Terraform files
**Symptoms**:
- No syntax highlighting
- No auto-completion
- Format on save not working
- Validation errors not shown

**Root Causes**:
- Extension not installed
- Incorrect file associations
- Extension configuration issues
- Terraform binary not found by extension

**Solutions**:
```bash
# Install VS Code extension
code --install-extension hashicorp.terraform

# Check extension status
code --list-extensions | grep terraform

# Configure file associations
# In VS Code settings.json:
{
  "files.associations": {
    "*.tf": "terraform",
    "*.tfvars": "terraform"
  },
  "terraform.format.enable": true,
  "terraform.lint.enable": true
}

# Verify terraform path in extension settings
# Point to correct terraform binary location
```

**Prevention**:
- Install extensions during initial setup
- Configure settings properly
- Test IDE functionality after installation
- Keep extensions updated

### Issue 6: Permission and Security Issues
**Problem**: Permission denied errors during installation or execution
**Symptoms**:
```
Permission denied: /usr/local/bin/terraform
sudo: terraform: command not found
```

**Root Causes**:
- Insufficient permissions for installation
- Binary ownership issues
- Security policies blocking execution
- Incorrect file permissions

**Solutions**:
```bash
# Fix binary permissions
sudo chmod +x /usr/local/bin/terraform
sudo chown root:root /usr/local/bin/terraform

# Install to user directory
mkdir -p ~/bin
mv terraform ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Use package manager (recommended)
brew install hashicorp/tap/terraform  # macOS
sudo apt install terraform            # Ubuntu

# Check security policies
# Consult system administrator for corporate policies
```

**Prevention**:
- Use package managers when possible
- Follow principle of least privilege
- Document security requirements
- Test in similar environments

## Platform-Specific Issues

### macOS Issues
```bash
# Homebrew not found
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Gatekeeper blocking execution
sudo spctl --master-disable  # Not recommended for security
# Or: System Preferences > Security & Privacy > Allow apps downloaded from anywhere

# M1/M2 chip compatibility
arch -arm64 brew install hashicorp/tap/terraform
```

### Linux Issues
```bash
# Missing dependencies
sudo apt update
sudo apt install -y gnupg software-properties-common curl

# Repository key issues
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# SELinux issues (CentOS/RHEL)
sudo setsebool -P httpd_can_network_connect 1
```

### Windows Issues
```powershell
# PowerShell execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Chocolatey installation
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform

# PATH issues
$env:PATH += ";C:\ProgramData\chocolatey\bin"
```

## Debugging Tools and Techniques

### Environment Debugging
```bash
# Check environment variables
env | grep -i terraform
env | grep -i aws

# Verify PATH
echo $PATH
which terraform
which aws

# Check shell configuration
cat ~/.bashrc | grep -i terraform
cat ~/.zshrc | grep -i terraform
```

### Network Debugging
```bash
# Test connectivity
curl -I https://registry.terraform.io/
curl -I https://releases.hashicorp.com/

# DNS resolution
nslookup registry.terraform.io
dig registry.terraform.io

# Proxy settings
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

### Log Analysis
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Analyze logs
grep -i error terraform-debug.log
grep -i "failed" terraform-debug.log

# AWS CLI debug
aws --debug sts get-caller-identity
```

## Recovery Procedures

### Complete Reinstallation
```bash
# Remove existing installation
sudo rm -f /usr/local/bin/terraform
rm -rf ~/.terraform.d/

# Clear cache
rm -rf .terraform/
rm .terraform.lock.hcl

# Reinstall using package manager
brew uninstall terraform
brew install hashicorp/tap/terraform

# Verify clean installation
terraform version
terraform init
```

### Configuration Reset
```bash
# Reset AWS configuration
rm -rf ~/.aws/
aws configure

# Reset Terraform configuration
rm -rf ~/.terraform.d/
terraform init

# Reset IDE settings
# Remove and reinstall extensions
# Reset workspace settings
```

## Prevention Best Practices

### Installation Checklist
- [ ] Use package managers when possible
- [ ] Verify installation in clean environment
- [ ] Test all functionality before proceeding
- [ ] Document installation steps
- [ ] Create installation scripts for teams

### Maintenance Procedures
- [ ] Regular version updates
- [ ] Credential rotation schedule
- [ ] Extension and tool updates
- [ ] Environment validation testing
- [ ] Backup configuration files

This comprehensive troubleshooting guide helps resolve common installation issues and establishes reliable Terraform development environments.
