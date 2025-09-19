# Problem 21: Modules - Basic Usage and Structure

## Overview
This solution demonstrates the fundamental concepts of Terraform modules, including module structure, basic usage, and best practices for creating reusable infrastructure components.

## Learning Objectives
- Understand Terraform module structure and organization
- Learn how to create and use basic modules
- Master module input/output patterns
- Understand module versioning and reusability
- Learn best practices for module design

## Solution Structure
```
Problem-21-Modules-Basic/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── modules/
│   └── s3-bucket/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── templates/
    ├── user_data.sh
    └── app.conf
```

## Key Concepts Demonstrated

### 1. Module Structure
- **Module Directory**: Each module is a self-contained directory
- **Module Files**: `main.tf`, `variables.tf`, `outputs.tf` pattern
- **Module Interface**: Clear input/output definitions

### 2. Module Usage
- **Module Block**: Using modules in root configuration
- **Input Variables**: Passing values to modules
- **Output Values**: Accessing module outputs
- **Module Calls**: Multiple instances of the same module

### 3. Module Benefits
- **Reusability**: Write once, use many times
- **Maintainability**: Centralized logic and updates
- **Organization**: Clear separation of concerns
- **Testing**: Isolated testing of components

## Implementation Details

### Module Creation
The `modules/s3-bucket/` directory contains a reusable S3 bucket module that:
- Creates an S3 bucket with configurable name and tags
- Implements bucket versioning and server-side encryption
- Provides outputs for bucket name and ARN
- Uses input variables for customization

### Module Usage
The root configuration demonstrates:
- Calling the S3 bucket module multiple times
- Passing different input values to each instance
- Accessing module outputs for further use
- Using module outputs in other resources

### Best Practices
- **Clear Naming**: Descriptive module and variable names
- **Documentation**: Comprehensive variable descriptions
- **Validation**: Input validation rules
- **Outputs**: Useful output values for consumers
- **Versioning**: Module version constraints

## Usage Instructions

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the Plan**:
   ```bash
   terraform plan
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```

4. **Verify Resources**:
   ```bash
   terraform show
   ```

## Expected Outputs
- Multiple S3 buckets created using the module
- Bucket names and ARNs displayed as outputs
- Module outputs accessible for further use

## Knowledge Check
- What is the purpose of Terraform modules?
- How do you pass input variables to a module?
- What are the benefits of using modules?
- How do you access module outputs?
- What is the recommended file structure for modules?

## Next Steps
- Explore advanced module features (count, for_each)
- Learn about module versioning and registry
- Study module composition patterns
- Practice creating custom modules
