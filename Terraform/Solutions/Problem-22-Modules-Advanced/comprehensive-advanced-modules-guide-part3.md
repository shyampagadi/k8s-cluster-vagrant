## Part 3: Module Testing and Validation Strategies

### 3.1 Comprehensive Module Testing

#### Unit Testing with Terratest
```go
// test/application_test.go
package test

import (
    "testing"
    "time"
    
    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestApplicationModule(t *testing.T) {
    t.Parallel()
    
    // Unique test identifier
    testName := "app-test-" + strings.ToLower(random.UniqueId())
    awsRegion := "us-west-2"
    
    // Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
        
        Vars: map[string]interface{}{
            "environment": "test",
            "region":      awsRegion,
            "application_config": map[string]interface{}{
                "name":    testName,
                "version": "1.0.0",
                "compute": map[string]interface{}{
                    "instance_type":    "t3.micro",
                    "min_capacity":     1,
                    "max_capacity":     3,
                    "desired_capacity": 2,
                    "launch_template": map[string]interface{}{
                        "image_id": "ami-0c02fb55956c7d316",
                    },
                },
                "load_balancer": map[string]interface{}{
                    "type":   "application",
                    "scheme": "internet-facing",
                    "target_groups": []map[string]interface{}{
                        {
                            "name":     "web",
                            "port":     80,
                            "protocol": "HTTP",
                            "health_check": map[string]interface{}{
                                "enabled":             true,
                                "healthy_threshold":   2,
                                "unhealthy_threshold": 2,
                                "timeout":             5,
                                "interval":            30,
                                "path":                "/health",
                                "matcher":             "200",
                            },
                        },
                    },
                    "listeners": []map[string]interface{}{
                        {
                            "port":     80,
                            "protocol": "HTTP",
                            "default_action": map[string]interface{}{
                                "type":               "forward",
                                "target_group_index": 0,
                            },
                        },
                    },
                },
                "monitoring": map[string]interface{}{
                    "enabled": true,
                    "cloudwatch": map[string]interface{}{
                        "log_retention_days":  14,
                        "detailed_monitoring": true,
                    },
                },
            },
        },
        
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": awsRegion,
        },
    }
    
    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)
    
    // Deploy infrastructure
    terraform.InitAndApply(t, terraformOptions)
    
    // Test outputs
    testApplicationOutputs(t, terraformOptions, awsRegion)
    testLoadBalancerHealth(t, terraformOptions, awsRegion)
    testAutoScalingGroup(t, terraformOptions, awsRegion)
    testMonitoring(t, terraformOptions, awsRegion)
}

func testApplicationOutputs(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
    // Test basic outputs
    appInfo := terraform.OutputMap(t, terraformOptions, "application_info")
    
    assert.NotEmpty(t, appInfo["name"])
    assert.NotEmpty(t, appInfo["version"])
    assert.Equal(t, "test", appInfo["environment"])
    
    // Test compute outputs
    compute := appInfo["compute"].(map[string]interface{})
    assert.NotEmpty(t, compute["auto_scaling_group"])
    assert.NotEmpty(t, compute["launch_template"])
    
    // Test load balancer outputs
    loadBalancer := appInfo["load_balancer"].(map[string]interface{})
    assert.NotEmpty(t, loadBalancer["dns_name"])
    assert.NotEmpty(t, loadBalancer["arn"])
}

func testLoadBalancerHealth(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
    // Get load balancer DNS name
    lbDnsName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")
    
    // Wait for load balancer to be ready
    maxRetries := 30
    timeBetweenRetries := 10 * time.Second
    
    aws.WaitForLoadBalancerToBeReady(t, lbDnsName, awsRegion, maxRetries, timeBetweenRetries)
    
    // Test HTTP response
    url := fmt.Sprintf("http://%s/health", lbDnsName)
    http_helper.HttpGetWithRetry(t, url, nil, 200, "OK", maxRetries, timeBetweenRetries)
}

func testAutoScalingGroup(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
    // Get Auto Scaling Group name
    asgName := terraform.Output(t, terraformOptions, "auto_scaling_group_name")
    
    // Verify ASG configuration
    asg := aws.GetAutoScalingGroup(t, asgName, awsRegion)
    
    assert.Equal(t, int64(2), *asg.DesiredCapacity)
    assert.Equal(t, int64(1), *asg.MinSize)
    assert.Equal(t, int64(3), *asg.MaxSize)
    
    // Verify instances are running
    assert.True(t, len(asg.Instances) >= 1)
    
    for _, instance := range asg.Instances {
        assert.Equal(t, "InService", *instance.LifecycleState)
        assert.Equal(t, "Healthy", *instance.HealthStatus)
    }
}

func testMonitoring(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
    // Test CloudWatch log group
    appInfo := terraform.OutputMap(t, terraformOptions, "application_info")
    monitoring := appInfo["monitoring"].(map[string]interface{})
    
    if monitoring != nil {
        logGroup := monitoring["log_group"].(map[string]interface{})
        logGroupName := logGroup["name"].(string)
        
        // Verify log group exists
        aws.GetCloudWatchLogGroup(t, logGroupName, awsRegion)
    }
}
```

