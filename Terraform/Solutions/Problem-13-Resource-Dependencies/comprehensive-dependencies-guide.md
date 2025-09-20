# Problem 13: Terraform Resource Dependencies Mastery

## Dependency Fundamentals

### Types of Dependencies
1. **Implicit Dependencies** - Automatically detected by Terraform
2. **Explicit Dependencies** - Manually specified with depends_on
3. **Data Dependencies** - Dependencies through data sources
4. **Module Dependencies** - Dependencies between modules

## Implicit Dependencies

### Automatic Dependency Detection
```hcl
# VPC creates implicit dependency chain
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
  
  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Implicit dependency on IGW
  }
  
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id      # Implicit dependency on subnet
  route_table_id = aws_route_table.public.id # Implicit dependency on route table
}
```

### Complex Implicit Dependencies
```hcl
# Security group with cross-references
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Implicit dependency
  }
  
  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]  # Implicit dependency
  }
  
  tags = {
    Name = "alb-sg"
  }
}

# Instance with multiple implicit dependencies
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id           # Implicit dependency
  vpc_security_group_ids = [aws_security_group.web.id]    # Implicit dependency
  key_name               = aws_key_pair.main.key_name     # Implicit dependency
  
  tags = {
    Name = "web-server"
  }
}
```

## Explicit Dependencies

### Using depends_on
```hcl
# Explicit dependency for ordering
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  # Explicit dependency ensures NAT gateway is created first
  depends_on = [aws_nat_gateway.main]
  
  tags = {
    Name = "web-server"
  }
}

# Multiple explicit dependencies
resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  
  db_name  = "myapp"
  username = "admin"
  password = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  # Ensure VPC and security groups are ready
  depends_on = [
    aws_vpc.main,
    aws_security_group.database,
    aws_db_subnet_group.main
  ]
  
  tags = {
    Name = "main-database"
  }
}
```

### Cross-Module Dependencies
```hcl
# Module with explicit dependencies
module "database" {
  source = "./modules/database"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Explicit dependency on VPC module completion
  depends_on = [module.vpc]
}

module "application" {
  source = "./modules/application"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  database_endpoint = module.database.endpoint
  
  # Explicit dependencies on both modules
  depends_on = [
    module.vpc,
    module.database
  ]
}
```

## Dependency Graph Management

### Understanding Dependency Cycles
```hcl
# AVOID: Circular dependency (will cause error)
# resource "aws_security_group" "web" {
#   ingress {
#     security_groups = [aws_security_group.app.id]
#   }
# }
# 
# resource "aws_security_group" "app" {
#   ingress {
#     security_groups = [aws_security_group.web.id]  # Creates cycle
#   }
# }

# CORRECT: Break circular dependency with separate rules
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = "app-sg"
  }
}

# Separate rules to avoid circular dependency
resource "aws_security_group_rule" "web_to_app" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.web.id
}

resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.app.id
}
```

### Optimizing Dependency Chains
```hcl
# Parallel resource creation where possible
resource "aws_subnet" "public" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # All subnets can be created in parallel
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # All private subnets can also be created in parallel
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# NAT Gateways depend on public subnets and EIPs
resource "aws_eip" "nat" {
  count = 3
  
  domain = "vpc"
  
  # EIPs can be created in parallel
  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = 3
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  # NAT Gateways depend on both EIPs and subnets
  depends_on = [aws_internet_gateway.main]
  
  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
}
```

This comprehensive guide covers all aspects of Terraform resource dependencies, from automatic detection to complex dependency management and optimization strategies.
