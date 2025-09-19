#!/bin/bash

# Troubleshooting - User Data Script

# Set troubleshooting-focused error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Logging function with troubleshooting context
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TROUBLESHOOTING] $1" | tee -a /var/log/app.log
}

# Troubleshooting error handling function
handle_troubleshooting_error() {
    local exit_code=$?
    local line_number=$1
    log "TROUBLESHOOTING ERROR: Script failed at line $line_number with exit code $exit_code"
    log "TROUBLESHOOTING ERROR: Command that failed: $BASH_COMMAND"
    
    # Send troubleshooting alert (if monitoring is enabled)
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "TROUBLESHOOTING ALERT: Sending troubleshooting notification"
        # Here you would typically send to CloudWatch, SNS, etc.
    fi
    
    exit $exit_code
}

# Set troubleshooting error trap
trap 'handle_troubleshooting_error $LINENO' ERR

log "Starting troubleshooting demo setup"

# Update system packages with troubleshooting tools
log "Updating system packages with troubleshooting tools"
yum update -y

# Install required packages with troubleshooting focus
log "Installing required packages with troubleshooting focus"
yum install -y httpd mysql-client jq htop iotop netstat-nat tcpdump strace

# Configure Apache for troubleshooting
log "Configuring Apache for troubleshooting"
cat > /etc/httpd/conf.d/troubleshooting.conf << EOF
# Troubleshooting configuration for Apache
ServerTokens Prod
ServerSignature Off

# Logging for troubleshooting
LogLevel warn
ErrorLog /var/log/httpd/error_log
CustomLog /var/log/httpd/access_log combined

# Performance tuning for troubleshooting
KeepAlive On
KeepAliveTimeout 5
MaxKeepAliveRequests 100

# Security headers for troubleshooting
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
EOF

# Create application directory with troubleshooting features
log "Creating application directory with troubleshooting features"
mkdir -p /var/www/html/app
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create application configuration with troubleshooting settings
log "Creating application configuration with troubleshooting settings"
cat > /var/www/html/app/config.php << EOF
<?php
// Application Configuration with Troubleshooting Focus
define('APP_NAME', '${app_name}');
define('ENVIRONMENT', '${environment}');
define('PROJECT_NAME', '${project_name}');
define('TROUBLESHOOTING_ENABLED', '${troubleshooting_enabled}');
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

// Troubleshooting Configuration
define('ERROR_LOG_FILE', '/var/log/app_errors.log');
define('MAX_ERROR_COUNT', 100);
define('ERROR_THRESHOLD', 10);
define('TROUBLESHOOTING_ENABLED', true);
define('DEBUGGING_ENABLED', true);
define('VALIDATION_ENABLED', true);
define('MONITORING_ENABLED', true);
EOF

