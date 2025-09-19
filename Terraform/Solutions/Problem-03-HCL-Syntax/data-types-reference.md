# HCL Data Types Reference

## Overview

This reference provides comprehensive coverage of all HCL data types, their usage, validation, and best practices. Understanding data types is crucial for writing effective Terraform configurations.

## Primitive Types

### String

Strings represent text data and are the most commonly used data type in HCL.

#### Basic String Syntax
```hcl
# Simple string
name = "web-server"
description = "Web server instance"

# String with special characters
path = "C:\\Program Files\\Apache"
url = "https://example.com/api/v1"
```

#### Multi-line Strings
```hcl
# Multi-line string with heredoc
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
EOF

# Multi-line string with different delimiter
script_content = <<-SCRIPT
  #!/bin/bash
  echo "Starting application..."
  ./start.sh
SCRIPT
```

#### String Interpolation
```hcl
# Basic interpolation
bucket_name = "${var.project_name}-${var.environment}"

# Complex interpolation
instance_name = "${var.project_name}-${var.environment}-web-${count.index + 1}"

# Conditional interpolation
dns_name = var.environment == "production" ? "${var.subdomain}.${var.domain}" : "dev.${var.domain}"
```

#### String Functions
```hcl
# Format strings
formatted_name = format("%s-%s-%d", var.project_name, var.environment, random_id.suffix.hex)

# Case conversion
upper_name = upper(var.project_name)
lower_name = lower(var.project_name)

# String manipulation
trimmed_name = trimspace(var.project_name)
clean_name = replace(var.project_name, "_", "-")

# String splitting and joining
parts = split("-", var.project_name)
joined_name = join("-", ["web", "server", "01"])
```

#### String Validation
```hcl
variable "project_name" {
  type        = string
  description = "Name of the project"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}
```

### Number

Numbers represent numeric values, including integers and floating-point numbers.

#### Integer Numbers
```hcl
# Simple integers
count = 3
port = 80
timeout = 300

# Integer expressions
total_instances = var.web_count + var.db_count
half_count = var.total_count / 2
remainder = var.total_count % 3
```

#### Floating-Point Numbers
```hcl
# Float values
cpu_threshold = 80.5
memory_usage = 75.25
cost_per_hour = 0.0234

# Float expressions
total_cost = var.instance_count * var.hourly_rate
average_cost = total_cost / var.instance_count
```

#### Number Validation
```hcl
variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "cpu_threshold" {
  type        = number
  description = "CPU utilization threshold"
  default     = 80.0
  
  validation {
    condition     = var.cpu_threshold >= 0.0 && var.cpu_threshold <= 100.0
    error_message = "CPU threshold must be between 0 and 100."
  }
}
```

#### Number Functions
```hcl
# Mathematical functions
max_value = max(var.value1, var.value2, var.value3)
min_value = min(var.value1, var.value2, var.value3)
abs_value = abs(var.negative_number)

# Rounding functions
rounded_up = ceil(var.float_value)
rounded_down = floor(var.float_value)
rounded = round(var.float_value)
```

### Boolean

Booleans represent true/false values and are used for conditional logic.

#### Basic Boolean Values
```hcl
# Simple boolean values
enable_monitoring = true
enable_debug_logging = false
enable_encryption = true
```

#### Boolean Expressions
```hcl
# Comparison expressions
is_production = var.environment == "production"
is_development = var.environment == "development"
has_enough_instances = var.instance_count >= 3

# Logical expressions
enable_monitoring = var.environment == "production" && var.monitoring_enabled
is_development_or_staging = var.environment == "development" || var.environment == "staging"
should_backup = !var.skip_backup
```

#### Boolean Validation
```hcl
variable "enable_monitoring" {
  type        = bool
  description = "Enable monitoring for instances"
  default     = true
}

variable "enable_debug_logging" {
  type        = bool
  description = "Enable debug logging"
  default     = false
}
```

#### Boolean Functions
```hcl
# Boolean functions
all_true = alltrue([var.condition1, var.condition2, var.condition3])
any_true = anytrue([var.condition1, var.condition2, var.condition3])
```

## Collection Types

### List

Lists represent ordered collections of values of the same type.

#### List of Strings
```hcl
# Simple list of strings
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
security_groups = ["web-sg", "db-sg", "cache-sg"]

# List with expressions
instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
```

#### List of Numbers
```hcl
# List of numbers
port_numbers = [80, 443, 8080, 8443]
cpu_values = [0.5, 1.0, 2.0, 4.0]

# List with expressions
port_ranges = [for i in range(5) : 8000 + i]
```

