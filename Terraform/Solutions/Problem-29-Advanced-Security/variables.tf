# Problem 29: Advanced Security - Zero Trust and Compliance
# Input variables for the advanced security configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "advanced-security"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for security monitoring"
  type        = string
  default     = "t3.medium"
}

variable "enable_zero_trust" {
  description = "Enable zero-trust architecture"
  type        = bool
  default     = true
}

variable "enable_compliance_monitoring" {
  description = "Enable compliance monitoring"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable encryption for all resources"
  type        = bool
  default     = true
}
