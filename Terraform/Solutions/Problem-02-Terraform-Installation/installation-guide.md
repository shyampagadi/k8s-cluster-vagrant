# Terraform Installation Guide

## Overview

This guide provides comprehensive installation instructions for Terraform CLI on Windows, macOS, and Linux systems. Choose the method that best fits your environment and preferences.

## Prerequisites

- Administrative privileges (for system-wide installation)
- Internet connection for downloading Terraform
- Basic command-line knowledge

## Installation Methods

### 1. Windows Installation

#### Method 1: Using Chocolatey (Recommended)

Chocolatey is a package manager for Windows that simplifies software installation.

**Step 1: Install Chocolatey**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Step 2: Install Terraform**
```powershell
# Install Terraform
choco install terraform

# Verify installation
terraform version
```

**Benefits:**
- Easy installation and updates
- Automatic PATH configuration
- Dependency management
- Easy uninstallation

#### Method 2: Using Scoop

Scoop is a command-line installer for Windows that doesn't require administrative privileges.

**Step 1: Install Scoop**
```powershell
# Run PowerShell (not as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Step 2: Install Terraform**
```powershell
# Install Terraform
scoop install terraform

# Verify installation
terraform version
```

**Benefits:**
- No administrative privileges required
- User-specific installation
- Easy updates and management

#### Method 3: Manual Installation

**Step 1: Download Terraform**
```powershell
# Download Terraform (replace version with latest)
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_windows_amd64.zip" -OutFile "terraform.zip"
```

**Step 2: Extract and Install**
```powershell
# Extract to C:\terraform
Expand-Archive -Path "terraform.zip" -DestinationPath "C:\terraform"

# Add to PATH (temporary)
$env:PATH += ";C:\terraform"

# Add to PATH permanently
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\terraform", [EnvironmentVariableTarget]::User)
```

**Step 3: Verify Installation**
```powershell
# Restart PowerShell and verify
terraform version
```

### 2. macOS Installation

#### Method 1: Using Homebrew (Recommended)

Homebrew is the most popular package manager for macOS.

**Step 1: Install Homebrew**
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (if needed)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Step 2: Install Terraform**
```bash
# Install Terraform
brew install terraform

# Verify installation
terraform version
```

**Benefits:**
- Easy installation and updates
- Automatic PATH configuration
- Dependency management
- Easy uninstallation

#### Method 2: Manual Installation

**Step 1: Download Terraform**
```bash
# Download Terraform (replace version with latest)
curl -O https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_darwin_amd64.zip
```

**Step 2: Extract and Install**
```bash
# Extract Terraform
unzip terraform_1.5.0_darwin_amd64.zip

# Move to /usr/local/bin
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

**Step 3: Clean Up**
```bash
# Remove downloaded file
rm terraform_1.5.0_darwin_amd64.zip
```

### 3. Linux Installation

#### Method 1: Using Package Manager

**Ubuntu/Debian:**
```bash
# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Update package list
sudo apt-get update

# Install Terraform
sudo apt-get install terraform

# Verify installation
terraform version
```

**CentOS/RHEL/Fedora:**
```bash
# Install yum-utils
sudo yum install -y yum-utils

# Add HashiCorp repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# Verify installation
terraform version
```

**Arch Linux:**
```bash
# Install Terraform
sudo pacman -S terraform

# Verify installation
terraform version
```

#### Method 2: Manual Installation

**Step 1: Download Terraform**
```bash
# Download Terraform (replace version with latest)
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
```

**Step 2: Extract and Install**
```bash
# Extract Terraform
unzip terraform_1.5.0_linux_amd64.zip

# Move to /usr/local/bin
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

**Step 3: Clean Up**
```bash
# Remove downloaded file
rm terraform_1.5.0_linux_amd64.zip
```

## Verification

### Check Installation
```bash
# Check Terraform version
terraform version

