#!/bin/bash

# User Data Script for Conditional Logic Demo
# This script demonstrates conditional logic in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
INSTANCE_COUNT="${instance_count}"
MIN_SIZE="${min_size}"
MAX_SIZE="${max_size}"
DESIRED_CAPACITY="${desired_capacity}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Instance Count: ${INSTANCE_COUNT}" >> /var/log/user-data.log
echo "Min Size: ${MIN_SIZE}" >> /var/log/user-data.log
echo "Max Size: ${MAX_SIZE}" >> /var/log/user-data.log
echo "Desired Capacity: ${DESIRED_CAPACITY}" >> /var/log/user-data.log
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
        .conditional { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .type { background-color: #f0f8ff; padding: 10px; border-radius: 3px; margin: 5px 0; }
        .advanced { background-color: #fff8f0; padding: 10px; border-radius: 3px; margin: 5px 0; }
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
        <p class="status">✓ Conditional logic demo is active</p>
    </div>
    
    <div class="conditional">
        <h2>Terraform Conditional Logic Demo</h2>
        <p>This page demonstrates Terraform conditional logic:</p>
        
        <div class="type">
            <h3>Conditional Resource Creation</h3>
            <ul>
                <li><strong>Environment-Based:</strong> Different resources for different environments</li>
                <li><strong>Count-Based:</strong> Different instance counts based on environment</li>
                <li><strong>Feature-Based:</strong> Different features enabled for different environments</li>
                <li><strong>Security-Based:</strong> Different security configurations for different environments</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Ternary Operator</h3>
            <ul>
                <li><strong>Conditional Values:</strong> Different values based on conditions</li>
                <li><strong>Environment-Specific:</strong> Different configurations for different environments</li>
                <li><strong>Feature Flags:</strong> Different features enabled for different environments</li>
                <li><strong>Resource Counts:</strong> Different resource counts based on environment</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Dynamic Blocks</h3>
            <ul>
                <li><strong>Conditional Blocks:</strong> Different blocks based on conditions</li>
                <li><strong>Environment-Specific:</strong> Different blocks for different environments</li>
                <li><strong>Feature-Based:</strong> Different blocks based on features</li>
                <li><strong>Security-Based:</strong> Different blocks based on security requirements</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Conditional Logic</h3>
            <ul>
                <li><strong>Complex Conditions:</strong> Multiple conditions combined</li>
                <li><strong>Nested Conditions:</strong> Conditions within conditions</li>
                <li><strong>Function-Based:</strong> Conditions using functions</li>
                <li><strong>Variable-Based:</strong> Conditions based on variables</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Production Strategies</h3>
            <ul>
                <li><strong>Production-Grade Conditions:</strong> Production-ready conditional logic</li>
                <li><strong>Environment Validation:</strong> Validate environment-specific conditions</li>
                <li><strong>Comprehensive Monitoring:</strong> Environment-specific monitoring levels</li>
                <li><strong>Cost Management:</strong> Environment-specific cost optimization</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Current Configuration</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
                <li><strong>Instance Count:</strong> ${INSTANCE_COUNT}</li>
                <li><strong>Min Size:</strong> ${MIN_SIZE}</li>
                <li><strong>Max Size:</strong> ${MAX_SIZE}</li>
                <li><strong>Desired Capacity:</strong> ${DESIRED_CAPACITY}</li>
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
        <h2>Conditional Logic Benefits</h2>
        <p>Benefits of using conditional logic in Terraform:</p>
        <ul>
            <li><strong>Environment-Specific Configurations:</strong> Different configurations for different environments</li>
            <li><strong>Feature Flags:</strong> Enable/disable features based on conditions</li>
            <li><strong>Resource Optimization:</strong> Optimize resources based on conditions</li>
            <li><strong>Cost Management:</strong> Manage costs based on conditions</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Best Practices</h2>
        <p>Best practices for conditional logic:</p>
        <ul>
            <li><strong>Use Clear Conditions:</strong> Use clear and understandable conditions</li>
            <li><strong>Document Conditions:</strong> Document all conditional logic</li>
            <li><strong>Test Conditions:</strong> Test all conditional scenarios</li>
            <li><strong>Validate Conditions:</strong> Validate conditions before deployment</li>
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
echo "<h2>Conditional Logic Demo</h2>";
echo "<hr>";
echo "<h3>Conditional Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>Instance Count:</strong> ${INSTANCE_COUNT}</p>";
echo "<p><strong>Min Size:</strong> ${MIN_SIZE}</p>";
echo "<p><strong>Max Size:</strong> ${MAX_SIZE}</p>";
echo "<p><strong>Desired Capacity:</strong> ${DESIRED_CAPACITY}</p>";
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
    'conditional_logic_demo' => 'active',
    'instance_count' => '${INSTANCE_COUNT}',
    'min_size' => '${MIN_SIZE}',
    'max_size' => '${MAX_SIZE}',
    'desired_capacity' => '${DESIRED_CAPACITY}',
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
echo "Conditional logic demo is active" >> /var/log/user-data.log