# Problem 28: CI/CD Integration - DevOps Automation
# Input variables for the CI/CD integration configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ci-cd-integration"
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

variable "instance_type" {
  description = "EC2 instance type for CI/CD runner"
  type        = string
  default     = "t3.medium"
}

variable "enable_automated_testing" {
  description = "Enable automated testing"
  type        = bool
  default     = true
}

variable "enable_security_scanning" {
  description = "Enable security scanning"
  type        = bool
  default     = true
}
