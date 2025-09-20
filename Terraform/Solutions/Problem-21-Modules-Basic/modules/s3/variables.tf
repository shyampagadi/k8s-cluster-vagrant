# S3 Module - variables.tf

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state"
  type        = bool
  default     = false
}

variable "server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration"
  type        = any
  default     = null
}

variable "public_access_block" {
  description = "Map containing public access block configuration"
  type        = any
  default     = null
}

variable "lifecycle_configuration" {
  description = "Map containing lifecycle configuration"
  type        = any
  default     = null
}

variable "cors_rule" {
  description = "List of maps containing rules for Cross-Origin Resource Sharing"
  type        = any
  default     = null
}

variable "website" {
  description = "Map containing static web-site hosting or redirect configuration"
  type        = any
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}
