# HCL Expressions and Functions Guide

## Overview

This guide provides comprehensive coverage of HCL expressions, functions, and operators. Understanding these concepts is essential for writing dynamic and flexible Terraform configurations.

## Expressions

Expressions are used to compute values in HCL. They can be simple values, references to other values, or complex computations.

### Basic Expressions

#### Literal Values
```hcl
# String literals
name = "web-server"
description = "Web server instance"

# Number literals
count = 3
port = 80
timeout = 300

# Boolean literals
enabled = true
disabled = false
```

#### Variable References
```hcl
# Simple variable reference
instance_count = var.instance_count
project_name = var.project_name
environment = var.environment

# Variable with default
instance_type = var.instance_type != null ? var.instance_type : "t3.micro"
```

#### Resource References
```hcl
# Reference to resource attributes
subnet_id = aws_subnet.public.id
vpc_id = aws_vpc.main.id
security_group_id = aws_security_group.web.id

# Reference to data source attributes
ami_id = data.aws_ami.ubuntu.id
availability_zones = data.aws_availability_zones.available.names
```

#### Local Value References
```hcl
# Reference to local values
common_tags = local.common_tags
instance_name = local.instance_name
formatted_name = local.formatted_name
```

## Operators

### Arithmetic Operators

#### Addition (+)
```hcl
# Simple addition
total_instances = var.web_count + var.db_count
total_cost = var.instance_count * var.hourly_rate

# String concatenation
full_name = var.first_name + " " + var.last_name
```

#### Subtraction (-)
```hcl
# Simple subtraction
remaining_count = var.total_count - var.used_count
available_ports = var.max_ports - var.used_ports
```

#### Multiplication (*)
```hcl
# Simple multiplication
total_cost = var.instance_count * var.hourly_rate
total_memory = var.instance_count * var.memory_per_instance
```

#### Division (/)
```hcl
# Simple division
average_cost = var.total_cost / var.instance_count
half_count = var.total_count / 2
```

#### Modulo (%)
```hcl
# Modulo operation
remainder = var.total_count % 3
is_even = var.number % 2 == 0
```

### Comparison Operators

#### Equality (==)
```hcl
# String equality
is_production = var.environment == "production"
is_development = var.environment == "development"

# Number equality
is_exact_count = var.instance_count == 3
is_zero = var.count == 0

# Boolean equality
is_enabled = var.monitoring_enabled == true
```

#### Inequality (!=)
```hcl
# String inequality
is_not_development = var.environment != "development"
is_not_empty = var.name != ""

# Number inequality
is_not_zero = var.count != 0
is_not_negative = var.value != -1

# Boolean inequality
is_not_disabled = var.enabled != false
```

#### Greater Than (>)
```hcl
# Number comparison
has_enough_instances = var.instance_count > 3
is_high_cost = var.cost > var.budget

# String comparison (lexicographic)
is_after = var.version > "1.0.0"
```

#### Greater Than or Equal (>=)
```hcl
# Number comparison
meets_minimum = var.instance_count >= 2
is_sufficient = var.memory >= 1024

# String comparison
is_version_ok = var.version >= "1.0.0"
```

#### Less Than (<)
```hcl
# Number comparison
under_limit = var.instance_count < 10
is_low_cost = var.cost < var.budget

# String comparison
is_before = var.version < "2.0.0"
```

#### Less Than or Equal (<=)
```hcl
# Number comparison
within_budget = var.cost <= var.budget
is_small = var.size <= 100
```

### Logical Operators

#### Logical AND (&&)
```hcl
# Multiple conditions
enable_monitoring = var.environment == "production" && var.monitoring_enabled
is_valid_config = var.instance_count > 0 && var.instance_type != ""

# Complex conditions
should_create = var.environment == "production" && var.instance_count > 0 && var.monitoring_enabled
```

#### Logical OR (||)
```hcl
# Alternative conditions
is_development = var.environment == "development" || var.environment == "staging"
is_web_or_api = var.service_type == "web" || var.service_type == "api"

# Multiple alternatives
is_valid_environment = var.environment == "development" || var.environment == "staging" || var.environment == "production"
```

#### Logical NOT (!)
```hcl
# Negation
should_backup = !var.skip_backup
is_not_empty = !var.name == ""
is_not_disabled = !var.disabled
```

## Functions

### String Functions

#### format()
```hcl
# Basic formatting
formatted_name = format("%s-%s-%d", var.project_name, var.environment, random_id.suffix.hex)
formatted_url = format("https://%s.%s", var.subdomain, var.domain)

# Complex formatting
formatted_config = format("""
  server_name: %s
  port: %d
  environment: %s
  enabled: %t
""", var.server_name, var.port, var.environment, var.enabled)
```

#### upper()
```hcl
# Convert to uppercase
upper_name = upper(var.project_name)
upper_environment = upper(var.environment)
```

#### lower()
```hcl
# Convert to lowercase
lower_name = lower(var.project_name)
lower_environment = lower(var.environment)
```

