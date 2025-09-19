# Terraform Workflow Documentation

## Overview

The Terraform workflow is a systematic process for managing infrastructure through code. Understanding this workflow is crucial for effective Terraform usage and troubleshooting.

## The Terraform Workflow

The Terraform workflow consists of four main commands that work together to manage infrastructure:

1. **terraform init** - Initialize the working directory
2. **terraform plan** - Create an execution plan
3. **terraform apply** - Apply the changes
4. **terraform destroy** - Destroy the infrastructure

## Detailed Command Analysis

### 1. terraform init

#### Purpose
Initializes the working directory and downloads required providers and modules.

#### What Happens Internally
1. **Backend Initialization:** Sets up the backend for state storage
2. **Provider Download:** Downloads required provider plugins
3. **Module Download:** Downloads required modules
4. **Working Directory Setup:** Creates necessary directories and files
5. **Configuration Validation:** Validates the configuration syntax

#### Command Syntax
```bash
terraform init [options]
```

#### Common Options
```bash
# Initialize with specific backend configuration
terraform init -backend-config="bucket=my-terraform-state"

# Initialize with specific provider version
terraform init -upgrade

# Initialize without downloading providers
terraform init -backend=false

# Initialize with specific module source
terraform init -from-module=hashicorp/consul/aws
```

#### Example Output
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Installing hashicorp/aws v4.67.0...
- Installed hashicorp/aws v4.67.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

#### Files Created
- `.terraform/` directory with provider plugins
- `.terraform.lock.hcl` with provider version locks
- Backend configuration files

#### When to Use
- First time setting up a Terraform project
- After adding new providers or modules
- After changing backend configuration
- When provider versions need updating

### 2. terraform plan

#### Purpose
Creates an execution plan showing what changes will be made to the infrastructure.

#### What Happens Internally
1. **Configuration Parsing:** Reads and parses all `.tf` files
2. **State Reading:** Reads current state from backend
3. **Provider Communication:** Communicates with providers to understand current resources
4. **Dependency Analysis:** Analyzes resource dependencies
5. **Plan Generation:** Creates execution plan
6. **Output Display:** Shows what changes will be made

#### Command Syntax
```bash
terraform plan [options] [plan-file]
```

#### Common Options
```bash
# Save plan to file
terraform plan -out=plan.tfplan

# Plan specific resource
terraform plan -target=aws_s3_bucket.my_bucket

# Plan with specific variables
terraform plan -var="instance_type=t3.large"

# Plan with variable file
terraform plan -var-file="production.tfvars"

# Plan with detailed output
terraform plan -detailed-exitcode
```

#### Example Output
```
Terraform will perform the following actions:

  # aws_s3_bucket.my_bucket will be created
  + resource "aws_s3_bucket" "my_bucket" {
      + bucket = "my-terraform-bucket-a1b2c3d4"
      + id     = "my-terraform-bucket-a1b2c3d4"
    }

  # aws_s3_bucket_versioning.my_bucket_versioning will be created
  + resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
      + bucket = (known after apply)
      + id     = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

#### Plan File Structure
```json
{
  "format_version": "1.0",
  "terraform_version": "1.5.0",
  "planned_values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_s3_bucket.my_bucket",
          "mode": "managed",
          "type": "aws_s3_bucket",
          "name": "my_bucket",
          "values": {
            "bucket": "my-terraform-bucket-a1b2c3d4"
          }
        }
      ]
    }
  },
  "resource_changes": [
    {
      "address": "aws_s3_bucket.my_bucket",
      "change": {
        "actions": ["create"],
        "before": null,
        "after": {
          "bucket": "my-terraform-bucket-a1b2c3d4"
        }
      }
    }
  ]
}
```

#### When to Use
- Before applying changes to review what will happen
- To validate configuration changes
- To generate plan files for automated deployments
- To check for potential issues

### 3. terraform apply

#### Purpose
Executes the plan and makes the actual changes to the infrastructure.

#### What Happens Internally
1. **Plan Validation:** Validates the execution plan
2. **Resource Creation:** Creates resources in dependency order
3. **State Updates:** Updates state file with new resource information
4. **Output Generation:** Generates output values
5. **Error Handling:** Handles errors and rollbacks

#### Command Syntax
```bash
terraform apply [options] [plan-file]
```

#### Common Options
```bash
# Apply specific plan file
terraform apply plan.tfplan

# Apply with auto-approval
terraform apply -auto-approve

# Apply specific resource
terraform apply -target=aws_s3_bucket.my_bucket

# Apply with specific variables
terraform apply -var="instance_type=t3.large"

# Apply with variable file
terraform apply -var-file="production.tfvars"
```

#### Example Output
```
Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.

Enter a value: yes

aws_s3_bucket.my_bucket: Creating...
aws_s3_bucket.my_bucket: Still creating... [10s elapsed]
aws_s3_bucket.my_bucket: Creation complete after 11s [id=my-terraform-bucket-a1b2c3d4]

aws_s3_bucket_versioning.my_bucket_versioning: Creating...
aws_s3_bucket_versioning.my_bucket_versioning: Creation complete after 2s [id=my-terraform-bucket-a1b2c3d4]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "my-terraform-bucket-a1b2c3d4"
bucket_arn = "arn:aws:s3:::my-terraform-bucket-a1b2c3d4"
```

#### State File Updates
After apply, the state file is updated with:
- New resource information
- Resource relationships
- Output values
- Metadata

#### When to Use
- To implement infrastructure changes
- After reviewing a plan
- In automated deployment pipelines
- To create new resources

### 4. terraform destroy

#### Purpose
Destroys all managed resources and cleans up the infrastructure.

#### What Happens Internally
1. **State Reading:** Reads current state
2. **Dependency Analysis:** Analyzes resource dependencies
3. **Destruction Plan:** Creates destruction plan
4. **Resource Destruction:** Destroys resources in reverse dependency order
5. **State Cleanup:** Removes destroyed resources from state

#### Command Syntax
```bash
terraform destroy [options]
```

#### Common Options
```bash
# Destroy with auto-approval
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.my_bucket

