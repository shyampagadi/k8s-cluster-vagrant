# Terraform Solutions: Complete Implementation Guide

## Table of Contents
1. [Foundation Level Solutions](#foundation-level-solutions)
2. [Intermediate Level Solutions](#intermediate-level-solutions)
3. [Advanced Level Solutions](#advanced-level-solutions)
4. [Expert Level Solutions](#expert-level-solutions)
5. [Production Scenarios Solutions](#production-scenarios-solutions)

---

## Foundation Level Solutions - ROCK-SOLID FOUNDATION

### Solution 1: Understanding Infrastructure as Code and Terraform Concepts

#### Infrastructure as Code (IaC) Explanation:
```markdown
Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than through physical hardware configuration or interactive configuration tools.

Key Benefits:
- Version Control: Infrastructure changes are tracked in version control
- Consistency: Same infrastructure across environments
- Automation: Reduces manual errors and speeds up deployment
- Documentation: Infrastructure is self-documenting
- Collaboration: Teams can work together on infrastructure changes
```

#### Terraform Architecture Understanding:
```markdown
Terraform Architecture Components:

1. Terraform Core:
   - Reads configuration files
   - Manages state
   - Creates execution plans
   - Applies changes

2. Terraform Providers:
   - AWS, Azure, GCP, etc.
   - Translate Terraform configuration to API calls
   - Handle authentication and resource management

3. State Management:
   - Tracks current state of infrastructure
   - Enables Terraform to determine what changes are needed
   - Critical for team collaboration

4. Configuration Language (HCL):
   - Human-readable configuration syntax
   - Supports variables, functions, and expressions
```

#### Terraform vs Other IaC Tools:
```markdown
Comparison Chart:

| Tool | Type | Language | State Management | Multi-Cloud |
|------|------|----------|------------------|-------------|
| Terraform | Declarative | HCL | Yes | Yes |
| CloudFormation | Declarative | JSON/YAML | Yes | AWS Only |
| Pulumi | Imperative | Programming Languages | Yes | Yes |
| Ansible | Imperative | YAML | No | Yes |

Terraform Advantages:
- Multi-cloud support
- Large provider ecosystem
- Strong state management
- Declarative approach
- Active community
```

---

### Solution 2: Terraform Installation and First Steps

#### Installation Commands with Explanations:
```bash
# Windows (using Chocolatey)
choco install terraform
# Chocolatey is a package manager for Windows that simplifies software installation

# macOS (using Homebrew)
brew install terraform
# Homebrew is a package manager for macOS that manages software installations

# Linux (using manual installation)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
# Manual installation gives you control over the exact version
```

#### Understanding Terraform File Structure:
```markdown
Terraform File Naming Conventions:
- .tf files: Main configuration files
- .tfvars files: Variable definition files
- .tfstate files: State files (auto-generated)
- .tfstate.backup files: State backup files

Common File Names:
- main.tf: Primary configuration file
- variables.tf: Variable definitions
- outputs.tf: Output definitions
- providers.tf: Provider configurations
- terraform.tfvars: Default variable values
```

#### First Resource with Full Understanding:
```hcl
# terraform block - specifies Terraform and provider requirements
terraform {
  required_version = ">= 1.0"  # Minimum Terraform version
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Provider source
      version = "~> 5.0"         # Version constraint (~> allows patch updates)
    }
  }
}

# provider block - configures the AWS provider
provider "aws" {
  region = "us-west-2"  # AWS region for resources
}

# resource block - defines an AWS S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "My First Bucket"
    Environment = "Development"
  }
}

# resource block - generates random ID for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4  # 4 bytes = 8 hex characters
}
```

#### Understanding Terraform Workflow:
```bash
# Step 1: Initialize Terraform
terraform init
# Downloads providers, sets up backend, creates .terraform directory
# This is REQUIRED before any other commands

# Step 2: Plan the deployment
terraform plan
# Shows what Terraform will do without making changes
# Displays resources to be created, updated, or destroyed
# Always run this before apply in production

# Step 3: Apply the configuration
terraform apply
# Actually creates/modifies/destroys resources
# Shows the same plan and asks for confirmation
# Can be automated with -auto-approve flag

# Step 4: Show current state
terraform show
# Displays the current state of all resources
# Useful for debugging and understanding current infrastructure

# Step 5: Destroy resources (when done)
terraform destroy
# Destroys all resources defined in the configuration
# Shows what will be destroyed and asks for confirmation
```

#### Understanding What Happens During Each Command:
```markdown
terraform init:
- Downloads provider plugins to .terraform/providers/
- Initializes backend configuration
- Creates .terraform directory structure
- Downloads modules if any are used

terraform plan:
- Reads configuration files
- Refreshes state (checks current resource status)
- Creates execution plan
- Shows what changes will be made
- Does NOT make any changes

terraform apply:
- Shows the same plan as terraform plan
- Asks for confirmation (unless -auto-approve)
- Creates/modifies/destroys resources
- Updates state file
- Shows results of operations

terraform destroy:
- Shows what will be destroyed
- Asks for confirmation
- Destroys all resources
- Updates state file
- Removes resources from state
```

#### AWS Authentication Setup:
```bash
# Method 1: AWS CLI configuration
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format

# Method 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Method 3: IAM roles (recommended for EC2 instances)
# Attach IAM role to EC2 instance with appropriate permissions
```

---

### Solution 3: HCL Syntax Deep Dive

#### Understanding HCL Syntax Rules:
```markdown
HCL (HashiCorp Configuration Language) Syntax Rules:

1. Comments:
   - Single line: # This is a comment
   - Multi-line: /* This is a multi-line comment */

2. Identifiers:
   - Must start with letter or underscore
   - Can contain letters, numbers, underscores, hyphens
   - Case sensitive

3. Strings:
   - Single quotes: 'literal string'
   - Double quotes: "string with ${interpolation}"
   - Heredoc: <<EOF ... EOF

4. Numbers:
   - Integers: 42, -17
   - Floats: 3.14, -2.5

5. Booleans:
   - true, false (lowercase)
```

#### HCL Constructs Deep Dive:
```hcl
# 1. Blocks - containers for other content
resource "aws_instance" "example" {
  # Block type: resource
  # Block label: aws_instance
  # Block name: example
  # Block body: { ... }
}

# 2. Arguments - assign values to names
ami           = "ami-0c02fb55956c7d316"  # String argument
instance_type = "t2.micro"                # String argument
count         = 3                        # Number argument
monitoring    = true                      # Boolean argument

# 3. Expressions - references to values
# Literal expressions
"hello world"
42
true

# Reference expressions
var.instance_type
aws_instance.example.id
data.aws_ami.amazon_linux.id

# Function calls
length(var.subnet_ids)
upper(var.environment)
```

#### Data Types in HCL:
```hcl
# Strings
single_quoted = 'This is a literal string'
double_quoted = "This string has ${var.interpolation}"
heredoc_string = <<EOF
This is a multi-line string
that can span multiple lines
EOF

# Numbers
integer_number = 42
negative_number = -17
float_number = 3.14159

# Booleans
true_value = true
false_value = false

# Lists
string_list = ["item1", "item2", "item3"]
number_list = [1, 2, 3, 4, 5]
mixed_list = ["string", 42, true]

# Maps
simple_map = {
  key1 = "value1"
  key2 = "value2"
}

nested_map = {
  environment = "production"
  settings = {
    min_size = 1
    max_size = 10
  }
}
```

#### String Interpolation and Expressions:
```hcl
# Basic interpolation
bucket_name = "my-bucket-${var.environment}"

# Complex interpolation
instance_name = "${var.project_name}-${var.environment}-${count.index + 1}"

# Function calls in interpolation
formatted_name = "instance-${upper(var.environment)}-${formatdate("YYYY-MM-DD", timestamp())}"

# Conditional expressions
instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"

# Mathematical expressions
total_cost = var.instance_count * var.hourly_rate * 24

# String functions
formatted_tags = {
  Name = "${title(var.project_name)} ${title(var.environment)} Instance"
  Environment = upper(var.environment)
}
```

#### Attribute References and Resource Addressing:
```hcl
# Basic attribute reference
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}

# Reference from another resource
resource "aws_security_group" "web" {
  name = "web-sg"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Reference with count
resource "aws_instance" "web" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "web-instance-${count.index + 1}"
  }
}

# Reference with for_each
resource "aws_instance" "app" {
  for_each = var.environments
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  tags = {
    Name        = "app-${each.key}"
    Environment = each.key
  }
}

# Cross-referencing resources
resource "aws_instance" "database" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [aws_security_group.database.id]
  subnet_id              = aws_subnet.private.id
}
```

#### Multi-line Strings and Heredoc:
```hcl
# Heredoc syntax for multi-line strings
user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from Terraform!</h1>" > /var/www/html/index.html
EOF

# Heredoc with interpolation
user_data = <<EOF
#!/bin/bash
echo "Environment: ${var.environment}" > /etc/environment
echo "Database: ${aws_db_instance.main.endpoint}" >> /etc/environment
EOF

# Indented heredoc
user_data = <<-EOF
  #!/bin/bash
  # This script will be indented
  yum update -y
  yum install -y httpd
EOF
```

---

### Solution 4: Provider Ecosystem Understanding

#### variables.tf - All Variable Types
```hcl
# String variable
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
  
  validation {
    condition     = length(var.project_name) > 2
    error_message = "Project name must be at least 3 characters long."
  }
}

# Number variable
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Boolean variable
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

# List variable
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# Set variable
variable "allowed_ports" {
  description = "Set of allowed ports"
  type        = set(number)
  default     = [80, 443, 22]
}

# Map variable
variable "environment_tags" {
  description = "Tags for different environments"
  type        = map(string)
  default = {
    dev  = "Development"
    prod = "Production"
    test = "Testing"
  }
}

# Object variable
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    instance_class = string
    allocated_storage = number
    multi_az       = bool
  })
  default = {
    engine           = "mysql"
    instance_class   = "db.t3.micro"
    allocated_storage = 20
    multi_az         = false
  }
}

# Tuple variable
variable "network_config" {
  description = "Network configuration"
  type = tuple([string, number, bool])
  default = ["10.0.0.0/16", 24, true]
}

# Complex nested object
variable "application_config" {
  description = "Application configuration"
  type = object({
    name = string
    environment = string
    scaling = object({
      min_capacity = number
      max_capacity = number
      target_cpu   = number
    })
    networking = object({
      vpc_cidr     = string
      subnets = list(object({
        name       = string
        cidr_block = string
        az         = string
      }))
    })
  })
  default = {
    name = "my-app"
    environment = "dev"
    scaling = {
      min_capacity = 1
      max_capacity = 10
      target_cpu   = 70
    }
    networking = {
      vpc_cidr = "10.0.0.0/16"
      subnets = [
        {
          name       = "public-1"
          cidr_block = "10.0.1.0/24"
          az         = "us-west-2a"
        },
        {
          name       = "public-2"
          cidr_block = "10.0.2.0/24"
          az         = "us-west-2b"
        }
      ]
    }
  }
}
```

#### terraform.tfvars
```hcl
project_name = "my-terraform-project"
instance_count = 3
enable_monitoring = true
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
allowed_ports = [80, 443, 22, 8080]
environment_tags = {
  dev  = "Development"
  prod = "Production"
  test = "Testing"
  staging = "Staging"
}
```

#### Variable Precedence Examples:
```bash
# Command line variables (highest precedence)
terraform apply -var="project_name=cli-project"

# Environment variables
export TF_VAR_project_name="env-project"
terraform apply

# .tfvars files
terraform apply -var-file="production.tfvars"

# Default values (lowest precedence)
# Used when no other value is provided
```

---

### Solution 3: Outputs and Data Sources

#### outputs.tf - Comprehensive Outputs
```hcl
# Basic output
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.bucket
}

# Sensitive output
output "database_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

# Complex output with formatting
output "instance_info" {
  description = "Information about created instances"
  value = {
    instance_ids = aws_instance.web[*].id
    public_ips   = aws_instance.web[*].public_ip
    private_ips  = aws_instance.web[*].private_ip
  }
}

# Conditional output
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].dns_name : null
}

# Output with function usage
output "formatted_tags" {
  description = "Formatted tags for all resources"
  value = {
    for k, v in local.common_tags : k => upper(v)
  }
}
```

#### data-sources.tf - Various Data Sources
```hcl
# AWS data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# External data sources
data "external" "git_info" {
  program = ["bash", "-c", "echo '{\"branch\":\"'$(git branch --show-current)'\",\"commit\":\"'$(git rev-parse HEAD)'\"}'"]
}

# HTTP data source
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Local file data source
data "local_file" "config" {
  filename = "${path.module}/config.json"
}

# Template data source
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    db_endpoint = aws_db_instance.main.endpoint
    app_port    = 8080
  }
}
```

---

### Solution 4: Loops and Iteration - Count

#### count-examples.tf
```hcl
# Basic count usage
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "web-instance-${count.index + 1}"
    Type = "web"
  }
}

# Count with conditional logic
resource "aws_instance" "monitoring" {
  count         = var.enable_monitoring ? 1 : 0
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.small"
  
  tags = {
    Name = "monitoring-instance"
    Type = "monitoring"
  }
}

# Count with different configurations
resource "aws_instance" "app" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = count.index == 0 ? "t2.medium" : "t2.micro"
  
  tags = {
    Name = "app-instance-${count.index + 1}"
    Type = count.index == 0 ? "primary" : "secondary"
  }
}

# Count with subnet assignment
resource "aws_instance" "distributed" {
  count         = length(var.availability_zones)
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "distributed-instance-${count.index + 1}"
    AZ   = var.availability_zones[count.index]
  }
}

# Count limitations example
resource "aws_instance" "count_limitation" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  # This will cause issues if you change the count
  # because Terraform can't determine which instance to update
  tags = {
    Name = "count-instance-${count.index}"
  }
}
```

---

### Solution 5: Loops and Iteration - For Each

#### foreach-examples.tf
```hcl
# For_each with map
resource "aws_instance" "web_foreach" {
  for_each = var.environments
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  tags = {
    Name        = "web-${each.key}"
    Environment = each.key
    Type        = each.value.type
  }
}

# For_each with set
resource "aws_security_group_rule" "web_ingress" {
  for_each = var.allowed_ports
  
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
}

# For_each with complex map
resource "aws_instance" "complex_foreach" {
  for_each = {
    for idx, config in var.server_configs : config.name => config
  }
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  tags = merge(each.value.tags, {
    Name = each.key
    Index = each.value.index
  })
}

# For_each with conditional logic
resource "aws_instance" "conditional_foreach" {
  for_each = {
    for k, v in var.environments : k => v
    if v.enabled == true
  }
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  tags = {
    Name        = "conditional-${each.key}"
    Environment = each.key
  }
}

# For_each advantages over count
resource "aws_instance" "foreach_advantage" {
  for_each = var.instance_map
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  # You can safely add/remove items from the map
  # without affecting other instances
  tags = {
    Name = each.key
    Role = each.value.role
  }
}
```

#### variables.tf for for_each examples
```hcl
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    instance_type = string
    type          = string
  }))
  default = {
    dev = {
      instance_type = "t2.micro"
      type          = "development"
    }
    prod = {
      instance_type = "t2.medium"
      type          = "production"
    }
  }
}

variable "server_configs" {
  description = "Server configurations"
  type = list(object({
    name          = string
    instance_type = string
    index         = number
    tags          = map(string)
  }))
  default = [
    {
      name          = "web-server-1"
      instance_type = "t2.micro"
      index         = 1
      tags = {
        Role = "web"
        Tier = "frontend"
      }
    },
    {
      name          = "app-server-1"
      instance_type = "t2.small"
      index         = 2
      tags = {
        Role = "app"
        Tier = "backend"
      }
    }
  ]
}

variable "instance_map" {
  description = "Instance map for for_each"
  type = map(object({
    instance_type = string
    role          = string
  }))
  default = {
    "web-1" = {
      instance_type = "t2.micro"
      role          = "web"
    }
    "app-1" = {
      instance_type = "t2.small"
      role          = "app"
    }
  }
}
```

---

### Solution 6: Conditional Logic and Dynamic Blocks

#### conditional-examples.tf
```hcl
# Basic conditional expression
resource "aws_instance" "conditional_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"
  
  tags = {
    Name        = "conditional-instance"
    Environment = var.environment
  }
}

# Conditional resource creation
resource "aws_instance" "monitoring" {
  count         = var.enable_monitoring ? 1 : 0
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.small"
  
  tags = {
    Name = "monitoring-instance"
  }
}

# Dynamic blocks for security groups
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress blocks
  dynamic "ingress" {
    for_each = var.web_ports
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress blocks
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

# Nested conditional logic
resource "aws_instance" "complex_conditional" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? (
    var.high_performance ? "t2.large" : "t2.medium"
  ) : "t2.micro"
  
  tags = {
    Name        = "complex-instance"
    Environment = var.environment
    Performance = var.high_performance ? "high" : "standard"
  }
}

# Conditional with locals
locals {
  instance_config = var.environment == "prod" ? {
    instance_type = "t2.medium"
    monitoring    = true
    backup        = true
  } : {
    instance_type = "t2.micro"
    monitoring    = false
    backup        = false
  }
}

resource "aws_instance" "local_conditional" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_config.instance_type
  
  tags = {
    Name        = "local-conditional-instance"
    Environment = var.environment
    Monitoring  = local.instance_config.monitoring ? "enabled" : "disabled"
  }
}
```

#### variables.tf for conditional examples
```hcl
variable "web_ports" {
  description = "Web ports configuration"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "egress_rules" {
  description = "Egress rules configuration"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

---

### Solution 7: Locals and Functions

#### locals.tf - Comprehensive Examples
```hcl
# Basic locals
locals {
  project_name = "my-terraform-project"
  environment  = var.environment
  region       = data.aws_region.current.name
  
  # Common tags
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = data.aws_caller_identity.current.user_id
  }
  
  # String functions
  bucket_name = "${local.project_name}-${local.environment}-${random_id.suffix.hex}"
  formatted_name = upper("${local.project_name}-${local.environment}")
  
  # Numeric functions
  instance_count = min(var.max_instances, max(var.min_instances, var.desired_instances))
  
  # Collection functions
  all_availability_zones = concat(var.primary_azs, var.secondary_azs)
  unique_ports = distinct(concat(var.web_ports, var.app_ports))
  
  # Conditional locals
  instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"
  
  # Complex calculations
  subnet_cidrs = [
    for i in range(0, var.subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  # Map transformations
  environment_config = {
    for env, config in var.environments : env => {
      instance_type = config.instance_type
      min_size     = config.min_size
      max_size     = config.max_size
      enabled      = config.enabled
    }
  }
  
  # Filtered collections
  enabled_environments = {
    for k, v in var.environments : k => v
    if v.enabled == true
  }
  
  # String manipulation
  formatted_ports = join(", ", [for port in var.allowed_ports : tostring(port)])
  
  # Encoding functions
  base64_user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port = 8080
    db_host  = aws_db_instance.main.endpoint
  }))
  
  # Date and time functions
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  
  # File functions
  config_content = file("${path.module}/config.json")
  
  # Template functions
  rendered_template = templatefile("${path.module}/template.tpl", {
    project_name = local.project_name
    environment  = local.environment
    region       = local.region
  })
}

# Advanced locals with complex logic
locals {
  # Network calculations
  vpc_cidr = "10.0.0.0/16"
  subnet_bits = 8
  
  # Calculate subnets dynamically
  subnets = {
    for i, az in var.availability_zones : az => {
      cidr_block = cidrsubnet(local.vpc_cidr, local.subnet_bits, i)
      az_index   = i
    }
  }
  
  # Security group rules with complex logic
  security_group_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for rule in sg_config.rules : {
        security_group_name = sg_name
        rule_name          = rule.name
        port               = rule.port
        protocol           = rule.protocol
        cidr_blocks        = rule.cidr_blocks
      }
    ]
  ])
  
  # Resource naming with validation
  resource_names = {
    for resource_type, config in var.resources : resource_type => {
      name = "${local.project_name}-${local.environment}-${resource_type}"
      tags = merge(local.common_tags, config.tags)
    }
  }
}
```

#### functions-examples.tf
```hcl
# String functions
resource "aws_s3_bucket" "string_functions" {
  bucket = "${lower(local.project_name)}-${local.environment}-${substr(random_id.suffix.hex, 0, 4)}"
  
  tags = {
    Name = title("${local.project_name} ${local.environment} bucket")
  }
}

