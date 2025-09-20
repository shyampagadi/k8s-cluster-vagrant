#!/bin/bash

cd /mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions

# Problem-specific content for Problems 11-20
declare -A problem_content=(
    ["11"]="Conditional Logic|Dynamic resource creation patterns, conditional expressions, and environment-based logic"
    ["12"]="Locals Functions|Data transformation, reuse patterns, and built-in function mastery"
    ["13"]="Resource Dependencies|Explicit and implicit dependency management, dependency graphs"
    ["14"]="Lifecycle Rules|Advanced resource lifecycle management, create_before_destroy, ignore_changes"
    ["15"]="Workspaces Environments|Multi-environment management, workspace strategies, state isolation"
    ["16"]="File Organization|Project structure, best practices, team collaboration patterns"
    ["17"]="Error Handling|Debugging techniques, troubleshooting, error prevention strategies"
    ["18"]="Security Fundamentals|Security best practices, encryption, access control, compliance"
    ["19"]="Performance Optimization|Optimization techniques, cost management, resource efficiency"
    ["20"]="Troubleshooting|Common issues, debugging tools, resolution strategies, prevention"
)

# Function to create hands-on exercises
create_hands_on_exercises() {
    local problem_num=$1
    local problem_title=$2
    local problem_focus=$3
    local problem_dir="Problem-$problem_num-$(echo $problem_title | tr ' ' '-')"
    
    if [ ! -d "$problem_dir" ]; then
        return
    fi
    
    echo "📝 Creating exercises for Problem $problem_num: $problem_title"
    
    cat > "$problem_dir/HANDS-ON-EXERCISES.md" << 'EOF'
# Problem PROBLEM_NUM: PROBLEM_TITLE - Hands-On Exercises

## Exercise 1: Basic Implementation (30 minutes)
**Objective**: Implement basic PROBLEM_TITLE functionality
**Difficulty**: Beginner

### Requirements
- Understand core concepts of PROBLEM_TITLE
- Implement basic configuration
- Test and validate functionality
- Document lessons learned

### Step-by-Step Implementation

#### Step 1: Environment Setup
```bash
# Create exercise directory
mkdir problem-PROBLEM_NUM-exercise
cd problem-PROBLEM_NUM-exercise

# Initialize Terraform
terraform init
```

#### Step 2: Basic Configuration
```hcl
# Create main.tf with basic implementation
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Basic implementation specific to PROBLEM_TITLE
# Add your configuration here
```

#### Step 3: Testing and Validation
```bash
# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Verify results
terraform output
```

### Validation Checklist
- [ ] Configuration validates without errors
- [ ] Plan executes successfully
- [ ] Resources are created as expected
- [ ] Outputs provide useful information

## Exercise 2: Intermediate Configuration (45 minutes)
**Objective**: Implement more complex PROBLEM_TITLE scenarios
**Difficulty**: Intermediate

### Requirements
- Advanced configuration patterns
- Multiple resource integration
- Error handling implementation
- Performance considerations

### Implementation Tasks

#### Task 1: Advanced Configuration
Implement more complex scenarios with multiple components and integrations.

#### Task 2: Error Handling
Add comprehensive error handling and validation rules.

#### Task 3: Performance Optimization
Optimize configuration for performance and cost efficiency.

#### Task 4: Integration Testing
Test integration with other Terraform concepts and AWS services.

### Challenge Tasks
1. Implement conditional logic
2. Add comprehensive validation
3. Create reusable patterns
4. Add monitoring and alerting

## Exercise 3: Production-Ready Implementation (60 minutes)
**Objective**: Create production-grade PROBLEM_TITLE configuration
**Difficulty**: Advanced

### Requirements
- Security best practices
- Performance optimization
- Monitoring and alerting
- Backup and recovery
- Documentation and maintenance

### Production Checklist
- [ ] Security controls implemented
- [ ] Performance optimized
- [ ] Monitoring configured
- [ ] Backup procedures tested
- [ ] Documentation complete
- [ ] Team training provided

## Exercise 4: Integration Challenge (75 minutes)
**Objective**: Integrate PROBLEM_TITLE with other Terraform concepts
**Difficulty**: Advanced

### Integration Points
- Module integration
- State management
- CI/CD pipeline integration
- Multi-environment deployment

### Challenge Tasks
1. Create reusable modules
2. Implement remote state
3. Set up automated deployment
4. Configure multiple environments

## Exercise 5: Troubleshooting Lab (30 minutes)
**Objective**: Practice debugging and troubleshooting PROBLEM_TITLE issues
**Difficulty**: Intermediate

### Scenarios
1. Configuration errors and fixes
2. Authentication and permission issues
3. Resource conflicts and resolution
4. Performance problems and optimization

## Solutions and Explanations

### Exercise 1 Solution
```hcl
# Complete basic implementation with explanations
# This demonstrates the fundamental concepts
```

### Exercise 2 Solution
```hcl
# Advanced implementation with best practices
# Including error handling and optimization
```

### Exercise 3 Solution
```hcl
# Production-ready implementation
# With security, monitoring, and compliance
```

### Exercise 4 Solution
```hcl
# Integrated solution with modules and automation
# Demonstrating enterprise patterns
```

## Key Learning Points

### Technical Skills
- Mastery of PROBLEM_TITLE concepts
- Implementation of best practices
- Integration with other technologies
- Troubleshooting and debugging

### Professional Skills
- Problem-solving approaches
- Documentation and communication
- Team collaboration patterns
- Continuous learning mindset

This hands-on approach ensures practical mastery of PROBLEM_TITLE through progressive skill building and real-world application.
EOF

    # Replace placeholders with actual values
    sed -i "s/PROBLEM_NUM/$problem_num/g" "$problem_dir/HANDS-ON-EXERCISES.md"
    sed -i "s/PROBLEM_TITLE/$problem_title/g" "$problem_dir/HANDS-ON-EXERCISES.md"
    sed -i "s/PROBLEM_FOCUS/$problem_focus/g" "$problem_dir/HANDS-ON-EXERCISES.md"
}

# Generate exercises for Problems 11-20
for problem_num in {11..20}; do
    if [ -n "${problem_content[$problem_num]}" ]; then
        IFS='|' read -r problem_title problem_focus <<< "${problem_content[$problem_num]}"
        create_hands_on_exercises "$problem_num" "$problem_title" "$problem_focus"
    fi
done

echo "✅ Hands-on exercises created for Problems 11-20!"
