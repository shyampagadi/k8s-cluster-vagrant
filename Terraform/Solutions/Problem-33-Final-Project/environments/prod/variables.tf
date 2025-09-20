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
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# Production-specific values
variable "prod_instance_type" {
  description = "Instance type for production"
  type        = string
  default     = "t3.medium"
}

variable "prod_min_size" {
  description = "Minimum number of instances for production"
  type        = number
  default     = 3
}

variable "prod_max_size" {
  description = "Maximum number of instances for production"
  type        = number
  default     = 10
}

variable "prod_desired_capacity" {
  description = "Desired number of instances for production"
  type        = number
  default     = 3
}

variable "prod_db_instance_class" {
  description = "Database instance class for production"
  type        = string
  default     = "db.t3.medium"
}

variable "prod_db_allocated_storage" {
  description = "Database allocated storage for production"
  type        = number
  default     = 100
}

variable "prod_db_max_allocated_storage" {
  description = "Database max allocated storage for production"
  type        = number
  default     = 1000
}

variable "prod_db_backup_retention_period" {
  description = "Database backup retention period for production"
  type        = number
  default     = 7
}

variable "prod_log_retention_days" {
  description = "Log retention days for production"
  type        = number
  default     = 30
}
