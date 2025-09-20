# Enterprise Advanced Module Patterns

## 🏢 Module Registry and Governance

### Private Module Registry
```hcl
# Module with semantic versioning
module "enterprise_vpc" {
  source  = "company.registry.io/networking/vpc/aws"
  version = "~> 2.1.0"
  
  name = var.vpc_name
  cidr = var.vpc_cidr
  
  compliance_level = "SOC2"
  cost_center     = var.cost_center
  
  tags = local.governance_tags
}
```

### Module Composition Patterns
```hcl
# Hierarchical module composition
module "platform" {
  source = "./modules/platform"
  
  # Foundation dependencies
  vpc_config = {
    cidr = "10.0.0.0/16"
    azs  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
  
  # Security baseline
  security_config = {
    enable_guardduty = true
    enable_waf      = true
    compliance_mode = "strict"
  }
  
  tags = local.enterprise_tags
}

# Application layer depends on platform
module "applications" {
  source = "./modules/applications"
  
  platform_outputs = module.platform
  
  applications = {
    web_app = {
      replicas = 3
      resources = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
  }
}
```

## 🔒 Advanced Security Patterns

### Policy as Code Integration
```hcl
# OPA policy enforcement
resource "aws_config_configuration_recorder" "compliance" {
  name     = "enterprise-compliance"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Custom Config rules for module compliance
resource "aws_config_config_rule" "module_tagging" {
  name = "required-module-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "Environment"
    tag2Key = "CostCenter"
    tag3Key = "Owner"
  })

  depends_on = [aws_config_configuration_recorder.compliance]
}
```

### Multi-Account Module Deployment
```hcl
# Cross-account module deployment
provider "aws" {
  alias  = "security"
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.security_account_id}:role/TerraformRole"
  }
}

provider "aws" {
  alias  = "production"
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.production_account_id}:role/TerraformRole"
  }
}

# Security account resources
module "security_baseline" {
  source = "./modules/security"
  
  providers = {
    aws = aws.security
  }
  
  account_type = "security"
  
  security_config = {
    enable_guardduty    = true
    enable_security_hub = true
    enable_macie       = true
  }
}

# Production account resources
module "production_workloads" {
  source = "./modules/workloads"
  
  providers = {
    aws = aws.production
  }
  
  # Cross-account dependencies
  security_account_id = var.security_account_id
  kms_key_arn        = module.security_baseline.kms_key_arn
  
  workloads = var.production_workloads
}
```

## 📊 Advanced Testing Patterns

### Module Testing Framework
```hcl
# Terratest integration
terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

# Unit tests for module logic
resource "test_assertions" "vpc_validation" {
  component = "vpc_module"

  check "subnet_count" {
    assertion = length(module.vpc.private_subnets) >= 2
    error_message = "VPC must have at least 2 private subnets for HA"
  }

  check "nat_gateway_count" {
    assertion = var.environment == "production" ? length(module.vpc.nat_gateways) >= 2 : true
    error_message = "Production environments require multiple NAT gateways"
  }
}

# Integration tests
resource "test_assertions" "integration_tests" {
  component = "module_integration"

  check "database_connectivity" {
    assertion = can(module.database.endpoint)
    error_message = "Database endpoint must be accessible"
  }

  check "security_group_rules" {
    assertion = length(module.security_group.ingress_rules) > 0
    error_message = "Security group must have ingress rules"
  }
}
```

This provides enterprise-grade advanced module patterns for Problem 22.
