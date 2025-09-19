# Problem 30: Production Deployment - Blue-Green and Canary
# Input variables for the production deployment configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "production-deployment"
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
  description = "EC2 instance type for application"
  type        = string
  default     = "t3.medium"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "desired_instances" {
  description = "Desired number of instances"
  type        = number
  default     = 3
}

variable "enable_blue_green" {
  description = "Enable blue-green deployment"
  type        = bool
  default     = true
}

variable "enable_canary" {
  description = "Enable canary deployment"
  type        = bool
  default     = false
}
