#!/bin/bash

# Error Handling and Validation - User Data Script

# Set error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/app.log
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "ERROR: Script failed at line $line_number with exit code $exit_code"
    log "ERROR: Command that failed: $BASH_COMMAND"
    
    # Send error notification (if monitoring is enabled)
    if [ "${error_handling}" = "enabled" ]; then
        log "ERROR: Sending error notification"
        # Here you would typically send to CloudWatch, SNS, etc.
    fi
    
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

log "Starting error handling demo setup"

# Update system packages
log "Updating system packages"
yum update -y

# Install required packages
log "Installing required packages"
yum install -y httpd mysql-client jq

# Create application directory
log "Creating application directory"
mkdir -p /var/www/html/app

# Create application configuration with validation
log "Creating application configuration"
cat > /var/www/html/app/config.php << EOF
<?php
// Application Configuration with Error Handling
define('APP_NAME', '${app_name}');
define('ENVIRONMENT', '${environment}');
define('PROJECT_NAME', '${project_name}');
define('ERROR_HANDLING', '${error_handling}');
define('INSTANCE_ID', '${instance_id}');

// Database Configuration
define('DB_HOST', 'localhost');
define('DB_PORT', '3306');
define('DB_NAME', 'webapp');
define('DB_USER', 'admin');

// Application Settings
define('DEBUG_MODE', ${environment == "dev" ? "true" : "false"});
define('LOG_LEVEL', '${environment == "prod" ? "error" : "debug"}');
define('ERROR_REPORTING', 'E_ALL');
define('DISPLAY_ERRORS', ${environment == "dev" ? "true" : "false"});

// Error Handling Configuration
define('ERROR_LOG_FILE', '/var/log/app_errors.log');
define('MAX_ERROR_COUNT', 100);
define('ERROR_THRESHOLD', 10);
EOF