#### List of Objects
```hcl
# List of objects
security_groups = [
  {
    name        = "web"
    description = "Web server security group"
    ports       = [80, 443]
    protocol    = "tcp"
  },
  {
    name        = "database"
    description = "Database security group"
    ports       = [3306, 5432]
    protocol    = "tcp"
  }
]
```

#### List Functions
```hcl
# List manipulation
first_item = var.items[0]
last_item = var.items[length(var.items) - 1]
item_count = length(var.items)

# List filtering
even_numbers = [for i in var.numbers : i if i % 2 == 0]
positive_numbers = [for i in var.numbers : i if i > 0]

# List transformation
doubled_numbers = [for i in var.numbers : i * 2]
formatted_names = [for name in var.names : upper(name)]
```

#### List Validation
```hcl
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-west-2a", "us-west-2b"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified."
  }
}
```

### Set

Sets represent collections of unique values of the same type.

#### Set of Strings
```hcl
# Set of strings (unique values)
unique_tags = ["production", "web", "frontend", "production"]  # Duplicates removed
unique_regions = ["us-west-2", "us-east-1", "eu-west-1"]
```

#### Set of Numbers
```hcl
# Set of numbers
unique_ports = [80, 443, 8080, 80]  # Duplicates removed
unique_sizes = [1, 2, 4, 8, 16]
```

#### Set Functions
```hcl
# Set operations
unique_items = toset(var.items)
set_size = length(toset(var.items))

# Set filtering
unique_even_numbers = toset([for i in var.numbers : i if i % 2 == 0])
```

#### Set Validation
```hcl
variable "unique_tags" {
  type        = set(string)
  description = "Set of unique tags"
  default     = ["production", "web", "frontend"]
}
```

### Map

Maps represent key-value pairs where keys are strings and values can be any type.

#### Map of Strings
```hcl
# Simple map of strings
environment_tags = {
  Environment = "production"
  Project     = "web-app"
  Owner       = "devops-team"
  CostCenter  = "engineering"
}

# Map with expressions
dynamic_tags = {
  Environment = var.environment
  Project     = var.project_name
  ManagedBy   = "Terraform"
  CreatedAt   = timestamp()
}
```

#### Map of Objects
```hcl
# Map of objects
server_configs = {
  web = {
    instance_type = "t3.micro"
    disk_size     = 20
    monitoring    = true
    ports         = [80, 443]
  }
  db = {
    instance_type = "t3.small"
    disk_size     = 100
    monitoring    = true
    ports         = [3306, 5432]
  }
  cache = {
    instance_type = "t3.micro"
    disk_size     = 10
    monitoring    = false
    ports         = [6379]
  }
}
```

#### Map Functions
```hcl
# Map operations
has_key = contains(keys(var.tags), "Environment")
tag_count = length(var.tags)
all_keys = keys(var.server_configs)
all_values = values(var.server_configs)

# Map filtering
production_configs = {
  for name, config in var.server_configs : name => config
  if config.environment == "production"
}

# Map transformation
scaled_configs = {
  for name, config in var.server_configs : name => {
    instance_type = config.instance_type
    disk_size     = config.disk_size * 2
    monitoring    = config.monitoring
  }
}
```

#### Map Validation
```hcl
variable "environment_tags" {
  type        = map(string)
  description = "Map of environment tags"
  default     = {
    Environment = "production"
    Project     = "web-app"
  }
  
  validation {
    condition     = contains(keys(var.environment_tags), "Environment")
    error_message = "Environment tag is required."
  }
}
```

### Tuple

Tuples represent fixed-length lists with elements of different types.

#### Basic Tuples
```hcl
# Tuple with different types
server_info = ["web-server", 3, true]
database_config = ["mysql", "8.0", 100, false]
```

#### Tuple Functions
```hcl
# Tuple operations
first_element = var.tuple[0]
second_element = var.tuple[1]
tuple_length = length(var.tuple)
```

#### Tuple Validation
```hcl
variable "server_info" {
  type        = tuple([string, number, bool])
  description = "Server information tuple"
  default     = ["web-server", 3, true]
}
```

### Object

Objects represent structured data with named attributes of specific types.

#### Basic Objects
```hcl
# Simple object
database_config = {
  engine    = "mysql"
  version   = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  backup_retention_period = 7
  multi_az  = false
}
```

