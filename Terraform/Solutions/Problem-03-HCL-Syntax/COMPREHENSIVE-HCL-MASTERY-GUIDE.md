# Problem 3: HCL Syntax Mastery - Complete Language Reference

## HCL Language Fundamentals

### What is HCL?
HashiCorp Configuration Language (HCL) is a structured configuration language designed to be both human and machine-readable. It's the native language for Terraform configurations.

### HCL vs JSON vs YAML
```hcl
# HCL - Human-readable and expressive
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

```json
// JSON - Machine-readable but verbose
{
  "resource": {
    "aws_instance": {
      "web": {
        "ami": "ami-0c02fb55956c7d316",
        "instance_type": "t3.micro",
        "tags": {
          "Name": "WebServer"
        }
      }
    }
  }
}
```

## Core HCL Constructs

### 1. Blocks - Configuration Containers
```hcl
# Block syntax: block_type "label1" "label2" {
#   argument = value
# }

# Resource block with two labels
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
}

# Variable block with one label
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

# Output block with one label
output "instance_ip" {
  value = aws_instance.web.public_ip
}

# Nested blocks
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  
  # Nested block
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  
  # Multiple nested blocks
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 100
    volume_type = "gp3"
  }
  
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 200
    volume_type = "gp3"
  }
}
```

### 2. Arguments - Value Assignment
```hcl
resource "aws_instance" "web" {
  # Simple string argument
  ami = "ami-0c02fb55956c7d316"
  
  # Simple string argument
  instance_type = "t3.micro"
  
  # Number argument
  monitoring = true
  
  # List argument
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Map argument
  tags = {
    Name        = "WebServer"
    Environment = "production"
    Owner       = "devops-team"
  }
}
```

### 3. Expressions - Value Computation
```hcl
# Literal expressions
ami           = "ami-0c02fb55956c7d316"
instance_type = "t3.micro"
count         = 3
enabled       = true

# Reference expressions
subnet_id = aws_subnet.main.id
vpc_id    = data.aws_vpc.default.id

# Function call expressions
availability_zone = data.aws_availability_zones.available.names[0]
instance_name     = format("%s-%02d", var.prefix, count.index + 1)

# Arithmetic expressions
total_storage = var.root_volume_size + var.data_volume_size
cpu_credits   = var.instance_type == "t3.micro" ? "standard" : "unlimited"
```

## HCL Data Types in Detail

### Strings
```hcl
# Simple strings
name = "web-server"
region = "us-west-2"

# Strings with special characters
description = "This is a \"quoted\" string with special chars: $, %, &"

# Multi-line strings (heredoc)
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
EOF

# Indented heredoc (removes leading whitespace)
script = <<-SCRIPT
  #!/bin/bash
  echo "Starting setup..."
  # Install packages
  yum install -y docker
  systemctl start docker
SCRIPT

# Raw strings (no interpolation)
regex_pattern = <<~PATTERN
  ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
PATTERN
```

### Numbers
```hcl
# Integers
instance_count = 3
port = 80
timeout = 300

# Floating point
cpu_utilization_threshold = 75.5
memory_ratio = 0.8
price_per_hour = 0.0464

# Scientific notation
max_connections = 1e6
nano_seconds = 1.5e-9

# Hexadecimal
permissions = 0755
color_code = 0xFF0000
```

### Booleans
```hcl
# Boolean literals
enabled = true
debug_mode = false
auto_scaling = true

# Boolean expressions
delete_on_termination = var.environment != "production"
enable_monitoring = var.instance_type != "t3.micro"
create_backup = var.environment == "production" ? true : false
```

### Lists (Arrays)
```hcl
# Simple lists
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
ports = [80, 443, 8080, 8443]
environments = ["dev", "staging", "prod"]

# Mixed type lists (not recommended)
mixed_list = ["string", 123, true]

# Nested lists
subnet_configs = [
  ["10.0.1.0/24", "us-west-2a"],
  ["10.0.2.0/24", "us-west-2b"],
  ["10.0.3.0/24", "us-west-2c"]
]

# List of objects
ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  },
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from private networks"
  }
]
```

### Maps (Objects)
```hcl
# Simple maps
tags = {
  Name        = "web-server"
  Environment = "production"
  Owner       = "devops-team"
  Project     = "ecommerce"
}

