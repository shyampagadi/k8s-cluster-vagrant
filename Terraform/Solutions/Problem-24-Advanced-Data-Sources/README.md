# Problem 24: Advanced Data Sources - Complex Queries and Filtering

## 🎯 Overview

This problem focuses on mastering advanced Terraform data sources for complex infrastructure queries, dynamic resource discovery, and sophisticated filtering patterns. You'll learn to leverage data sources for dynamic infrastructure management, complex queries, and advanced resource discovery techniques.

## 📚 Learning Objectives

By completing this problem, you will:
- ✅ Master advanced data source patterns and complex queries
- ✅ Implement sophisticated filtering and resource discovery
- ✅ Understand dynamic data source usage and optimization
- ✅ Learn advanced data transformation and processing techniques
- ✅ Develop enterprise-grade data source strategies

## 📁 Problem Structure

```
Problem-24-Advanced-Data-Sources/
├── README.md                           # This overview file
├── advanced-datasources-guide.md       # Complete data sources guide
├── exercises.md                        # Step-by-step practical exercises
├── best-practices.md                   # Enterprise best practices
├── TROUBLESHOOTING-GUIDE.md            # Common issues and solutions
├── main.tf                             # Infrastructure with advanced data sources
├── variables.tf                        # Data source variables
├── outputs.tf                          # Data source outputs
├── terraform.tfvars.example            # Example variable values
└── templates/                          # Template files
    ├── user_data.sh                    # User data script
    └── app.conf                        # Application configuration
```

## 🚀 Getting Started

### Prerequisites
- Terraform >= 1.0 installed
- AWS CLI configured with appropriate permissions
- Understanding of basic Terraform concepts (Problems 1-23)
- Experience with basic data sources

### Quick Start
```bash
# 1. Clone or navigate to the problem directory
cd Problem-24-Advanced-Data-Sources

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
```

## 📖 Learning Path

### Step 1: Study the Advanced Data Sources Guide
Start with `advanced-datasources-guide.md` to understand:
- Advanced data source patterns and best practices
- Complex query construction and optimization
- Dynamic resource discovery techniques
- Data transformation and processing methods
- Enterprise-scale data source strategies

### Step 2: Complete Hands-On Exercises
Work through `exercises.md` which includes:
- **Exercise 1**: Complex AMI Discovery (45 min)
- **Exercise 2**: Dynamic Subnet Selection (60 min)
- **Exercise 3**: Advanced Security Group Queries (75 min)
- **Exercise 4**: Multi-Region Resource Discovery (90 min)
- **Exercise 5**: Custom Data Source Integration (60 min)

### Step 3: Study Best Practices
Review `best-practices.md` to learn:
- Enterprise data source patterns
- Performance optimization techniques
- Security and compliance considerations
- Error handling and validation strategies

### Step 4: Practice Troubleshooting
Use `TROUBLESHOOTING-GUIDE.md` to learn:
- Common data source issues
- Query optimization techniques
- Performance bottleneck resolution
- Advanced debugging strategies

### Step 5: Implement the Solution
Examine the working Terraform code to see:
- Production-ready data source implementations
- Complex query patterns and filtering
- Advanced data transformation examples
- Enterprise-grade data source strategies

## 🏗️ What You'll Build

### Advanced AMI Discovery Features
- Multi-criteria AMI filtering and selection
- Dynamic AMI version management
- Cross-region AMI discovery
- Custom AMI tagging and organization
- Automated AMI lifecycle management

### Dynamic Infrastructure Discovery
- Automatic subnet and availability zone discovery
- Dynamic security group and VPC discovery
- Cross-account resource discovery
- Multi-region infrastructure mapping
- Resource dependency discovery

### Complex Data Transformation
- Advanced data filtering and processing
- Custom data source integration
- Dynamic configuration generation
- Complex data structure manipulation
- Enterprise data validation patterns

### Advanced Query Patterns
- Sophisticated filtering and sorting
- Complex conditional logic in queries
- Performance-optimized data retrieval
- Caching and optimization strategies
- Error handling and fallback mechanisms

## 🎯 Key Concepts Demonstrated

### Advanced Data Source Patterns
- **Complex Filtering**: Multi-criteria resource filtering
- **Dynamic Discovery**: Automatic resource discovery
- **Data Transformation**: Advanced data processing
- **Performance Optimization**: Efficient query patterns

### Enterprise Terraform Features
- Advanced data source configuration
- Complex data transformation functions
- Dynamic resource selection patterns
- Enterprise-scale data management
- Performance optimization techniques

### Production Best Practices
- Security by design with data validation
- Performance optimization and caching
- Comprehensive error handling
- Enterprise documentation standards
- Advanced testing and validation strategies

## 🔧 Customization Options

### Environment-Specific Data Discovery
```hcl
# Development environment - cost-optimized AMIs
data "aws_ami" "development" {
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
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Production environment - latest stable AMIs
data "aws_ami" "production" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

### Dynamic Infrastructure Discovery
```hcl
# Discover available subnets dynamically
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Select subnets based on criteria
locals {
  selected_subnets = [
    for subnet in data.aws_subnets.available.ids :
    subnet if contains(data.aws_subnet.details[subnet].tags, "Tier", "public")
  ]
}
```

### Multi-Region Resource Discovery
```hcl
# Primary region resources
data "aws_ami" "primary" {
  provider = aws.primary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Secondary region resources
data "aws_ami" "secondary" {
  provider = aws.secondary
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

## 📊 Success Metrics

After completing this problem, you should be able to:
- [ ] Design complex data source queries
- [ ] Implement sophisticated filtering patterns
- [ ] Optimize data source performance
- [ ] Handle complex data transformations
- [ ] Debug advanced data source issues
- [ ] Apply enterprise data source patterns
- [ ] Implement dynamic resource discovery
- [ ] Design scalable data source architectures

## 🔗 Integration with Other Problems

### Prerequisites (Required)
- **Problem 9**: Basic data sources
- **Problem 11**: Conditional logic
- **Problem 12**: Functions and locals
- **Problem 23**: State management

### Next Steps
- **Problem 25**: Custom providers and data sources
- **Problem 26**: Advanced loops with data sources
- **Problem 27**: Enterprise patterns with data sources
- **Problem 30**: Production deployment with dynamic discovery

## 📞 Support and Resources

### Documentation Files
- `advanced-datasources-guide.md`: Complete theoretical coverage
- `exercises.md`: Step-by-step implementation exercises
- `best-practices.md`: Enterprise best practices
- `TROUBLESHOOTING-GUIDE.md`: Common issues and debugging techniques

### External Resources
- [Terraform Data Sources Documentation](https://www.terraform.io/docs/language/data-sources/index.html)
- [AWS Provider Data Sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources)
- [Terraform Functions Documentation](https://www.terraform.io/docs/language/functions/index.html)

### Community Support
- [HashiCorp Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [Terraform GitHub Issues](https://github.com/hashicorp/terraform/issues)

---

## 🎉 Ready to Begin?

Start your advanced data sources journey by reading the comprehensive guide and then dive into the hands-on exercises. This problem will transform you from a basic data source user into an advanced data source expert capable of creating sophisticated, dynamic infrastructure solutions.

**From Basic Queries to Advanced Discovery - Your Journey Continues Here!** 🚀