# Numeric functions
resource "aws_instance" "numeric_functions" {
  count = min(max(var.min_instances, var.desired_instances), var.max_instances)
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "instance-${count.index + 1}"
  }
}

# Collection functions
resource "aws_instance" "collection_functions" {
  for_each = toset(distinct(concat(var.web_servers, var.app_servers)))
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = each.value
  }
}

# Encoding functions
resource "aws_instance" "encoding_functions" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_config = jsonencode({
      port     = 8080
      database = aws_db_instance.main.endpoint
    })
  }))
  
  tags = {
    Name = "encoding-instance"
  }
}
```

---

### Solution 8: Resource Dependencies and Lifecycle Rules

#### dependencies.tf
```hcl
# Implicit dependencies (Terraform automatically detects)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

# Explicit dependencies with depends_on
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  
  # Explicit dependency
  depends_on = [
    aws_security_group.web,
    aws_route_table.public
  ]
  
  tags = {
    Name = "web-instance"
  }
}

# Lifecycle rules
resource "aws_instance" "lifecycle_example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "lifecycle-instance"
  }
}

resource "aws_instance" "replacement_example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  # Create new instance before destroying old one
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "replacement-instance"
  }
}

resource "aws_instance" "ignore_changes_example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  # Ignore changes to specific attributes
  lifecycle {
    ignore_changes = [
      tags,
      user_data
    ]
  }
  
  tags = {
    Name = "ignore-changes-instance"
  }
}

