#!/bin/bash

cd /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions

# Problem 37
cat > Problem-37-Infrastructure-Testing/terraform.tfvars.example << 'EOF'
aws_region    = "us-west-2"
environment   = "test"
instance_type = "t3.micro"
EOF

# Problem 38
cat > Problem-38-Policy-as-Code/terraform.tfvars.example << 'EOF'
aws_region   = "us-west-2"
project_name = "policy-demo"
EOF

# Problem 39
cat > Problem-39-Multi-Cloud-Patterns/terraform.tfvars.example << 'EOF'
aws_region     = "us-west-2"
azure_location = "East US"
project_name   = "multi-cloud-demo"
environment    = "dev"

aws_vpc_cidr   = "10.0.0.0/16"
azure_vnet_cidr = "10.1.0.0/16"

aws_availability_zones = ["us-west-2a", "us-west-2b"]
azure_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]

enable_cross_cloud_connectivity = false
EOF

# Problem 40
cat > Problem-40-GitOps-Advanced/terraform.tfvars.example << 'EOF'
aws_region         = "us-west-2"
cluster_name       = "my-eks-cluster"
enable_argocd      = true
enable_flux        = false
enable_monitoring  = true
git_repository_url = "https://github.com/example/demo-app"
EOF

echo "Terraform.tfvars.example files created!"
