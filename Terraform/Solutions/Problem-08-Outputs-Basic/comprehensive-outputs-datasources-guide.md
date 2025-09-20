# Terraform Outputs and Data Sources - Complete Guide

## Overview

This comprehensive guide covers Terraform outputs and data sources, including advanced patterns, cross-module communication, and enterprise-grade data management strategies.

## Output Fundamentals

### Basic Output Syntax

```hcl
output "output_name" {
  description = "Description of the output"
  value       = resource.type.name.attribute
  sensitive   = false
  depends_on  = [resource.dependency]
}
```

### Simple Outputs

```hcl
# Basic resource outputs
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}
```

### Complex Outputs

```hcl
# VPC and networking outputs
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count = 3
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
}

# Structured output
output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id     = aws_vpc.main.id
    vpc_arn    = aws_vpc.main.arn
    cidr_block = aws_vpc.main.cidr_block
    
    subnets = {
      public = {
        ids   = aws_subnet.public[*].id
        cidrs = aws_subnet.public[*].cidr_block
        azs   = aws_subnet.public[*].availability_zone
      }
    }
    
    dns_config = {
      hostnames_enabled = aws_vpc.main.enable_dns_hostnames
      support_enabled   = aws_vpc.main.enable_dns_support
    }
  }
}

# List outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

# Map outputs
output "subnet_az_mapping" {
  description = "Mapping of subnet IDs to availability zones"
  value = {
    for subnet in aws_subnet.public :
    subnet.id => subnet.availability_zone
  }
}
```

## Data Source Fundamentals

### Basic Data Sources

```hcl
# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Use data sources in outputs
output "deployment_info" {
  description = "Deployment information"
  value = {
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
    azs        = data.aws_availability_zones.available.names
  }
}
```

### AMI Data Sources

```hcl
# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Output AMI information
output "ami_info" {
  description = "AMI information"
  value = {
    ubuntu = {
      id           = data.aws_ami.ubuntu.id
      name         = data.aws_ami.ubuntu.name
      description  = data.aws_ami.ubuntu.description
      creation_date = data.aws_ami.ubuntu.creation_date
    }
    amazon_linux = {
      id           = data.aws_ami.amazon_linux.id
      name         = data.aws_ami.amazon_linux.name
      description  = data.aws_ami.amazon_linux.description
      creation_date = data.aws_ami.amazon_linux.creation_date
    }
  }
}
```

### VPC and Networking Data Sources

```hcl
# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get VPC by tags
data "aws_vpc" "main" {
  tags = {
    Name = "main-vpc"
  }
}

# Get subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "public"
  }
}

data "aws_subnet" "public_details" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

# Output networking information
output "network_info" {
  description = "Network information"
  value = {
    default_vpc = {
      id         = data.aws_vpc.default.id
      cidr_block = data.aws_vpc.default.cidr_block
    }
    
    main_vpc = {
      id         = data.aws_vpc.main.id
      cidr_block = data.aws_vpc.main.cidr_block
    }
    
    public_subnets = {
      for subnet in data.aws_subnet.public_details :
      subnet.id => {
        cidr_block        = subnet.cidr_block
        availability_zone = subnet.availability_zone
      }
    }
  }
}
```

## Advanced Output Patterns

### Conditional Outputs

```hcl
variable "create_database" {
  description = "Whether to create database"
  type        = bool
  default     = false
}

resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0
  
  identifier     = "main-database"
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
}

# Conditional output
output "database_endpoint" {
  description = "Database endpoint (if created)"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

# Alternative using try()
output "database_endpoint_safe" {
  description = "Database endpoint (safe access)"
  value       = try(aws_db_instance.main[0].endpoint, "not_created")
}
```

### Sensitive Outputs

```hcl
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "main" {
  identifier = "main-database"
  password   = random_password.db_password.result
  # ... other configuration
}

# Sensitive output
output "database_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

# Connection string (also sensitive)
output "database_connection_string" {
  description = "Database connection string"
  value = format(
    "mysql://%s:%s@%s:%d/%s",
    aws_db_instance.main.username,
    random_password.db_password.result,
    aws_db_instance.main.endpoint,
    aws_db_instance.main.port,
    aws_db_instance.main.db_name
  )
  sensitive = true
}
```