# Complex lifecycle rules
resource "aws_instance" "complex_lifecycle" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  lifecycle {
    # Only ignore changes to tags, not other attributes
    ignore_changes = [tags]
    
    # Replace instance if instance_type changes
    replace_triggered_by = [var.instance_type]
  }
  
  tags = {
    Name = "complex-lifecycle-instance"
  }
}
```

---

### Solution 9: State Management Fundamentals

#### state-commands.tf
```hcl
# Basic state management
resource "aws_s3_bucket" "state_bucket" {
  bucket = "terraform-state-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "terraform-state-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

#### State Management Commands:
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.state_bucket

# Move resource in state
terraform state mv aws_s3_bucket.old_name aws_s3_bucket.new_name

# Remove resource from state (without destroying)
terraform state rm aws_s3_bucket.unwanted_bucket

# Import existing resource
terraform import aws_s3_bucket.existing_bucket existing-bucket-name

# Refresh state
terraform refresh

# Show state in JSON format
terraform show -json

# Backup state
cp terraform.tfstate terraform.tfstate.backup

# Restore state
cp terraform.tfstate.backup terraform.tfstate
```

---

### Solution 10: Workspaces and Environment Management

#### workspace-examples.tf
```hcl
# Workspace-aware configuration
resource "aws_instance" "workspace_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = terraform.workspace == "prod" ? "t2.medium" : "t2.micro"
  
  tags = {
    Name        = "workspace-instance"
    Environment = terraform.workspace
    Workspace   = terraform.workspace
  }
}

