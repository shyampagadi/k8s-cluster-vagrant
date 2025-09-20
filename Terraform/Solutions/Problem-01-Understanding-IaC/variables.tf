# Problem 1: Understanding Infrastructure as Code - Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the IaC demonstration project"
  type        = string
  default     = "iac-fundamentals"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "enable_logging" {
  description = "Enable CloudWatch logging for demonstration"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "IaC Fundamentals"
    Purpose   = "Learning"
    ManagedBy = "Terraform"
  }
}
