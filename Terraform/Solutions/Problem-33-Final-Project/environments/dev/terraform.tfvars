# Development Environment Variable Values

project_name = "final-project"
aws_region   = "us-west-2"
vpc_cidr     = "10.0.0.0/16"

availability_zones = ["us-west-2a", "us-west-2b"]

# Development-specific values
dev_instance_type = "t3.micro"
dev_min_size = 1
dev_max_size = 3
dev_desired_capacity = 1

dev_db_instance_class = "db.t3.micro"
dev_db_allocated_storage = 20
dev_db_max_allocated_storage = 50
dev_db_backup_retention_period = 1

dev_log_retention_days = 7