### Computed Outputs

```hcl
# Compute derived values
locals {
  instance_count = length(aws_instance.web)
  
  total_cpu_cores = sum([
    for instance in aws_instance.web :
    lookup(local.instance_type_specs, instance.instance_type, {}).vcpus
  ])
  
  instance_type_specs = {
    "t3.micro"  = { vcpus = 2, memory = 1 }
    "t3.small"  = { vcpus = 2, memory = 2 }
    "t3.medium" = { vcpus = 2, memory = 4 }
    "t3.large"  = { vcpus = 2, memory = 8 }
  }
}

output "cluster_stats" {
  description = "Cluster statistics"
  value = {
    instance_count  = local.instance_count
    total_cpu_cores = local.total_cpu_cores
    
    instances_by_az = {
      for az in distinct([for i in aws_instance.web : i.availability_zone]) :
      az => length([for i in aws_instance.web : i if i.availability_zone == az])
    }
    
    cost_estimate = {
      hourly_cost  = local.instance_count * 0.0116  # t3.micro hourly rate
      monthly_cost = local.instance_count * 0.0116 * 24 * 30
    }
  }
}
```

## Cross-Module Communication

### Module Outputs

```hcl
# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    web      = aws_security_group.web.id
    database = aws_security_group.database.id
    internal = aws_security_group.internal.id
  }
}
```

### Using Module Outputs

```hcl
# main.tf
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.private_subnet_ids
  security_group_ids   = [module.networking.security_group_ids.web]
  
  instance_type = "t3.medium"
  instance_count = 3
}

# Root module outputs
output "infrastructure_info" {
  description = "Complete infrastructure information"
  value = {
    networking = {
      vpc_id             = module.networking.vpc_id
      public_subnet_ids  = module.networking.public_subnet_ids
      private_subnet_ids = module.networking.private_subnet_ids
      security_groups    = module.networking.security_group_ids
    }
    
    compute = {
      instance_ids = module.compute.instance_ids
      load_balancer = {
        dns_name = module.compute.load_balancer_dns_name
        zone_id  = module.compute.load_balancer_zone_id
      }
    }
  }
}
```

## Remote State Data Sources

### Accessing Remote State

```hcl
# Access shared infrastructure state
data "terraform_remote_state" "shared" {
  backend = "s3"
  
  config = {
    bucket = "company-terraform-state"
    key    = "shared/infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

# Access networking state
data "terraform_remote_state" "networking" {
  backend = "s3"
  
  config = {
    bucket = "company-terraform-state"
    key    = "networking/${var.environment}/terraform.tfstate"
    region = "us-west-2"
  }
}

# Use remote state outputs
resource "aws_instance" "app" {
  ami           = data.terraform_remote_state.shared.outputs.ami_id
  instance_type = "t3.medium"
  subnet_id     = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
  
  vpc_security_group_ids = [
    data.terraform_remote_state.networking.outputs.security_group_ids.app
  ]
}

output "remote_state_info" {
  description = "Information from remote states"
  value = {
    shared_ami_id = data.terraform_remote_state.shared.outputs.ami_id
    vpc_id        = data.terraform_remote_state.networking.outputs.vpc_id
    
    available_subnets = {
      public  = data.terraform_remote_state.networking.outputs.public_subnet_ids
      private = data.terraform_remote_state.networking.outputs.private_subnet_ids
    }
  }
}
```

## Data Source Filtering and Processing

### Advanced Filtering

