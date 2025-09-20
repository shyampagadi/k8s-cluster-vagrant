# Staging Environment Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "file-organization-demo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "staging_instance_count" {
  description = "Number of instances for staging"
  type        = number
  default     = 2
}

variable "staging_instance_type" {
  description = "Instance type for staging"
  type        = string
  default     = "t3.small"
}
