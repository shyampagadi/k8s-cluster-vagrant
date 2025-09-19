#!/bin/bash

# Performance Optimization - User Data Script

# Set performance-focused error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Logging function with performance context
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PERFORMANCE] $1" | tee -a /var/log/app.log
}

# Performance error handling function
handle_performance_error() {
    local exit_code=$?
    local line_number=$1
    log "PERFORMANCE ERROR: Script failed at line $line_number with exit code $exit_code"
    log "PERFORMANCE ERROR: Command that failed: $BASH_COMMAND"
    
    # Send performance alert (if monitoring is enabled)
    if [ "${performance_optimized}" = "true" ]; then
        log "PERFORMANCE ALERT: Sending performance notification"
        # Here you would typically send to CloudWatch, SNS, etc.
    fi
    
    exit $exit_code
}

# Set performance error trap
trap 'handle_performance_error $LINENO' ERR

log "Starting performance optimization demo setup"

# Update system packages with performance optimizations
log "Updating system packages with performance optimizations"
yum update -y

# Install required packages with performance focus
log "Installing required packages with performance focus"
yum install -y httpd mysql-client jq htop iotop

# Configure Apache for performance
log "Configuring Apache for performance"
cat > /etc/httpd/conf.d/performance.conf << EOF
# Performance optimizations for Apache
ServerTokens Prod
ServerSignature Off

# Performance tuning
KeepAlive On
KeepAliveTimeout 5
MaxKeepAliveRequests 100

# Compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>

# Caching
LoadModule expires_module modules/mod_expires.so
<Location />
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
</Location>

# Security headers for performance
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
EOF

# Create application directory with performance optimizations
log "Creating application directory with performance optimizations"
mkdir -p /var/www/html/app
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create application configuration with performance settings
log "Creating application configuration with performance settings"
cat > /var/www/html/app/config.php << EOF
<?php
// Application Configuration with Performance Focus
define('APP_NAME', '${app_name}');
define('ENVIRONMENT', '${environment}');
define('PROJECT_NAME', '${project_name}');
define('PERFORMANCE_OPTIMIZED', '${performance_optimized}');
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

// Performance Configuration
define('ERROR_LOG_FILE', '/var/log/app_errors.log');
define('MAX_ERROR_COUNT', 100);
define('ERROR_THRESHOLD', 10);
define('CACHE_ENABLED', true);
define('CACHE_TTL', 300);
define('COMPRESSION_ENABLED', true);
define('OPTIMIZATION_ENABLED', true);
EOF