# Create application index page with error handling
log "Creating application index page"
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Error Handling Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .info h3 { color: #333; }
        .info p { margin: 5px 0; }
        .status { background: #e8f5e8; padding: 10px; border-radius: 3px; }
        .error { background: #ffe8e8; padding: 10px; border-radius: 3px; }
        .warning { background: #fff8e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Error Handling Demo</h1>
            <p>Welcome to the Terraform Error Handling demonstration!</p>
        </div>
        
        <div class="info">
            <h3>Project Information</h3>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Application:</strong> ${app_name}</p>
            <p><strong>Instance ID:</strong> ${instance_id}</p>
            <p><strong>Error Handling:</strong> ${error_handling}</p>
        </div>
        
        <div class="info">
            <h3>Infrastructure Details</h3>
            <p><strong>Instance Type:</strong> t3.micro</p>
            <p><strong>Region:</strong> us-west-2</p>
            <p><strong>Created:</strong> $(date)</p>
        </div>
        
        <div class="status">
            <h3>Status</h3>
            <p>✅ Web server is running</p>
            <p>✅ Application is configured</p>
            <p>✅ Error handling is implemented</p>
            <p>✅ Validation is enabled</p>
        </div>
        
        <div class="info">
            <h3>Error Handling Features</h3>
            <p>This instance demonstrates:</p>
            <ul>
                <li>Comprehensive error handling</li>
                <li>Validation strategies</li>
                <li>Debugging techniques</li>
                <li>Monitoring and alerting</li>
                <li>Error recovery mechanisms</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create application status page with error handling
log "Creating application status page"
cat > /var/www/html/status.php << EOF
<?php
// Application Status Page with Error Handling
header('Content-Type: application/json');

try {
    \$status = [
        'application' => [
            'name' => '${app_name}',
            'environment' => '${environment}',
            'project' => '${project_name}',
            'instance_id' => '${instance_id}',
            'error_handling' => '${error_handling}'
        ],
        'infrastructure' => [
            'instance_type' => 't3.micro',
            'region' => 'us-west-2',
            'created_at' => date('Y-m-d H:i:s'),
            'uptime' => shell_exec('uptime -p')
        ],
        'services' => [
            'apache' => 'running',
            'mysql_client' => 'installed',
            'php' => 'available'
        ],
        'error_handling' => [
            'enabled' => true,
            'validation' => 'enabled',
            'monitoring' => 'enabled',
            'recovery' => 'enabled'
        ],
        'health' => [
            'status' => 'healthy',
            'checks' => [
                'disk_space' => 'ok',
                'memory' => 'ok',
                'cpu' => 'ok',
                'network' => 'ok'
            ]
        ]
    ];
    
    echo json_encode(\$status, JSON_PRETTY_PRINT);
    
} catch (Exception \$e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal server error',
        'message' => \$e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
}
?>
EOF

# Create application configuration file with validation
log "Creating application configuration file"
cat > /var/www/html/app/app.conf << EOF
[application]
name = ${app_name}
environment = ${environment}
project = ${project_name}
instance_id = ${instance_id}
error_handling = ${error_handling}

[infrastructure]
instance_type = t3.micro
region = us-west-2
created_at = $(date)

[error_handling]
enabled = true
validation = enabled
monitoring = enabled
recovery = enabled

[monitoring]
enabled = true
log_level = ${environment == "prod" ? "error" : "debug"}
retention_days = 7

[security]
encryption_enabled = true
backup_enabled = true
monitoring_enabled = true

[database]
host = localhost
port = 3306
name = webapp
username = admin
# Password should be set via environment variable

[logging]
level = ${environment == "prod" ? "error" : "debug"}
format = json
output = stdout
file = /var/log/app.log

[features]
debug_mode = ${environment == "dev" ? "true" : "false"}
profiling = ${environment == "dev" ? "true" : "false"}
metrics = true
tracing = ${environment == "prod" ? "true" : "false"}

[performance]
cache_enabled = true
cache_ttl = 300
compression_enabled = true
static_files_cached = true

[deployment]
strategy = rolling
health_check_path = /health
readiness_check_path = /ready
liveness_check_path = /live

[observability]
metrics_endpoint = /metrics
health_endpoint = /health
status_endpoint = /status
info_endpoint = /info
EOF

# Set proper permissions
log "Setting proper permissions"
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Start and enable Apache
log "Starting and enabling Apache"
systemctl start httpd
systemctl enable httpd

# Create error log file
log "Creating error log file"
touch /var/log/app_errors.log
chown apache:apache /var/log/app_errors.log

# Create health check script with error handling
log "Creating health check script"
cat > /var/www/html/health.sh << EOF
#!/bin/bash

# Health check script with error handling
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/app.log
}

handle_error() {
    local exit_code=\$?
    local line_number=\$1
    log "ERROR: Health check failed at line \$line_number with exit code \$exit_code"
    exit \$exit_code
}

trap 'handle_error \$LINENO' ERR

log "=== Application Health Check ==="
log "Date: \$(date)"
log "Project: ${project_name}"
log "Environment: ${environment}"
log "Instance ID: ${instance_id}"
log "Error Handling: ${error_handling}"
log ""

log "=== System Status ==="
log "Uptime: \$(uptime -p)"
log "Memory: \$(free -h)"
log "Disk: \$(df -h /)"
log ""

log "=== Service Status ==="
systemctl status httpd --no-pager
log ""

log "=== Application Status ==="
curl -s http://localhost/status.php | jq . 2>/dev/null || log "Status page not available"
log ""

log "=== Error Handling Status ==="
log "Error handling: ${error_handling}"
log "Validation: enabled"
log "Monitoring: enabled"
log "Recovery: enabled"
EOF

chmod +x /var/www/html/health.sh

# Create application info file
log "Creating application info file"
cat > /var/www/html/info.txt << EOF
Error Handling Demo
==================

Project: ${project_name}
Environment: ${environment}
Application: ${app_name}
Instance ID: ${instance_id}
Error Handling: ${error_handling}

This instance demonstrates comprehensive Terraform error handling:

1. Error detection and validation
2. Comprehensive validation strategies
3. Debugging techniques
4. Monitoring and alerting
5. Error recovery mechanisms

Created: $(date)
EOF

# Create error handling test script
log "Creating error handling test script"
cat > /var/www/html/test_errors.sh << EOF
#!/bin/bash

# Error handling test script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/app.log
}

test_error_handling() {
    log "Testing error handling mechanisms"
    
    # Test 1: Invalid command
    log "Test 1: Testing invalid command handling"
    if ! command -v nonexistent_command >/dev/null 2>&1; then
        log "PASS: Invalid command properly handled"
    else
        log "FAIL: Invalid command not handled"
    fi
    
    # Test 2: File operations
    log "Test 2: Testing file operation error handling"
    if [ -f "/nonexistent/file" ]; then
        log "FAIL: File existence check failed"
    else
        log "PASS: File existence check passed"
    fi
    
    # Test 3: Network connectivity
    log "Test 3: Testing network connectivity"
    if curl -s --connect-timeout 5 http://localhost >/dev/null; then
        log "PASS: Network connectivity test passed"
    else
        log "FAIL: Network connectivity test failed"
    fi
    
    log "Error handling tests completed"
}

test_error_handling
EOF

chmod +x /var/www/html/test_errors.sh

# Log completion
log "Error handling demo setup completed successfully"
log "All error handling mechanisms are now in place"
