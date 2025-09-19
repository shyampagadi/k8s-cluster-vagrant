# Error Handling and Validation - Variables

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "error-handling-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
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

# Random Configuration
variable "random_byte_length" {
  description = "Byte length for random ID generation"
  type        = number
  default     = 4
  
  validation {
    condition     = var.random_byte_length >= 1 && var.random_byte_length <= 8
    error_message = "Random byte length must be between 1 and 8."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 6
    error_message = "Subnet count must be between 1 and 6."
  }
}

# Security Configuration
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition     = length(var.ssh_cidr_blocks) > 0
    error_message = "At least one SSH CIDR block must be specified."
  }
  
  validation {
    condition     = alltrue([for cidr in var.ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

# Instance Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "web-app"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app_name))
    error_message = "App name must contain only lowercase letters, numbers, and hyphens."
  }
}

# Database Configuration
variable "create_database" {
  description = "Whether to create database"
  type        = bool
  default     = false
}

variable "database_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
  
  validation {
    condition     = contains(["mysql", "postgres", "oracle-ee", "sqlserver-ee"], var.database_engine)
    error_message = "Database engine must be mysql, postgres, oracle-ee, or sqlserver-ee."
  }
}

variable "database_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.database_version))
    error_message = "Database version must be in format 'major.minor' (e.g., 8.0)."
  }
}

variable "database_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.database_instance_class))
    error_message = "Database instance class must be a valid RDS instance class."
  }
}

variable "database_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.database_allocated_storage >= 20 && var.database_allocated_storage <= 1000
    error_message = "Database allocated storage must be between 20 and 1000 GB."
  }
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "webapp"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
  }
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "admin"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.database_username))
    error_message = "Database username must start with a letter and contain only alphanumeric characters."
  }
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "TempPassword123!"
  
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
  
  validation {
    condition     = can(regex(".*[A-Z].*", var.database_password))
    error_message = "Database password must contain at least one uppercase letter."
  }
  
  validation {
    condition     = can(regex(".*[a-z].*", var.database_password))
    error_message = "Database password must contain at least one lowercase letter."
  }
  
  validation {
    condition     = can(regex(".*[0-9].*", var.database_password))
    error_message = "Database password must contain at least one number."
  }
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 3306
  
  validation {
    condition     = var.database_port >= 1024 && var.database_port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

variable "backup_window" {
  description = "Database backup window"
  type        = string
  default     = "03:00-04:00"
  
  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = "Database maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
  
  validation {
    condition     = can(regex("^[a-z]{3}:[0-2][0-9]:[0-5][0-9]-[a-z]{3}:[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM."
  }
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ for database"
  type        = bool
  default     = false
}

# S3 Configuration
variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Block public access to S3 bucket"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# Error Handling Configuration
variable "enable_error_handling" {
  description = "Enable comprehensive error handling"
  type        = bool
  default     = true
}

variable "enable_validation" {
  description = "Enable comprehensive validation"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "error_threshold_cpu" {
  description = "CPU utilization threshold for alerts"
  type        = number
  default     = 80
  
  validation {
    condition     = var.error_threshold_cpu >= 50 && var.error_threshold_cpu <= 100
    error_message = "CPU threshold must be between 50 and 100."
  }
}

variable "error_threshold_disk" {
  description = "Disk utilization threshold for alerts"
  type        = number
  default     = 85
  
  validation {
    condition     = var.error_threshold_disk >= 50 && var.error_threshold_disk <= 100
    error_message = "Disk threshold must be between 50 and 100."
  }
}

variable "error_threshold_memory" {
  description = "Memory utilization threshold for alerts"
  type        = number
  default     = 80
  
  validation {
    condition     = var.error_threshold_memory >= 50 && var.error_threshold_memory <= 100
    error_message = "Memory threshold must be between 50 and 100."
  }
}

# Recovery Configuration
variable "enable_auto_recovery" {
  description = "Enable automatic recovery mechanisms"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365."
  }
}

variable "enable_rollback" {
  description = "Enable rollback capabilities"
  type        = bool
  default     = true
}

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for k, v in var.additional_tags : can(regex("^[a-zA-Z0-9\\s\\-_.:/=+@]*$", v))])
    error_message = "Tag values must contain only valid characters."
  }
}
