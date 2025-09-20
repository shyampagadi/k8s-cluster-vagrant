# Problem 10: Terraform Loops and Iteration Mastery

## Loop Fundamentals in Terraform

### Why Loops Matter
Loops in Terraform allow you to create multiple similar resources without duplicating code. They enable dynamic infrastructure creation based on input variables and data sources.

### Types of Iteration in Terraform
1. **count** - Creates multiple instances of a resource
2. **for_each** - Creates resources based on a map or set
3. **for expressions** - Transform and filter data
4. **dynamic blocks** - Create nested configuration blocks dynamically

## Count-Based Iteration

### Basic Count Usage
```hcl
# Create multiple EC2 instances
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}

# Variables for count example
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 3
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}
```

### Conditional Count
```hcl
# Create resource only in production
resource "aws_instance" "monitoring" {
  count = var.environment == "production" ? 1 : 0
  
  ami           = var.monitoring_ami
  instance_type = "t3.small"
  
  tags = {
    Name = "${var.project_name}-monitoring"
  }
}

# Create different numbers based on environment
resource "aws_instance" "app" {
  count = var.environment == "production" ? 5 : (
    var.environment == "staging" ? 2 : 1
  )
  
  ami           = var.app_ami
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
    Environment = var.environment
  }
}
```

### Count with Data Sources
```hcl
# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create subnets in all available AZs
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}
```

### Count Limitations and Pitfalls
```hcl
# PROBLEM: Changing count can cause resource recreation
# If you change instance_count from 3 to 2, the last instance is destroyed
# If you change from 3 to 4, a new instance is created
# But if you remove the middle item from a list, resources get recreated

# BETTER APPROACH: Use for_each for more stable resource management
```

## For_Each Iteration

### Basic For_Each with Set
```hcl
# Create instances for each environment
variable "environments" {
  description = "Set of environments"
  type        = set(string)
  default     = ["development", "staging", "production"]
}

resource "aws_instance" "env_specific" {
  for_each = var.environments
  
  ami           = var.ami_id
  instance_type = each.value == "production" ? "t3.large" : "t3.micro"
  
  tags = {
    Name        = "${var.project_name}-${each.value}"
    Environment = each.value
  }
}
```

### For_Each with Map
```hcl
# Define server configurations
variable "servers" {
  description = "Map of server configurations"
  type = map(object({
    instance_type = string
    ami_id        = string
    disk_size     = number
  }))
  
  default = {
    web = {
      instance_type = "t3.medium"
      ami_id        = "ami-0c02fb55956c7d316"
      disk_size     = 20
    }
    api = {
      instance_type = "t3.large"
      ami_id        = "ami-0c02fb55956c7d316"
      disk_size     = 50
    }
    worker = {
      instance_type = "t3.xlarge"
      ami_id        = "ami-0c02fb55956c7d316"
      disk_size     = 100
    }
  }
}

# Create instances based on server configurations
resource "aws_instance" "servers" {
  for_each = var.servers
  
  ami           = each.value.ami_id
  instance_type = each.value.instance_type
  
  root_block_device {
    volume_size = each.value.disk_size
    volume_type = "gp3"
    encrypted   = true
  }
  
  tags = {
    Name = "${var.project_name}-${each.key}"
    Type = each.key
  }
}
```

### For_Each with Complex Objects
```hcl
# Complex subnet configuration
variable "subnet_configs" {
  description = "Subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public           = bool
    tags             = map(string)
  }))
  
  default = {
    public_1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-west-2a"
      public           = true
      tags = {
        Type = "Public"
        Tier = "Web"
      }
    }
    public_2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-west-2b"
      public           = true
      tags = {
        Type = "Public"
        Tier = "Web"
      }
    }
    private_1 = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-west-2a"
      public           = false
      tags = {
        Type = "Private"
        Tier = "Application"
      }
    }
    private_2 = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-west-2b"
      public           = false
      tags = {
        Type = "Private"
        Tier = "Application"
      }
    }
  }
}

resource "aws_subnet" "main" {
  for_each = var.subnet_configs
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.public
  
  tags = merge(each.value.tags, {
    Name = "${var.project_name}-${each.key}"
  })
}
```

### For_Each with Data Sources
```hcl
# Get all available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Convert list to set for for_each
locals {
  az_set = toset(data.aws_availability_zones.available.names)
}

# Create NAT Gateway in each AZ
resource "aws_nat_gateway" "main" {
  for_each = local.az_set
  
  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.public[each.value].id
  
  tags = {
    Name = "${var.project_name}-nat-${each.value}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Create corresponding EIPs
resource "aws_eip" "nat" {
  for_each = local.az_set
  
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-eip-${each.value}"
  }
}
```

## For Expressions

### List Transformations
```hcl
# Transform list of objects
variable "users" {
  description = "List of user objects"
  type = list(object({
    name  = string
    email = string
    role  = string
  }))
  
  default = [
    {
      name  = "john"
      email = "john@example.com"
      role  = "admin"
    },
    {
      name  = "jane"
      email = "jane@example.com"
      role  = "user"
    },
    {
      name  = "bob"
      email = "bob@example.com"
      role  = "admin"
    }
  ]
}

locals {
  # Extract just the names
  user_names = [for user in var.users : user.name]
  
  # Extract emails of admin users only
  admin_emails = [
    for user in var.users : user.email
    if user.role == "admin"
  ]
  
  # Transform to uppercase names
  upper_names = [for user in var.users : upper(user.name)]
  
  # Create formatted strings
  user_descriptions = [
    for user in var.users : 
    "${user.name} (${user.email}) - ${user.role}"
  ]
}
```

