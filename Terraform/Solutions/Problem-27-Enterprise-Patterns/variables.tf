# Problem 27: Enterprise Patterns - Large-Scale Infrastructure
# Input variables for the enterprise patterns configuration

variable "enterprise_name" {
  description = "Name of the enterprise project"
  type        = string
  default     = "enterprise-demo"
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

variable "primary_azs" {
  description = "Availability zones for primary region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "secondary_azs" {
  description = "Availability zones for secondary region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enterprise_instance_type" {
  description = "EC2 instance type for enterprise workloads"
  type        = string
  default     = "t3.large"
}

variable "min_instances" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 3
}

variable "max_instances" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 10
}

variable "desired_instances" {
  description = "Desired number of instances in auto scaling group"
  type        = number
  default     = 5
}
