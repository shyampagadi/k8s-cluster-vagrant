# HCL Syntax Deep Dive - Variable Definitions

# String Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hcl-syntax-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
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

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Number Variables
variable "instance_count" {
  description = "Number of web instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "web_count" {
  description = "Number of web instances"
  type        = number
  default     = 2
}

variable "db_count" {
  description = "Number of database instances"
  type        = number
  default     = 1
}

variable "total_count" {
  description = "Total number of instances"
  type        = number
  default     = 3
}

variable "cpu_threshold" {
  description = "CPU utilization threshold percentage"
  type        = number
  default     = 80.0
  
  validation {
    condition     = var.cpu_threshold >= 0.0 && var.cpu_threshold <= 100.0
    error_message = "CPU threshold must be between 0 and 100."
  }
}

# Boolean Variables
variable "monitoring_enabled" {
  description = "Enable monitoring for instances"
  type        = bool
  default     = true
}

variable "create_database" {
  description = "Create database instance"
  type        = bool
  default     = false
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

# Set Variables
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
    Project     = "hcl-syntax-demo"
    Owner       = "devops-team"
    CostCenter  = "engineering"
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

variable "monitoring_config" {
  description = "Monitoring configuration object"
  type = object({
    enabled = bool
    retention_days = number
    alert_threshold = number
    notification_email = string
  })
  default = {
    enabled = true
    retention_days = 30
    alert_threshold = 80.0
    notification_email = "admin@example.com"
  }
}

# Complex Nested Object Variables
variable "application_config" {
  description = "Complex application configuration"
  type = object({
    name = string
    version = string
    database = object({
      engine = string
      version = string
      instance_class = string
    })
    monitoring = object({
      enabled = bool
      retention_days = number
      alert_threshold = number
    })
    scaling = object({
      min_instances = number
      max_instances = number
      target_cpu = number
    })
  })
  default = {
    name = "web-app"
    version = "1.0.0"
    database = {
      engine = "mysql"
      version = "8.0"
      instance_class = "db.t3.micro"
    }
    monitoring = {
      enabled = true
      retention_days = 30
      alert_threshold = 80.0
    }
    scaling = {
      min_instances = 2
      max_instances = 10
      target_cpu = 70.0
    }
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

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
