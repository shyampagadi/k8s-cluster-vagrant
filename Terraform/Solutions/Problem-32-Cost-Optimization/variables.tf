# Problem 32: Cost Optimization - Resource Efficiency and Monitoring
# Input variables for the cost optimization configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cost-optimization"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type (cost-optimized)"
  type        = string
  default     = "t3.small"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 5
}

variable "desired_instances" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "enable_spot_instances" {
  description = "Enable spot instances for cost savings"
  type        = bool
  default     = false
}

variable "enable_reserved_instances" {
  description = "Enable reserved instances for cost savings"
  type        = bool
  default     = false
}
