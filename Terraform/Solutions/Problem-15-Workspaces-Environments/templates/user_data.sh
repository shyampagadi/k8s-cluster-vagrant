#!/bin/bash

# User Data Script for Workspaces and Environment Management Demo
# This script demonstrates workspaces and environment management in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
WORKSPACE="${workspace}"
TIER="${tier}"
COST_CENTER="${cost_center}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Workspace: ${WORKSPACE}" >> /var/log/user-data.log
echo "Tier: ${TIER}" >> /var/log/user-data.log
echo "Cost Center: ${COST_CENTER}" >> /var/log/user-data.log
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
        .workspaces { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .type { background-color: #f0f8ff; padding: 10px; border-radius: 3px; margin: 5px 0; }
        .advanced { background-color: #fff8f0; padding: 10px; border-radius: 3px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to ${APP_NAME}</h1>
        <p>Environment: ${ENVIRONMENT}</p>
        <p>Workspace: ${WORKSPACE}</p>
        <p>Instance ID: ${INSTANCE_ID}</p>
        <p>Deployment Time: $(date)</p>
    </div>
    
    <div class="info">
        <h2>Application Status</h2>
        <p class="status">✓ Application is running</p>
        <p class="status">✓ Web server is configured</p>
        <p class="status">✓ Workspaces and environment management demo is active</p>
    </div>
    
    <div class="workspaces">
        <h2>Terraform Workspaces and Environment Management Demo</h2>
        <p>This page demonstrates Terraform workspaces and environment management:</p>
        
        <div class="type">
            <h3>Workspace Fundamentals</h3>
            <ul>
                <li><strong>Environment Isolation:</strong> Separate state for different environments</li>
                <li><strong>Configuration Reuse:</strong> Use the same configuration for multiple environments</li>
                <li><strong>State Management:</strong> Manage multiple state files efficiently</li>
                <li><strong>Deployment Flexibility:</strong> Deploy to different environments easily</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Workspace Management</h3>
            <ul>
                <li><strong>Workspace List:</strong> terraform workspace list</li>
                <li><strong>Workspace New:</strong> terraform workspace new dev</li>
                <li><strong>Workspace Select:</strong> terraform workspace select dev</li>
                <li><strong>Workspace Show:</strong> terraform workspace show</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Environment Isolation</h3>
            <ul>
                <li><strong>Workspace-Specific CIDR:</strong> Different CIDR blocks for different environments</li>
                <li><strong>Workspace-Specific AZs:</strong> Different availability zones for different environments</li>
                <li><strong>Workspace-Specific Naming:</strong> Different resource naming for different environments</li>
                <li><strong>Security Isolation:</strong> Different security configurations for different environments</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Workspace-Specific Configurations</h3>
            <ul>
                <li><strong>Instance Configurations:</strong> Different instance types and counts</li>
                <li><strong>Database Configurations:</strong> Different database classes and settings</li>
                <li><strong>Feature Flags:</strong> Different features enabled for different environments</li>
                <li><strong>Security Configurations:</strong> Different security settings for different environments</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Production Strategies</h3>
            <ul>
                <li><strong>Production-Grade Configurations:</strong> Production-ready workspace configurations</li>
                <li><strong>Workspace Validation:</strong> Validate workspace names and configurations</li>
                <li><strong>Comprehensive Monitoring:</strong> Environment-specific monitoring levels</li>
                <li><strong>Cost Management:</strong> Environment-specific cost centers</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Current Configuration</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Workspace:</strong> ${WORKSPACE}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
                <li><strong>Tier:</strong> ${TIER}</li>
                <li><strong>Cost Center:</strong> ${COST_CENTER}</li>
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
        <h2>Workspace Benefits</h2>
        <p>Benefits of using workspaces in Terraform:</p>
        <ul>
            <li><strong>Environment Isolation:</strong> Separate state for dev/staging/prod</li>
            <li><strong>Configuration Reuse:</strong> Single configuration for multiple environments</li>
            <li><strong>State Management:</strong> Efficient state file management</li>
            <li><strong>Deployment Flexibility:</strong> Easy environment switching</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Best Practices</h2>
        <p>Best practices for workspace management:</p>
        <ul>
            <li><strong>Use Meaningful Names:</strong> Use descriptive workspace names</li>
            <li><strong>Validate Workspaces:</strong> Validate workspace names and configurations</li>
            <li><strong>Use Workspace-Specific Configurations:</strong> Different configurations for different environments</li>
            <li><strong>Document Usage:</strong> Document workspace usage and configurations</li>
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
echo "<h2>Workspace: ${WORKSPACE}</h2>";
echo "<h2>Instance ID: ${INSTANCE_ID}</h2>";
echo "<h2>Workspaces and Environment Management Demo</h2>";
echo "<hr>";
echo "<h3>Workspace Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Workspace:</strong> ${WORKSPACE}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>Tier:</strong> ${TIER}</p>";
echo "<p><strong>Cost Center:</strong> ${COST_CENTER}</p>";
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
    'workspace' => '${WORKSPACE}',
    'instance_id' => '${INSTANCE_ID}',
    'workspaces_demo' => 'active',
    'tier' => '${TIER}',
    'cost_center' => '${COST_CENTER}',
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
echo "Workspaces and environment management demo is active" >> /var/log/user-data.log
