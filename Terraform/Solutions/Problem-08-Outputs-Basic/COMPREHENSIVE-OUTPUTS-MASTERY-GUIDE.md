# Problem 8: Terraform Outputs Mastery - Data Sharing and Integration

## Output Fundamentals

### What are Terraform Outputs?
Outputs are a way to extract and share data from your Terraform configuration. They make information about your infrastructure available to other Terraform configurations, external systems, and team members.

### Basic Output Syntax
```hcl
output "output_name" {
  description = "Description of what this output contains"
  value       = resource.resource_name.attribute
  sensitive   = false
}
```

## Basic Output Patterns

### Simple Resource Outputs
```hcl
# VPC outputs
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# EC2 instance outputs
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.web[*].private_ip
}
```

### Database Connection Outputs
```hcl
# RDS database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.medium"
  
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  tags = {
    Name = "${var.project_name}-database"
  }
}

# Database connection information
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# Complete connection string
output "database_connection_string" {
  description = "Database connection string"
  value       = "mysql://${aws_db_instance.main.username}:${var.database_password}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}
```

## Advanced Output Patterns

### Structured Output Objects
```hcl
# Complex infrastructure outputs
output "infrastructure_info" {
  description = "Complete infrastructure information"
  value = {
    # Network information
    network = {
      vpc_id         = aws_vpc.main.id
      vpc_cidr       = aws_vpc.main.cidr_block
      public_subnets = {
        for subnet in aws_subnet.public : subnet.availability_zone => {
          id         = subnet.id
          cidr_block = subnet.cidr_block
          az         = subnet.availability_zone
        }
      }
      private_subnets = {
        for subnet in aws_subnet.private : subnet.availability_zone => {
          id         = subnet.id
          cidr_block = subnet.cidr_block
          az         = subnet.availability_zone
        }
      }
    }
    
    # Compute information
    compute = {
      web_instances = [
        for instance in aws_instance.web : {
          id         = instance.id
          public_ip  = instance.public_ip
          private_ip = instance.private_ip
          az         = instance.availability_zone
          type       = instance.instance_type
        }
      ]
      
      load_balancer = {
        arn      = aws_lb.main.arn
        dns_name = aws_lb.main.dns_name
        zone_id  = aws_lb.main.zone_id
      }
    }
    
    # Database information
    database = {
      endpoint = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      name     = aws_db_instance.main.db_name
    }
    
    # Security information
    security = {
      web_security_group_id = aws_security_group.web.id
      db_security_group_id  = aws_security_group.database.id
    }
  }
}
```

### Conditional Outputs
```hcl
# Conditional output based on resource creation
output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL (only if monitoring is enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_dashboard.main[0].dashboard_url : null
}

output "backup_vault_arn" {
  description = "AWS Backup vault ARN (only if backup is enabled)"
  value       = var.enable_backup ? aws_backup_vault.main[0].arn : "Backup not enabled"
}

# Environment-specific outputs
output "environment_specific_info" {
  description = "Environment-specific configuration information"
  value = var.environment == "production" ? {
    monitoring_enabled = true
    backup_enabled     = true
    multi_az          = true
    instance_type     = "t3.large"
  } : var.environment == "staging" ? {
    monitoring_enabled = true
    backup_enabled     = false
    multi_az          = false
    instance_type     = "t3.medium"
  } : {
    monitoring_enabled = false
    backup_enabled     = false
    multi_az          = false
    instance_type     = "t3.micro"
  }
}
```

### Computed and Derived Outputs
```hcl
# Calculated outputs
output "total_monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value = (
    # EC2 instances cost
    length(aws_instance.web) * (
      var.instance_type == "t3.micro" ? 8.76 :
      var.instance_type == "t3.small" ? 17.52 :
      var.instance_type == "t3.medium" ? 35.04 :
      var.instance_type == "t3.large" ? 70.08 : 140.16
    ) +
    # RDS cost
    (var.database_instance_class == "db.t3.micro" ? 17.52 :
     var.database_instance_class == "db.t3.small" ? 35.04 :
     var.database_instance_class == "db.t3.medium" ? 70.08 : 140.16) +
    # Storage cost (EBS + RDS)
    (var.ebs_volume_size * 0.10) + (var.database_storage_size * 0.115)
  )
}

# Resource counts
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    ec2_instances    = length(aws_instance.web)
    subnets         = length(aws_subnet.public) + length(aws_subnet.private)
    security_groups = length([aws_security_group.web, aws_security_group.database])
    load_balancers  = var.create_load_balancer ? 1 : 0
    databases       = 1
    total_resources = (
      length(aws_instance.web) +
      length(aws_subnet.public) +
      length(aws_subnet.private) +
      2 + # security groups
      (var.create_load_balancer ? 1 : 0) +
      1 # database
    )
  }
}
```

## Output Formatting and Processing

### Formatted String Outputs
```hcl
# Formatted connection strings
output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for instance in aws_instance.web :
    "ssh -i ${var.key_name}.pem ec2-user@${instance.public_ip}"
  ]
}

output "application_urls" {
  description = "Application URLs"
  value = [
    for instance in aws_instance.web :
    "http://${instance.public_ip}:${var.application_port}"
  ]
}

# Load balancer URL
output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "https://${aws_lb.main.dns_name}"
}

# Database connection examples
output "database_connection_examples" {
  description = "Database connection examples for different tools"
  value = {
    mysql_cli = "mysql -h ${aws_db_instance.main.endpoint} -P ${aws_db_instance.main.port} -u ${aws_db_instance.main.username} -p ${aws_db_instance.main.db_name}"
    
    python = "mysql+pymysql://${aws_db_instance.main.username}:PASSWORD@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
    
    nodejs = jsonencode({
      host     = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      user     = aws_db_instance.main.username
      password = "PASSWORD"
      database = aws_db_instance.main.db_name
    })
    
    java = "jdbc:mysql://${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}?user=${aws_db_instance.main.username}&password=PASSWORD"
  }
  sensitive = true
}
```