# Workspace-specific variables
locals {
  environment_config = {
    dev = {
      instance_count = 1
      instance_type  = "t2.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t2.small"
    }
    prod = {
      instance_count = 3
      instance_type  = "t2.medium"
    }
  }
  
  current_config = local.environment_config[terraform.workspace]
}

resource "aws_instance" "workspace_config" {
  count         = local.current_config.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  tags = {
    Name        = "workspace-config-instance-${count.index + 1}"
    Environment = terraform.workspace
  }
}
```

#### Workspace Commands:
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete old_workspace
```

---

### Solution 11: File Organization and Project Structure

#### Project Structure:
```
terraform-project/
├── main.tf                 # Main configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Default variable values
├── providers.tf            # Provider configurations
├── data-sources.tf         # Data source definitions
├── locals.tf               # Local values
├── security-groups.tf      # Security group resources
├── networking.tf            # VPC and networking resources
├── compute.tf              # EC2 and compute resources
├── storage.tf              # S3 and storage resources
├── database.tf             # RDS and database resources
├── monitoring.tf           # CloudWatch and monitoring
├── environments/           # Environment-specific files
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/                # Custom modules
│   ├── vpc/
│   ├── ec2/
│   └── database/
└── scripts/                # Helper scripts
    ├── deploy.sh
    └── destroy.sh
```

