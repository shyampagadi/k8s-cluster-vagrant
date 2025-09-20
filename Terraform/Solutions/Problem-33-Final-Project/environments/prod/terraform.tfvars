# Production Environment Variable Values

project_name = "final-project"
aws_region   = "us-west-2"
vpc_cidr     = "10.2.0.0/16"

availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Production-specific values
prod_instance_type = "t3.medium"
prod_min_size = 3
prod_max_size = 10
prod_desired_capacity = 3

prod_db_instance_class = "db.t3.medium"
prod_db_allocated_storage = 100
prod_db_max_allocated_storage = 1000
prod_db_backup_retention_period = 7

prod_log_retention_days = 30