#### trimspace()
```hcl
# Remove leading and trailing whitespace
trimmed_name = trimspace(var.project_name)
clean_description = trimspace(var.description)
```

#### replace()
```hcl
# Replace characters
clean_name = replace(var.project_name, "_", "-")
url_safe_name = replace(var.name, " ", "-")
```

#### split()
```hcl
# Split string into list
parts = split("-", var.project_name)
words = split(" ", var.description)
```

#### join()
```hcl
# Join list into string
joined_name = join("-", ["web", "server", "01"])
full_path = join("/", ["home", "user", "project"])
```

#### substr()
```hcl
# Extract substring
short_name = substr(var.project_name, 0, 10)
suffix = substr(var.project_name, -5, -1)
```

### Numeric Functions

#### max()
```hcl
# Find maximum value
max_instances = max(var.web_count, var.db_count, var.cache_count)
max_cost = max(var.cost1, var.cost2, var.cost3)
```

#### min()
```hcl
# Find minimum value
min_instances = min(var.web_count, var.db_count, var.cache_count)
min_cost = min(var.cost1, var.cost2, var.cost3)
```

#### abs()
```hcl
# Absolute value
abs_value = abs(var.negative_number)
abs_difference = abs(var.value1 - var.value2)
```

#### ceil()
```hcl
# Round up
rounded_up = ceil(var.float_value)
instances_needed = ceil(var.total_workload / var.workload_per_instance)
```

#### floor()
```hcl
# Round down
rounded_down = floor(var.float_value)
instances_available = floor(var.total_resources / var.resources_per_instance)
```

#### round()
```hcl
# Round to nearest integer
rounded = round(var.float_value)
```

### Collection Functions

#### length()
```hcl
# Get length of collection
item_count = length(var.items)
tag_count = length(var.tags)
port_count = length(var.ports)
```

#### keys()
```hcl
# Get keys from map
tag_keys = keys(var.tags)
config_keys = keys(var.server_configs)
```

#### values()
```hcl
# Get values from map
tag_values = values(var.tags)
config_values = values(var.server_configs)
```

#### contains()
```hcl
# Check if collection contains value
has_environment_tag = contains(keys(var.tags), "Environment")
has_web_port = contains(var.ports, 80)
```

#### index()
```hcl
# Get index of value in list
web_index = index(var.services, "web")
api_index = index(var.services, "api")
```

### Type Conversion Functions

#### tostring()
```hcl
# Convert to string
string_number = tostring(var.number_value)
string_bool = tostring(var.bool_value)
string_list = [for i in var.numbers : tostring(i)]
```

#### tonumber()
```hcl
# Convert to number
number_string = tonumber(var.string_value)
number_bool = tonumber(var.bool_value)
number_list = [for s in var.strings : tonumber(s)]
```

#### tobool()
```hcl
# Convert to boolean
bool_string = tobool(var.string_value)
bool_number = tobool(var.number_value)
```

#### tolist()
```hcl
# Convert to list
list_set = tolist(var.set_value)
list_map = tolist(var.map_value)
```

#### toset()
```hcl
# Convert to set
set_list = toset(var.list_value)
set_map = toset(var.map_value)
```

#### tomap()
```hcl
# Convert to map
map_object = tomap(var.object_value)
map_list = tomap(var.list_value)
```

### Encoding Functions

#### base64encode()
```hcl
# Encode to base64
encoded_data = base64encode(var.sensitive_data)
encoded_script = base64encode(var.user_data_script)
```

#### base64decode()
```hcl
# Decode from base64
decoded_data = base64decode(var.encoded_data)
decoded_script = base64decode(var.encoded_script)
```

#### jsonencode()
```hcl
# Encode to JSON
json_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }
  ]
})
```

#### yamlencode()
```hcl
# Encode to YAML
yaml_config = yamlencode({
  server = {
    name = var.server_name
    port = var.port
    enabled = var.enabled
  }
})
```

### Date and Time Functions

#### timestamp()
```hcl
# Current timestamp
current_time = timestamp()
deployment_time = timestamp()
```

#### timeadd()
```hcl
# Add time
future_time = timeadd(timestamp(), "24h")
expiry_time = timeadd(timestamp(), "30d")
```

#### formatdate()
```hcl
# Format date
formatted_date = formatdate("YYYY-MM-DD", timestamp())
formatted_time = formatdate("HH:mm:ss", timestamp())
```

### File Functions

#### file()
```hcl
# Read file content
script_content = file("${path.module}/scripts/start.sh")
config_content = file("${path.module}/config/app.conf")
```

#### templatefile()
```hcl
# Template file with variables
user_data = templatefile("${path.module}/templates/user_data.sh", {
  app_name = var.app_name
  environment = var.environment
  db_host = aws_db_instance.main.endpoint
})
```

### Network Functions

#### cidrhost()
```hcl
# Get host address from CIDR
first_host = cidrhost(var.cidr_block, 1)
last_host = cidrhost(var.cidr_block, -1)
```

