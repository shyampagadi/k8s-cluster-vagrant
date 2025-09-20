# Problem 1: IaC Fundamentals - Hands-On Exercises

## 🎯 Exercise 1: Traditional vs IaC Comparison (30 min)

### Manual Infrastructure Setup
```bash
# Traditional approach - manual AWS setup
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --count 1 \
  --instance-type t3.micro \
  --key-name my-key \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678

# Manual S3 bucket creation
aws s3 mb s3://my-manual-bucket-$(date +%s)

# Manual security group
aws ec2 create-security-group \
  --group-name manual-sg \
  --description "Manually created security group"
```

### IaC Approach - Terraform
```hcl
# main.tf - Infrastructure as Code
terraform {
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

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id             = var.subnet_id
  
  tags = {
    Name = "IaC-Demo-Instance"
    Type = "Demo"
  }
}

resource "aws_s3_bucket" "demo" {
  bucket = "iac-demo-bucket-${random_id.suffix.hex}"
  
  tags = {
    Purpose = "IaC Demonstration"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "iac-demo-"
  description = "IaC Demo Security Group"
  
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

resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

## 🎯 Exercise 2: Version Control Integration (45 min)

### Git Repository Setup
```bash
# Initialize Git repository
git init terraform-iac-demo
cd terraform-iac-demo

# Create .gitignore for Terraform
cat > .gitignore << EOF
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
*.tfplan

# OS files
.DS_Store
Thumbs.db
EOF

# Initial commit
git add .
git commit -m "Initial IaC project setup"
```

### Infrastructure Evolution Tracking
```hcl
# Version 1: Basic infrastructure
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  tags = {
    Name    = "Web Server"
    Version = "1.0"
  }
}
```

```bash
git add .
git commit -m "v1.0: Basic web server infrastructure"
```

```hcl
# Version 2: Add monitoring
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  monitoring    = true
  
  tags = {
    Name    = "Web Server"
    Version = "2.0"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  
  dimensions = {
    InstanceId = aws_instance.web.id
  }
}
```

```bash
git add .
git commit -m "v2.0: Add CloudWatch monitoring"
```

## 🎯 Exercise 3: IaC Benefits Demonstration (60 min)

### Reproducibility Test
```bash
# Deploy infrastructure
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Document current state
terraform show > infrastructure-state-v1.txt

# Destroy and recreate
terraform destroy -auto-approve
terraform apply -auto-approve

# Verify identical recreation
terraform show > infrastructure-state-v2.txt
diff infrastructure-state-v1.txt infrastructure-state-v2.txt
```

### Multi-Environment Deployment
```hcl
# environments/dev.tfvars
environment = "development"
instance_type = "t3.micro"
enable_monitoring = false

# environments/prod.tfvars  
environment = "production"
instance_type = "t3.small"
enable_monitoring = true
```

```bash
# Deploy to different environments
terraform workspace new development
terraform apply -var-file="environments/dev.tfvars"

terraform workspace new production  
terraform apply -var-file="environments/prod.tfvars"
```

## 🎯 Exercise 4: IaC Testing and Validation (45 min)

### Terraform Validation
```bash
# Format check
terraform fmt -check

# Validation
terraform validate

# Security scanning
tfsec .

# Plan analysis
terraform plan -detailed-exitcode
```

### Infrastructure Testing
```hcl
# test/main_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraformInfrastructure(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "instance_type": "t3.micro",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    instanceId := terraform.Output(t, terraformOptions, "instance_id")
    assert.NotEmpty(t, instanceId)
}
```

## 🎯 Exercise 5: IaC Best Practices Implementation (90 min)

### Modular Structure
```
project/
├── main.tf
├── variables.tf  
├── outputs.tf
├── modules/
│   ├── compute/
│   ├── networking/
│   └── storage/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── tests/
```

### Security Implementation
```hcl
# Security best practices
resource "aws_s3_bucket" "secure" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secure" {
  bucket = aws_s3_bucket.secure.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Documentation Standards
```hcl
# Well-documented infrastructure
resource "aws_instance" "web" {
  # Use latest Amazon Linux 2 AMI
  ami           = data.aws_ami.amazon_linux.id
  
  # Right-sized for development workloads
  instance_type = var.instance_type
  
  # Enable detailed monitoring for production
  monitoring = var.environment == "production"
  
  # Apply consistent tagging strategy
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-server"
    Role = "web"
  })
}
```

## 📊 Success Validation

### Completion Checklist
- [ ] Compare manual vs IaC approaches
- [ ] Implement version control workflow
- [ ] Demonstrate infrastructure reproducibility
- [ ] Deploy to multiple environments
- [ ] Validate and test infrastructure code
- [ ] Apply security best practices
- [ ] Document infrastructure properly

### Learning Outcomes
- Understanding of IaC principles and benefits
- Hands-on experience with Terraform basics
- Version control integration skills
- Multi-environment deployment patterns
- Infrastructure testing and validation
- Security and documentation best practices
