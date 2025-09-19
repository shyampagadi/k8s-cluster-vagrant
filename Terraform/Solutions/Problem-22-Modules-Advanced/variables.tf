# Problem 22: Modules - Advanced Features and Patterns
# Input variables for the advanced module configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "advanced-modules"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "create_compute_resources" {
  description = "Whether to create compute resources"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size for auto scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size for auto scaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity for auto scaling group"
  type        = number
  default     = 2
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = false
}

variable "storage_configurations" {
  description = "Storage configurations for different purposes"
  type = map(object({
    purpose     = string
    versioning  = bool
    encryption  = bool
    lifecycle   = bool
  }))
  default = {
    logs = {
      purpose     = "logs"
      versioning  = true
      encryption  = true
      lifecycle   = true
    }
    data = {
      purpose     = "data"
      versioning  = false
      encryption  = true
      lifecycle   = false
    }
    backup = {
      purpose     = "backup"
      versioning  = true
      encryption  = true
      lifecycle   = true
    }
  }
}