### JSON and YAML Outputs
```hcl
# JSON configuration output
output "application_config_json" {
  description = "Application configuration in JSON format"
  value = jsonencode({
    environment = var.environment
    
    database = {
      host     = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      name     = aws_db_instance.main.db_name
      username = aws_db_instance.main.username
    }
    
    cache = {
      host = aws_elasticache_cluster.main.cache_nodes[0].address
      port = aws_elasticache_cluster.main.cache_nodes[0].port
    }
    
    load_balancer = {
      dns_name = aws_lb.main.dns_name
      zone_id  = aws_lb.main.zone_id
    }
    
    instances = [
      for instance in aws_instance.web : {
        id         = instance.id
        private_ip = instance.private_ip
        az         = instance.availability_zone
      }
    ]
  })
}

# Kubernetes ConfigMap YAML
output "kubernetes_configmap_yaml" {
  description = "Kubernetes ConfigMap YAML for application configuration"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "${var.project_name}-config"
      namespace = "default"
    }
    data = {
      "database.host"     = aws_db_instance.main.endpoint
      "database.port"     = tostring(aws_db_instance.main.port)
      "database.name"     = aws_db_instance.main.db_name
      "cache.host"        = aws_elasticache_cluster.main.cache_nodes[0].address
      "cache.port"        = tostring(aws_elasticache_cluster.main.cache_nodes[0].port)
      "loadbalancer.dns"  = aws_lb.main.dns_name
      "environment"       = var.environment
    }
  })
}
```

## Sensitive Outputs

### Handling Sensitive Data
```hcl
# Sensitive database information
output "database_password" {
  description = "Database master password"
  value       = var.database_password
  sensitive   = true
}

output "database_connection_string_secure" {
  description = "Complete database connection string with credentials"
  value = {
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
    password = var.database_password
  }
  sensitive = true
}

# API keys and secrets
output "application_secrets" {
  description = "Application secrets and API keys"
  value = {
    api_key        = var.api_key
    jwt_secret     = var.jwt_secret
    encryption_key = var.encryption_key
  }
  sensitive = true
}
```

## Output Usage Patterns

### Module Outputs
```hcl
# Module outputs for reusability
output "vpc_module_outputs" {
  description = "VPC module outputs for use by other modules"
  value = {
    vpc_id              = aws_vpc.main.id
    vpc_cidr_block      = aws_vpc.main.cidr_block
    public_subnet_ids   = aws_subnet.public[*].id
    private_subnet_ids  = aws_subnet.private[*].id
    internet_gateway_id = aws_internet_gateway.main.id
    nat_gateway_ids     = aws_nat_gateway.main[*].id
    route_table_ids = {
      public  = aws_route_table.public.id
      private = aws_route_table.private[*].id
    }
  }
}

# Security group outputs
output "security_group_outputs" {
  description = "Security group outputs for use by other modules"
  value = {
    web_security_group_id      = aws_security_group.web.id
    app_security_group_id      = aws_security_group.app.id
    database_security_group_id = aws_security_group.database.id
  }
}
```

### Cross-Stack References
```hcl
# Outputs for cross-stack references
output "shared_infrastructure" {
  description = "Shared infrastructure information for other stacks"
  value = {
    # Network stack outputs
    network = {
      vpc_id             = aws_vpc.main.id
      public_subnet_ids  = aws_subnet.public[*].id
      private_subnet_ids = aws_subnet.private[*].id
    }
    
    # Security stack outputs
    security = {
      web_sg_id = aws_security_group.web.id
      app_sg_id = aws_security_group.app.id
      db_sg_id  = aws_security_group.database.id
    }
    
    # Shared services
    services = {
      load_balancer_arn      = aws_lb.main.arn
      load_balancer_dns_name = aws_lb.main.dns_name
      target_group_arn       = aws_lb_target_group.web.arn
    }
  }
}
```

### Debugging and Troubleshooting Outputs
```hcl
# Debug information outputs
output "debug_information" {
  description = "Debug information for troubleshooting"
  value = {
    terraform_version = "1.6.0"
    aws_region       = data.aws_region.current.name
    availability_zones = data.aws_availability_zones.available.names
    
    resource_counts = {
      instances       = length(aws_instance.web)
      subnets        = length(aws_subnet.public) + length(aws_subnet.private)
      security_groups = 3
    }
    
    configuration = {
      environment    = var.environment
      project_name   = var.project_name
      instance_type  = var.instance_type
      instance_count = var.instance_count
    }
    
    timestamps = {
      created_at = timestamp()
      plan_time  = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    }
  }
}

# Validation outputs
output "validation_results" {
  description = "Configuration validation results"
  value = {
    vpc_cidr_valid = can(cidrhost(aws_vpc.main.cidr_block, 0))
    
    subnet_count_valid = (
      length(aws_subnet.public) >= 2 &&
      length(aws_subnet.private) >= 2
    )
    
    instance_distribution = {
      for az in data.aws_availability_zones.available.names :
      az => length([
        for instance in aws_instance.web :
        instance.availability_zone if instance.availability_zone == az
      ])
    }
    
    security_groups_configured = {
      web_sg_rules = length(aws_security_group.web.ingress)
      app_sg_rules = length(aws_security_group.app.ingress)
      db_sg_rules  = length(aws_security_group.database.ingress)
    }
  }
}
```

This comprehensive guide covers all aspects of Terraform outputs, from basic resource information sharing to complex structured outputs, sensitive data handling, and cross-stack integration patterns.
