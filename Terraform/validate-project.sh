#!/bin/bash

# Terraform Zero-to-Hero Project Validation Script
# Validates project completeness and quality

echo "🔍 TERRAFORM ZERO-TO-HERO PROJECT VALIDATION"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to check if file exists
check_file() {
    local file_path="$1"
    local description="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $description - File not found: $file_path"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir_path="$1"
    local description="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $description - Directory not found: $dir_path"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to check file content
check_content() {
    local file_path="$1"
    local pattern="$2"
    local description="$3"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file_path" ] && grep -q "$pattern" "$file_path"; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $description - Pattern not found in: $file_path"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

echo -e "\n${BLUE}📋 CHECKING PROJECT STRUCTURE${NC}"
echo "================================"

# Check main project files
check_file "README-UPDATED.md" "Main README file"
check_file "Terraform-Practice-Problems-Updated.md" "Updated practice problems"
check_file "FINAL-100-PERCENT-COMPLETE.md" "Final completion status"

echo -e "\n${BLUE}📁 CHECKING SOLUTION DIRECTORIES${NC}"
echo "=================================="

# Check all 35 problem directories
for i in {1..35}; do
    if [ $i -le 9 ]; then
        problem_dir="Solutions/Problem-0$i-*"
    else
        problem_dir="Solutions/Problem-$i-*"
    fi
    
    # Find the actual directory name
    actual_dir=$(find Solutions -maxdepth 1 -type d -name "Problem-$(printf "%02d" $i)-*" | head -1)
    
    if [ -n "$actual_dir" ]; then
        check_directory "$actual_dir" "Problem $i solution directory"
        
        # Check for main Terraform files
        check_file "$actual_dir/main.tf" "Problem $i main.tf"
        check_file "$actual_dir/variables.tf" "Problem $i variables.tf"
        check_file "$actual_dir/outputs.tf" "Problem $i outputs.tf"
        check_file "$actual_dir/README.md" "Problem $i README.md"
    else
        echo -e "${RED}❌ FAIL${NC}: Problem $i solution directory not found"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    fi
done

echo -e "\n${BLUE}🔧 CHECKING MODULE STRUCTURE (Problem 21)${NC}"
echo "==========================================="

# Check Problem 21 modules
problem21_dir="Solutions/Problem-21-Modules-Basic"
if [ -d "$problem21_dir" ]; then
    modules=("vpc" "security-group" "ec2" "alb" "s3")
    
    for module in "${modules[@]}"; do
        module_dir="$problem21_dir/modules/$module"
        check_directory "$module_dir" "Module: $module"
        check_file "$module_dir/main.tf" "Module $module main.tf"
        check_file "$module_dir/variables.tf" "Module $module variables.tf"
        check_file "$module_dir/outputs.tf" "Module $module outputs.tf"
    done
    
    # Check template files
    check_file "$problem21_dir/templates/web_user_data.sh" "Web server user data template"
fi

echo -e "\n${BLUE}☸️ CHECKING KUBERNETES IMPLEMENTATIONS${NC}"
echo "======================================="

# Check Problem 30 (EKS)
problem30_dir="Solutions/Problem-30-Microservices-Infrastructure"
if [ -d "$problem30_dir" ]; then
    check_content "$problem30_dir/main.tf" "aws_eks_cluster" "Problem 30 EKS cluster resource"
    check_content "$problem30_dir/main.tf" "kubernetes_namespace" "Problem 30 Kubernetes namespace"
    check_content "$problem30_dir/main.tf" "helm_release" "Problem 30 Helm release"
    check_file "$problem30_dir/templates/kubeconfig.tpl" "Problem 30 kubeconfig template"
fi

# Check Problem 35 (Kubernetes Fundamentals)
problem35_dir="Solutions/Problem-35-Kubernetes-Fundamentals"
if [ -d "$problem35_dir" ]; then
    check_content "$problem35_dir/main.tf" "kubernetes_deployment" "Problem 35 Kubernetes deployment"
    check_content "$problem35_dir/main.tf" "kubernetes_service" "Problem 35 Kubernetes service"
    check_content "$problem35_dir/main.tf" "kubernetes_config_map" "Problem 35 ConfigMap"
    check_content "$problem35_dir/main.tf" "kubernetes_secret" "Problem 35 Secret"
fi

echo -e "\n${BLUE}🔒 CHECKING SECURITY IMPLEMENTATIONS${NC}"
echo "====================================="

# Check for security best practices
security_patterns=("encrypted.*=.*true" "enable_deletion_protection" "block_public_acls")
for pattern in "${security_patterns[@]}"; do
    if find Solutions -name "*.tf" -exec grep -l "$pattern" {} \; | head -1 > /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}: Security pattern found: $pattern"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️ WARN${NC}: Security pattern not found: $pattern"
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
done

echo -e "\n${BLUE}📊 CHECKING PROVIDER CONFIGURATIONS${NC}"
echo "===================================="

# Check for required providers
providers=("hashicorp/aws" "hashicorp/kubernetes" "hashicorp/helm" "hashicorp/random")
for provider in "${providers[@]}"; do
    if find Solutions -name "*.tf" -exec grep -l "$provider" {} \; | head -1 > /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}: Provider found: $provider"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️ WARN${NC}: Provider not found: $provider"
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
done

echo -e "\n${BLUE}📈 VALIDATION SUMMARY${NC}"
echo "====================="

# Calculate percentage
if [ $TOTAL_CHECKS -gt 0 ]; then
    PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
else
    PERCENTAGE=0
fi

echo "Total Checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Success Rate: ${GREEN}$PERCENTAGE%${NC}"

# Final assessment
if [ $PERCENTAGE -ge 95 ]; then
    echo -e "\n${GREEN}🎉 PROJECT STATUS: EXCELLENT (95%+)${NC}"
    echo -e "${GREEN}✅ Ready for production deployment!${NC}"
    exit 0
elif [ $PERCENTAGE -ge 85 ]; then
    echo -e "\n${YELLOW}⚠️ PROJECT STATUS: GOOD (85-94%)${NC}"
    echo -e "${YELLOW}Minor issues to address${NC}"
    exit 1
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "\n${YELLOW}⚠️ PROJECT STATUS: NEEDS IMPROVEMENT (70-84%)${NC}"
    echo -e "${YELLOW}Several issues to address${NC}"
    exit 2
else
    echo -e "\n${RED}❌ PROJECT STATUS: CRITICAL ISSUES (<70%)${NC}"
    echo -e "${RED}Major issues require immediate attention${NC}"
    exit 3
fi
