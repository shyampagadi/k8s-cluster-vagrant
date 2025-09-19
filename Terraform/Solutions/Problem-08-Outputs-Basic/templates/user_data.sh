#!/bin/bash

# User Data Script for Outputs Demo
# This script demonstrates output usage in Terraform

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
        .outputs { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
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
        <p class="status">✓ Outputs demo is active</p>
    </div>
    
    <div class="outputs">
        <h2>Terraform Outputs Demo</h2>
        <p>This page demonstrates Terraform output usage:</p>
        
        <div class="type">
            <h3>Basic Output Types</h3>
            <ul>
                <li><strong>String Outputs:</strong> vpc_id, bucket_name, instance_public_ip</li>
                <li><strong>Number Outputs:</strong> instance_count, subnet_count, total_cost</li>
                <li><strong>Boolean Outputs:</strong> monitoring_enabled, encryption_enabled</li>
                <li><strong>List Outputs:</strong> availability_zones, subnet_ids, instance_ids</li>
                <li><strong>Map Outputs:</strong> environment_tags, resource_tags</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Output Patterns</h3>
            <ul>
                <li><strong>Complex Expressions:</strong> resource_summary, instance_details</li>
                <li><strong>Conditional Outputs:</strong> database_endpoint, monitoring_dashboard_url</li>
                <li><strong>Sensitive Outputs:</strong> database_password, database_credentials</li>
                <li><strong>Formatted Outputs:</strong> deployment_summary, infrastructure_summary</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Output Usage Examples</h3>
            <ul>
                <li><strong>Basic Reference:</strong> output "vpc_id" { value = aws_vpc.main.id }</li>
                <li><strong>Conditional Output:</strong> output "database_endpoint" { value = var.create_database ? aws_db_instance.main[0].endpoint : null }</li>
                <li><strong>Sensitive Output:</strong> output "password" { value = var.password; sensitive = true }</li>
                <li><strong>Formatted Output:</strong> output "summary" { value = format("Project: %s", var.project_name) }</li>
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
        <h2>Output Best Practices</h2>
        <p>Best practices for Terraform outputs:</p>
        <ul>
            <li><strong>Documentation:</strong> Always include descriptions</li>
            <li><strong>Security:</strong> Mark sensitive outputs appropriately</li>
            <li><strong>Formatting:</strong> Use format() for user-friendly outputs</li>
            <li><strong>Conditionals:</strong> Use conditional outputs for optional resources</li>
            <li><strong>Dependencies:</strong> Consider output dependencies</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Output Dependencies</h2>
        <p>Outputs can have dependencies:</p>
        <ul>
            <li><strong>Implicit:</strong> Through resource references</li>
            <li><strong>Explicit:</strong> Using depends_on</li>
            <li><strong>Order:</strong> Consider output order and timing</li>
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
echo "<h2>Outputs Demo</h2>";
echo "<hr>";
echo "<h3>Output Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
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
    'outputs_demo' => 'active',
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
echo "Outputs demo is active" >> /var/log/user-data.log
