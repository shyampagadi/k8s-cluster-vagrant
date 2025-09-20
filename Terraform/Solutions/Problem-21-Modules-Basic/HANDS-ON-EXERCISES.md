# Problem 21: Terraform Modules - Hands-On Exercises

## Exercise 1: VPC Module Development (45 minutes)
**Objective**: Create a comprehensive VPC module with configurable subnets and routing

### Requirements
Create a VPC module that supports:
- Configurable CIDR blocks
- Dynamic subnet creation across multiple AZs
- Optional NAT Gateway for private subnets
- Internet Gateway for public subnets
- Proper route table configuration

### Step-by-Step Implementation

#### Step 1: Create VPC Module Structure
```bash
mkdir -p modules/vpc
cd modules/vpc
touch main.tf variables.tf outputs.tf README.md
```

#### Step 2: Implement VPC Core Resources
```hcl
# modules/vpc/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}
```

#### Step 3: Implement Dynamic Subnet Creation
```hcl
# Public subnets
resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Private subnets
resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Type = "Private"
  })
}
```

#### Step 4: Add Variable Validation
```hcl
# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 6
    error_message = "Public subnet count must be between 1 and 6."
  }
}
```

### Validation Checklist
- [ ] VPC created with correct CIDR
- [ ] Public subnets have internet gateway route
- [ ] Private subnets created in different AZs
- [ ] NAT Gateway created if enabled
- [ ] All resources properly tagged

## Exercise 2: EC2 Module with Security Groups (60 minutes)
**Objective**: Create an EC2 module with dynamic security group rules

### Requirements
- Support multiple instance types and counts
- Dynamic security group rule creation
- User data template support
- EBS volume configuration
- Instance profile attachment

### Implementation Tasks

#### Task 1: Create EC2 Module Base
```hcl
# modules/ec2/main.tf
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "instance" {
  name_prefix = "${var.name}-"
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
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}
```

#### Task 2: Implement Instance Configuration
```hcl
resource "aws_instance" "main" {
  count = var.instance_count

  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id             = var.subnet_ids[count.index % length(var.subnet_ids)]

  user_data = var.user_data_script

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${count.index + 1}"
  })
}
```

### Challenge Tasks
1. Add support for additional EBS volumes
2. Implement instance replacement strategy
3. Add CloudWatch monitoring configuration
4. Create launch template for Auto Scaling

## Exercise 3: Database Module Implementation (75 minutes)
**Objective**: Create a comprehensive RDS module with security and backup features

### Requirements
- Multi-engine support (MySQL, PostgreSQL)
- Subnet group management
- Parameter group customization
- Backup configuration
- Security group with restricted access

### Implementation Steps

#### Step 1: Database Subnet Group
```hcl
# modules/database/main.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}
```

#### Step 2: Database Security Group
```hcl
resource "aws_security_group" "database" {
  name_prefix = "${var.name}-db-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Database access"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
  })
}
```

#### Step 3: RDS Instance Configuration
```hcl
resource "aws_db_instance" "main" {
  identifier = var.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  tags = var.tags
}
```

### Advanced Challenges
1. Add read replica support
2. Implement parameter group customization
3. Add monitoring and alerting
4. Create backup automation

## Exercise 4: Module Composition (90 minutes)
**Objective**: Use all modules together to create complete infrastructure

### Requirements
- Deploy VPC with public and private subnets
- Create web servers in private subnets
- Deploy database in database subnets
- Configure security groups for proper access
- Add load balancer for web servers

### Implementation Example
```hcl
# main.tf
locals {
  name = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  name     = local.name
  vpc_cidr = "10.0.0.0/16"

  public_subnet_count  = 2
  private_subnet_count = 2

  enable_nat_gateway = true

  tags = local.common_tags
}

module "web_servers" {
  source = "./modules/ec2"

  name           = "${local.name}-web"
  instance_count = 2
  instance_type  = "t3.micro"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr]
    }
  ]

  tags = merge(local.common_tags, {
    Type = "WebServer"
  })
}

module "database" {
  source = "./modules/database"

  name = "${local.name}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  database_name = "webapp"
  username      = "admin"
  password      = var.db_password

  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id

  allowed_security_groups = [module.web_servers.security_group_id]

  tags = merge(local.common_tags, {
    Type = "Database"
  })
}
```

### Validation Steps
1. Deploy infrastructure with `terraform apply`
2. Verify VPC and subnets are created
3. Check security group rules
4. Test connectivity between components
5. Validate backup configuration

## Exercise 5: Module Testing and Documentation (45 minutes)
**Objective**: Create comprehensive module documentation and examples

### Tasks
1. Create README.md for each module
2. Add usage examples
3. Document all variables and outputs
4. Create validation tests
5. Add troubleshooting guides

### Documentation Template
```markdown
# Module Name

## Description
Brief description of what the module does.

## Usage
```hcl
module "example" {
  source = "./modules/module-name"
  
  # Required variables
  name = "example"
  
  # Optional variables
  tags = {
    Environment = "production"
  }
}
```

## Requirements
- Terraform >= 1.0
- AWS Provider >= 5.0

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Resource name | string | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| id | Resource ID |
```

## Solutions and Explanations

### Exercise 1 Solution
The VPC module demonstrates proper resource organization and variable validation. Key patterns include:
- Using `cidrsubnet()` for automatic subnet calculation
- Data sources for availability zone discovery
- Conditional resource creation with `count`

### Exercise 2 Solution
The EC2 module shows advanced security group configuration:
- Dynamic blocks for flexible rule creation
- Proper resource dependencies
- Instance distribution across subnets

### Exercise 3 Solution
The database module implements security best practices:
- Encrypted storage by default
- Restricted network access
- Proper backup configuration

### Exercise 4 Solution
Module composition demonstrates:
- Proper module dependencies
- Data flow between modules
- Consistent tagging strategy

This hands-on approach ensures practical mastery of Terraform module development.