#### providers.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}
```

---

### Solution 12: Error Handling and Validation

#### validation-examples.tf
```hcl
# Variable validation
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
}

# Complex validation
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    instance_class = string
    allocated_storage = number
  })
  
  validation {
    condition = var.database_config.allocated_storage >= 20 && var.database_config.allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }
  
  validation {
    condition = contains(["mysql", "postgres", "oracle"], var.database_config.engine)
    error_message = "Database engine must be one of: mysql, postgres, oracle."
  }
}

# Error handling with try function
locals {
  # Safe access to potentially undefined values
  instance_type = try(var.instance_config.instance_type, "t2.micro")
  
  # Error handling for data sources
  ami_id = try(data.aws_ami.amazon_linux.id, "ami-0c02fb55956c7d316")
  
  # Conditional error handling
  database_endpoint = var.enable_database ? aws_db_instance.main[0].endpoint : null
}

# Resource with error handling
resource "aws_instance" "error_handling" {
  ami           = local.ami_id
  instance_type = local.instance_type
  
  # Conditional resource creation
  count = var.enable_instance ? 1 : 0
  
  tags = {
    Name = "error-handling-instance"
  }
  
  # Lifecycle rule for error recovery
  lifecycle {
    ignore_changes = [ami]
  }
}
```

---

### Solution 13: Hello World Infrastructure

#### main.tf
```hcl
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