#### Integration Testing Framework
```go
// test/integration_test.go
package test

import (
    "testing"
    "time"
    
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/suite"
)

type IntegrationTestSuite struct {
    suite.Suite
    terraformOptions *terraform.Options
    awsRegion        string
}

func (suite *IntegrationTestSuite) SetupSuite() {
    suite.awsRegion = "us-west-2"
    
    suite.terraformOptions = &terraform.Options{
        TerraformDir: "../examples/integration",
        
        Vars: map[string]interface{}{
            "environment": "integration",
            "region":      suite.awsRegion,
        },
        
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": suite.awsRegion,
        },
    }
    
    // Deploy infrastructure once for all tests
    terraform.InitAndApply(suite.T(), suite.terraformOptions)
}

func (suite *IntegrationTestSuite) TearDownSuite() {
    // Clean up after all tests
    terraform.Destroy(suite.T(), suite.terraformOptions)
}

func (suite *IntegrationTestSuite) TestEndToEndWorkflow() {
    // Test complete application workflow
    suite.testApplicationDeployment()
    suite.testDatabaseConnectivity()
    suite.testLoadBalancerRouting()
    suite.testAutoScaling()
    suite.testMonitoringAlerts()
}

func (suite *IntegrationTestSuite) testApplicationDeployment() {
    // Verify application is deployed and healthy
    lbDnsName := terraform.Output(suite.T(), suite.terraformOptions, "load_balancer_dns_name")
    
    // Test application endpoints
    endpoints := []string{
        fmt.Sprintf("http://%s/", lbDnsName),
        fmt.Sprintf("http://%s/health", lbDnsName),
        fmt.Sprintf("http://%s/api/status", lbDnsName),
    }
    
    for _, endpoint := range endpoints {
        http_helper.HttpGetWithRetry(
            suite.T(),
            endpoint,
            nil,
            200,
            "",
            30,
            10*time.Second,
        )
    }
}

func (suite *IntegrationTestSuite) testDatabaseConnectivity() {
    // Test database connectivity from application
    lbDnsName := terraform.Output(suite.T(), suite.terraformOptions, "load_balancer_dns_name")
    
    // Test database health endpoint
    dbHealthUrl := fmt.Sprintf("http://%s/api/db/health", lbDnsName)
    http_helper.HttpGetWithRetry(
        suite.T(),
        dbHealthUrl,
        nil,
        200,
        "healthy",
        30,
        10*time.Second,
    )
}

func (suite *IntegrationTestSuite) testLoadBalancerRouting() {
    // Test load balancer routing to multiple targets
    lbDnsName := terraform.Output(suite.T(), suite.terraformOptions, "load_balancer_dns_name")
    
    // Make multiple requests to verify load balancing
    instanceIds := make(map[string]bool)
    
    for i := 0; i < 10; i++ {
        response := http_helper.HttpGet(suite.T(), fmt.Sprintf("http://%s/api/instance", lbDnsName), nil)
        instanceIds[response] = true
        time.Sleep(1 * time.Second)
    }
    
    // Verify requests are distributed across multiple instances
    suite.True(len(instanceIds) > 1, "Load balancer should distribute requests across multiple instances")
}

func (suite *IntegrationTestSuite) testAutoScaling() {
    // Test auto scaling behavior
    asgName := terraform.Output(suite.T(), suite.terraformOptions, "auto_scaling_group_name")
    
    // Get initial instance count
    initialAsg := aws.GetAutoScalingGroup(suite.T(), asgName, suite.awsRegion)
    initialCount := len(initialAsg.Instances)
    
    // Simulate load to trigger scaling
    suite.simulateLoad()
    
    // Wait for scaling to occur
    time.Sleep(5 * time.Minute)
    
    // Verify scaling occurred
    scaledAsg := aws.GetAutoScalingGroup(suite.T(), asgName, suite.awsRegion)
    scaledCount := len(scaledAsg.Instances)
    
    suite.True(scaledCount > initialCount, "Auto scaling should increase instance count under load")
}

func TestIntegrationSuite(t *testing.T) {
    suite.Run(t, new(IntegrationTestSuite))
}
```