# Maps with different value types
instance_config = {
  type         = "t3.medium"
  count        = 3
  monitoring   = true
  storage_gb   = 20
}

# Nested maps
environment_configs = {
  development = {
    instance_type = "t3.micro"
    instance_count = 1
    monitoring = false
    backup_enabled = false
  }
  staging = {
    instance_type = "t3.small"
    instance_count = 2
    monitoring = true
    backup_enabled = true
  }
  production = {
    instance_type = "t3.large"
    instance_count = 5
    monitoring = true
    backup_enabled = true
  }
}

# Complex nested structures
application_config = {
  web_tier = {
    instances = {
      type = "t3.medium"
      count = 3
      subnets = ["subnet-1", "subnet-2", "subnet-3"]
    }
    load_balancer = {
      type = "application"
      scheme = "internet-facing"
      ports = [80, 443]
    }
  }
  app_tier = {
    instances = {
      type = "t3.large"
      count = 2
      subnets = ["subnet-4", "subnet-5"]
    }
  }
  data_tier = {
    database = {
      engine = "mysql"
      version = "8.0"
      instance_class = "db.t3.medium"
      storage_gb = 100
    }
  }
}
```

## String Interpolation and Expressions

### Basic Interpolation
```hcl
# Variable interpolation
resource_name = "${var.project_name}-web-server"
bucket_name = "${var.environment}-${var.application}-logs"

# Resource attribute interpolation
subnet_id = aws_subnet.main.id
vpc_cidr = aws_vpc.main.cidr_block

# Complex interpolation with functions
instance_name = "${var.environment}-${var.application}-${formatdate("YYYY-MM-DD", timestamp())}"
backup_name = "${aws_instance.web.id}-backup-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
```

### Conditional Expressions (Ternary Operator)
```hcl
# Basic conditional
instance_type = var.environment == "production" ? "t3.large" : "t3.micro"

# Nested conditionals
storage_type = var.environment == "production" ? "gp3" : (
  var.environment == "staging" ? "gp2" : "standard"
)

# Complex conditionals with multiple conditions
backup_retention = var.environment == "production" && var.critical_data ? 30 : (
  var.environment == "staging" ? 7 : 1
)

# Conditional resource creation
create_monitoring = var.environment == "production" || var.enable_monitoring

# Conditional lists
security_groups = var.environment == "production" ? [
  aws_security_group.web.id,
  aws_security_group.monitoring.id,
  aws_security_group.backup.id
] : [aws_security_group.web.id]
```

### Function Calls
```hcl
# String functions
upper_name = upper(var.project_name)
lower_region = lower(var.aws_region)
title_case = title(var.application_name)

# Date and time functions
current_time = timestamp()
formatted_date = formatdate("YYYY-MM-DD", timestamp())
iso_date = formatdate("RFC3339", timestamp())

# Collection functions
first_az = element(data.aws_availability_zones.available.names, 0)
subnet_count = length(var.subnet_cidrs)
sorted_zones = sort(data.aws_availability_zones.available.names)

# Numeric functions
max_instances = max(var.min_instances, 1)
total_storage = sum([var.root_volume_size, var.data_volume_size, var.log_volume_size])

# Encoding functions
user_data_encoded = base64encode(templatefile("${path.module}/user-data.sh", {
  database_url = var.database_url
  api_key = var.api_key
}))

# Network functions
subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 1)
host_ip = cidrhost(var.subnet_cidr, 10)
network_address = cidrnetmask(var.vpc_cidr)

# File functions
ssh_key = file("${path.module}/keys/id_rsa.pub")
config_template = templatefile("${path.module}/templates/config.tpl", {
  environment = var.environment
  database_host = aws_db_instance.main.endpoint
})
```

## Advanced HCL Features

### For Expressions (List and Map Comprehensions)
```hcl
# List comprehension - create list from list
instance_names = [
  for i in range(var.instance_count) : 
  "${var.prefix}-${i + 1}"
]

# List comprehension with filtering
production_instances = [
  for instance in aws_instance.web : instance.id
  if instance.tags.Environment == "production"
]

