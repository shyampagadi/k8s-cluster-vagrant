# Security Fundamentals - Variables

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "security-demo"
  
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

# Security Configuration
variable "security_level" {
  description = "Security level for resources"
  type        = string
  default     = "high"
  
  validation {
    condition     = contains(["low", "medium", "high", "critical"], var.security_level)
    error_message = "Security level must be low, medium, high, or critical."
  }
}

variable "compliance_level" {
  description = "Compliance level for resources"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["basic", "standard", "high", "critical"], var.compliance_level)
    error_message = "Compliance level must be basic, standard, high, or critical."
  }
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "internal"
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be public, internal, confidential, or restricted."
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
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be in format 'family.size' (e.g., t3.micro)."
  }
}

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

# Security Features
variable "encryption_enabled" {
  description = "Enable encryption for resources"
  type        = bool
  default     = true
}

variable "backup_required" {
  description = "Whether backup is required"
  type        = bool
  default     = true
}

variable "monitoring_enabled" {
  description = "Enable monitoring for resources"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Enable audit logging"
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

# Security Scanning Configuration
variable "enable_security_scanning" {
  description = "Enable security scanning"
  type        = bool
  default     = true
}

variable "security_scanning_schedule" {
  description = "Schedule for security scanning"
  type        = string
  default     = "cron(0 2 * * ? *)"  # Daily at 2 AM
  
  validation {
    condition     = can(regex("^cron\\(.*\\)$", var.security_scanning_schedule))
    error_message = "Security scanning schedule must be a valid cron expression."
  }
}

# Compliance Configuration
variable "compliance_standards" {
  description = "Compliance standards to follow"
  type        = list(string)
  default     = ["SOC2", "PCI-DSS"]
  
  validation {
    condition     = length(var.compliance_standards) > 0
    error_message = "At least one compliance standard must be specified."
  }
}

variable "data_residency_requirements" {
  description = "Data residency requirements"
  type        = list(string)
  default     = ["US"]
  
  validation {
    condition     = length(var.data_residency_requirements) > 0
    error_message = "At least one data residency requirement must be specified."
  }
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