### 3.2 Module Validation and Linting

#### Pre-commit Validation
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
          - --hook-config=--add-to-existing-file=true
          - --hook-config=--create-file-if-not-exist=true
      - id: terraform_tflint
        args:
          - --args=--only=terraform_deprecated_interpolation
          - --args=--only=terraform_deprecated_index
          - --args=--only=terraform_unused_declarations
          - --args=--only=terraform_comment_syntax
          - --args=--only=terraform_documented_outputs
          - --args=--only=terraform_documented_variables
          - --args=--only=terraform_typed_variables
          - --args=--only=terraform_module_pinned_source
          - --args=--only=terraform_naming_convention
          - --args=--only=terraform_required_version
          - --args=--only=terraform_required_providers
          - --args=--only=terraform_standard_module_structure
      - id: terraform_tfsec
        args:
          - --args=--minimum-severity=MEDIUM
      - id: checkov
        args:
          - --framework=terraform
          - --skip-check=CKV_AWS_79  # Skip specific checks if needed
```

#### Custom Validation Scripts
```bash
#!/bin/bash
# scripts/validate-module.sh

set -e

MODULE_PATH=${1:-"."}
echo "Validating Terraform module at: $MODULE_PATH"

# Change to module directory
cd "$MODULE_PATH"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -backend=false

# Validate syntax
echo "Validating Terraform syntax..."
terraform validate

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check=true -diff=true

# Security scanning with tfsec
echo "Running security scan with tfsec..."
tfsec . --minimum-severity MEDIUM

# Linting with tflint
echo "Running linting with tflint..."
tflint --init
tflint

# Documentation check
echo "Checking documentation..."
terraform-docs markdown table --output-file README.md --output-mode inject .

# Variable validation
echo "Validating variables..."
python3 scripts/validate-variables.py

# Output validation
echo "Validating outputs..."
python3 scripts/validate-outputs.py

echo "Module validation completed successfully!"
```

#### Variable Validation Script
```python
#!/usr/bin/env python3
# scripts/validate-variables.py

import json
import re
import sys
from pathlib import Path

def validate_variables():
    """Validate Terraform variables for consistency and best practices."""
    
    variables_file = Path("variables.tf")
    if not variables_file.exists():
        print("No variables.tf file found")
        return True
    
    errors = []
    
    # Read variables file
    with open(variables_file, 'r') as f:
        content = f.read()
    
    # Extract variable blocks
    variable_blocks = re.findall(r'variable\s+"([^"]+)"\s*{([^}]+)}', content, re.DOTALL)
    
    for var_name, var_content in variable_blocks:
        # Check naming convention
        if not re.match(r'^[a-z][a-z0-9_]*$', var_name):
            errors.append(f"Variable '{var_name}' doesn't follow naming convention (snake_case)")
        
        # Check for description
        if 'description' not in var_content:
            errors.append(f"Variable '{var_name}' missing description")
        
        # Check for type
        if 'type' not in var_content:
            errors.append(f"Variable '{var_name}' missing type specification")
        
        # Check for validation rules on sensitive variables
        if any(keyword in var_name.lower() for keyword in ['password', 'key', 'secret', 'token']):
            if 'validation' not in var_content:
                errors.append(f"Sensitive variable '{var_name}' should have validation rules")
    
    if errors:
        print("Variable validation errors:")
        for error in errors:
            print(f"  - {error}")
        return False
    
    print("All variables validated successfully")
    return True

if __name__ == "__main__":
    success = validate_variables()
    sys.exit(0 if success else 1)
```

### 3.3 Performance Testing and Optimization

#### Performance Benchmarking
```bash
#!/bin/bash
# scripts/performance-benchmark.sh

set -e

BENCHMARK_DIR="benchmarks"
RESULTS_FILE="$BENCHMARK_DIR/results-$(date +%Y%m%d-%H%M%S).json"

mkdir -p "$BENCHMARK_DIR"

echo "Starting Terraform performance benchmark..."

