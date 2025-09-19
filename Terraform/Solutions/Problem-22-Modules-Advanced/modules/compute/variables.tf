# Compute Module Variables
# Input variables for the compute module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_suffix" {
  description = "Unique project suffix for naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups"
  type = object({
    web      = string
    database = string
  })
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum size for auto scaling group"
  type        = number
}

variable "max_size" {
  description = "Maximum size for auto scaling group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity for auto scaling group"
  type        = number
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling"
  type        = bool
  default     = true
}
