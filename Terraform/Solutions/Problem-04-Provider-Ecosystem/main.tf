# Provider Ecosystem Understanding - Comprehensive Examples

# Configure Terraform and Providers
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    
    # Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    
    # Google Cloud Provider
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    
    # Community Providers
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
    
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    
    # Utility Providers
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Provider    = "AWS"
    }
  }
  
  # Assume role configuration (if needed)
  dynamic "assume_role" {
    for_each = var.aws_assume_role_arn != null ? [1] : []
    content {
      role_arn = var.aws_assume_role_arn
    }
  }
  
  # Endpoint configuration (if needed)
  dynamic "endpoints" {
    for_each = var.aws_endpoints != null ? [var.aws_endpoints] : []
    content {
      s3  = endpoints.value.s3
      ec2 = endpoints.value.ec2
    }
  }
}

# AWS Provider Aliases
provider "aws" {
  alias  = "production"
  region = var.production_region
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Provider    = "AWS"
    }
  }
  
  dynamic "assume_role" {
    for_each = var.production_assume_role_arn != null ? [1] : []
    content {
      role_arn = var.production_assume_role_arn
    }
  }
}

provider "aws" {
  alias  = "development"
  region = var.development_region
  
  default_tags {
    tags = {
      Environment = "development"
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Provider    = "AWS"
    }
  }
  
  dynamic "assume_role" {
    for_each = var.development_assume_role_arn != null ? [1] : []
    content {
      role_arn = var.development_assume_role_arn
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  
  # Use environment variables for authentication
  # subscription_id = var.azure_subscription_id
  # client_id       = var.azure_client_id
  # client_secret   = var.azure_client_secret
  # tenant_id       = var.azure_tenant_id
}

# Azure Provider Aliases
provider "azurerm" {
  alias = "production"
  features {}
  
  subscription_id = var.azure_production_subscription_id
  client_id       = var.azure_production_client_id
  client_secret   = var.azure_production_client_secret
  tenant_id       = var.azure_production_tenant_id
}

provider "azurerm" {
  alias = "development"
  features {}
  
  subscription_id = var.azure_development_subscription_id
  client_id       = var.azure_development_client_id
  client_secret   = var.azure_development_client_secret
  tenant_id       = var.azure_development_tenant_id
}

# Google Cloud Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
  
  # Use application default credentials
  # credentials = file(var.gcp_service_account_key_path)
}

# Google Cloud Provider Aliases
provider "google" {
  alias   = "production"
  project = var.gcp_production_project_id
  region  = var.gcp_production_region
  zone    = var.gcp_production_zone
}

provider "google" {
  alias   = "development"
  project = var.gcp_development_project_id
  region  = var.gcp_development_region
  zone    = var.gcp_development_zone
}

# Community Provider Configurations
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  
  # API URL (for EU)
  api_url = var.datadog_api_url
  
  # Validate SSL
  validate_ssl = true
}

provider "github" {
  token = var.github_token
  
  # Base URL for GitHub Enterprise
  base_url = var.github_base_url
  
  # Owner (organization or user)
  owner = var.github_owner
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
  
  # Or use cluster info
  # host                   = var.cluster_endpoint
  # cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  # token                  = var.cluster_token
}

# Generate random values for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_string" "password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Local values for provider-specific configurations
locals {
  # AWS-specific values
  aws_common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Provider    = "AWS"
  }
  
  # Azure-specific values
  azure_common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Provider    = "Azure"
  }
  
  # GCP-specific values
  gcp_common_labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
    provider    = "gcp"
  }
  
  # Common naming
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
}

# AWS Resources
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.aws_common_tags, {
    Name = "${local.resource_prefix}-vpc"
    Type = "VPC"
  })
}

resource "aws_subnet" "public" {
  count = length(var.aws_availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.aws_vpc_cidr, 8, count.index)
  availability_zone       = var.aws_availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.aws_common_tags, {
    Name = "${local.resource_prefix}-public-${count.index + 1}"
    Type = "Public Subnet"
    AZ   = var.aws_availability_zones[count.index]
  })
}

resource "aws_security_group" "web" {
  name_prefix = "${local.resource_prefix}-web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
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
  
  tags = merge(local.aws_common_tags, {
    Name = "${local.resource_prefix}-web-sg"
    Type = "Security Group"
  })
}

resource "aws_instance" "web" {
  count = var.aws_instance_count
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.aws_instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = merge(local.aws_common_tags, {
    Name = "${local.resource_prefix}-web-${count.index + 1}"
    Type = "EC2 Instance"
  })
}

