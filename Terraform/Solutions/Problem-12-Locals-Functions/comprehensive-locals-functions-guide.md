# Problem 12: Terraform Locals and Functions Mastery

## Locals Fundamentals

### What are Local Values?
Local values (locals) allow you to assign names to expressions and reuse them throughout your configuration. They help reduce repetition and make configurations more maintainable.

### Basic Locals Syntax
```hcl
locals {
  # Simple value assignment
  project_name = "my-application"
  environment  = "production"
  
  # Computed values
  name_prefix = "${local.project_name}-${local.environment}"
  
  # Complex expressions
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  }
}
```

## Essential Terraform Functions

### String Functions
```hcl
locals {
  # String manipulation
  project_upper = upper(var.project_name)           # "MY-PROJECT"
  project_lower = lower(var.project_name)           # "my-project"
  project_title = title(var.project_name)           # "My-Project"
  
  # String formatting
  formatted_name = format("%s-%s-%03d", var.project_name, var.environment, var.instance_number)
  
  # String replacement
  sanitized_name = replace(var.project_name, "_", "-")
  
  # String splitting and joining
  name_parts = split("-", var.project_name)
  joined_name = join("_", local.name_parts)
  
  # String length and substring
  name_length = length(var.project_name)
  short_name = substr(var.project_name, 0, 8)
  
  # String trimming
  trimmed_name = trimspace(var.project_name)
  
  # Regular expressions
  valid_name = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
}

# Use in resources
resource "aws_s3_bucket" "main" {
  bucket = local.sanitized_name
  
  tags = merge(local.common_tags, {
    Name = local.formatted_name
  })
}
```

### Numeric Functions
```hcl
locals {
  # Basic math
  total_instances = var.web_instances + var.app_instances
  average_cpu = (var.web_cpu + var.app_cpu) / 2
  
  # Min/Max functions
  min_instances = max(var.desired_instances, 1)
  max_storage = min(var.requested_storage, 1000)
  
  # Absolute and ceiling/floor
  storage_difference = abs(var.current_storage - var.target_storage)
  rounded_cpu = ceil(var.cpu_utilization)
  floored_memory = floor(var.memory_utilization)
  
  # Power and logarithm
  storage_power_of_2 = pow(2, var.storage_exponent)
  log_value = log(var.numeric_value, 10)
  
  # Modulo operations
  instance_az_index = var.instance_index % length(data.aws_availability_zones.available.names)
}

# Use in resource sizing
resource "aws_instance" "web" {
  count = local.min_instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.rounded_cpu > 2 ? "t3.large" : "t3.medium"
  
  availability_zone = data.aws_availability_zones.available.names[local.instance_az_index]
  
  root_block_device {
    volume_size = local.max_storage
  }
  
  tags = {
    Name = "${local.project_name}-web-${count.index + 1}"
  }
}
```

### Collection Functions
```hcl
# Sample data
variable "instance_configs" {
  type = list(object({
    name = string
    type = string
    size = number
  }))
  
  default = [
    { name = "web-1", type = "t3.medium", size = 20 },
    { name = "web-2", type = "t3.large", size = 50 },
    { name = "app-1", type = "t3.xlarge", size = 100 }
  ]
}

locals {
  # Length function
  instance_count = length(var.instance_configs)
  
  # Element access
  first_instance = element(var.instance_configs, 0)
  last_instance = element(var.instance_configs, length(var.instance_configs) - 1)
  
  # Index function
  web_instance_index = index([for config in var.instance_configs : config.name], "web-1")
  
  # Contains function
  has_large_instances = contains([for config in var.instance_configs : config.type], "t3.large")
  
  # Distinct values
  unique_instance_types = distinct([for config in var.instance_configs : config.type])
  
  # Sorting
  sorted_by_size = sort([for config in var.instance_configs : config.size])
  
  # Reverse
  reversed_configs = reverse(var.instance_configs)
  
  # Slice operations
  first_two_instances = slice(var.instance_configs, 0, 2)
  
  # Flatten nested lists
  all_tags = flatten([
    for config in var.instance_configs : [
      "Name:${config.name}",
      "Type:${config.type}",
      "Size:${config.size}"
    ]
  ])
  
  # Compact (remove empty values)
  non_empty_names = compact([
    for config in var.instance_configs : 
    config.name != "" ? config.name : null
  ])
}
```

### Map and Set Functions
```hcl
variable "environment_configs" {
  type = map(object({
    instance_type = string
    min_size     = number
    max_size     = number
  }))
  
  default = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    staging = {
      instance_type = "t3.small"
      min_size     = 2
      max_size     = 4
    }
    prod = {
      instance_type = "t3.medium"
      min_size     = 3
      max_size     = 10
    }
  }
}

locals {
  # Keys and values
  environment_names = keys(var.environment_configs)
  instance_types = values(var.environment_configs)[*].instance_type
  
  # Lookup with default
  current_config = lookup(var.environment_configs, var.environment, {
    instance_type = "t3.micro"
    min_size     = 1
    max_size     = 1
  })
  
  # Merge maps
  default_tags = {
    ManagedBy = "terraform"
    Project   = var.project_name
  }
  
  environment_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
  }
  
  all_tags = merge(local.default_tags, local.environment_tags, var.additional_tags)
  
  # Convert between types
  environment_set = toset(local.environment_names)
  config_list = [for env, config in var.environment_configs : config]
  
  # Zipmap (create map from two lists)
  env_instance_map = zipmap(
    local.environment_names,
    [for config in local.config_list : config.instance_type]
  )
}
```

