#!/bin/bash

# User Data Script for Variables Demo
# This script demonstrates variable usage in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
ENABLE_MONITORING="${enable_monitoring}"
ENABLE_ENCRYPTION="${enable_encryption}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Enable Monitoring: ${ENABLE_MONITORING}" >> /var/log/user-data.log
echo "Enable Encryption: ${ENABLE_ENCRYPTION}" >> /var/log/user-data.log
echo "Timestamp: $(date)" >> /var/log/user-data.log

# Update system
yum update -y

# Install required packages
yum install -y httpd php mysql

# Configure Apache
cat > /etc/httpd/conf.d/${APP_NAME}.conf << EOF
<VirtualHost *:80>
    ServerName ${APP_NAME}.local
    DocumentRoot /var/www/html/${APP_NAME}
    
    <Directory /var/www/html/${APP_NAME}>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/${APP_NAME}_error.log
    CustomLog /var/log/httpd/${APP_NAME}_access.log combined
</VirtualHost>
EOF

# Create application directory
mkdir -p /var/www/html/${APP_NAME}

# Create index page
cat > /var/www/html/${APP_NAME}/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${APP_NAME} - ${ENVIRONMENT}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .status { color: green; font-weight: bold; }
        .variables { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .type { background-color: #f0f8ff; padding: 10px; border-radius: 3px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to ${APP_NAME}</h1>
        <p>Environment: ${ENVIRONMENT}</p>
        <p>Instance ID: ${INSTANCE_ID}</p>
        <p>Deployment Time: $(date)</p>
    </div>
    
    <div class="info">
        <h2>Application Status</h2>
        <p class="status">✓ Application is running</p>
        <p class="status">✓ Web server is configured</p>
        <p class="status">✓ Variables demo is active</p>
    </div>
    
    <div class="variables">
        <h2>Terraform Variables Demo</h2>
        <p>This page demonstrates Terraform variable usage:</p>
        
        <div class="type">
            <h3>String Variables</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Boolean Variables</h3>
            <ul>
                <li><strong>Enable Monitoring:</strong> ${ENABLE_MONITORING}</li>
                <li><strong>Enable Encryption:</strong> ${ENABLE_ENCRYPTION}</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Variable Usage Patterns</h3>
            <ul>
                <li><strong>Basic Reference:</strong> var.app_name</li>
                <li><strong>String Interpolation:</strong> ${var.app_name}-${var.environment}</li>
                <li><strong>Conditional Logic:</strong> var.environment == 'production' ? 't3.large' : 't3.micro'</li>
                <li><strong>Boolean Logic:</strong> var.enable_monitoring && var.environment == 'production'</li>
            </ul>
        </div>
    </div>
    
    <div class="info">
        <h2>System Information</h2>
        <p>Hostname: $(hostname)</p>
        <p>IP Address: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
        <p>Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
        <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    </div>
    
    <div class="info">
        <h2>Variable Precedence</h2>
        <p>Terraform resolves variables in this order:</p>
        <ol>
            <li><strong>Command Line:</strong> terraform apply -var='instance_count=5'</li>
            <li><strong>Environment Variables:</strong> export TF_VAR_instance_count=3</li>
            <li><strong>Variable Files:</strong> terraform.tfvars</li>
            <li><strong>Default Values:</strong> variable definition</li>
        </ol>
    </div>
    
    <div class="info">
        <h2>Variable Validation</h2>
        <p>Terraform validates variables using:</p>
        <ul>
            <li><strong>Type Constraints:</strong> string, number, bool</li>
            <li><strong>Validation Rules:</strong> condition and error_message</li>
            <li><strong>Custom Functions:</strong> contains, regex, range checks</li>
        </ul>
    </div>
</body>
</html>
EOF

# Create PHP info page
cat > /var/www/html/${APP_NAME}/info.php << EOF
<?php
echo "<h1>${APP_NAME} - PHP Information</h1>";
echo "<h2>Environment: ${ENVIRONMENT}</h2>";
echo "<h2>Instance ID: ${INSTANCE_ID}</h2>";
echo "<h2>Variables Demo</h2>";
echo "<hr>";
echo "<h3>Variable Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Enable Monitoring:</strong> ${ENABLE_MONITORING}</p>";
echo "<p><strong>Enable Encryption:</strong> ${ENABLE_ENCRYPTION}</p>";
echo "<hr>";
phpinfo();
?>
EOF

# Create health check endpoint
cat > /var/www/html/${APP_NAME}/health.php << EOF
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'app_name' => '${APP_NAME}',
    'environment' => '${ENVIRONMENT}',
    'instance_id' => '${INSTANCE_ID}',
    'variables_demo' => 'active',
    'enable_monitoring' => '${ENABLE_MONITORING}',
    'enable_encryption' => '${ENABLE_ENCRYPTION}',
    'timestamp' => date('Y-m-d H:i:s'),
    'uptime' => shell_exec('uptime -p')
]);
?>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html/${APP_NAME}
chmod -R 755 /var/www/html/${APP_NAME}

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Log completion
echo "User data script completed successfully" >> /var/log/user-data.log
echo "Application ${APP_NAME} is ready in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Variables demo is active" >> /var/log/user-data.log