resource "aws_s3_bucket" "main" {
  bucket = "${local.resource_prefix}-bucket"
  
  tags = merge(local.aws_common_tags, {
    Name = "${local.resource_prefix}-bucket"
    Type = "S3 Bucket"
  })
}

# Azure Resources
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.azure_location
  
  tags = local.azure_common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = merge(local.azure_common_tags, {
    Name = "${local.resource_prefix}-vnet"
    Type = "Virtual Network"
  })
}

resource "azurerm_subnet" "public" {
  count = length(var.azure_subnet_cidrs)
  
  name                 = "${local.resource_prefix}-public-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_subnet_cidrs[count.index]]
}

resource "azurerm_network_security_group" "web" {
  name                = "${local.resource_prefix}-web-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = merge(local.azure_common_tags, {
    Name = "${local.resource_prefix}-web-nsg"
    Type = "Network Security Group"
  })
}

resource "azurerm_storage_account" "main" {
  name                     = "${local.resource_prefix}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = merge(local.azure_common_tags, {
    Name = "${local.resource_prefix}-storage"
    Type = "Storage Account"
  })
}

# Google Cloud Resources
resource "google_compute_network" "main" {
  name                    = "${local.resource_prefix}-vpc"
  auto_create_subnetworks = false
  
  labels = local.gcp_common_labels
}

resource "google_compute_subnetwork" "public" {
  count = length(var.gcp_subnet_cidrs)
  
  name          = "${local.resource_prefix}-public-${count.index + 1}"
  ip_cidr_range = var.gcp_subnet_cidrs[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main.id
  
  labels = merge(local.gcp_common_labels, {
    name = "${local.resource_prefix}-public-${count.index + 1}"
    type = "subnetwork"
  })
}

resource "google_compute_firewall" "web" {
  name    = "${local.resource_prefix}-web-fw"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  
  labels = merge(local.gcp_common_labels, {
    name = "${local.resource_prefix}-web-fw"
    type = "firewall"
  })
}

resource "google_storage_bucket" "main" {
  name     = "${local.resource_prefix}-bucket"
  location = var.gcp_region
  
  labels = merge(local.gcp_common_labels, {
    name = "${local.resource_prefix}-bucket"
    type = "storage_bucket"
  })
}

# Datadog Resources
resource "datadog_monitor" "aws_cpu" {
  count = var.enable_datadog_monitoring ? 1 : 0
  
  name               = "AWS CPU Usage - ${local.resource_prefix}"
  type               = "metric alert"
  query              = "avg(last_5m):avg:aws.ec2.cpuutilization{*} > 80"
  message            = "AWS CPU usage is high"
  escalation_message = "AWS CPU usage is critically high"
  
  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}",
    "provider:aws"
  ]
}

resource "datadog_monitor" "azure_cpu" {
  count = var.enable_datadog_monitoring ? 1 : 0
  
  name               = "Azure CPU Usage - ${local.resource_prefix}"
  type               = "metric alert"
  query              = "avg(last_5m):avg:azure.vm.processor_percent{*} > 80"
  message            = "Azure CPU usage is high"
  escalation_message = "Azure CPU usage is critically high"
  
  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}",
    "provider:azure"
  ]
}

# GitHub Resources
resource "github_repository" "main" {
  count = var.create_github_repo ? 1 : 0
  
  name        = "${local.resource_prefix}-repo"
  description = "Repository for ${var.project_name} in ${var.environment}"
  visibility  = var.github_repo_visibility
  
  has_issues   = true
  has_projects = true
  has_wiki     = true
  
  topics = [
    "terraform",
    "infrastructure",
    var.environment,
    var.project_name
  ]
}

# Kubernetes Resources
resource "kubernetes_namespace" "main" {
  count = var.create_kubernetes_namespace ? 1 : 0
  
  metadata {
    name = "${local.resource_prefix}-ns"
    
    labels = {
      environment = var.environment
      project     = var.project_name
      managed_by  = "terraform"
    }
  }
}

resource "kubernetes_config_map" "main" {
  count = var.create_kubernetes_namespace ? 1 : 0
  
  metadata {
    name      = "${local.resource_prefix}-config"
    namespace = kubernetes_namespace.main[0].metadata[0].name
  }
  
  data = {
    environment = var.environment
    project     = var.project_name
    provider    = "multi-cloud"
  }
}

# Data Sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "azurerm_client_config" "current" {}

data "google_client_config" "current" {}