# Function to measure execution time
measure_time() {
    local command="$1"
    local description="$2"
    
    echo "Measuring: $description"
    
    start_time=$(date +%s.%N)
    eval "$command"
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc)
    echo "Duration: ${duration}s"
    
    # Store result
    echo "{\"operation\": \"$description\", \"duration\": $duration, \"timestamp\": \"$(date -Iseconds)\"}" >> "$RESULTS_FILE.tmp"
}

# Initialize benchmark results
echo "[" > "$RESULTS_FILE.tmp"

# Benchmark terraform init
measure_time "terraform init -upgrade" "terraform_init"
echo "," >> "$RESULTS_FILE.tmp"

# Benchmark terraform plan
measure_time "terraform plan -out=tfplan" "terraform_plan"
echo "," >> "$RESULTS_FILE.tmp"

# Benchmark terraform apply
measure_time "terraform apply -auto-approve tfplan" "terraform_apply"
echo "," >> "$RESULTS_FILE.tmp"

# Benchmark terraform destroy
measure_time "terraform destroy -auto-approve" "terraform_destroy"

# Finalize results file
echo "]" >> "$RESULTS_FILE.tmp"
sed '$ s/,$//' "$RESULTS_FILE.tmp" > "$RESULTS_FILE"
rm "$RESULTS_FILE.tmp"

echo "Benchmark completed. Results saved to: $RESULTS_FILE"

# Generate performance report
python3 scripts/generate-performance-report.py "$RESULTS_FILE"
```

#### Performance Analysis Script
```python
#!/usr/bin/env python3
# scripts/generate-performance-report.py

import json
import sys
import statistics
from datetime import datetime
from pathlib import Path

def generate_performance_report(results_file):
    """Generate performance analysis report from benchmark results."""
    
    with open(results_file, 'r') as f:
        results = json.load(f)
    
    print("Terraform Performance Analysis Report")
    print("=" * 50)
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Analyze each operation
    operations = {}
    for result in results:
        op = result['operation']
        duration = float(result['duration'])
        
        if op not in operations:
            operations[op] = []
        operations[op].append(duration)
    
    # Performance summary
    print("Performance Summary:")
    print("-" * 30)
    
    total_time = 0
    for op, durations in operations.items():
        avg_duration = statistics.mean(durations)
        total_time += avg_duration
        
        print(f"{op:20}: {avg_duration:8.2f}s")
    
    print(f"{'Total Time':20}: {total_time:8.2f}s")
    print()
    
    # Performance recommendations
    print("Performance Recommendations:")
    print("-" * 35)
    
    for op, durations in operations.items():
        avg_duration = statistics.mean(durations)
        
        if op == "terraform_init" and avg_duration > 60:
            print(f"- Consider using terraform init -upgrade=false for faster initialization")
        
        if op == "terraform_plan" and avg_duration > 120:
            print(f"- Plan operation is slow. Consider:")
            print(f"  * Using -target for specific resources")
            print(f"  * Optimizing provider configurations")
            print(f"  * Reducing resource count per module")
        
        if op == "terraform_apply" and avg_duration > 300:
            print(f"- Apply operation is slow. Consider:")
            print(f"  * Using parallelism settings")
            print(f"  * Breaking down into smaller modules")
            print(f"  * Optimizing resource dependencies")
    
    # Historical comparison
    benchmark_dir = Path(results_file).parent
    historical_files = list(benchmark_dir.glob("results-*.json"))
    
    if len(historical_files) > 1:
        print()
        print("Historical Comparison:")
        print("-" * 25)
        
        # Compare with previous benchmark
        historical_files.sort()
        if len(historical_files) >= 2:
            prev_file = historical_files[-2]
            
            with open(prev_file, 'r') as f:
                prev_results = json.load(f)
            
            prev_operations = {}
            for result in prev_results:
                op = result['operation']
                duration = float(result['duration'])
                
                if op not in prev_operations:
                    prev_operations[op] = []
                prev_operations[op].append(duration)
            
            for op in operations:
                if op in prev_operations:
                    current_avg = statistics.mean(operations[op])
                    prev_avg = statistics.mean(prev_operations[op])
                    
                    change = ((current_avg - prev_avg) / prev_avg) * 100
                    
                    if abs(change) > 5:  # Significant change
                        direction = "slower" if change > 0 else "faster"
                        print(f"{op}: {abs(change):.1f}% {direction}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 generate-performance-report.py <results_file>")
        sys.exit(1)
    
    results_file = sys.argv[1]
    generate_performance_report(results_file)
```
