# Variables for Problem 22: Advanced Modules

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "advanced-modules"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "compliance_level" {
  description = "Compliance level required"
  type        = string
  default     = "high"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 3
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_network_acls" {
  description = "Enable Network ACLs"
  type        = bool
  default     = true
}

variable "enable_dhcp_options" {
  description = "Enable DHCP Options"
  type        = bool
  default     = false
}

variable "nat_gateway_per_az" {
  description = "Create NAT Gateway per AZ"
  type        = bool
  default     = true
}

# Compute Configuration
variable "web_instance_type" {
  description = "Instance type for web tier"
  type        = string
  default     = "t3.medium"
}

variable "web_min_size" {
  description = "Minimum size for web tier ASG"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum size for web tier ASG"
  type        = number
  default     = 10
}

variable "web_desired_capacity" {
  description = "Desired capacity for web tier ASG"
  type        = number
  default     = 3
}

variable "app_instance_type" {
  description = "Instance type for app tier"
  type        = string
  default     = "t3.large"
}

variable "app_min_size" {
  description = "Minimum size for app tier ASG"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum size for app tier ASG"
  type        = number
  default     = 10
}

variable "app_desired_capacity" {
  description = "Desired capacity for app tier ASG"
  type        = number
  default     = 3
}

variable "cpu_high_threshold" {
  description = "CPU high threshold for scaling"
  type        = number
  default     = 80
}

variable "cpu_low_threshold" {
  description = "CPU low threshold for scaling"
  type        = number
  default     = 20
}

# Load Balancer Configuration
variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate"
  type        = string
  default     = null
}

variable "enable_alb_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = true
}

# Database Configuration
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Database allocated storage"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Database max allocated storage"
  type        = number
  default     = 1000
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Database backup retention period"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Database backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Database maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "create_read_replicas" {
  description = "Create read replicas"
  type        = bool
  default     = false
}

variable "db_replica_instance_class" {
  description = "Database replica instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_monitoring_interval" {
  description = "Database monitoring interval"
  type        = number
  default     = 60
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = false
}

# Security Configuration
variable "external_api_key" {
  description = "External API key"
  type        = string
  default     = "your-api-key-here"
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  default     = "your-jwt-secret-here"
  sensitive   = true
}

# DNS Configuration
variable "create_dns_records" {
  description = "Create DNS records"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "example.com"
}

variable "create_hosted_zone" {
  description = "Create hosted zone"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = "admin@example.com"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL"
  type        = string
  default     = null
}

# Logging Configuration
variable "enable_cloudtrail" {
  description = "Enable CloudTrail"
  type        = bool
  default     = true
}
