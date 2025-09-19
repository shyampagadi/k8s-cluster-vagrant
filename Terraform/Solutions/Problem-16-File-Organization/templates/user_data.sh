#!/bin/bash

# File Organization and Project Structure - User Data Script

# Update system packages
yum update -y

# Install required packages
yum install -y httpd mysql-client

# Create application directory
mkdir -p /var/www/html/app

# Create application configuration
cat > /var/www/html/app/config.php << EOF
<?php
// Application Configuration
define('APP_NAME', '${app_name}');
define('ENVIRONMENT', '${environment}');
define('PROJECT_NAME', '${project_name}');
define('FILE_ORGANIZATION', '${file_organization}');
define('INSTANCE_ID', '${instance_id}');

// Database Configuration
define('DB_HOST', 'localhost');
define('DB_PORT', '3306');
define('DB_NAME', 'webapp');
define('DB_USER', 'admin');

// Application Settings
define('DEBUG_MODE', ${environment == "dev" ? "true" : "false"});
define('LOG_LEVEL', '${environment == "prod" ? "error" : "debug"}');
EOF

# Create application index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>File Organization Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .info h3 { color: #333; }
        .info p { margin: 5px 0; }
        .status { background: #e8f5e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>File Organization Demo</h1>
            <p>Welcome to the Terraform File Organization demonstration!</p>
        </div>
        
        <div class="info">
            <h3>Project Information</h3>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Application:</strong> ${app_name}</p>
            <p><strong>Instance ID:</strong> ${instance_id}</p>
            <p><strong>File Organization:</strong> ${file_organization}</p>
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
            <p>✅ File organization is implemented</p>
        </div>
        
        <div class="info">
            <h3>File Organization Patterns</h3>
            <p>This instance demonstrates:</p>
            <ul>
                <li>Resource-based file organization</li>
                <li>Environment-specific configurations</li>
                <li>Proper naming conventions</li>
                <li>Comprehensive documentation</li>
                <li>Version control integration</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create application status page
cat > /var/www/html/status.php << EOF
<?php
// Application Status Page
header('Content-Type: application/json');

\$status = [
    'application' => [
        'name' => '${app_name}',
        'environment' => '${environment}',
        'project' => '${project_name}',
        'instance_id' => '${instance_id}',
        'file_organization' => '${file_organization}'
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
    'file_organization' => [
        'pattern' => 'resource-based',
        'structure' => 'organized',
        'documentation' => 'comprehensive',
        'version_control' => 'integrated'
    ]
];

echo json_encode(\$status, JSON_PRETTY_PRINT);
?>
EOF

# Create application configuration file
cat > /var/www/html/app/app.conf << EOF
[application]
name = ${app_name}
environment = ${environment}
project = ${project_name}
instance_id = ${instance_id}
file_organization = ${file_organization}

[infrastructure]
instance_type = t3.micro
region = us-west-2
created_at = $(date)

[file_organization]
pattern = resource-based
structure = organized
documentation = comprehensive
version_control = integrated

[monitoring]
enabled = true
log_level = ${environment == "prod" ? "error" : "debug"}
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create log file
echo "Application started at $(date)" >> /var/log/app.log
echo "Project: ${project_name}" >> /var/log/app.log
echo "Environment: ${environment}" >> /var/log/app.log
echo "File Organization: ${file_organization}" >> /var/log/app.log

# Create health check script
cat > /var/www/html/health.sh << EOF
#!/bin/bash
# Health check script

echo "=== Application Health Check ==="
echo "Date: \$(date)"
echo "Project: ${project_name}"
echo "Environment: ${environment}"
echo "Instance ID: ${instance_id}"
echo "File Organization: ${file_organization}"
echo ""

echo "=== System Status ==="
echo "Uptime: \$(uptime -p)"
echo "Memory: \$(free -h)"
echo "Disk: \$(df -h /)"
echo ""

echo "=== Service Status ==="
systemctl status httpd --no-pager
echo ""

echo "=== Application Status ==="
curl -s http://localhost/status.php | jq . 2>/dev/null || echo "Status page not available"
EOF

chmod +x /var/www/html/health.sh

# Create application info file
cat > /var/www/html/info.txt << EOF
File Organization Demo
=====================

Project: ${project_name}
Environment: ${environment}
Application: ${app_name}
Instance ID: ${instance_id}
File Organization: ${file_organization}

This instance demonstrates proper Terraform file organization patterns:

1. Resource-based organization
2. Environment-specific configurations
3. Proper naming conventions
4. Comprehensive documentation
5. Version control integration

Created: $(date)
EOF

# Log completion
echo "File organization demo setup completed at $(date)" >> /var/log/app.log
