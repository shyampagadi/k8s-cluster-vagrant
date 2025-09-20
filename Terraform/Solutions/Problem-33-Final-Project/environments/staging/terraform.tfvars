# Staging Environment Variable Values

project_name = "final-project"
aws_region   = "us-west-2"
vpc_cidr     = "10.1.0.0/16"

availability_zones = ["us-west-2a", "us-west-2b"]

# Staging-specific values
staging_instance_type = "t3.small"
staging_min_size = 2
staging_max_size = 5
staging_desired_capacity = 2

staging_db_instance_class = "db.t3.small"
staging_db_allocated_storage = 50
staging_db_max_allocated_storage = 100
staging_db_backup_retention_period = 3

staging_log_retention_days = 14