```hcl
# Get specific AMIs with multiple filters
data "aws_ami" "web_server" {
  most_recent = true
  owners      = ["self", "amazon"]
  
  filter {
    name   = "name"
    values = ["web-server-*"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "tag:Application"
    values = ["web"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get instances by tags
data "aws_instances" "web_servers" {
  filter {
    name   = "tag:Role"
    values = ["web"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Process instance data
data "aws_instance" "web_details" {
  for_each    = toset(data.aws_instances.web_servers.ids)
  instance_id = each.value
}

output "web_server_inventory" {
  description = "Web server inventory"
  value = {
    total_count = length(data.aws_instances.web_servers.ids)
    
    instances = {
      for instance in data.aws_instance.web_details :
      instance.id => {
        private_ip        = instance.private_ip
        public_ip         = instance.public_ip
        instance_type     = instance.instance_type
        availability_zone = instance.availability_zone
        subnet_id         = instance.subnet_id
        
        tags = instance.tags
      }
    }
    
    by_az = {
      for az in distinct([for i in data.aws_instance.web_details : i.availability_zone]) :
      az => [
        for i in data.aws_instance.web_details :
        i.id if i.availability_zone == az
      ]
    }
  }
}
```

### Data Transformation

```hcl
# Transform and aggregate data
data "aws_route53_zone" "zones" {
  for_each = toset(var.domain_names)
  name     = each.value
}

locals {
  # Transform zone data
  zone_info = {
    for domain, zone in data.aws_route53_zone.zones :
    domain => {
      zone_id      = zone.zone_id
      name_servers = zone.name_servers
      comment      = zone.comment
      
      # Compute derived values
      is_private = zone.private_zone
      record_count = zone.resource_record_set_count
    }
  }
  
  # Aggregate statistics
  zone_stats = {
    total_zones    = length(local.zone_info)
    private_zones  = length([for z in local.zone_info : z if z.is_private])
    public_zones   = length([for z in local.zone_info : z if !z.is_private])
    total_records  = sum([for z in local.zone_info : z.record_count])
  }
}

output "dns_infrastructure" {
  description = "DNS infrastructure information"
  value = {
    zones = local.zone_info
    stats = local.zone_stats
  }
}
```

## Output Organization Patterns

### Hierarchical Outputs

```hcl
# Organize outputs by category
output "infrastructure" {
  description = "Complete infrastructure information"
  value = {
    metadata = {
      deployment_time = timestamp()
      terraform_version = "1.5.0"
      region = data.aws_region.current.name
      account_id = data.aws_caller_identity.current.account_id
    }
    
    networking = {
      vpc = {
        id         = aws_vpc.main.id
        cidr_block = aws_vpc.main.cidr_block
        dns_config = {
          hostnames = aws_vpc.main.enable_dns_hostnames
          support   = aws_vpc.main.enable_dns_support
        }
      }
      
      subnets = {
        public = {
          ids   = aws_subnet.public[*].id
          cidrs = aws_subnet.public[*].cidr_block
        }
        private = {
          ids   = aws_subnet.private[*].id
          cidrs = aws_subnet.private[*].cidr_block
        }
      }
      
      routing = {
        internet_gateway_id = aws_internet_gateway.main.id
        nat_gateway_ids     = aws_nat_gateway.main[*].id
        route_table_ids = {
          public  = aws_route_table.public.id
          private = aws_route_table.private[*].id
        }
      }
    }
    
    compute = {
      instances = {
        web = {
          ids         = aws_instance.web[*].id
          private_ips = aws_instance.web[*].private_ip
          public_ips  = aws_instance.web[*].public_ip
        }
      }
      
      load_balancing = {
        alb = {
          dns_name = aws_lb.main.dns_name
          zone_id  = aws_lb.main.zone_id
          arn      = aws_lb.main.arn
        }
        target_groups = {
          web = {
            arn  = aws_lb_target_group.web.arn
            name = aws_lb_target_group.web.name
          }
        }
      }
    }
    
    security = {
      security_groups = {
        web      = aws_security_group.web.id
        database = aws_security_group.database.id
        internal = aws_security_group.internal.id
      }
      
      key_pairs = {
        web = aws_key_pair.web.key_name
      }
    }
  }
}
```

### Environment-Specific Outputs

