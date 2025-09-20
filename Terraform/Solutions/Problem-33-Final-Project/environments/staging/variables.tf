# Development Environment Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "final-project"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# Development-specific values
variable "staging_instance_type" {
  description = "Instance type for staging"
  type        = string
  default     = "t3.small"
}

variable "staging_min_size" {
  description = "Minimum number of instances for staging"
  type        = number
  default     = 2
}

variable "staging_max_size" {
  description = "Maximum number of instances for staging"
  type        = number
  default     = 5
}

variable "staging_desired_capacity" {
  description = "Desired number of instances for staging"
  type        = number
  default     = 2
}

variable "staging_db_instance_class" {
  description = "Database instance class for staging"
  type        = string
  default     = "db.t3.small"
}

variable "staging_db_allocated_storage" {
  description = "Database allocated storage for staging"
  type        = number
  default     = 50
}

variable "staging_db_max_allocated_storage" {
  description = "Database max allocated storage for staging"
  type        = number
  default     = 100
}

variable "staging_db_backup_retention_period" {
  description = "Database backup retention period for staging"
  type        = number
  default     = 3
}

variable "staging_log_retention_days" {
  description = "Log retention days for staging"
  type        = number
  default     = 14
}
