# Problem 25: Custom Providers and External Integrations
# Comprehensive custom provider usage and external system integrations

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for external API integration
data "http" "external_api" {
  count = var.enable_external_api_integration ? 1 : 0
  
  url = var.external_api_url
  
  request_headers = {
    Accept        = "application/json"
    Authorization = "Bearer ${var.api_token}"
    User-Agent    = "Terraform/${terraform.version}"
  }
  
  request_timeout_ms = var.api_timeout_ms
  
  lifecycle {
    postcondition {
      condition     = contains([200, 201], self.status_code)
      error_message = "External API returned unexpected status code: ${self.status_code}"
    }
  }
}

# External data source for custom script execution
data "external" "custom_script" {
  count = var.enable_custom_script ? 1 : 0
  
  program = ["python3", "${path.module}/scripts/custom_data_processor.py"]
  
  query = {
    environment = var.environment
    project     = var.project_name
    region      = var.aws_region
    config_data = jsonencode(var.custom_script_config)
  }
  
  working_dir = path.module
}

# TLS provider for certificate generation
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "main" {
  private_key_pem = tls_private_key.main.private_key_pem

  subject {
    common_name  = var.certificate_common_name
    organization = var.organization_name
  }

  validity_period_hours = var.certificate_validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Local file generation for configuration
resource "local_file" "config" {
  content = templatefile("${path.module}/templates/app_config.tpl", {
    database_url    = aws_db_instance.main.endpoint
    redis_url       = aws_elasticache_cluster.main.cache_nodes[0].address
    api_key         = random_password.api_key.result
    environment     = var.environment
    external_data   = var.enable_external_api_integration ? jsondecode(data.http.external_api[0].response_body) : {}
    custom_data     = var.enable_custom_script ? data.external.custom_script[0].result : {}
  })
  
  filename = "${path.module}/generated/app_config.json"
  
  file_permission = "0644"
}

# Random provider for generating secrets
resource "random_password" "api_key" {
  length  = 32
  special = true
}

resource "random_id" "deployment_id" {
  byte_length = 8
}

resource "random_uuid" "session_secret" {}

# Null resource for custom provisioning
resource "null_resource" "custom_provisioner" {
  count = var.enable_custom_provisioning ? 1 : 0
  
  triggers = {
    deployment_id = random_id.deployment_id.hex
    config_hash   = md5(local_file.config.content)
  }
  
  provisioner "local-exec" {
    command = "${path.module}/scripts/custom_provisioner.sh"
    
    environment = {
      DEPLOYMENT_ID = random_id.deployment_id.hex
      CONFIG_FILE   = local_file.config.filename
      AWS_REGION    = var.aws_region
      ENVIRONMENT   = var.environment
    }
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/cleanup.sh"
    
    environment = {
      DEPLOYMENT_ID = self.triggers.deployment_id
    }
  }
}

# Template provider for dynamic configuration
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh.tpl")
  
  vars = {
    api_key         = random_password.api_key.result
    deployment_id   = random_id.deployment_id.hex
    session_secret  = random_uuid.session_secret.result
    database_url    = aws_db_instance.main.endpoint
    redis_url       = aws_elasticache_cluster.main.cache_nodes[0].address
    ssl_cert        = base64encode(tls_self_signed_cert.main.cert_pem)
    ssl_key         = base64encode(tls_private_key.main.private_key_pem)
    external_config = var.enable_external_api_integration ? base64encode(data.http.external_api[0].response_body) : ""
  }
}

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name          = "${var.project_name}-vpc"
    DeploymentId  = random_id.deployment_id.hex
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway and routing
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security groups
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# RDS Database
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = var.skip_final_snapshot

  tags = {
    Name         = "${var.project_name}-db"
    DeploymentId = random_id.deployment_id.hex
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name         = "${var.project_name}-redis"
    DeploymentId = random_id.deployment_id.hex
  }
}

# Launch template with custom user data
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(data.template_file.user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name         = "${var.project_name}-web"
      DeploymentId = random_id.deployment_id.hex
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "DeploymentId"
    value               = random_id.deployment_id.hex
    propagate_at_launch = true
  }

  depends_on = [null_resource.custom_provisioner]
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name         = "${var.project_name}-alb"
    DeploymentId = random_id.deployment_id.hex
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# S3 bucket for storing generated certificates and configs
resource "aws_s3_bucket" "config" {
  bucket = "${var.project_name}-config-${random_id.deployment_id.hex}"

  tags = {
    Name         = "${var.project_name}-config"
    DeploymentId = random_id.deployment_id.hex
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload generated certificate to S3
resource "aws_s3_object" "ssl_cert" {
  bucket = aws_s3_bucket.config.id
  key    = "ssl/certificate.pem"
  content = tls_self_signed_cert.main.cert_pem
  
  server_side_encryption = "AES256"
  
  tags = {
    Name = "SSL Certificate"
  }
}

resource "aws_s3_object" "ssl_key" {
  bucket = aws_s3_bucket.config.id
  key    = "ssl/private_key.pem"
  content = tls_private_key.main.private_key_pem
  
  server_side_encryption = "AES256"
  
  tags = {
    Name = "SSL Private Key"
  }
}

# Upload generated config to S3
resource "aws_s3_object" "app_config" {
  bucket = aws_s3_bucket.config.id
  key    = "config/app_config.json"
  content = local_file.config.content
  
  server_side_encryption = "AES256"
  
  tags = {
    Name = "Application Configuration"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name         = "${var.project_name}-logs"
    DeploymentId = random_id.deployment_id.hex
  }
}

# Systems Manager Parameter Store for secrets
resource "aws_ssm_parameter" "api_key" {
  name  = "/${var.project_name}/api_key"
  type  = "SecureString"
  value = random_password.api_key.result

  tags = {
    Name         = "${var.project_name}-api-key"
    DeploymentId = random_id.deployment_id.hex
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/db_password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name         = "${var.project_name}-db-password"
    DeploymentId = random_id.deployment_id.hex
  }
}

resource "aws_ssm_parameter" "session_secret" {
  name  = "/${var.project_name}/session_secret"
  type  = "SecureString"
  value = random_uuid.session_secret.result

  tags = {
    Name         = "${var.project_name}-session-secret"
    DeploymentId = random_id.deployment_id.hex
  }
}
