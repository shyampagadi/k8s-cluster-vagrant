# S3 Bucket Module Variables
# Input variables for the S3 bucket module

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "purpose" {
  description = "Purpose of the bucket (logs, data, backup, etc.)"
  type        = string
}
