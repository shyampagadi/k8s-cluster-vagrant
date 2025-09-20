#!/bin/bash

# Script to standardize Problems 1-10 documentation to match Problems 21-30 quality

echo "🔥 STANDARDIZING PROBLEMS 1-10 DOCUMENTATION..."

# Array of problems to standardize
problems=(
    "Problem-01-Understanding-IaC"
    "Problem-02-Terraform-Installation" 
    "Problem-03-HCL-Syntax"
    "Problem-04-Provider-Ecosystem"
    "Problem-05-Resource-Lifecycle"
    "Problem-06-Variables-Basic"
    "Problem-07-Variables-Complex"
    "Problem-08-Outputs-Basic"
    "Problem-09-Data-Sources-AWS"
    "Problem-10-Loops-Iteration"
)

# Problem titles for proper documentation
declare -A problem_titles=(
    ["Problem-01-Understanding-IaC"]="Infrastructure as Code Fundamentals"
    ["Problem-02-Terraform-Installation"]="Terraform Installation and Setup"
    ["Problem-03-HCL-Syntax"]="HCL Syntax and Language Features"
    ["Problem-04-Provider-Ecosystem"]="Provider Ecosystem and Configuration"
    ["Problem-05-Resource-Lifecycle"]="Resource Lifecycle Management"
    ["Problem-06-Variables-Basic"]="Variables and Input Validation"
    ["Problem-07-Variables-Complex"]="Advanced Variable Patterns"
    ["Problem-08-Outputs-Basic"]="Outputs and Data Sharing"
    ["Problem-09-Data-Sources-AWS"]="Data Sources and Dynamic Queries"
    ["Problem-10-Loops-Iteration"]="Loops and Iteration Patterns"
)

# Base directory
BASE_DIR="/mnt/c/Users/Shyam/Documents/vagrant-k8s/Terraform/Solutions"

for problem in "${problems[@]}"; do
    echo "📝 Standardizing $problem..."
    
    problem_dir="$BASE_DIR/$problem"
    title="${problem_titles[$problem]}"
    
    # Create standardized README.md
    cat > "$problem_dir/README.md" << EOF
# ${problem}: ${title}

## 🎯 Overview

This problem focuses on mastering ${title,,} through comprehensive theory and hands-on practice. You'll learn fundamental concepts, implementation patterns, and production-ready techniques essential for Terraform expertise.

## 📚 Learning Objectives

By completing this problem, you will:
- ✅ Master core concepts and implementation patterns
- ✅ Understand best practices and real-world applications  
- ✅ Build production-ready configurations
- ✅ Develop troubleshooting and debugging skills
- ✅ Apply enterprise-grade patterns and security practices

## 📁 Problem Structure

\`\`\`
${problem}/
├── README.md                           # This overview file
├── COMPREHENSIVE-$(echo ${title^^} | tr ' ' '-')-GUIDE.md           # Complete implementation guide
├── HANDS-ON-EXERCISES.md              # Progressive practical exercises
├── TROUBLESHOOTING-GUIDE.md           # Common issues and solutions
├── main.tf                            # Working examples
├── variables.tf                       # Variable definitions
├── outputs.tf                         # Output examples
├── terraform.tfvars.example           # Example configuration
└── templates/                         # Template files (if applicable)
\`\`\`

## 🚀 Getting Started

### Prerequisites
- Terraform >= 1.0 installed
- AWS CLI configured with appropriate permissions
- Understanding of previous problems (if applicable)

### Quick Start
\`\`\`bash
# 1. Navigate to the problem directory
cd ${problem}

# 2. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 3. Edit variables for your environment
vim terraform.tfvars

# 4. Initialize Terraform
terraform init

# 5. Review the execution plan
terraform plan

# 6. Apply the configuration
terraform apply
\`\`\`

## 📖 Learning Path

### Step 1: Study the Comprehensive Guide
Start with \`COMPREHENSIVE-$(echo ${title^^} | tr ' ' '-')-GUIDE.md\` to understand:
- Theoretical foundations and core concepts
- Advanced implementation patterns
- Security and performance considerations
- Enterprise best practices

### Step 2: Complete Hands-On Exercises
Work through \`HANDS-ON-EXERCISES.md\` which includes:
- **Exercise 1**: Basic Implementation (30-45 min)
- **Exercise 2**: Advanced Patterns (45-60 min)
- **Exercise 3**: Production Scenarios (60-90 min)
- **Exercise 4**: Troubleshooting Practice (30 min)

### Step 3: Practice Troubleshooting
Use \`TROUBLESHOOTING-GUIDE.md\` to learn:
- Common issues and error patterns
- Advanced debugging techniques
- Performance optimization
- Prevention strategies

### Step 4: Implement the Solution
Examine the working Terraform code to see:
- Production-ready implementations
- Best practice patterns
- Security configurations
- Performance optimizations

## 🎯 Key Concepts Demonstrated

### Core Patterns
- **Best Practices**: Industry-standard implementation patterns
- **Security**: Security-first approach with proper configurations
- **Performance**: Optimized resource management
- **Maintainability**: Clean, documented, and reusable code

### Advanced Features
- Comprehensive variable validation
- Dynamic resource configuration
- Conditional logic and expressions
- Error handling and recovery

### Production Readiness
- Enterprise security patterns
- Performance optimization
- Comprehensive error handling
- Documentation and maintenance procedures

## 📊 Success Metrics

After completing this problem, you should be able to:
- [ ] Understand core concepts and principles
- [ ] Implement basic and advanced patterns
- [ ] Apply security best practices
- [ ] Debug and troubleshoot issues
- [ ] Optimize for performance
- [ ] Document solutions properly
- [ ] Apply enterprise patterns
- [ ] Prepare for real-world scenarios

## 🔗 Integration with Other Problems

### Prerequisites (Recommended)
- Previous problems in sequence for foundational knowledge

### Next Steps
- Continue with subsequent problems
- Apply learned concepts in advanced scenarios
- Integrate with enterprise patterns

## 📞 Support and Resources

### Documentation Files
- \`COMPREHENSIVE-$(echo ${title^^} | tr ' ' '-')-GUIDE.md\`: Complete theoretical and practical coverage
- \`HANDS-ON-EXERCISES.md\`: Step-by-step implementation exercises
- \`TROUBLESHOOTING-GUIDE.md\`: Common issues and debugging techniques

### External Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)

### Community Support
- [HashiCorp Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [Terraform GitHub Issues](https://github.com/hashicorp/terraform/issues)

---

## 🎉 Ready to Begin?

Start your ${title,,} journey by reading the comprehensive guide and then dive into the hands-on exercises. This problem will build essential skills for Terraform mastery.

**Your ${title} Mastery Journey Starts Here!** 🚀
EOF

    echo "✅ Created standardized README for $problem"
done

echo "🎉 All Problems 1-10 READMEs standardized!"
