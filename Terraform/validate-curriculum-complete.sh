#!/bin/bash

# Comprehensive Terraform Curriculum Validation Script
# Validates all 40 problems for enterprise-grade quality standards

echo "🔥 TERRAFORM ZERO-TO-HERO CURRICULUM VALIDATION"
echo "=============================================="

# Initialize counters
total_problems=40
validated_problems=0
total_files=0
total_lines=0
missing_components=()

# Required components for each problem
required_files=(
    "README.md"
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "terraform.tfvars.example"
)

optional_enterprise_files=(
    "COMPREHENSIVE-*-GUIDE.md"
    "HANDS-ON-EXERCISES.md"
    "TROUBLESHOOTING-GUIDE.md"
    "ENTERPRISE-*-PATTERNS*.md"
)

echo "📊 ANALYZING ALL 40 PROBLEMS..."
echo ""

# Function to check problem completeness
check_problem() {
    local problem_dir=$1
    local problem_name=$(basename "$problem_dir")
    local problem_score=0
    local max_score=10
    
    echo "🔍 Validating $problem_name..."
    
    # Check required files (5 points)
    for file in "${required_files[@]}"; do
        if [[ -f "$problem_dir/$file" ]]; then
            ((problem_score++))
        else
            missing_components+=("$problem_name: Missing $file")
        fi
    done
    
    # Check comprehensive guides (2 points)
    if ls "$problem_dir"/COMPREHENSIVE-*-GUIDE.md 1> /dev/null 2>&1; then
        ((problem_score+=2))
    else
        missing_components+=("$problem_name: Missing comprehensive guide")
    fi
    
    # Check hands-on exercises (2 points)
    if [[ -f "$problem_dir/HANDS-ON-EXERCISES.md" ]] || [[ -f "$problem_dir/COMPREHENSIVE-HANDS-ON-EXERCISES.md" ]]; then
        ((problem_score+=2))
    else
        missing_components+=("$problem_name: Missing hands-on exercises")
    fi
    
    # Check troubleshooting guide (1 point)
    if [[ -f "$problem_dir/TROUBLESHOOTING-GUIDE.md" ]]; then
        ((problem_score++))
    fi
    
    # Count files and lines
    local file_count=$(find "$problem_dir" -name "*.md" -o -name "*.tf" | wc -l)
    local line_count=$(find "$problem_dir" -name "*.md" -o -name "*.tf" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    
    total_files=$((total_files + file_count))
    total_lines=$((total_lines + line_count))
    
    # Calculate percentage
    local percentage=$((problem_score * 100 / max_score))
    
    if [[ $percentage -ge 80 ]]; then
        echo "  ✅ $problem_name: $percentage% ($problem_score/$max_score) - EXCELLENT"
        ((validated_problems++))
    elif [[ $percentage -ge 60 ]]; then
        echo "  ⚠️  $problem_name: $percentage% ($problem_score/$max_score) - GOOD"
    else
        echo "  ❌ $problem_name: $percentage% ($problem_score/$max_score) - NEEDS IMPROVEMENT"
    fi
    
    echo "     Files: $file_count, Lines: $line_count"
    echo ""
}

# Validate all problems
for i in {1..40}; do
    if [[ $i -lt 10 ]]; then
        problem_dir="Solutions/Problem-0$i-*"
    else
        problem_dir="Solutions/Problem-$i-*"
    fi
    
    # Find the actual directory
    actual_dir=$(find . -maxdepth 1 -type d -name "$problem_dir" | head -1)
    
    if [[ -d "$actual_dir" ]]; then
        check_problem "$actual_dir"
    else
        echo "❌ Problem $i: Directory not found"
        missing_components+=("Problem-$i: Directory missing")
    fi
done

echo "📈 CURRICULUM QUALITY REPORT"
echo "============================"
echo "Total Problems: $total_problems"
echo "Validated Problems (≥80%): $validated_problems"
echo "Success Rate: $((validated_problems * 100 / total_problems))%"
echo "Total Files: $total_files"
echo "Total Lines of Code/Documentation: $total_lines"
echo ""

# Quality breakdown by problem range
echo "📊 QUALITY BREAKDOWN BY RANGE"
echo "=============================="

ranges=("01-10" "11-20" "21-30" "31-40")
range_names=("Foundation" "Intermediate" "Advanced" "Expert")

for i in "${!ranges[@]}"; do
    range="${ranges[$i]}"
    name="${range_names[$i]}"
    
    if [[ "$range" == "01-10" ]]; then
        start=1; end=10
    elif [[ "$range" == "11-20" ]]; then
        start=11; end=20
    elif [[ "$range" == "21-30" ]]; then
        start=21; end=30
    else
        start=31; end=40
    fi
    
    range_files=0
    range_lines=0
    
    for j in $(seq $start $end); do
        if [[ $j -lt 10 ]]; then
            problem_pattern="Solutions/Problem-0$j-*"
        else
            problem_pattern="Solutions/Problem-$j-*"
        fi
        
        actual_dir=$(find . -maxdepth 1 -type d -name "$problem_pattern" | head -1)
        if [[ -d "$actual_dir" ]]; then
            files=$(find "$actual_dir" -name "*.md" -o -name "*.tf" | wc -l)
            lines=$(find "$actual_dir" -name "*.md" -o -name "*.tf" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
            range_files=$((range_files + files))
            range_lines=$((range_lines + lines))
        fi
    done
    
    echo "$name (Problems $start-$end): $range_files files, $range_lines lines"
done

echo ""

# Enterprise readiness assessment
echo "🏢 ENTERPRISE READINESS ASSESSMENT"
echo "=================================="

enterprise_features=0
total_enterprise_features=8

# Check for comprehensive guides
comprehensive_guides=$(find Solutions/ -name "COMPREHENSIVE-*-GUIDE.md" | wc -l)
if [[ $comprehensive_guides -ge 20 ]]; then
    echo "✅ Comprehensive Guides: $comprehensive_guides (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Comprehensive Guides: $comprehensive_guides (Needs more)"
fi

# Check for hands-on exercises
hands_on_exercises=$(find Solutions/ -name "*HANDS-ON*" | wc -l)
if [[ $hands_on_exercises -ge 15 ]]; then
    echo "✅ Hands-On Exercises: $hands_on_exercises (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Hands-On Exercises: $hands_on_exercises (Needs more)"
fi

# Check for troubleshooting guides
troubleshooting_guides=$(find Solutions/ -name "TROUBLESHOOTING-GUIDE.md" | wc -l)
if [[ $troubleshooting_guides -ge 30 ]]; then
    echo "✅ Troubleshooting Guides: $troubleshooting_guides (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Troubleshooting Guides: $troubleshooting_guides (Needs more)"
fi

# Check for enterprise patterns
enterprise_patterns=$(find Solutions/ -name "*ENTERPRISE*" | wc -l)
if [[ $enterprise_patterns -ge 10 ]]; then
    echo "✅ Enterprise Patterns: $enterprise_patterns (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Enterprise Patterns: $enterprise_patterns (Needs more)"
fi

# Check documentation volume
if [[ $total_lines -ge 60000 ]]; then
    echo "✅ Documentation Volume: $total_lines lines (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Documentation Volume: $total_lines lines (Needs more)"
fi

# Check for advanced topics coverage
advanced_topics=("GitOps" "Multi-Cloud" "Policy-as-Code" "Infrastructure-Testing")
covered_topics=0
for topic in "${advanced_topics[@]}"; do
    if find Solutions/ -name "*$topic*" | grep -q .; then
        ((covered_topics++))
    fi
done

if [[ $covered_topics -eq 4 ]]; then
    echo "✅ Advanced Topics Coverage: $covered_topics/4 (Complete)"
    ((enterprise_features++))
else
    echo "⚠️  Advanced Topics Coverage: $covered_topics/4 (Incomplete)"
fi

# Check for production readiness
production_keywords=("production" "enterprise" "security" "monitoring" "compliance")
production_files=0
for keyword in "${production_keywords[@]}"; do
    count=$(find Solutions/ -name "*.md" -exec grep -l "$keyword" {} \; | wc -l)
    production_files=$((production_files + count))
done

if [[ $production_files -ge 100 ]]; then
    echo "✅ Production Readiness: $production_files references (Excellent)"
    ((enterprise_features++))
else
    echo "⚠️  Production Readiness: $production_files references (Needs more)"
fi

# Overall enterprise score
enterprise_score=$((enterprise_features * 100 / total_enterprise_features))
echo ""
echo "🎯 ENTERPRISE READINESS SCORE: $enterprise_score% ($enterprise_features/$total_enterprise_features)"

if [[ $enterprise_score -ge 90 ]]; then
    echo "🏆 ENTERPRISE GRADE: A+ (World-Class)"
elif [[ $enterprise_score -ge 80 ]]; then
    echo "🥇 ENTERPRISE GRADE: A (Excellent)"
elif [[ $enterprise_score -ge 70 ]]; then
    echo "🥈 ENTERPRISE GRADE: B+ (Good)"
else
    echo "🥉 ENTERPRISE GRADE: B (Needs Improvement)"
fi

echo ""

# Missing components summary
if [[ ${#missing_components[@]} -gt 0 ]]; then
    echo "⚠️  MISSING COMPONENTS"
    echo "====================="
    for component in "${missing_components[@]}"; do
        echo "  - $component"
    done
    echo ""
fi

# Final summary
echo "🎉 CURRICULUM VALIDATION COMPLETE"
echo "================================="
echo "Overall Success Rate: $((validated_problems * 100 / total_problems))%"
echo "Enterprise Readiness: $enterprise_score%"
echo "Total Content: $total_files files, $total_lines lines"

if [[ $((validated_problems * 100 / total_problems)) -ge 90 ]] && [[ $enterprise_score -ge 80 ]]; then
    echo ""
    echo "🏆 WORLD-CLASS CURRICULUM ACHIEVED!"
    echo "Ready for enterprise deployment and professional certification preparation."
else
    echo ""
    echo "⚠️  CURRICULUM NEEDS ENHANCEMENT"
    echo "Review missing components and improve quality scores."
fi
