#!/bin/bash

# User Data Script for Loops and Iteration Demo
# This script demonstrates loop usage in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
INSTANCE_TYPE="${instance_type}"
DISK_SIZE="${disk_size}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Instance Type: ${INSTANCE_TYPE}" >> /var/log/user-data.log
echo "Disk Size: ${DISK_SIZE}" >> /var/log/user-data.log
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
        .loops { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .type { background-color: #f0f8ff; padding: 10px; border-radius: 3px; margin: 5px 0; }
        .advanced { background-color: #fff8f0; padding: 10px; border-radius: 3px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to ${APP_NAME}</h1>
        <p>Environment: ${ENVIRONMENT}</p>
        <p>Instance ID: ${INSTANCE_ID}</p>
        <p>Instance Type: ${INSTANCE_TYPE}</p>
        <p>Deployment Time: $(date)</p>
    </div>
    
    <div class="info">
        <h2>Application Status</h2>
        <p class="status">✓ Application is running</p>
        <p class="status">✓ Web server is configured</p>
        <p class="status">✓ Loops and iteration demo is active</p>
    </div>
    
    <div class="loops">
        <h2>Terraform Loops and Iteration Demo</h2>
        <p>This page demonstrates Terraform loop usage:</p>
        
        <div class="type">
            <h3>Count Meta-argument</h3>
            <ul>
                <li><strong>Basic Count:</strong> count = var.instance_count</li>
                <li><strong>Conditional Count:</strong> count = var.create_instances ? var.instance_count : 0</li>
                <li><strong>Environment Count:</strong> count = var.environment == 'production' ? 3 : 1</li>
                <li><strong>Splat Expressions:</strong> aws_instance.web[*].id</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>For Each Meta-argument</h3>
            <ul>
                <li><strong>Map For Each:</strong> for_each = var.server_configs</li>
                <li><strong>Set For Each:</strong> for_each = toset(var.security_group_names)</li>
                <li><strong>Each References:</strong> each.key, each.value</li>
                <li><strong>Filtered For Each:</strong> for_each = { for name, config in var.server_configs : name => config if config.environment == 'production' }</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Dynamic Blocks</h3>
            <ul>
                <li><strong>Security Group Rules:</strong> dynamic 'ingress' { for_each = var.ingress_rules }</li>
                <li><strong>EBS Volumes:</strong> dynamic 'ebs_block_device' { for_each = each.value.ebs_volumes }</li>
                <li><strong>Route Table Routes:</strong> dynamic 'route' { for_each = var.routes }</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Patterns</h3>
            <ul>
                <li><strong>Nested Iteration:</strong> Combining count and for_each</li>
                <li><strong>Complex Data Structures:</strong> Iteration with nested objects</li>
                <li><strong>Conditional Logic:</strong> Dynamic resource creation</li>
                <li><strong>Performance Optimization:</strong> Using locals for computed values</li>
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
        <h2>Count vs For Each</h2>
        <p>When to use count vs for_each:</p>
        <ul>
            <li><strong>Count:</strong> Simple numeric iteration, list-based iteration, conditional creation</li>
            <li><strong>For Each:</strong> Map-based iteration, set-based iteration, complex data structures</li>
            <li><strong>Count Benefits:</strong> Simple syntax, easy to understand, good for numeric iteration</li>
            <li><strong>For Each Benefits:</strong> More flexible, better for complex data, easier to manage individual resources</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Performance Considerations</h2>
        <p>Best practices for loop performance:</p>
        <ul>
            <li><strong>Use Locals:</strong> Compute values in locals to avoid repeated calculations</li>
            <li><strong>Resource Naming:</strong> Use consistent naming patterns</li>
            <li><strong>Error Handling:</strong> Validate iteration data</li>
            <li><strong>Resource Order:</strong> Consider resource creation order</li>
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
echo "<h2>Loops and Iteration Demo</h2>";
echo "<hr>";
echo "<h3>Loop Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>Instance Type:</strong> ${INSTANCE_TYPE}</p>";
echo "<p><strong>Disk Size:</strong> ${DISK_SIZE}</p>";
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
    'loops_demo' => 'active',
    'instance_type' => '${INSTANCE_TYPE}',
    'disk_size' => '${DISK_SIZE}',
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
echo "Loops and iteration demo is active" >> /var/log/user-data.log
