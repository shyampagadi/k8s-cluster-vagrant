# Problem 26: Advanced Loops - Complex Iteration Patterns
# Input variables for the advanced loops configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "advanced-loops"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_all_environments" {
  description = "Enable all environments (dev, staging, prod)"
  type        = bool
  default     = true
}

variable "custom_instance_types" {
  description = "Custom instance types override for environments"
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

variable "custom_instance_counts" {
  description = "Custom instance counts override for environments"
  type = map(number)
  default = {
    dev     = 2
    staging = 3
    prod    = 5
  }
}