#### Nested Objects
```hcl
# Nested object
application_config = {
  name = "web-app"
  version = "1.0.0"
  database = {
    engine = "mysql"
    version = "8.0"
    instance_class = "db.t3.micro"
  }
  monitoring = {
    enabled = true
    retention_days = 30
    alert_threshold = 80.0
  }
}
```

#### Object Functions
```hcl
# Object operations
has_database = contains(keys(var.config), "database")
database_engine = var.config.database.engine
monitoring_enabled = var.config.monitoring.enabled
```

#### Object Validation
```hcl
variable "database_config" {
  type = object({
    engine    = string
    version   = string
    instance_class = string
    allocated_storage = number
    backup_retention_period = number
    multi_az  = bool
  })
  
  default = {
    engine    = "mysql"
    version   = "8.0"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    backup_retention_period = 7
    multi_az  = false
  }
  
  validation {
    condition     = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}
```

## Type Conversion

### Implicit Type Conversion
```hcl
# HCL automatically converts compatible types
string_number = "123"  # Can be used where number is expected
number_string = 123    # Can be used where string is expected
```

### Explicit Type Conversion
```hcl
# Convert to string
string_value = tostring(var.number_value)
string_list = [for i in var.numbers : tostring(i)]

# Convert to number
number_value = tonumber(var.string_value)
number_list = [for s in var.strings : tonumber(s)]

# Convert to bool
bool_value = tobool(var.string_value)

# Convert to list
list_value = tolist(var.set_value)

# Convert to set
set_value = toset(var.list_value)

# Convert to map
map_value = tomap(var.object_value)
```

## Type Constraints

### Type Constraints in Variables
```hcl
# String constraints
variable "name" {
  type = string
}

# Number constraints
variable "count" {
  type = number
}

# Boolean constraints
variable "enabled" {
  type = bool
}

# List constraints
variable "items" {
  type = list(string)
}

# Set constraints
variable "unique_items" {
  type = set(string)
}

# Map constraints
variable "tags" {
  type = map(string)
}

# Tuple constraints
variable "info" {
  type = tuple([string, number, bool])
}

# Object constraints
variable "config" {
  type = object({
    name = string
    count = number
    enabled = bool
  })
}
```

### Type Constraints in Resources
```hcl
# Resource attributes have implicit type constraints
resource "aws_instance" "web" {
  ami           = "ami-12345678"  # String
  instance_type = "t3.micro"      # String
  count         = 3               # Number
  monitoring    = true            # Boolean
  
  tags = {                        # Map of strings
    Name = "Web Server"
    Environment = "production"
  }
}
```

## Best Practices

### 1. Use Appropriate Types
```hcl
# Use specific types for better validation
variable "instance_count" {
  type        = number
  description = "Number of instances"
  default     = 1
}

# Use objects for structured data
variable "database_config" {
  type = object({
    engine = string
    version = string
    instance_class = string
  })
}
```

### 2. Validate Input Types
```hcl
# Always validate input types
variable "port" {
  type        = number
  description = "Port number"
  
  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}
```

### 3. Use Type Conversion Carefully
```hcl
# Use explicit type conversion when needed
locals {
  port_string = tostring(var.port)
  port_number = tonumber(var.port_string)
}
```

### 4. Document Type Expectations
```hcl
# Document expected types in comments
variable "server_configs" {
  type = map(object({
    instance_type = string  # AWS instance type
    disk_size     = number  # Disk size in GB
    monitoring    = bool    # Enable monitoring
  }))
  description = "Configuration for different server types"
}
```

## Common Type Errors

### 1. Type Mismatch
```hcl
# Error: Type mismatch
variable "count" {
  type    = string
  default = 3  # Number assigned to string type
}

# Solution: Correct type
variable "count" {
  type    = number
  default = 3
}
```

### 2. Invalid Type Conversion
```hcl
# Error: Invalid conversion
invalid_number = tonumber("not-a-number")

# Solution: Use try function
safe_number = try(tonumber(var.string_value), 0)
```

### 3. Missing Type Constraints
```hcl
# Error: No type constraint
variable "items" {
  default = ["item1", "item2", "item3"]
}

# Solution: Add type constraint
variable "items" {
  type    = list(string)
  default = ["item1", "item2", "item3"]
}
```

## Conclusion

Understanding HCL data types is essential for writing effective Terraform configurations. By mastering:

1. **Primitive types** (string, number, bool)
2. **Collection types** (list, set, map, tuple, object)
3. **Type conversion** and constraints
4. **Validation** and error handling
5. **Best practices** and common pitfalls

You'll be able to create robust, maintainable, and error-free Terraform configurations. Remember to always validate your inputs and use appropriate types for your data structures.
