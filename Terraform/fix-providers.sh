#!/bin/bash

# Fix provider versions across all solutions
cd /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions

# Update AWS provider from 4.0 to 5.0
find . -name "*.tf" -exec sed -i 's/version = "~> 4\.0"/version = "~> 5.0"/g' {} \;

# Update random provider from 3.0 to 3.1
find . -name "*.tf" -exec sed -i 's/version = "~> 3\.0"/version = "~> 3.1"/g' {} \;

# Update kubernetes provider to consistent version
find . -name "*.tf" -exec sed -i 's/version = "~> 2\.2[0-9]"/version = "~> 2.23"/g' {} \;

# Update helm provider to consistent version
find . -name "*.tf" -exec sed -i 's/version = "~> 2\.1[0-9]"/version = "~> 2.11"/g' {} \;

echo "Provider versions updated successfully!"