resource "aws_instance" "hello_world" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World from Terraform!</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "Hello-World-Instance"
    Environment = "Development"
    Project     = "Terraform-Learning"
  }
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

#### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

#### outputs.tf
```hcl
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.hello_world.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.hello_world.id
}
```

#### terraform.tfvars
```hcl
aws_region     = "us-west-2"
instance_type  = "t2.micro"
```

---

### Solution 2: Multi-Environment Setup

#### environments/dev.tfvars
```hcl
environment   = "development"
instance_type = "t2.micro"
ami_id        = "ami-0c02fb55956c7d316"
```

#### environments/staging.tfvars
```hcl
environment   = "staging"
instance_type = "t2.small"
ami_id        = "ami-0c02fb55956c7d316"
```

#### environments/prod.tfvars
```hcl
environment   = "production"
instance_type = "t2.medium"
ami_id        = "ami-0c02fb55956c7d316"
```

#### Commands for workspace management:
```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch to environment and apply
terraform workspace select dev
terraform apply -var-file="environments/dev.tfvars"

terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"

terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"
```

---

### Solution 3: Security Groups and Networking

#### vpc.tf
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

#### security-groups.tf
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-security-group"
  }
}

resource "aws_security_group" "database" {
  name_prefix = "db-sg-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "database-security-group"
  }
}
```

---

## Intermediate Level Solutions

### Solution 4: Database Infrastructure

#### database.tf
```hcl
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]

  tags = {
    Name = "main-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "mysql-optimized"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "1000"
  }
}

