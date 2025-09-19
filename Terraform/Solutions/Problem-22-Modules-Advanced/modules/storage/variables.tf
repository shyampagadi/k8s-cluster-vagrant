# Storage Module Variables
# Input variables for the storage module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_suffix" {
  description = "Unique project suffix for naming"
  type        = string
}

variable "storage_type" {
  description = "Type of storage (logs, data, backup, etc.)"
  type        = string
}

variable "storage_config" {
  description = "Storage configuration object"
  type = object({
    purpose     = string
    versioning  = bool
    encryption  = bool
    lifecycle   = bool
  })
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}