# Map comprehension - create map from list
instance_map = {
  for i, instance in aws_instance.web : 
  instance.id => {
    name = "${var.prefix}-${i + 1}"
    az = instance.availability_zone
    type = instance.instance_type
  }
}

# Complex transformations
subnet_configs = {
  for i, cidr in var.subnet_cidrs : 
  "subnet-${i + 1}" => {
    cidr_block = cidr
    availability_zone = data.aws_availability_zones.available.names[i % length(data.aws_availability_zones.available.names)]
    map_public_ip = i < var.public_subnet_count
    tags = {
      Name = "${var.prefix}-subnet-${i + 1}"
      Type = i < var.public_subnet_count ? "public" : "private"
    }
  }
}

# Conditional for expressions
filtered_subnets = {
  for k, v in local.all_subnets : k => v
  if v.environment == var.current_environment
}
```

### Dynamic Blocks
```hcl
# Dynamic ingress rules for security group
resource "aws_security_group" "web" {
  name_prefix = "${var.name}-web-"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self            = lookup(ingress.value, "self", null)
    }
  }

  # Static egress rule
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Dynamic EBS block devices
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size          = ebs_block_device.value.volume_size
      volume_type          = ebs_block_device.value.volume_type
      encrypted            = lookup(ebs_block_device.value, "encrypted", true)
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
    }
  }

  tags = var.tags
}

# Nested dynamic blocks
resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  dynamic "block_device_mappings" {
    for_each = var.block_devices
    content {
      device_name = block_device_mappings.value.device_name
      
      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []
        content {
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
          encrypted            = lookup(ebs.value, "encrypted", true)
          delete_on_termination = lookup(ebs.value, "delete_on_termination", true)
        }
      }
    }
  }
}
```

### Splat Expressions
```hcl
# Simple splat - get all instance IDs
instance_ids = aws_instance.web[*].id

# Attribute splat - get specific attributes
instance_private_ips = aws_instance.web[*].private_ip
instance_public_ips = aws_instance.web[*].public_ip

# Splat with index
instance_info = [
  for i, instance in aws_instance.web : {
    index = i
    id = instance.id
    ip = instance.private_ip
  }
]

# Complex splat expressions
subnet_route_table_associations = aws_route_table_association.private[*].id
security_group_rules = aws_security_group.web.ingress[*].from_port

# Conditional splat
web_instance_ids = [
  for instance in aws_instance.web : instance.id
  if instance.tags.Type == "web"
]
```

## Comments and Documentation

### Comment Styles
```hcl
# Single-line comment
resource "aws_instance" "web" {
  ami = "ami-0c02fb55956c7d316"  # Inline comment
  
  /*
   * Multi-line comment
   * Useful for longer explanations
   * and documentation blocks
   */
  instance_type = "t3.micro"
  
  # TODO: Add monitoring configuration
  # FIXME: Update AMI ID for latest version
  # NOTE: This instance is for development only
}
```

### Documentation Best Practices
```hcl
# Resource: Web Server Instance
# Purpose: Hosts the main web application
# Dependencies: VPC, Security Group, Key Pair
# Maintenance: Updated monthly with latest AMI
resource "aws_instance" "web" {
  # AMI: Latest Amazon Linux 2 (updated monthly)
  ami = data.aws_ami.amazon_linux.id
  
  # Instance type: Based on environment requirements
  # Development: t3.micro, Staging: t3.small, Production: t3.medium+
  instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
  
  # Security: Attach web security group for HTTP/HTTPS access
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Networking: Place in private subnet for security
  subnet_id = aws_subnet.private[0].id
  
  # Monitoring: Enable detailed monitoring in production
  monitoring = var.environment == "production"
  
  # Storage: Root volume configuration
  root_block_device {
    volume_type = "gp3"  # Latest generation for better performance
    volume_size = 20     # 20GB sufficient for web server
    encrypted   = true   # Always encrypt storage
  }
  
  # User Data: Bootstrap script for application setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    app_version = var.app_version
  }))
  
  # Tags: Comprehensive tagging for resource management
  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Purpose     = "Web application hosting"
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
  }
}
```

This comprehensive guide covers all essential HCL syntax elements needed for mastering Terraform configurations.
