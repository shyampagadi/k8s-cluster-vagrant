# Terraform Interview Questions

## Basic Concepts

### 1. What is Terraform and how does it differ from other infrastructure tools?
**Answer**: Terraform is an Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure using declarative configuration files. Unlike imperative tools like Ansible, Terraform uses a declarative approach where you describe the desired state, and Terraform figures out how to achieve it.

### 2. Explain the difference between Terraform and CloudFormation.
**Answer**: 
- **Terraform**: Multi-cloud, open-source, uses HCL syntax, supports multiple providers
- **CloudFormation**: AWS-specific, uses JSON/YAML, native AWS service

### 3. What is the Terraform state file and why is it important?
**Answer**: The state file tracks the current state of your infrastructure and maps real-world resources to your configuration. It's crucial for:
- Tracking resource dependencies
- Determining what changes need to be made
- Storing resource metadata
- Enabling collaboration between team members

## Intermediate Concepts

### 4. How do you handle sensitive data in Terraform?
**Answer**: 
- Use `sensitive = true` for variables and outputs
- Store sensitive data in environment variables
- Use external secret management systems
- Never commit sensitive data to version control

### 5. Explain Terraform modules and their benefits.
**Answer**: Modules are reusable packages of Terraform configurations that encapsulate groups of resources. Benefits include:
- Code reusability
- Better organization
- Easier maintenance
- Standardization across environments

### 6. What are Terraform workspaces and when would you use them?
**Answer**: Workspaces allow you to manage multiple environments (dev, staging, prod) with the same configuration. Use them when you need to:
- Isolate environments
- Manage multiple deployments
- Avoid resource conflicts

## Advanced Concepts

### 7. How do you handle Terraform state in a team environment?
**Answer**: 
- Use remote state backends (S3, Consul, etc.)
- Implement state locking (DynamoDB for S3)
- Use state versioning and backup
- Implement proper access controls

### 8. Explain Terraform's dependency graph and how it works.
**Answer**: Terraform builds a dependency graph based on resource references and explicit dependencies. It ensures resources are created/destroyed in the correct order and can parallelize independent operations.

### 9. How do you implement blue-green deployments with Terraform?
**Answer**: 
- Use separate target groups for blue and green environments
- Create separate auto-scaling groups
- Use ALB listener rules to switch traffic
- Implement health checks and rollback procedures

## Scenario-Based Questions

### 10. How would you handle a situation where Terraform state is out of sync with actual infrastructure?
**Answer**: 
- Use `terraform refresh` to sync state
- Use `terraform import` for existing resources
- Use `terraform state rm` for resources no longer managed
- Implement proper state management practices

### 11. Describe your approach to testing Terraform configurations.
**Answer**: 
- Use `terraform plan` for validation
- Implement unit testing with Terratest
- Use integration testing in isolated environments
- Implement policy testing with Sentinel

### 12. How do you handle Terraform in a CI/CD pipeline?
**Answer**: 
- Use automated testing and validation
- Implement proper state management
- Use environment-specific configurations
- Implement rollback procedures
- Use proper access controls and secrets management

## Best Practices

### 13. What are your Terraform security best practices?
**Answer**: 
- Never commit sensitive data
- Use IAM roles and policies
- Implement least privilege access
- Use encryption for state files
- Regular security audits

### 14. How do you optimize Terraform performance?
**Answer**: 
- Use parallel execution
- Optimize resource dependencies
- Use data sources efficiently
- Implement proper state management
- Use targeted operations when possible

### 15. Describe your approach to Terraform code organization.
**Answer**: 
- Use modules for reusability
- Separate environments
- Use consistent naming conventions
- Implement proper documentation
- Use version control best practices

## Hands-On Scenarios

### 16. Create a Terraform configuration for a web application with auto-scaling.
**Answer**: Would include VPC, subnets, security groups, ALB, target groups, launch template, auto-scaling group, and necessary IAM roles.

### 17. How would you implement disaster recovery with Terraform?
**Answer**: 
- Multi-region deployment
- Automated backup and replication
- Cross-region state management
- Automated failover procedures

### 18. Design a Terraform module for a database cluster.
**Answer**: Would include RDS cluster, subnets, security groups, parameter groups, backup configuration, and monitoring.

## Tips for Success

### Preparation
- Practice hands-on scenarios
- Understand real-world use cases
- Review Terraform documentation
- Practice with different providers

### During the Interview
- Think out loud
- Ask clarifying questions
- Explain your reasoning
- Discuss trade-offs and alternatives

### Follow-up
- Ask about team practices
- Discuss learning opportunities
- Understand the role requirements
- Show enthusiasm for the technology
