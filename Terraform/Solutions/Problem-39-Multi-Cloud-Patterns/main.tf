# Problem 39: Multi-Cloud Patterns (AWS + Azure)
# Implementing cloud-agnostic infrastructure patterns

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
}

# Azure Provider
provider "azurerm" {
  features {}
}

# Random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for cloud-agnostic patterns
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    MultiCloud  = "true"
  }
  
  # Cloud-agnostic naming convention
  resource_prefix = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
}

# AWS Resources
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name  = "${local.resource_prefix}-vpc"
    Cloud = "AWS"
  })
}

resource "aws_subnet" "main" {
  count = length(var.aws_availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.aws_vpc_cidr, 8, count.index)
  availability_zone = var.aws_availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name  = "${local.resource_prefix}-subnet-${count.index + 1}"
    Cloud = "AWS"
  })
}

resource "aws_s3_bucket" "storage" {
  bucket = "${local.resource_prefix}-storage"

  tags = merge(local.common_tags, {
    Cloud   = "AWS"
    Purpose = "Multi-cloud storage"
  })
}

# Azure Resources
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.azure_location

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    Cloud = "Azure"
  })
}

resource "azurerm_subnet" "main" {
  count = length(var.azure_subnet_cidrs)
  
  name                 = "${local.resource_prefix}-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_subnet_cidrs[count.index]]
}

resource "azurerm_storage_account" "storage" {
  name                     = replace("${local.resource_prefix}storage", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(local.common_tags, {
    Cloud   = "Azure"
    Purpose = "Multi-cloud storage"
  })
}

# Cloud-agnostic data processing
locals {
  # Combine cloud resources for unified management
  all_networks = {
    aws = {
      id         = aws_vpc.main.id
      cidr       = aws_vpc.main.cidr_block
      cloud      = "AWS"
      region     = var.aws_region
      subnet_ids = aws_subnet.main[*].id
    }
    azure = {
      id         = azurerm_virtual_network.main.id
      cidr       = azurerm_virtual_network.main.address_space[0]
      cloud      = "Azure"
      region     = var.azure_location
      subnet_ids = azurerm_subnet.main[*].id
    }
  }
  
  all_storage = {
    aws = {
      name  = aws_s3_bucket.storage.bucket
      type  = "S3"
      cloud = "AWS"
    }
    azure = {
      name  = azurerm_storage_account.storage.name
      type  = "Storage Account"
      cloud = "Azure"
    }
  }
}

# Cross-cloud connectivity (conceptual)
resource "aws_vpc_peering_connection" "cross_cloud" {
  count = var.enable_cross_cloud_connectivity ? 1 : 0
  
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.main.id  # In real scenario, this would be cross-region
  auto_accept = true

  tags = merge(local.common_tags, {
    Name    = "${local.resource_prefix}-cross-cloud-peering"
    Purpose = "Multi-cloud connectivity"
  })
}