resource "aws_db_instance" "main" {
  identifier = "main-database"

  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "maindb"
  username = "admin"
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.mysql.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  multi_az = true

  skip_final_snapshot = false
  final_snapshot_identifier = "main-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "main-database"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}
```

---

### Solution 5: Load Balancer and Auto Scaling

#### load-balancer.tf
```hcl
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

#### auto-scaling.tf
```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_endpoint = aws_db_instance.main.endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-instance"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = [aws_subnet.public.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 10
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}
```

---

### Solution 6: State Management and Remote Backend

#### backend.tf
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

#### Commands for backend setup:
```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-bucket

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Initialize backend
terraform init -backend-config="backend-config.tfvars"
```

---

## Advanced Level Solutions

### Solution 7: Module Development

#### modules/vpc/main.tf
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-subnet-${count.index + 1}"
  })
}
```

#### modules/vpc/variables.tf
```hcl
variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

#### modules/vpc/outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}
```

---

### Solution 8: Advanced Data Sources and Locals

#### data-sources.tf
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
```

#### locals.tf
```hcl
locals {
  common_tags = {
    Project     = "Terraform-Learning"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = data.aws_caller_identity.current.user_id
  }

  environment_config = {
    development = {
      instance_type = "t2.micro"
      min_size     = 1
      max_size     = 3
    }
    staging = {
      instance_type = "t2.small"
      min_size     = 2
      max_size     = 5
    }
    production = {
      instance_type = "t2.medium"
      min_size     = 3
      max_size     = 10
    }
  }

  current_config = local.environment_config[var.environment]
}
```