### Map Transformations
```hcl
# Transform list to map
locals {
  # Create map with name as key
  users_by_name = {
    for user in var.users : user.name => user
  }
  
  # Create map with email as key, only for admins
  admin_users_by_email = {
    for user in var.users : user.email => user
    if user.role == "admin"
  }
  
  # Transform existing map
  server_names = {
    for key, config in var.servers : key => "${var.project_name}-${key}"
  }
}
```

### Complex For Expressions
```hcl
# Nested for expressions
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    regions = list(string)
    instance_types = list(string)
  }))
  
  default = {
    development = {
      regions = ["us-west-2"]
      instance_types = ["t3.micro"]
    }
    production = {
      regions = ["us-west-2", "us-east-1"]
      instance_types = ["t3.medium", "t3.large"]
    }
  }
}

locals {
  # Create all combinations of environment, region, and instance type
  all_combinations = flatten([
    for env_name, env_config in var.environments : [
      for region in env_config.regions : [
        for instance_type in env_config.instance_types : {
          environment   = env_name
          region       = region
          instance_type = instance_type
          key          = "${env_name}-${region}-${instance_type}"
        }
      ]
    ]
  ])
  
  # Convert to map for for_each usage
  combinations_map = {
    for combo in local.all_combinations : combo.key => combo
  }
}
```

## Dynamic Blocks

### Basic Dynamic Block
```hcl
# Variable for ingress rules
variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  
  default = [
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
}

# Security group with dynamic ingress rules
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}
```

### Conditional Dynamic Blocks
```hcl
# Variable for optional EBS volumes
variable "ebs_volumes" {
  description = "Optional EBS volumes"
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
    encrypted   = bool
  }))
  
  default = []
}

# EC2 instance with conditional EBS volumes
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  # Dynamic EBS volumes (only if specified)
  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size          = ebs_block_device.value.volume_size
      volume_type          = ebs_block_device.value.volume_type
      encrypted            = ebs_block_device.value.encrypted
      delete_on_termination = true
    }
  }

  tags = {
    Name = "${var.project_name}-web"
  }
}
```

### Nested Dynamic Blocks
```hcl
# Complex launch template configuration
variable "block_devices" {
  description = "Block device configurations"
  type = list(object({
    device_name = string
    ebs = object({
      volume_size = number
      volume_type = string
      encrypted   = bool
    })
  }))
  
  default = [
    {
      device_name = "/dev/sda1"
      ebs = {
        volume_size = 20
        volume_type = "gp3"
        encrypted   = true
      }
    },
    {
      device_name = "/dev/sdf"
      ebs = {
        volume_size = 100
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Nested dynamic blocks
  dynamic "block_device_mappings" {
    for_each = var.block_devices
    content {
      device_name = block_device_mappings.value.device_name
      
      dynamic "ebs" {
        for_each = [block_device_mappings.value.ebs]
        content {
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
          encrypted            = ebs.value.encrypted
          delete_on_termination = true
        }
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web"
    }
  }
}
```

## Advanced Iteration Patterns

### Combining Count and For_Each
```hcl
# Create multiple instances per environment
variable "environment_configs" {
  description = "Environment configurations"
  type = map(object({
    instance_count = number
    instance_type  = string
  }))
  
  default = {
    development = {
      instance_count = 1
      instance_type  = "t3.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
    }
    production = {
      instance_count = 3
      instance_type  = "t3.medium"
    }
  }
}

# First, create the base configuration for each environment
locals {
  # Flatten the configuration to create individual instance configs
  instance_configs = flatten([
    for env_name, env_config in var.environment_configs : [
      for i in range(env_config.instance_count) : {
        key           = "${env_name}-${i + 1}"
        environment   = env_name
        instance_type = env_config.instance_type
        index        = i + 1
      }
    ]
  ])
  
  # Convert to map for for_each
  instances_map = {
    for config in local.instance_configs : config.key => config
  }
}

# Create instances using for_each
resource "aws_instance" "multi_env" {
  for_each = local.instances_map
  
  ami           = var.ami_id
  instance_type = each.value.instance_type
  
  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = each.value.environment
    Index       = each.value.index
  }
}
```

### Conditional Iteration
```hcl
# Create resources only for specific conditions
locals {
  # Only create monitoring instances for production and staging
  monitoring_environments = {
    for env_name, env_config in var.environment_configs : 
    env_name => env_config
    if contains(["staging", "production"], env_name)
  }
}

resource "aws_instance" "monitoring" {
  for_each = local.monitoring_environments
  
  ami           = var.monitoring_ami
  instance_type = "t3.small"
  
  tags = {
    Name        = "${var.project_name}-monitoring-${each.key}"
    Environment = each.key
    Purpose     = "monitoring"
  }
}
```

### Cross-Resource Iteration
```hcl
# Create security group rules that reference other resources
locals {
  # Create rules that allow communication between web and app tiers
  cross_tier_rules = [
    for web_instance in aws_instance.web : {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      source_security_group_id = aws_security_group.web.id
      description     = "Allow web tier to app tier"
    }
  ]
}

resource "aws_security_group_rule" "cross_tier" {
  count = length(local.cross_tier_rules)
  
  type                     = "ingress"
  from_port               = local.cross_tier_rules[count.index].from_port
  to_port                 = local.cross_tier_rules[count.index].to_port
  protocol                = local.cross_tier_rules[count.index].protocol
  source_security_group_id = local.cross_tier_rules[count.index].source_security_group_id
  security_group_id       = aws_security_group.app.id
  description             = local.cross_tier_rules[count.index].description
}
```

This comprehensive guide covers all aspects of loops and iteration in Terraform, from basic count usage to complex nested iterations and dynamic resource creation patterns.
