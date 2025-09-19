# Conditional Logic and Dynamic Blocks - Variable Definitions

# String Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "conditional-logic-demo"
  
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
variable "development_instance_count" {
  description = "Number of instances for development environment"
  type        = number
  default     = 1
  
  validation {
    condition     = var.development_instance_count > 0 && var.development_instance_count <= 5
    error_message = "Development instance count must be between 1 and 5."
  }
}

variable "staging_instance_count" {
  description = "Number of instances for staging environment"
  type        = number
  default     = 2
  
  validation {
    condition     = var.staging_instance_count > 0 && var.staging_instance_count <= 5
    error_message = "Staging instance count must be between 1 and 5."
  }
}

variable "production_instance_count" {
  description = "Number of instances for production environment"
  type        = number
  default     = 3
  
  validation {
    condition     = var.production_instance_count > 0 && var.production_instance_count <= 10
    error_message = "Production instance count must be between 1 and 10."
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

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.root_volume_size > 0
    error_message = "Root volume size must be greater than 0."
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

variable "enable_egress" {
  description = "Enable egress rules for security groups"
  type        = bool
  default     = true
}

# Instance Type Variables
variable "development_instance_type" {
  description = "Instance type for development environment"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.development_instance_type))
    error_message = "Development instance type must be a valid AWS instance type."
  }
}

variable "staging_instance_type" {
  description = "Instance type for staging environment"
  type        = string
  default     = "t3.small"
  
  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.staging_instance_type))
    error_message = "Staging instance type must be a valid AWS instance type."
  }
}

variable "production_instance_type" {
  description = "Instance type for production environment"
  type        = string
  default     = "t3.large"
  
  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.production_instance_type))
    error_message = "Production instance type must be a valid AWS instance type."
  }
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

# Complex List Variables for Dynamic Blocks
variable "production_ingress_rules" {
  description = "List of ingress rules for production environment"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
}

variable "development_ingress_rules" {
  description = "List of ingress rules for development environment"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "egress_rules" {
  description = "List of egress rules for security groups"
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

# Complex List Variables for EBS Volumes
variable "production_volumes" {
  description = "List of EBS volumes for production environment"
  type = list(object({
    device_name = string
    size        = number
    type        = string
  }))
  default = [
    {
      device_name = "/dev/sdf"
      size        = 50
      type        = "gp3"
    },
    {
      device_name = "/dev/sdg"
      size        = 100
      type        = "gp3"
    }
  ]
}

variable "development_volumes" {
  description = "List of EBS volumes for development environment"
  type = list(object({
    device_name = string
    size        = number
    type        = string
  }))
  default = [
    {
      device_name = "/dev/sdf"
      size        = 20
      type        = "gp2"
    }
  ]
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