# Expected output:
# Terraform v1.5.0
# on linux_amd64
```

### Check PATH
```bash
# Check if Terraform is in PATH
which terraform
# or
where terraform

# Expected output:
# /usr/local/bin/terraform
```

### Test Basic Functionality
```bash
# Test Terraform help
terraform help

# Test Terraform init (in empty directory)
mkdir test-terraform
cd test-terraform
terraform init
```

## Troubleshooting

### Common Issues

#### 1. Command Not Found
**Problem:** `terraform: command not found`
**Solution:**
```bash
# Check if Terraform is in PATH
echo $PATH

# Add Terraform to PATH
export PATH=$PATH:/path/to/terraform

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH=$PATH:/path/to/terraform' >> ~/.bashrc
source ~/.bashrc
```

#### 2. Permission Denied
**Problem:** `Permission denied` when running Terraform
**Solution:**
```bash
# Make Terraform executable
chmod +x terraform

# Or install with sudo
sudo mv terraform /usr/local/bin/
```

#### 3. Version Mismatch
**Problem:** Wrong Terraform version installed
**Solution:**
```bash
# Uninstall old version
# Windows: choco uninstall terraform
# macOS: brew uninstall terraform
# Linux: sudo apt-get remove terraform

# Install correct version
# Follow installation steps above
```

#### 4. Download Issues
**Problem:** Cannot download Terraform
**Solution:**
```bash
# Check internet connection
ping google.com

# Try alternative download method
# Use browser to download from https://releases.hashicorp.com/terraform/
```

### Platform-Specific Issues

#### Windows
- **PowerShell Execution Policy:** Set execution policy to allow script execution
- **Antivirus Software:** May block Terraform download or execution
- **Windows Defender:** May quarantine Terraform executable

#### macOS
- **Gatekeeper:** May block unsigned applications
- **Homebrew Issues:** May need to update Homebrew or fix permissions
- **Architecture:** Ensure you download the correct architecture (Intel vs Apple Silicon)

#### Linux
- **Package Manager Issues:** May need to update package lists
- **Dependencies:** May need to install additional dependencies
- **Permissions:** May need to use sudo for system-wide installation

## Uninstallation

### Windows
```powershell
# Chocolatey
choco uninstall terraform

# Scoop
scoop uninstall terraform

# Manual
# Remove from PATH and delete files
```

### macOS
```bash
# Homebrew
brew uninstall terraform

# Manual
sudo rm /usr/local/bin/terraform
```

### Linux
```bash
# Package Manager
sudo apt-get remove terraform
# or
sudo yum remove terraform

# Manual
sudo rm /usr/local/bin/terraform
```

## Best Practices

### 1. Version Management
- Pin Terraform version in your projects
- Use version constraints in provider blocks
- Test with different Terraform versions

### 2. Security
- Download Terraform from official sources only
- Verify checksums when downloading manually
- Keep Terraform updated for security patches

### 3. Environment Setup
- Use consistent installation methods across team
- Document installation process for team members
- Set up development environment consistently

### 4. Backup and Recovery
- Keep installation scripts and configurations
- Document custom configurations
- Have recovery procedures ready

## Next Steps

After successful installation:

1. **Verify Installation:** Run `terraform version`
2. **Set Up AWS CLI:** Configure AWS credentials
3. **Create First Project:** Follow Problem 02 solution
4. **Learn Basic Commands:** Practice init, plan, apply, destroy

## Additional Resources

- [Terraform Official Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [HashiCorp Releases](https://releases.hashicorp.com/terraform/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Community Forums](https://discuss.hashicorp.com/c/terraform-core)

## Conclusion

Terraform installation is straightforward with the right method for your platform. Choose the installation method that best fits your environment:

- **Windows:** Use Chocolatey or Scoop for easy management
- **macOS:** Use Homebrew for seamless integration
- **Linux:** Use package manager for system integration

After installation, verify the setup and proceed to create your first Terraform project. Remember to keep Terraform updated and follow security best practices.