## Advanced Locals Patterns

### Complex Data Processing
```hcl
# Process complex subnet configurations
variable "vpc_config" {
  type = object({
    cidr_block = string
    azs        = list(string)
    
    public_subnets = object({
      count       = number
      cidr_prefix = number
    })
    
    private_subnets = object({
      count       = number
      cidr_prefix = number
    })
    
    database_subnets = object({
      count       = number
      cidr_prefix = number
    })
  })
}

locals {
  # Calculate subnet CIDRs
  public_subnet_cidrs = [
    for i in range(var.vpc_config.public_subnets.count) :
    cidrsubnet(var.vpc_config.cidr_block, var.vpc_config.public_subnets.cidr_prefix, i)
  ]
  
  private_subnet_cidrs = [
    for i in range(var.vpc_config.private_subnets.count) :
    cidrsubnet(var.vpc_config.cidr_block, var.vpc_config.private_subnets.cidr_prefix, i + 10)
  ]
  
  database_subnet_cidrs = [
    for i in range(var.vpc_config.database_subnets.count) :
    cidrsubnet(var.vpc_config.cidr_block, var.vpc_config.database_subnets.cidr_prefix, i + 20)
  ]
  
  # Create comprehensive subnet configuration
  subnet_configs = merge(
    # Public subnets
    {
      for i, cidr in local.public_subnet_cidrs :
      "public-${i + 1}" => {
        cidr_block        = cidr
        availability_zone = var.vpc_config.azs[i % length(var.vpc_config.azs)]
        type             = "public"
        route_table      = "public"
        nat_gateway      = false
      }
    },
    # Private subnets
    {
      for i, cidr in local.private_subnet_cidrs :
      "private-${i + 1}" => {
        cidr_block        = cidr
        availability_zone = var.vpc_config.azs[i % length(var.vpc_config.azs)]
        type             = "private"
        route_table      = "private-${i % length(var.vpc_config.azs)}"
        nat_gateway      = true
      }
    },
    # Database subnets
    {
      for i, cidr in local.database_subnet_cidrs :
      "database-${i + 1}" => {
        cidr_block        = cidr
        availability_zone = var.vpc_config.azs[i % length(var.vpc_config.azs)]
        type             = "database"
        route_table      = "database"
        nat_gateway      = false
      }
    }
  )
  
  # Group subnets by type
  subnets_by_type = {
    for type in ["public", "private", "database"] :
    type => {
      for name, config in local.subnet_configs :
      name => config
      if config.type == type
    }
  }
}
```

### Environment-Specific Processing
```hcl
# Environment-specific configuration processing
locals {
  # Base configuration
  base_config = {
    monitoring_enabled = true
    backup_enabled    = true
    encryption_enabled = true
  }
  
  # Environment-specific overrides
  environment_overrides = {
    development = {
      monitoring_enabled = false
      backup_enabled    = false
      instance_type     = "t3.micro"
      storage_size      = 20
      replica_count     = 0
    }
    
    staging = {
      monitoring_enabled = true
      backup_enabled    = true
      instance_type     = "t3.small"
      storage_size      = 100
      replica_count     = 1
    }
    
    production = {
      monitoring_enabled = true
      backup_enabled    = true
      instance_type     = "t3.large"
      storage_size      = 500
      replica_count     = 2
    }
  }
  
  # Merge configurations
  final_config = merge(
    local.base_config,
    lookup(local.environment_overrides, var.environment, {})
  )
  
  # Calculate derived values
  total_storage_needed = local.final_config.storage_size * (1 + local.final_config.replica_count)
  
  # Determine features to enable
  features_enabled = {
    cloudwatch_logs = local.final_config.monitoring_enabled
    cloudwatch_metrics = local.final_config.monitoring_enabled
    backup_vault = local.final_config.backup_enabled
    kms_encryption = local.final_config.encryption_enabled
    multi_az = var.environment == "production"
    auto_scaling = var.environment != "development"
  }
}
```

