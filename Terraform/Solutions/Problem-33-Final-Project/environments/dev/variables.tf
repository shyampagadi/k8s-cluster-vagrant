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
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# Development-specific values
variable "dev_instance_type" {
  description = "Instance type for development"
  type        = string
  default     = "t3.micro"
}

variable "dev_min_size" {
  description = "Minimum number of instances for development"
  type        = number
  default     = 1
}

variable "dev_max_size" {
  description = "Maximum number of instances for development"
  type        = number
  default     = 3
}

variable "dev_desired_capacity" {
  description = "Desired number of instances for development"
  type        = number
  default     = 1
}

variable "dev_db_instance_class" {
  description = "Database instance class for development"
  type        = string
  default     = "db.t3.micro"
}

variable "dev_db_allocated_storage" {
  description = "Database allocated storage for development"
  type        = number
  default     = 20
}

variable "dev_db_max_allocated_storage" {
  description = "Database max allocated storage for development"
  type        = number
  default     = 50
}

variable "dev_db_backup_retention_period" {
  description = "Database backup retention period for development"
  type        = number
  default     = 1
}

variable "dev_log_retention_days" {
  description = "Log retention days for development"
  type        = number
  default     = 7
}