---

## Expert Level Solutions

### Solution 10: Multi-Cloud Deployment

#### providers.tf
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.aws_region
}

provider "aws" {
  alias  = "secondary"
  region = var.aws_secondary_region
}

provider "azurerm" {
  alias = "backup"
  features {}
}
```

#### multi-cloud.tf
```hcl
# Primary AWS Infrastructure
module "aws_primary" {
  source = "./modules/aws-infrastructure"
  
  providers = {
    aws = aws.primary
  }
  
  environment = var.environment
  region      = var.aws_region
}

# Secondary AWS Infrastructure
module "aws_secondary" {
  source = "./modules/aws-infrastructure"
  
  providers = {
    aws = aws.secondary
  }
  
  environment = "${var.environment}-backup"
  region      = var.aws_secondary_region
}

# Azure Backup Infrastructure
module "azure_backup" {
  source = "./modules/azure-infrastructure"
  
  providers = {
    azurerm = azurerm.backup
  }
  
  environment = "${var.environment}-azure"
  location    = var.azure_location
}
```

---

## Production Scenarios Solutions

### Solution 13: Microservices Infrastructure

#### eks.tf
```hcl
resource "aws_eks_cluster" "main" {
  name     = "main-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]

  tags = {
    Name = "main-eks-cluster"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "main-node-group"
  }
}
```

---

## Implementation Commands

### Basic Commands for All Solutions:
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Destroy resources
terraform destroy

# Format code
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

### Advanced Commands:
```bash
# Workspace management
terraform workspace list
terraform workspace new <name>
terraform workspace select <name>

# State management
terraform state mv <source> <destination>
terraform state rm <resource>

# Output values
terraform output
terraform output <output_name>

# Refresh state
terraform refresh

# Graph visualization
terraform graph | dot -Tpng > graph.png
```

---

## Best Practices Summary

### Code Organization:
- Use modules for reusable components
- Separate environments with workspaces or directories
- Use variables for configuration
- Implement proper tagging strategy

### Security:
- Use least privilege IAM policies
- Enable encryption at rest and in transit
- Implement proper security groups
- Use secrets management

### State Management:
- Use remote state storage
- Implement state locking
- Backup state files regularly
- Use state versioning

### Testing:
- Implement unit tests
- Use integration tests
- Validate with terraform-compliance
- Test in non-production environments first

---

*This solutions guide provides complete implementations for all practice problems. Each solution follows Terraform best practices and includes proper error handling, security configurations, and production-ready patterns.*