# Destroy with specific variables
terraform destroy -var="environment=development"

# Destroy with variable file
terraform destroy -var-file="production.tfvars"
```

#### Example Output
```
Terraform will perform the following actions:

  # aws_s3_bucket_versioning.my_bucket_versioning will be destroyed
  - resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
      - bucket = "my-terraform-bucket-a1b2c3d4"
      - id     = "my-terraform-bucket-a1b2c3d4"
    }

  # aws_s3_bucket.my_bucket will be destroyed
  - resource "aws_s3_bucket" "my_bucket" {
      - bucket = "my-terraform-bucket-a1b2c3d4"
      - id     = "my-terraform-bucket-a1b2c3d4"
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?
Enter a value: yes

aws_s3_bucket_versioning.my_bucket_versioning: Destroying... [id=my-terraform-bucket-a1b2c3d4]
aws_s3_bucket_versioning.my_bucket_versioning: Destruction complete after 1s

aws_s3_bucket.my_bucket: Destroying... [id=my-terraform-bucket-a1b2c3d4]
aws_s3_bucket.my_bucket: Destruction complete after 2s

Destroy complete! Resources: 0 added, 0 changed, 2 destroyed.
```

#### When to Use
- To clean up development environments
- To remove unused infrastructure
- To reset infrastructure state
- To comply with cost optimization policies

## Additional Commands

### terraform validate

#### Purpose
Validates the configuration files for syntax and internal consistency.

#### Command Syntax
```bash
terraform validate [options]
```

#### Example Output
```
Success! The configuration is valid.
```

#### When to Use
- Before planning or applying
- In CI/CD pipelines
- To check configuration syntax

### terraform fmt

#### Purpose
Formats Terraform configuration files to a canonical format.

#### Command Syntax
```bash
terraform fmt [options] [target-directory]
```

#### Common Options
```bash
# Format all files recursively
terraform fmt -recursive

# Check if files need formatting
terraform fmt -check

# Show differences
terraform fmt -diff
```

#### When to Use
- Before committing code
- To maintain consistent formatting
- In pre-commit hooks

### terraform show

#### Purpose
Shows the current state or a saved plan.

#### Command Syntax
```bash
terraform show [options] [plan-file]
```

#### Common Options
```bash
# Show current state
terraform show

# Show specific plan file
terraform show plan.tfplan

# Show in JSON format
terraform show -json
```

#### When to Use
- To inspect current state
- To review saved plans
- To debug configuration issues

## Workflow Best Practices

### 1. Always Plan Before Apply
```bash
# Good practice
terraform plan
terraform apply

# Avoid
terraform apply -auto-approve
```

### 2. Use Plan Files for Automation
```bash
# Generate plan file
terraform plan -out=plan.tfplan

# Apply plan file
terraform apply plan.tfplan
```

### 3. Validate Before Planning
```bash
# Complete workflow
terraform validate
terraform plan
terraform apply
```

### 4. Use Targeted Operations
```bash
# Plan specific resource
terraform plan -target=aws_s3_bucket.my_bucket

# Apply specific resource
terraform apply -target=aws_s3_bucket.my_bucket
```

### 5. Handle Errors Gracefully
```bash
# Check for errors
terraform plan -detailed-exitcode

# Exit codes:
# 0 - Success with no changes
# 1 - Error
# 2 - Success with changes
```

## Common Workflow Patterns

### 1. Development Workflow
```bash
# 1. Initialize
terraform init

# 2. Validate
terraform validate

# 3. Plan
terraform plan

# 4. Apply
terraform apply

# 5. Test
# ... test your infrastructure ...

# 6. Destroy (when done)
terraform destroy
```

### 2. CI/CD Workflow
```bash
# 1. Initialize
terraform init

# 2. Validate
terraform validate

# 3. Plan
terraform plan -out=plan.tfplan

# 4. Apply (with approval)
terraform apply plan.tfplan
```

### 3. Production Workflow
```bash
# 1. Initialize
terraform init

# 2. Validate
terraform validate

# 3. Plan
terraform plan -out=plan.tfplan

# 4. Review plan
terraform show plan.tfplan

# 5. Apply (manual approval)
terraform apply plan.tfplan
```

## Troubleshooting

### Common Issues

#### 1. Provider Not Found
```bash
# Error: Provider "aws" not found
# Solution: Run terraform init
terraform init
```

#### 2. State Lock Issues
```bash
# Error: Error acquiring the state lock
# Solution: Check for stuck locks
terraform force-unlock <lock-id>
```

#### 3. Configuration Errors
```bash
# Error: Invalid configuration
# Solution: Validate configuration
terraform validate
```

#### 4. Resource Conflicts
```bash
# Error: Resource already exists
# Solution: Import existing resource
terraform import aws_s3_bucket.my_bucket existing-bucket-name
```

## Conclusion

The Terraform workflow is a systematic process that ensures reliable infrastructure management. By following the proper sequence of commands and best practices, you can:

1. **Maintain Consistency:** Same process every time
2. **Reduce Errors:** Validation and planning before changes
3. **Enable Collaboration:** Shared understanding of the process
4. **Support Automation:** Predictable command sequence

Remember: The workflow is not just about running commands—it's about understanding what each command does and why it's important. This understanding will help you troubleshoot issues and optimize your infrastructure management process.
