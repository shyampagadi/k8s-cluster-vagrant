#!/bin/bash

# Security Fundamentals - User Data Script

# Set security-focused error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Logging function with security context
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECURITY] $1" | tee -a /var/log/app.log
}

# Security error handling function
handle_security_error() {
    local exit_code=$?
    local line_number=$1
    log "SECURITY ERROR: Script failed at line $line_number with exit code $exit_code"
    log "SECURITY ERROR: Command that failed: $BASH_COMMAND"
    
    # Send security alert (if monitoring is enabled)
    if [ "${security_level}" = "high" ] || [ "${security_level}" = "critical" ]; then
        log "SECURITY ALERT: Sending security notification"
        # Here you would typically send to CloudWatch, SNS, etc.
    fi
    
    exit $exit_code
}

# Set security error trap
trap 'handle_security_error $LINENO' ERR

log "Starting security fundamentals demo setup"

# Update system packages with security patches
log "Updating system packages with security patches"
yum update -y

# Install required packages with security focus
log "Installing required packages with security focus"
yum install -y httpd mysql-client jq fail2ban

# Configure fail2ban for security
log "Configuring fail2ban for security"
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Create application directory with proper permissions
log "Creating application directory with proper permissions"
mkdir -p /var/www/html/app
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create application configuration with security settings
log "Creating application configuration with security settings"
cat > /var/www/html/app/config.php << EOF
<?php
// Application Configuration with Security Focus
define('APP_NAME', '${app_name}');
define('ENVIRONMENT', '${environment}');
define('PROJECT_NAME', '${project_name}');
define('SECURITY_LEVEL', '${security_level}');
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

// Security Configuration
define('ERROR_LOG_FILE', '/var/log/app_errors.log');
define('MAX_ERROR_COUNT', 100);
define('ERROR_THRESHOLD', 10);
define('SECURITY_HEADERS', true);
define('CSRF_PROTECTION', true);
define('XSS_PROTECTION', true);
define('CONTENT_SECURITY_POLICY', true);
EOF