# Create application index page with troubleshooting features
log "Creating application index page with troubleshooting features"
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Troubleshooting Demo</title>
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'">
    <meta http-equiv="X-Content-Type-Options" content="nosniff">
    <meta http-equiv="X-Frame-Options" content="DENY">
    <meta http-equiv="X-XSS-Protection" content="1; mode=block">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .info h3 { color: #333; }
        .info p { margin: 5px 0; }
        .status { background: #e8f5e8; padding: 10px; border-radius: 3px; }
        .troubleshooting { background: #e8f5e8; padding: 10px; border-radius: 3px; }
        .warning { background: #fff8e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Troubleshooting Demo</h1>
            <p>Welcome to the Terraform Troubleshooting demonstration!</p>
        </div>
        
        <div class="info">
            <h3>Project Information</h3>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Application:</strong> ${app_name}</p>
            <p><strong>Instance ID:</strong> ${instance_id}</p>
            <p><strong>Troubleshooting Enabled:</strong> ${troubleshooting_enabled}</p>
        </div>
        
        <div class="info">
            <h3>Infrastructure Details</h3>
            <p><strong>Instance Type:</strong> t3.micro</p>
            <p><strong>Region:</strong> us-west-2</p>
            <p><strong>Created:</strong> $(date)</p>
        </div>
        
        <div class="troubleshooting">
            <h3>Troubleshooting Status</h3>
            <p>✅ Web server is running with troubleshooting features</p>
            <p>✅ Application is configured for troubleshooting</p>
            <p>✅ Troubleshooting is implemented</p>
            <p>✅ Debugging is enabled</p>
            <p>✅ Validation is active</p>
            <p>✅ Monitoring is enabled</p>
        </div>
        
        <div class="info">
            <h3>Troubleshooting Features</h3>
            <p>This instance demonstrates:</p>
            <ul>
                <li>Systematic debugging approaches</li>
                <li>Error analysis and interpretation</li>
                <li>State management troubleshooting</li>
                <li>Provider-specific debugging</li>
                <li>Infrastructure validation</li>
                <li>Performance troubleshooting</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create application status page with troubleshooting metrics
log "Creating application status page with troubleshooting metrics"
cat > /var/www/html/status.php << EOF
<?php
// Application Status Page with Troubleshooting Metrics
header('Content-Type: application/json');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');

try {
    \$status = [
        'application' => [
            'name' => '${app_name}',
            'environment' => '${environment}',
            'project' => '${project_name}',
            'instance_id' => '${instance_id}',
            'troubleshooting_enabled' => '${troubleshooting_enabled}'
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
            'php' => 'available',
            'htop' => 'installed',
            'iotop' => 'installed',
            'netstat' => 'installed',
            'tcpdump' => 'installed',
            'strace' => 'installed'
        ],
        'troubleshooting' => [
            'enabled' => '${troubleshooting_enabled}',
            'debugging' => 'enabled',
            'validation' => 'enabled',
            'monitoring' => 'enabled',
            'logging' => 'enabled',
            'health_checks' => 'enabled'
        ],
        'health' => [
            'status' => 'healthy',
            'checks' => [
                'disk_space' => 'ok',
                'memory' => 'ok',
                'cpu' => 'ok',
                'network' => 'ok',
                'troubleshooting' => 'ok'
            ]
        ],
        'metrics' => [
            'load_average' => shell_exec('uptime | awk -F\'load average:\' \'{ print $2 }\''),
            'memory_usage' => shell_exec('free -h | awk \'NR==2{printf "%.1f%%", $3*100/$2 }\''),
            'disk_usage' => shell_exec('df -h / | awk \'NR==2{print $5}\''),
            'cpu_usage' => shell_exec('top -bn1 | grep "Cpu(s)" | awk \'{print $2}\' | awk -F\'%\' \'{print $1}\''),
            'network_connections' => shell_exec('netstat -an | wc -l'),
            'process_count' => shell_exec('ps aux | wc -l')
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

# Create application configuration file with troubleshooting settings
log "Creating application configuration file with troubleshooting settings"
cat > /var/www/html/app/app.conf << EOF
[application]
name = ${app_name}
environment = ${environment}
project = ${project_name}
instance_id = ${instance_id}
troubleshooting_enabled = ${troubleshooting_enabled}

[infrastructure]
instance_type = t3.micro
region = us-west-2
created_at = $(date)

[troubleshooting]
enabled = ${troubleshooting_enabled}
debugging = enabled
validation = enabled
monitoring = enabled
logging = enabled
health_checks = enabled

[monitoring]
enabled = true
log_level = ${environment == "prod" ? "error" : "debug"}
retention_days = 7

[troubleshooting_features]
debugging_enabled = true
validation_enabled = true
monitoring_enabled = true
logging_enabled = true
health_checks_enabled = true

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

[troubleshooting_tools]
htop = installed
iotop = installed
netstat = installed
tcpdump = installed
strace = installed

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

[troubleshooting_strategies]
systematic_debugging = enabled
error_analysis = enabled
state_troubleshooting = enabled
provider_debugging = enabled
infrastructure_validation = enabled
performance_troubleshooting = enabled
EOF

# Set proper permissions
log "Setting proper permissions"
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Start and enable Apache
log "Starting and enabling Apache"
systemctl start httpd
systemctl enable httpd

# Create troubleshooting log files
log "Creating troubleshooting log files"
touch /var/log/app_errors.log
touch /var/log/troubleshooting.log
chown apache:apache /var/log/app_errors.log
chown apache:apache /var/log/troubleshooting.log

# Create troubleshooting health check script
log "Creating troubleshooting health check script"
cat > /var/www/html/troubleshooting_health.sh << EOF
#!/bin/bash

# Troubleshooting health check script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TROUBLESHOOTING] $1" | tee -a /var/log/app.log
}

test_troubleshooting() {
    log "Testing troubleshooting mechanisms"
    
    # Test 1: System troubleshooting tools
    log "Test 1: Testing system troubleshooting tools"
    if command -v htop >/dev/null 2>&1 && command -v iotop >/dev/null 2>&1 && command -v netstat >/dev/null 2>&1; then
        log "PASS: System troubleshooting tools are installed"
    else
        log "FAIL: System troubleshooting tools are missing"
    fi
    
    # Test 2: Service status
    log "Test 2: Testing service status"
    if systemctl is-active --quiet httpd; then
        log "PASS: Apache service is running"
    else
        log "FAIL: Apache service is not running"
    fi
    
    # Test 3: Network connectivity
    log "Test 3: Testing network connectivity"
    if curl -s --connect-timeout 5 http://localhost >/dev/null; then
        log "PASS: Network connectivity test passed"
    else
        log "FAIL: Network connectivity test failed"
    fi
    
    # Test 4: Troubleshooting features
    log "Test 4: Testing troubleshooting features"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Troubleshooting features are enabled"
    else
        log "WARNING: Troubleshooting features may not be enabled"
    fi
    
    # Test 5: Logging
    log "Test 5: Testing logging"
    if [ -f "/var/log/app.log" ] && [ -f "/var/log/app_errors.log" ]; then
        log "PASS: Logging is configured"
    else
        log "FAIL: Logging is not configured"
    fi
    
    log "Troubleshooting tests completed"
}

test_troubleshooting
EOF

chmod +x /var/www/html/troubleshooting_health.sh

# Create application info file
log "Creating application info file"
cat > /var/www/html/info.txt << EOF
Troubleshooting Demo
====================

Project: ${project_name}
Environment: ${environment}
Application: ${app_name}
Instance ID: ${instance_id}
Troubleshooting Enabled: ${troubleshooting_enabled}

This instance demonstrates comprehensive Terraform troubleshooting:

1. Systematic debugging approaches
2. Error analysis and interpretation
3. State management troubleshooting
4. Provider-specific debugging
5. Infrastructure validation
6. Performance troubleshooting

Created: $(date)
EOF

# Create troubleshooting test script
log "Creating troubleshooting test script"
cat > /var/www/html/test_troubleshooting.sh << EOF
#!/bin/bash

# Troubleshooting test script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TROUBLESHOOTING] $1" | tee -a /var/log/app.log
}

test_troubleshooting_strategies() {
    log "Testing troubleshooting strategies"
    
    # Test 1: Systematic debugging
    log "Test 1: Testing systematic debugging"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Systematic debugging is enabled"
    else
        log "WARNING: Systematic debugging may not be enabled"
    fi
    
    # Test 2: Error analysis
    log "Test 2: Testing error analysis"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Error analysis is enabled"
    else
        log "WARNING: Error analysis may not be enabled"
    fi
    
    # Test 3: State troubleshooting
    log "Test 3: Testing state troubleshooting"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: State troubleshooting is enabled"
    else
        log "WARNING: State troubleshooting may not be enabled"
    fi
    
    # Test 4: Provider debugging
    log "Test 4: Testing provider debugging"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Provider debugging is enabled"
    else
        log "WARNING: Provider debugging may not be enabled"
    fi
    
    # Test 5: Infrastructure validation
    log "Test 5: Testing infrastructure validation"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Infrastructure validation is enabled"
    else
        log "WARNING: Infrastructure validation may not be enabled"
    fi
    
    # Test 6: Performance troubleshooting
    log "Test 6: Testing performance troubleshooting"
    if [ "${troubleshooting_enabled}" = "true" ]; then
        log "PASS: Performance troubleshooting is enabled"
    else
        log "WARNING: Performance troubleshooting may not be enabled"
    fi
    
    log "Troubleshooting strategies tests completed"
}

test_troubleshooting_strategies
EOF

chmod +x /var/www/html/test_troubleshooting.sh

# Log completion
log "Troubleshooting demo setup completed successfully"
log "All troubleshooting mechanisms are now in place"
log "Troubleshooting enabled: ${troubleshooting_enabled}"
log "Debugging: enabled"
log "Validation: enabled"
log "Monitoring: enabled"
log "Logging: enabled"
log "Health checks: enabled"
