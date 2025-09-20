# Problem 34: Career Preparation - Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the portfolio project"
  type        = string
  default     = "terraform-portfolio"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "portfolio"
}

variable "domain_name" {
  description = "Domain name for the portfolio website"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = ""
}

variable "github_username" {
  description = "GitHub username for repository links"
  type        = string
  default     = ""
}

variable "linkedin_profile" {
  description = "LinkedIn profile URL"
  type        = string
  default     = ""
}

variable "contact_email" {
  description = "Contact email address"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and dashboards"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Terraform Portfolio"
    Environment = "Portfolio"
    Purpose     = "Career Preparation"
    ManagedBy   = "Terraform"
  }
}
