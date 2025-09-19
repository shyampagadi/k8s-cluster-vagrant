#!/bin/bash

# User Data Script for Lifecycle Rules Demo
# This script demonstrates lifecycle rules in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
INSTANCE_TYPE="${instance_type}"
AMI_ID="${ami_id}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Instance Type: ${INSTANCE_TYPE}" >> /var/log/user-data.log
echo "AMI ID: ${AMI_ID}" >> /var/log/user-data.log
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
        .lifecycle { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
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
        <p class="status">✓ Lifecycle rules demo is active</p>
    </div>
    
    <div class="lifecycle">
        <h2>Terraform Lifecycle Rules Demo</h2>
        <p>This page demonstrates Terraform lifecycle rules:</p>
        
        <div class="type">
            <h3>create_before_destroy</h3>
            <ul>
                <li><strong>Zero Downtime:</strong> Create new resources before destroying old ones</li>
                <li><strong>Service Continuity:</strong> Maintain service availability during updates</li>
                <li><strong>Rollback Safety:</strong> Safe rollback if new resources fail</li>
                <li><strong>Production Ready:</strong> Production-grade deployment strategy</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>prevent_destroy</h3>
            <ul>
                <li><strong>Data Protection:</strong> Prevent accidental deletion of critical resources</li>
                <li><strong>Infrastructure Safety:</strong> Protect infrastructure from accidental changes</li>
                <li><strong>Compliance:</strong> Meet compliance requirements for data protection</li>
                <li><strong>Audit Trail:</strong> Maintain audit trail of resource changes</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>ignore_changes</h3>
            <ul>
                <li><strong>Stability:</strong> Prevent unnecessary resource recreation</li>
                <li><strong>Performance:</strong> Avoid performance impact from unnecessary changes</li>
                <li><strong>Cost Optimization:</strong> Reduce costs from unnecessary resource recreation</li>
                <li><strong>Maintenance:</strong> Reduce maintenance overhead</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Lifecycle Management</h3>
            <ul>
                <li><strong>Resource Lifecycle:</strong> Manage entire resource lifecycle</li>
                <li><strong>Update Strategy:</strong> Define update strategies for resources</li>
                <li><strong>Deletion Strategy:</strong> Define deletion strategies for resources</li>
                <li><strong>Change Management:</strong> Manage changes to resources</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Lifecycle Patterns</h3>
            <ul>
                <li><strong>Conditional Lifecycle:</strong> Lifecycle rules based on conditions</li>
                <li><strong>Dynamic Lifecycle:</strong> Lifecycle rules that change based on variables</li>
                <li><strong>Cross-Resource Lifecycle:</strong> Lifecycle rules across multiple resources</li>
                <li><strong>Module Lifecycle:</strong> Lifecycle rules for modules</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Production Strategies</h3>
            <ul>
                <li><strong>Production-Grade Lifecycle:</strong> Production-ready lifecycle management</li>
                <li><strong>Lifecycle Validation:</strong> Validate lifecycle rules</li>
                <li><strong>Comprehensive Monitoring:</strong> Monitor lifecycle rule effects</li>
                <li><strong>Cost Optimization:</strong> Optimize costs with lifecycle rules</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Current Configuration</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
                <li><strong>Instance Type:</strong> ${INSTANCE_TYPE}</li>
                <li><strong>AMI ID:</strong> ${AMI_ID}</li>
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
        <h2>Lifecycle Rules Benefits</h2>
        <p>Benefits of using lifecycle rules in Terraform:</p>
        <ul>
            <li><strong>Zero Downtime Deployments:</strong> Deploy without service interruption</li>
            <li><strong>Data Protection:</strong> Protect critical data from accidental deletion</li>
            <li><strong>Resource Stability:</strong> Prevent unnecessary resource recreation</li>
            <li><strong>Cost Optimization:</strong> Optimize costs with lifecycle management</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Best Practices</h2>
        <p>Best practices for lifecycle rules:</p>
        <ul>
            <li><strong>Use create_before_destroy:</strong> For resources that need zero downtime</li>
            <li><strong>Use prevent_destroy:</strong> For critical resources that should not be deleted</li>
            <li><strong>Use ignore_changes:</strong> For attributes that change outside Terraform</li>
            <li><strong>Document Lifecycle Rules:</strong> Document all lifecycle rule usage</li>
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
echo "<h2>Lifecycle Rules Demo</h2>";
echo "<hr>";
echo "<h3>Lifecycle Rules Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>Instance Type:</strong> ${INSTANCE_TYPE}</p>";
echo "<p><strong>AMI ID:</strong> ${AMI_ID}</p>";
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
    'lifecycle_rules_demo' => 'active',
    'instance_type' => '${INSTANCE_TYPE}',
    'ami_id' => '${AMI_ID}',
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
echo "Lifecycle rules demo is active" >> /var/log/user-data.log