```hcl
# Different outputs based on environment
output "environment_info" {
  description = "Environment-specific information"
  value = merge(
    {
      environment = var.environment
      region      = data.aws_region.current.name
    },
    
    # Development-specific outputs
    var.environment == "development" ? {
      debug_info = {
        instance_details = {
          for instance in aws_instance.web :
          instance.id => {
            ssh_command = "ssh -i ${aws_key_pair.web.key_name}.pem ubuntu@${instance.public_ip}"
            logs_command = "aws logs tail /aws/ec2/${instance.id} --follow"
          }
        }
      }
    } : {},
    
    # Production-specific outputs
    var.environment == "production" ? {
      monitoring = {
        dashboard_url = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.project_name}-${var.environment}"
        alarm_count   = length(aws_cloudwatch_metric_alarm.production)
      }
    } : {}
  )
}
```

## Testing and Validation

### Output Testing

```bash
#!/bin/bash
# test-outputs.sh

echo "Testing Terraform outputs..."

# Apply configuration
terraform apply -auto-approve

# Test required outputs exist
required_outputs=("vpc_id" "subnet_ids" "instance_ids")

for output in "${required_outputs[@]}"; do
    value=$(terraform output -raw "$output" 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "❌ Required output '$output' is missing or null"
        exit 1
    else
        echo "✅ Output '$output' exists: $value"
    fi
done

# Test output formats
vpc_id=$(terraform output -raw vpc_id)
if [[ ! $vpc_id =~ ^vpc-[a-f0-9]{8,17}$ ]]; then
    echo "❌ VPC ID format is invalid: $vpc_id"
    exit 1
fi

# Test JSON output structure
terraform output -json infrastructure > output.json
if ! jq -e '.networking.vpc.id' output.json > /dev/null; then
    echo "❌ Infrastructure output structure is invalid"
    exit 1
fi

echo "All output tests passed!"
```

### Data Source Validation

```hcl
# Validate data source results
locals {
  # Ensure AMI exists and is valid
  ami_validation = data.aws_ami.ubuntu.id != "" ? null : file("ERROR: No Ubuntu AMI found")
  
  # Ensure VPC has subnets
  subnet_validation = length(data.aws_subnets.public.ids) > 0 ? null : file("ERROR: No public subnets found")
  
  # Validate availability zones
  az_validation = length(data.aws_availability_zones.available.names) >= 2 ? null : file("ERROR: Insufficient availability zones")
}
```

## Performance Considerations

### Efficient Data Source Usage

```hcl
# Cache expensive data source calls
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Reuse AMI data across resources
resource "aws_instance" "web" {
  count = 3
  
  ami           = data.aws_ami.ubuntu.id  # Single data source call
  instance_type = "t3.micro"
}

# Avoid repeated data source calls
locals {
  # Pre-fetch and cache
  current_region = data.aws_region.current.name
  account_id     = data.aws_caller_identity.current.account_id
}
```

## Best Practices

### 1. Output Documentation

```hcl
output "comprehensive_info" {
  description = <<-EOT
    Complete infrastructure information including:
    - VPC and networking details
    - Compute instance information
    - Load balancer configuration
    - Security group IDs
    
    Use this output to configure dependent resources
    or for infrastructure documentation.
  EOT
  
  value = {
    # ... output structure
  }
}
```

### 2. Sensitive Data Handling

```hcl
# Mark sensitive outputs appropriately
output "database_credentials" {
  description = "Database connection credentials"
  value = {
    endpoint = aws_db_instance.main.endpoint
    username = aws_db_instance.main.username
    password = aws_db_instance.main.password
  }
  sensitive = true
}
```

### 3. Output Validation

```hcl
# Validate output values
output "validated_vpc_id" {
  description = "VPC ID (validated)"
  value = can(regex("^vpc-[a-f0-9]{8,17}$", aws_vpc.main.id)) ? aws_vpc.main.id : null
}
```

## Conclusion

Outputs and data sources enable:
- **Information Sharing**: Pass data between modules and configurations
- **Infrastructure Discovery**: Find and use existing resources
- **Documentation**: Provide structured information about infrastructure
- **Integration**: Connect Terraform with external systems

Key takeaways:
- Structure outputs logically and hierarchically
- Use data sources efficiently to avoid performance issues
- Mark sensitive outputs appropriately
- Validate data source results
- Document outputs comprehensively
- Test output formats and structures
