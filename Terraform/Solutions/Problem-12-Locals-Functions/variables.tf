# Locals and Functions - Variable Definitions

# String Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "locals-functions-demo"
  
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
  default     = 2
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type."
  }
}

variable "instance_hourly_cost" {
  description = "Hourly cost per instance in USD"
  type        = number
  default     = 0.01
  
  validation {
    condition     = var.instance_hourly_cost > 0
    error_message = "Instance hourly cost must be greater than 0."
  }
}

variable "total_cost" {
  description = "Total cost for all instances"
  type        = number
  default     = 0.02
  
  validation {
    condition     = var.total_cost > 0
    error_message = "Total cost must be greater than 0."
  }
}

variable "cpu_threshold" {
  description = "CPU threshold percentage"
  type        = number
  default     = 80
  
  validation {
    condition     = var.cpu_threshold > 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "storage_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.storage_gb > 0
    error_message = "Storage size must be greater than 0."
  }
}

variable "duration_hours" {
  description = "Duration in hours"
  type        = number
  default     = 24
  
  validation {
    condition     = var.duration_hours > 0
    error_message = "Duration must be greater than 0."
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

variable "enable_multi_az" {
  description = "Enable Multi-AZ for database"
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

# Map Variables for Function Examples
variable "app_config" {
  description = "Application configuration"
  type        = map(string)
  default     = {
    app_name = "web-app"
    environment = "development"
    version = "1.0.0"
    debug = "false"
  }
}

variable "enabled_features" {
  description = "Enabled features"
  type        = list(string)
  default     = ["monitoring", "logging", "backup"]
}

variable "database_config" {
  description = "Database configuration"
  type        = map(string)
  default     = {
    host = "localhost"
    port = "3306"
    name = "webapp"
    username = "admin"
    ssl = "true"
  }
}

# Complex Map Variables for Function Examples
variable "server_configs" {
  description = "Map of server configurations for function examples"
  type = map(object({
    instance_type = string
    disk_size_gb  = number
    hourly_cost   = number
    enabled       = bool
  }))
  default = {
    web1 = {
      instance_type = "t3.micro"
      disk_size_gb  = 20
      hourly_cost   = 0.01
      enabled       = true
    }
    web2 = {
      instance_type = "t3.micro"
      disk_size_gb  = 20
      hourly_cost   = 0.01
      enabled       = true
    }
    app1 = {
      instance_type = "t3.small"
      disk_size_gb  = 50
      hourly_cost   = 0.02
      enabled       = true
    }
    app2 = {
      instance_type = "t3.small"
      disk_size_gb  = 50
      hourly_cost   = 0.02
      enabled       = false
    }
  }
  
  validation {
    condition     = alltrue([for name, config in var.server_configs : config.disk_size_gb > 0])
    error_message = "All disk sizes must be greater than 0."
  }
}

# Database Configuration Variables
variable "database_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
  
  validation {
    condition     = contains(["mysql", "postgres", "oracle-ee", "sqlserver-ee"], var.database_engine)
    error_message = "Database engine must be one of: mysql, postgres, oracle-ee, sqlserver-ee."
  }
}

variable "database_version" {
  description = "Database version"
  type        = string
  default     = "8.0"
  
  validation {
    condition     = length(var.database_version) > 0
    error_message = "Database version cannot be empty."
  }
}

variable "database_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition     = can(regex("^db\\.[a-z0-9.]+$", var.database_instance_class))
    error_message = "Database instance class must be a valid AWS RDS instance class."
  }
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "webapp"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "admin"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_username))
    error_message = "Database username must start with a letter and contain only letters, numbers, and underscores."
  }
}

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

variable "database_allocated_storage" {
  description = "Allocated storage for database in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.database_allocated_storage >= 20
    error_message = "Database allocated storage must be at least 20 GB."
  }
}

# Backup Configuration Variables
variable "backup_retention_period" {
  description = "Backup retention period (days)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period > 0
    error_message = "Backup retention period must be greater than 0."
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
