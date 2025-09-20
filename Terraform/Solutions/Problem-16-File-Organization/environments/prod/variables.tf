# Production Environment Variables

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
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "prod_instance_count" {
  description = "Number of instances for production"
  type        = number
  default     = 3
}

variable "prod_instance_type" {
  description = "Instance type for production"
  type        = string
  default     = "t3.medium"
}