#### cidrnetmask()
```hcl
# Get netmask from CIDR
netmask = cidrnetmask(var.cidr_block)
```

#### cidrsubnet()
```hcl
# Create subnet from CIDR
subnet_cidr = cidrsubnet(var.cidr_block, 8, 1)
```

### Conditional Functions

#### try()
```hcl
# Try multiple values
instance_type = try(var.instance_type, "t3.micro")
ami_id = try(var.ami_id, data.aws_ami.ubuntu.id, "ami-0c55b159cbfafe1d0")
database_endpoint = try(aws_db_instance.main.endpoint, "localhost:3306")
```

#### can()
```hcl
# Check if expression can be evaluated
is_valid_cidr = can(cidrhost(var.cidr_block, 0))
is_valid_number = can(tonumber(var.string_number))
```

## Advanced Expressions

### For Expressions

#### List For Expressions
```hcl
# Transform list
doubled_numbers = [for i in var.numbers : i * 2]
formatted_names = [for name in var.names : upper(name)]
instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
```

#### Map For Expressions
```hcl
# Transform map
scaled_configs = {
  for name, config in var.server_configs : name => {
    instance_type = config.instance_type
    disk_size = config.disk_size * 2
    monitoring = config.monitoring
  }
}

# Filter and transform
production_configs = {
  for name, config in var.server_configs : name => config
  if config.environment == "production"
}
```

#### Set For Expressions
```hcl
# Transform set
unique_even_numbers = toset([for i in var.numbers : i if i % 2 == 0])
unique_names = toset([for name in var.names : upper(name)])
```

### Conditional Expressions

#### Ternary Operator
```hcl
# Simple conditional
instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
monitoring = var.environment == "production" ? true : false

# Complex conditional
instance_count = var.environment == "production" ? 3 : var.environment == "staging" ? 2 : 1
```

#### Multiple Conditions
```hcl
# Multiple conditions
instance_type = var.environment == "production" ? "t3.large" : var.environment == "staging" ? "t3.medium" : "t3.micro"
monitoring = var.environment == "production" || var.environment == "staging" ? true : false
```

### Complex Expressions

#### Nested Expressions
```hcl
# Nested function calls
formatted_name = format("%s-%s-%s", upper(var.project_name), lower(var.environment), random_id.suffix.hex)
complex_calculation = max(min(var.instance_count * var.cost_per_instance, var.budget), var.minimum_cost)
```

#### Expression Chaining
```hcl
# Chain expressions
clean_name = trimspace(replace(upper(var.project_name), "_", "-"))
formatted_tags = {
  for key, value in var.tags : upper(key) => lower(value)
}
```

## Best Practices

### 1. Use Appropriate Functions
```hcl
# Use specific functions for specific purposes
formatted_name = format("%s-%s", var.project_name, var.environment)
clean_name = replace(var.name, " ", "-")
upper_name = upper(var.name)
```

### 2. Handle Errors Gracefully
```hcl
# Use try function for error handling
safe_number = try(tonumber(var.string_value), 0)
safe_cidr = try(cidrhost(var.cidr_block, 0), "10.0.0.0/16")
```

### 3. Use For Expressions for Data Transformation
```hcl
# Transform data efficiently
instance_names = [for i in range(var.instance_count) : "${var.project_name}-web-${i + 1}"]
production_configs = {
  for name, config in var.server_configs : name => config
  if config.environment == "production"
}
```

### 4. Document Complex Expressions
```hcl
# Document complex expressions
locals {
  # Calculate total cost: instances * hourly rate * hours per month
  total_cost = var.instance_count * var.hourly_rate * 24 * 30
  
  # Format instance name: project-environment-type-index
  instance_name = format("%s-%s-%s-%d", var.project_name, var.environment, var.instance_type, count.index + 1)
}
```

## Common Expression Errors

### 1. Type Mismatch
```hcl
# Error: Type mismatch
total = var.string_number + var.number_value

# Solution: Convert types
total = tonumber(var.string_number) + var.number_value
```

### 2. Undefined Reference
```hcl
# Error: Undefined reference
instance_type = var.undefined_variable

# Solution: Define variable or use try
instance_type = try(var.undefined_variable, "t3.micro")
```

### 3. Invalid Function Usage
```hcl
# Error: Invalid function usage
invalid_format = format("%s-%s", var.single_value)

# Solution: Provide correct number of arguments
valid_format = format("%s-%s", var.value1, var.value2)
```

## Conclusion

Mastering HCL expressions and functions is essential for writing dynamic and flexible Terraform configurations. By understanding:

1. **Basic expressions** and operators
2. **String, numeric, and collection functions**
3. **Type conversion** and encoding functions
4. **Advanced expressions** like for expressions and conditionals
5. **Best practices** and error handling

You'll be able to create sophisticated Terraform configurations that adapt to different environments and requirements. Remember to always validate your expressions and handle errors gracefully.
