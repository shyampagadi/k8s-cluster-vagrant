# Problem 31: Disaster Recovery - Multi-Region Backup and Recovery
# Input variables for the disaster recovery configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "disaster-recovery"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "primary_vpc_cr" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cr" {
  description = "CIDR block for secondary VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "enable_automated_failover" {
  description = "Enable automated failover"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}