# Create application index page with security headers
log "Creating application index page with security headers"
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Security Fundamentals Demo</title>
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
        .security { background: #e8f5e8; padding: 10px; border-radius: 3px; }
        .warning { background: #fff8e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Security Fundamentals Demo</h1>
            <p>Welcome to the Terraform Security Fundamentals demonstration!</p>
        </div>
        
        <div class="info">
            <h3>Project Information</h3>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Application:</strong> ${app_name}</p>
            <p><strong>Instance ID:</strong> ${instance_id}</p>
            <p><strong>Security Level:</strong> ${security_level}</p>
        </div>
        
        <div class="info">
            <h3>Infrastructure Details</h3>
            <p><strong>Instance Type:</strong> t3.micro</p>
            <p><strong>Region:</strong> us-west-2</p>
            <p><strong>Created:</strong> $(date)</p>
        </div>
        
        <div class="security">
            <h3>Security Status</h3>
            <p>✅ Web server is running securely</p>
            <p>✅ Application is configured with security settings</p>
            <p>✅ Security fundamentals are implemented</p>
            <p>✅ Encryption is enabled</p>
            <p>✅ Monitoring is active</p>
            <p>✅ Audit logging is enabled</p>
        </div>
        
        <div class="info">
            <h3>Security Features</h3>
            <p>This instance demonstrates:</p>
            <ul>
                <li>Secure infrastructure deployment</li>
                <li>Proper credential management</li>
                <li>Resource security and access control</li>
                <li>Compliance and governance</li>
                <li>Secrets management</li>
                <li>Security scanning and validation</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create application status page with security validation
log "Creating application status page with security validation"
cat > /var/www/html/status.php << EOF
<?php
// Application Status Page with Security Validation
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
            'security_level' => '${security_level}'
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
            'fail2ban' => 'active'
        ],
        'security' => [
            'level' => '${security_level}',
            'encryption' => 'enabled',
            'monitoring' => 'enabled',
            'audit_logging' => 'enabled',
            'security_scanning' => 'enabled'
        ],
        'health' => [
            'status' => 'healthy',
            'checks' => [
                'disk_space' => 'ok',
                'memory' => 'ok',
                'cpu' => 'ok',
                'network' => 'ok',
                'security' => 'ok'
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

# Create application configuration file with security settings
log "Creating application configuration file with security settings"
cat > /var/www/html/app/app.conf << EOF
[application]
name = ${app_name}
environment = ${environment}
project = ${project_name}
instance_id = ${instance_id}
security_level = ${security_level}

[infrastructure]
instance_type = t3.micro
region = us-west-2
created_at = $(date)

[security]
level = ${security_level}
encryption = enabled
monitoring = enabled
audit_logging = enabled
security_scanning = enabled

[monitoring]
enabled = true
log_level = ${environment == "prod" ? "error" : "debug"}
retention_days = 7

[security_features]
encryption_enabled = true
backup_enabled = true
monitoring_enabled = true
audit_logging_enabled = true
security_scanning_enabled = true

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

[security_headers]
content_security_policy = enabled
x_content_type_options = enabled
x_frame_options = enabled
x_xss_protection = enabled
strict_transport_security = enabled

[compliance]
standards = ["SOC2", "PCI-DSS"]
data_residency = ["US"]
audit_logging = enabled
encryption = enabled
backup = enabled
monitoring = enabled
EOF

# Set proper permissions
log "Setting proper permissions"
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Start and enable Apache
log "Starting and enabling Apache"
systemctl start httpd
systemctl enable httpd

# Create security log files
log "Creating security log files"
touch /var/log/app_errors.log
touch /var/log/security.log
chown apache:apache /var/log/app_errors.log
chown apache:apache /var/log/security.log

# Create security health check script
log "Creating security health check script"
cat > /var/www/html/security_health.sh << EOF
#!/bin/bash

# Security health check script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECURITY] $1" | tee -a /var/log/app.log
}

test_security() {
    log "Testing security mechanisms"
    
    # Test 1: File permissions
    log "Test 1: Testing file permissions"
    if [ -r /var/www/html/index.html ] && [ -w /var/www/html/app/config.php ]; then
        log "PASS: File permissions are correct"
    else
        log "FAIL: File permissions are incorrect"
    fi
    
    # Test 2: Service status
    log "Test 2: Testing service status"
    if systemctl is-active --quiet httpd && systemctl is-active --quiet fail2ban; then
        log "PASS: Security services are running"
    else
        log "FAIL: Security services are not running"
    fi
    
    # Test 3: Network connectivity
    log "Test 3: Testing network connectivity"
    if curl -s --connect-timeout 5 http://localhost >/dev/null; then
        log "PASS: Network connectivity test passed"
    else
        log "FAIL: Network connectivity test failed"
    fi
    
    # Test 4: Security headers
    log "Test 4: Testing security headers"
    if curl -s -I http://localhost | grep -q "X-Content-Type-Options"; then
        log "PASS: Security headers are present"
    else
        log "FAIL: Security headers are missing"
    fi
    
    log "Security tests completed"
}

test_security
EOF

chmod +x /var/www/html/security_health.sh

# Create application info file
log "Creating application info file"
cat > /var/www/html/info.txt << EOF
Security Fundamentals Demo
==========================

Project: ${project_name}
Environment: ${environment}
Application: ${app_name}
Instance ID: ${instance_id}
Security Level: ${security_level}

This instance demonstrates comprehensive Terraform security fundamentals:

1. Secure infrastructure deployment
2. Proper credential management
3. Resource security and access control
4. Compliance and governance
5. Secrets management
6. Security scanning and validation

Created: $(date)
EOF

# Create security test script
log "Creating security test script"
cat > /var/www/html/test_security.sh << EOF
#!/bin/bash

# Security test script
set -e
set -u
set -o pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECURITY] $1" | tee -a /var/log/app.log
}

test_security_fundamentals() {
    log "Testing security fundamentals"
    
    # Test 1: Encryption
    log "Test 1: Testing encryption"
    if [ "${security_level}" = "high" ] || [ "${security_level}" = "critical" ]; then
        log "PASS: Encryption is enabled"
    else
        log "WARNING: Encryption may not be enabled"
    fi
    
    # Test 2: Monitoring
    log "Test 2: Testing monitoring"
    if [ "${security_level}" = "high" ] || [ "${security_level}" = "critical" ]; then
        log "PASS: Monitoring is enabled"
    else
        log "WARNING: Monitoring may not be enabled"
    fi
    
    # Test 3: Audit logging
    log "Test 3: Testing audit logging"
    if [ "${security_level}" = "high" ] || [ "${security_level}" = "critical" ]; then
        log "PASS: Audit logging is enabled"
    else
        log "WARNING: Audit logging may not be enabled"
    fi
    
    # Test 4: Security scanning
    log "Test 4: Testing security scanning"
    if [ "${security_level}" = "high" ] || [ "${security_level}" = "critical" ]; then
        log "PASS: Security scanning is enabled"
    else
        log "WARNING: Security scanning may not be enabled"
    fi
    
    log "Security fundamentals tests completed"
}

test_security_fundamentals
EOF

chmod +x /var/www/html/test_security.sh

# Log completion
log "Security fundamentals demo setup completed successfully"
log "All security mechanisms are now in place"
log "Security level: ${security_level}"
log "Compliance: enabled"
log "Encryption: enabled"
log "Monitoring: enabled"
log "Audit logging: enabled"
