# Variables - Complex Types and Validation - Variable Definitions

# String Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "complex-variables-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "web-app"
  
  validation {
    condition     = length(var.app_name) > 0
    error_message = "App name cannot be empty."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = ""
  
  validation {
    condition     = var.ami_id == "" || can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "AMI ID must be a valid AWS AMI identifier."
  }
}

# Number Variables
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "hourly_rate" {
  description = "Hourly rate for cost calculation"
  type        = number
  default     = 0.0234
  
  validation {
    condition     = var.hourly_rate > 0
    error_message = "Hourly rate must be greater than 0."
  }
}

variable "database_port" {
  description = "Port number for database"
  type        = number
  default     = 3306
  
  validation {
    condition     = var.database_port > 0 && var.database_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days > 0
    error_message = "Log retention days must be greater than 0."
  }
}

# Boolean Variables
variable "create_database" {
  description = "Create database instance"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring for instances"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption for resources"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support for VPC"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Block public access to S3 bucket"
  type        = bool
  default     = true
}

# List Variables
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

variable "port_numbers" {
  description = "List of port numbers"
  type        = list(number)
  default     = [80, 443, 8080]
  
  validation {
    condition     = alltrue([for port in var.port_numbers : port > 0 && port <= 65535])
    error_message = "All ports must be between 1 and 65535."
  }
}

variable "unique_tags" {
  description = "Set of unique tags"
  type        = set(string)
  default     = ["production", "web", "frontend"]
}

variable "unique_ports" {
  description = "Set of unique port numbers"
  type        = set(number)
  default     = [80, 443, 8080, 8443]
}

# Map Variables
variable "environment_tags" {
  description = "Map of environment-specific tags"
  type        = map(string)
  default     = {
    Environment = "development"
    Project     = "complex-variables-demo"
    Owner       = "devops-team"
    CostCenter  = "engineering"
  }
  
  validation {
    condition     = contains(keys(var.environment_tags), "Environment")
    error_message = "Environment tag is required."
  }
}

variable "server_configs" {
  description = "Map of server configurations"
  type = map(object({
    instance_type = string
    disk_size     = number
    monitoring    = bool
    environment   = string
  }))
  default = {
    web = {
      instance_type = "t3.micro"
      disk_size     = 20
      monitoring    = true
      environment   = "production"
    }
    db = {
      instance_type = "t3.small"
      disk_size     = 100
      monitoring    = true
      environment   = "production"
    }
    cache = {
      instance_type = "t3.micro"
      disk_size     = 10
      monitoring    = false
      environment   = "development"
    }
  }
  
  validation {
    condition     = alltrue([for name, config in var.server_configs : can(regex("^[a-z0-9.]+$", config.instance_type))])
    error_message = "All instance types must be valid AWS instance types."
  }
}

# Tuple Variables
variable "server_info" {
  description = "Tuple containing server information"
  type        = tuple([string, number, bool])
  default     = ["web-server", 3, true]
}

variable "database_info" {
  description = "Tuple containing database information"
  type        = tuple([string, string, number, bool])
  default     = ["mysql", "8.0", 100, false]
}

# Object Variables
variable "database_config" {
  description = "Database configuration object"
  type = object({
    engine    = string
    version   = string
    instance_class = string
    allocated_storage = number
    backup_retention_period = number
    multi_az  = bool
    db_name   = string
    username  = string
  })
  default = {
    engine    = "mysql"
    version   = "8.0"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    backup_retention_period = 7
    multi_az  = false
    db_name   = "webapp"
    username  = "admin"
  }
  
  validation {
    condition     = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

# Complex List of Objects
variable "ingress_ports" {
  description = "List of ingress port configurations"
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
    },
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
  
  validation {
    condition     = alltrue([for rule in var.ingress_ports : rule.port > 0 && rule.port <= 65535])
    error_message = "All ports must be between 1 and 65535."
  }
}

variable "egress_rules" {
  description = "List of egress rule configurations"
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

# Sensitive Variables
variable "database_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"
  sensitive   = true
  
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# Backup Configuration Variables
variable "backup_retention_production" {
  description = "Backup retention period for production (days)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_production > 0
    error_message = "Production backup retention must be greater than 0."
  }
}

variable "backup_retention_development" {
  description = "Backup retention period for development (days)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_development > 0
    error_message = "Development backup retention must be greater than 0."
  }
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
  
  validation {
    condition     = can(regex("^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$", var.backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
  
  validation {
    condition     = can(regex("^[a-z]{3}:[0-9]{2}:[0-9]{2}-[a-z]{3}:[0-9]{2}:[0-9]{2}$", var.maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM."
  }
}

# Additional Configuration
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