## Date and Time Functions
```hcl
locals {
  # Current timestamp
  current_time = timestamp()
  
  # Formatted dates
  date_stamp = formatdate("YYYY-MM-DD", timestamp())
  time_stamp = formatdate("hh:mm:ss", timestamp())
  iso_timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  
  # Custom date formats
  backup_suffix = formatdate("YYYY-MM-DD-hhmm", timestamp())
  log_prefix = formatdate("YYYY/MM/DD", timestamp())
  
  # Date arithmetic (using timeadd function)
  backup_expiry = timeadd(timestamp(), "720h") # 30 days
  
  # Use in resource naming
  snapshot_name = "${var.project_name}-snapshot-${local.backup_suffix}"
  log_group_name = "/aws/lambda/${var.project_name}/${local.log_prefix}"
}

# Use in resources
resource "aws_db_snapshot" "manual" {
  db_instance_identifier = aws_db_instance.main.id
  db_snapshot_identifier = local.snapshot_name
  
  tags = {
    Name      = local.snapshot_name
    CreatedAt = local.current_time
    ExpiresAt = local.backup_expiry
  }
}
```

## File and Template Functions
```hcl
locals {
  # Read files
  ssh_public_key = file("${path.module}/keys/id_rsa.pub")
  
  # Base64 encoding
  user_data_script = base64encode(file("${path.module}/scripts/user-data.sh"))
  
  # Template files
  nginx_config = templatefile("${path.module}/templates/nginx.conf.tpl", {
    server_name = var.domain_name
    backend_port = var.backend_port
    ssl_cert_path = var.ssl_certificate_path
  })
  
  # JSON encoding/decoding
  app_config_json = jsonencode({
    database = {
      host = aws_db_instance.main.endpoint
      port = aws_db_instance.main.port
      name = aws_db_instance.main.db_name
    }
    cache = {
      host = aws_elasticache_cluster.main.cache_nodes[0].address
      port = aws_elasticache_cluster.main.cache_nodes[0].port
    }
    features = local.features_enabled
  })
  
  # YAML encoding
  kubernetes_config = yamlencode({
    apiVersion = "v1"
    kind = "ConfigMap"
    metadata = {
      name = "${var.project_name}-config"
    }
    data = {
      "app.json" = local.app_config_json
    }
  })
  
  # File hashing for change detection
  config_hash = filemd5("${path.module}/config/app.conf")
  script_hash = filesha256("${path.module}/scripts/deploy.sh")
}

# Use in resources
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.final_config.instance_type
  key_name      = aws_key_pair.main.key_name
  
  user_data = local.user_data_script
  
  tags = {
    Name       = "${var.project_name}-web"
    ConfigHash = local.config_hash
    ScriptHash = local.script_hash
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = local.ssh_public_key
}
```

## Network and Encoding Functions
```hcl
locals {
  # CIDR functions
  vpc_cidr = "10.0.0.0/16"
  
  # Calculate subnet CIDRs
  public_cidrs = [
    for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i)
  ]
  
  private_cidrs = [
    for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i + 10)
  ]
  
  # CIDR host calculations
  first_host = cidrhost(local.vpc_cidr, 1)
  last_host = cidrhost(local.vpc_cidr, -2)
  
  # Network mask
  network_mask = cidrnetmask(local.vpc_cidr)
  
  # Base64 encoding/decoding
  encoded_secret = base64encode(var.database_password)
  
  # URL encoding
  encoded_url = urlencode("https://example.com/path with spaces")
  
  # UUID generation
  unique_id = uuidv4()
  
  # MD5 and SHA hashing
  password_hash = md5(var.database_password)
  config_signature = sha256(local.app_config_json)
}

# Use in networking resources
resource "aws_subnet" "public" {
  count = length(local.public_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    CIDR = local.public_cidrs[count.index]
    FirstHost = cidrhost(local.public_cidrs[count.index], 1)
  }
}
```

## Type Conversion Functions
```hcl
variable "mixed_inputs" {
  description = "Mixed input types for conversion examples"
  type = object({
    string_number = string
    number_string = number
    list_set      = list(string)
    map_object    = map(string)
  })
  
  default = {
    string_number = "42"
    number_string = 3.14
    list_set      = ["a", "b", "c", "a"]
    map_object    = {
      key1 = "value1"
      key2 = "value2"
    }
  }
}

locals {
  # Type conversions
  number_from_string = tonumber(var.mixed_inputs.string_number)  # 42
  string_from_number = tostring(var.mixed_inputs.number_string)  # "3.14"
  
  # Collection conversions
  set_from_list = toset(var.mixed_inputs.list_set)              # {"a", "b", "c"}
  list_from_set = tolist(local.set_from_list)                   # ["a", "b", "c"]
  
  # Map conversions
  object_from_map = var.mixed_inputs.map_object
  map_from_object = local.object_from_map
  
  # Boolean conversions
  bool_from_string = tobool("true")                             # true
  bool_from_number = var.mixed_inputs.string_number != "0"      # true
  
  # Complex type conversions
  instance_map = {
    for i in range(3) : 
    "instance-${i}" => {
      name = "web-${i}"
      type = "t3.micro"
      az   = data.aws_availability_zones.available.names[i % length(data.aws_availability_zones.available.names)]
    }
  }
  
  instance_list = [
    for key, config in local.instance_map : merge(config, {
      id = key
    })
  ]
}
```

This comprehensive guide covers all essential Terraform functions and local value patterns, demonstrating practical usage in real infrastructure scenarios.
