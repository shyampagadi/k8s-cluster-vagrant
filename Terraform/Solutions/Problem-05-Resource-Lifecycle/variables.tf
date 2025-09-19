# Resource Lifecycle and State Management - Variable Definitions

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "resource-lifecycle-demo"
  
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

# AWS Configuration
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

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}

# EC2 Configuration
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

# Security Configuration
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
}

# Database Configuration
variable "create_database" {
  description = "Create database instance"
  type        = bool
  default     = false
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine    = string
    engine_version = string
    instance_class = string
    allocated_storage = number
    backup_retention_period = number
    db_name   = string
    username  = string
  })
  default = {
    engine    = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    backup_retention_period = 7
    db_name   = "webapp"
    username  = "admin"
  }
  
  validation {
    condition     = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring for instances"
  type        = bool
  default     = true
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    retention_days = number
    alert_threshold = number
  })
  default = {
    retention_days = 30
    alert_threshold = 80.0
  }
  
  validation {
    condition     = var.monitoring_config.retention_days > 0
    error_message = "Retention days must be greater than 0."
  }
}

# Lifecycle Configuration
variable "prevent_destroy" {
  description = "Prevent destruction of critical resources"
  type        = bool
  default     = false
}

variable "create_example_resource" {
  description = "Create example null resource"
  type        = bool
  default     = true
}

# Additional Configuration
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
