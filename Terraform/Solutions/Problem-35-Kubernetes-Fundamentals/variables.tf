# Variables for Problem 35: Kubernetes Fundamentals

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
  default     = "microservices-cluster"
}

variable "application_namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "applications"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# Database Configuration
variable "database_host" {
  description = "Database host"
  type        = string
  default     = "database-service"
}

variable "database_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "appuser"
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"
  sensitive   = true
}

# Application Configuration
variable "debug_mode" {
  description = "Enable debug mode"
  type        = string
  default     = "false"
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"
}

variable "max_connections" {
  description = "Maximum database connections"
  type        = string
  default     = "100"
}

variable "api_key" {
  description = "API key for external services"
  type        = string
  default     = "your-api-key-here"
  sensitive   = true
}

# Storage Configuration
variable "storage_size" {
  description = "Size of persistent volume"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "gp2"
}

# Web Application Configuration
variable "web_app_image" {
  description = "Docker image for web application"
  type        = string
  default     = "nginx:1.21"
}

variable "web_app_replicas" {
  description = "Number of web app replicas"
  type        = number
  default     = 3
}

variable "web_app_cpu_limit" {
  description = "CPU limit for web app containers"
  type        = string
  default     = "500m"
}

variable "web_app_memory_limit" {
  description = "Memory limit for web app containers"
  type        = string
  default     = "512Mi"
}

variable "web_app_cpu_request" {
  description = "CPU request for web app containers"
  type        = string
  default     = "250m"
}

variable "web_app_memory_request" {
  description = "Memory request for web app containers"
  type        = string
  default     = "256Mi"
}

# Database Configuration
variable "database_image" {
  description = "Docker image for database"
  type        = string
  default     = "postgres:13"
}

variable "database_replicas" {
  description = "Number of database replicas"
  type        = number
  default     = 1
}

variable "database_cpu_limit" {
  description = "CPU limit for database containers"
  type        = string
  default     = "1000m"
}

variable "database_memory_limit" {
  description = "Memory limit for database containers"
  type        = string
  default     = "1Gi"
}

variable "database_cpu_request" {
  description = "CPU request for database containers"
  type        = string
  default     = "500m"
}

variable "database_memory_request" {
  description = "Memory request for database containers"
  type        = string
  default     = "512Mi"
}

variable "database_storage_size" {
  description = "Size of database persistent volume"
  type        = string
  default     = "20Gi"
}

# Ingress Configuration
variable "app_domain" {
  description = "Domain name for the application"
  type        = string
  default     = "app.example.com"
}

# HPA Configuration
variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_cpu_target" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

# Backup Configuration
variable "backup_schedule" {
  description = "Cron schedule for database backups"
  type        = string
  default     = "0 2 * * *"
}