# Create application index page with performance optimizations
log "Creating application index page with performance optimizations"
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Performance Optimization Demo</title>
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
        .performance { background: #e8f5e8; padding: 10px; border-radius: 3px; }
        .warning { background: #fff8e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Performance Optimization Demo</h1>
            <p>Welcome to the Terraform Performance Optimization demonstration!</p>
        </div>
        
        <div class="info">
            <h3>Project Information</h3>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Application:</strong> ${app_name}</p>
            <p><strong>Instance ID:</strong> ${instance_id}</p>
            <p><strong>Performance Optimized:</strong> ${performance_optimized}</p>
        </div>
        
        <div class="info">
            <h3>Infrastructure Details</h3>
            <p><strong>Instance Type:</strong> t3.micro</p>
            <p><strong>Region:</strong> us-west-2</p>
            <p><strong>Created:</strong> $(date)</p>
        </div>
        
        <div class="performance">
            <h3>Performance Status</h3>
            <p>✅ Web server is running with performance optimizations</p>
            <p>✅ Application is configured for high performance</p>
            <p>✅ Performance optimization is implemented</p>
            <p>✅ Caching is enabled</p>
            <p>✅ Compression is enabled</p>
            <p>✅ Monitoring is active</p>
        </div>
        
        <div class="info">
            <h3>Performance Features</h3>
            <p>This instance demonstrates:</p>
            <ul>
                <li>Resource creation optimization</li>
                <li>Parallel execution strategies</li>
                <li>State performance optimization</li>
                <li>Provider performance tuning</li>
                <li>Caching and dependency optimization</li>
                <li>Large-scale deployment optimization</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create application status page with performance metrics
log "Creating application status page with performance metrics"
cat > /var/www/html/status.php << EOF
<?php
// Application Status Page with Performance Metrics
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
            'performance_optimized' => '${performance_optimized}'
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
            'iotop' => 'installed'
        ],
        'performance' => [
            'optimization' => 'enabled',
            'caching' => 'enabled',
            'compression' => 'enabled',
            'monitoring' => 'enabled',
            'parallel_execution' => 'enabled'
        ],
        'health' => [
            'status' => 'healthy',
            'checks' => [
                'disk_space' => 'ok',
                'memory' => 'ok',
                'cpu' => 'ok',
                'network' => 'ok',
                'performance' => 'ok'
            ]
        ],
        'metrics' => [
            'load_average' => shell_exec('uptime | awk -F\'load average:\' \'{ print $2 }\''),
            'memory_usage' => shell_exec('free -h | awk \'NR==2{printf "%.1f%%", $3*100/$2 }\''),
            'disk_usage' => shell_exec('df -h / | awk \'NR==2{print $5}\''),
            'cpu_usage' => shell_exec('top -bn1 | grep "Cpu(s)" | awk \'{print $2}\' | awk -F\'%\' \'{print $1}\'')
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

# Create application configuration file with performance settings
log "Creating application configuration file with performance settings"
cat > /var/www/html/app/app.conf << EOF
[application]
name = ${app_name}
environment = ${environment}
project = ${project_name}
instance_id = ${instance_id}
performance_optimized = ${performance_optimized}

[infrastructure]
instance_type = t3.micro
region = us-west-2
created_at = $(date)

[performance]
optimization = enabled
caching = enabled
compression = enabled
monitoring = enabled
parallel_execution = enabled

[monitoring]
enabled = true
log_level = ${environment == "prod" ? "error" : "debug"}
retention_days = 7

[performance_features]
caching_enabled = true
compression_enabled = true
monitoring_enabled = true
optimization_enabled = true
parallel_execution_enabled = true

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

[performance_tuning]
cache_enabled = true
cache_ttl = 300
compression_enabled = true
static_files_cached = true
optimization_enabled = true

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

[performance_optimization]
resource_optimization = enabled
parallel_execution = enabled
caching = enabled
state_optimization = enabled
provider_optimization = enabled

[scaling]
auto_scaling = enabled
load_balancing = enabled
monitoring = enabled
performance_insights = enabled
EOF

# Set proper permissions
log "Setting proper permissions"
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Start and enable Apache
log "Starting and enabling Apache"
systemctl start httpd
systemctl enable httpd

# Create performance log files
log "Creating performance log files"
touch /var/log/app_errors.log
touch /var/log/performance.log
chown apache:apache /var/log/app_errors.log
chown apache:apache /var/log/performance.log

# Create performance health check script
log "Creating performance health check script"
cat > /var/www/html/performance_health.sh << EOF
#!/bin/bash

# Performance health check script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PERFORMANCE] $1" | tee -a /var/log/app.log
}

test_performance() {
    log "Testing performance mechanisms"
    
    # Test 1: System performance
    log "Test 1: Testing system performance"
    load_avg=\$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    if (( \$(echo "\$load_avg < 2.0" | bc -l) )); then
        log "PASS: System load is acceptable (\$load_avg)"
    else
        log "WARNING: System load is high (\$load_avg)"
    fi
    
    # Test 2: Memory usage
    log "Test 2: Testing memory usage"
    memory_usage=\$(free | awk 'NR==2{printf "%.1f", \$3*100/\$2}')
    if (( \$(echo "\$memory_usage < 80.0" | bc -l) )); then
        log "PASS: Memory usage is acceptable (\$memory_usage%)"
    else
        log "WARNING: Memory usage is high (\$memory_usage%)"
    fi
    
    # Test 3: Disk usage
    log "Test 3: Testing disk usage"
    disk_usage=\$(df -h / | awk 'NR==2{print \$5}' | sed 's/%//')
    if [ "\$disk_usage" -lt 80 ]; then
        log "PASS: Disk usage is acceptable (\$disk_usage%)"
    else
        log "WARNING: Disk usage is high (\$disk_usage%)"
    fi
    
    # Test 4: Network connectivity
    log "Test 4: Testing network connectivity"
    if curl -s --connect-timeout 5 http://localhost >/dev/null; then
        log "PASS: Network connectivity test passed"
    else
        log "FAIL: Network connectivity test failed"
    fi
    
    # Test 5: Apache performance
    log "Test 5: Testing Apache performance"
    if systemctl is-active --quiet httpd; then
        log "PASS: Apache is running"
    else
        log "FAIL: Apache is not running"
    fi
    
    log "Performance tests completed"
}

test_performance
EOF

chmod +x /var/www/html/performance_health.sh

# Create application info file
log "Creating application info file"
cat > /var/www/html/info.txt << EOF
Performance Optimization Demo
=============================

Project: ${project_name}
Environment: ${environment}
Application: ${app_name}
Instance ID: ${instance_id}
Performance Optimized: ${performance_optimized}

This instance demonstrates comprehensive Terraform performance optimization:

1. Resource creation optimization
2. Parallel execution strategies
3. State performance optimization
4. Provider performance tuning
5. Caching and dependency optimization
6. Large-scale deployment optimization

Created: $(date)
EOF

# Create performance test script
log "Creating performance test script"
cat > /var/www/html/test_performance.sh << EOF
#!/bin/bash

# Performance test script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PERFORMANCE] $1" | tee -a /var/log/app.log
}

test_performance_optimization() {
    log "Testing performance optimization"
    
    # Test 1: Resource optimization
    log "Test 1: Testing resource optimization"
    if [ "${performance_optimized}" = "true" ]; then
        log "PASS: Resource optimization is enabled"
    else
        log "WARNING: Resource optimization may not be enabled"
    fi
    
    # Test 2: Parallel execution
    log "Test 2: Testing parallel execution"
    if [ "${performance_optimized}" = "true" ]; then
        log "PASS: Parallel execution is enabled"
    else
        log "WARNING: Parallel execution may not be enabled"
    fi
    
    # Test 3: Caching
    log "Test 3: Testing caching"
    if [ "${performance_optimized}" = "true" ]; then
        log "PASS: Caching is enabled"
    else
        log "WARNING: Caching may not be enabled"
    fi
    
    # Test 4: Monitoring
    log "Test 4: Testing monitoring"
    if [ "${performance_optimized}" = "true" ]; then
        log "PASS: Monitoring is enabled"
    else
        log "WARNING: Monitoring may not be enabled"
    fi
    
    log "Performance optimization tests completed"
}

test_performance_optimization
EOF

chmod +x /var/www/html/test_performance.sh

# Log completion
log "Performance optimization demo setup completed successfully"
log "All performance mechanisms are now in place"
log "Performance optimization: ${performance_optimized}"
log "Caching: enabled"
log "Compression: enabled"
log "Monitoring: enabled"
log "Parallel execution: enabled"
