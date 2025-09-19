#!/bin/bash

# User Data Script for Resource Dependencies Demo
# This script demonstrates resource dependencies in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
VPC_ID="${vpc_id}"
SUBNET_ID="${subnet_id}"
SECURITY_GROUP_ID="${security_group_id}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "VPC ID: ${VPC_ID}" >> /var/log/user-data.log
echo "Subnet ID: ${SUBNET_ID}" >> /var/log/user-data.log
echo "Security Group ID: ${SECURITY_GROUP_ID}" >> /var/log/user-data.log
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
        .dependencies { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
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
        <p class="status">✓ Resource dependencies demo is active</p>
    </div>
    
    <div class="dependencies">
        <h2>Terraform Resource Dependencies Demo</h2>
        <p>This page demonstrates Terraform resource dependencies:</p>
        
        <div class="type">
            <h3>Implicit Dependencies</h3>
            <ul>
                <li><strong>Resource References:</strong> Resources that reference other resources</li>
                <li><strong>Attribute References:</strong> Resources that use attributes from other resources</li>
                <li><strong>Data Source References:</strong> Resources that use data from other resources</li>
                <li><strong>Output References:</strong> Resources that use outputs from other resources</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Explicit Dependencies</h3>
            <ul>
                <li><strong>depends_on:</strong> Explicitly define resource dependencies</li>
                <li><strong>Resource Blocks:</strong> Define dependencies in resource blocks</li>
                <li><strong>Module Dependencies:</strong> Define dependencies between modules</li>
                <li><strong>Data Source Dependencies:</strong> Define dependencies for data sources</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Dependency Chain</h3>
            <ul>
                <li><strong>VPC:</strong> Foundation resource that other resources depend on</li>
                <li><strong>Internet Gateway:</strong> Depends on VPC</li>
                <li><strong>Route Table:</strong> Depends on VPC</li>
                <li><strong>Route:</strong> Depends on Route Table and Internet Gateway</li>
                <li><strong>Subnets:</strong> Depend on VPC</li>
                <li><strong>Route Table Association:</strong> Depends on Subnets and Route Table</li>
                <li><strong>Security Group:</strong> Depends on VPC</li>
                <li><strong>Instances:</strong> Depend on Subnets and Security Group</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Dependency Management</h3>
            <ul>
                <li><strong>Dependency Ordering:</strong> Resources are created in dependency order</li>
                <li><strong>Parallel Execution:</strong> Resources without dependencies can be created in parallel</li>
                <li><strong>Dependency Validation:</strong> Validate dependencies before creation</li>
                <li><strong>Dependency Visualization:</strong> Visualize dependency graphs</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Dependency Patterns</h3>
            <ul>
                <li><strong>Circular Dependencies:</strong> Avoid circular dependencies</li>
                <li><strong>Conditional Dependencies:</strong> Dependencies based on conditions</li>
                <li><strong>Dynamic Dependencies:</strong> Dependencies that change based on variables</li>
                <li><strong>Cross-Module Dependencies:</strong> Dependencies between modules</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Production Strategies</h3>
            <ul>
                <li><strong>Production-Grade Dependencies:</strong> Production-ready dependency management</li>
                <li><strong>Dependency Validation:</strong> Validate all dependencies</li>
                <li><strong>Comprehensive Monitoring:</strong> Monitor dependency health</li>
                <li><strong>Cost Optimization:</strong> Optimize costs with dependency management</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Current Configuration</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
                <li><strong>VPC ID:</strong> ${VPC_ID}</li>
                <li><strong>Subnet ID:</strong> ${SUBNET_ID}</li>
                <li><strong>Security Group ID:</strong> ${SECURITY_GROUP_ID}</li>
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
        <h2>Resource Dependencies Benefits</h2>
        <p>Benefits of proper resource dependency management:</p>
        <ul>
            <li><strong>Reliable Deployments:</strong> Resources are created in the correct order</li>
            <li><strong>Parallel Execution:</strong> Resources without dependencies can be created in parallel</li>
            <li><strong>Error Prevention:</strong> Prevent errors from missing dependencies</li>
            <li><strong>Performance Optimization:</strong> Optimize deployment performance</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Best Practices</h2>
        <p>Best practices for resource dependencies:</p>
        <ul>
            <li><strong>Use Implicit Dependencies:</strong> Prefer implicit dependencies over explicit ones</li>
            <li><strong>Minimize Explicit Dependencies:</strong> Only use explicit dependencies when necessary</li>
            <li><strong>Document Dependencies:</strong> Document complex dependency relationships</li>
            <li><strong>Test Dependencies:</strong> Test dependency relationships</li>
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
echo "<h2>Resource Dependencies Demo</h2>";
echo "<hr>";
echo "<h3>Resource Dependencies Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>VPC ID:</strong> ${VPC_ID}</p>";
echo "<p><strong>Subnet ID:</strong> ${SUBNET_ID}</p>";
echo "<p><strong>Security Group ID:</strong> ${SECURITY_GROUP_ID}</p>";
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
    'resource_dependencies_demo' => 'active',
    'vpc_id' => '${VPC_ID}',
    'subnet_id' => '${SUBNET_ID}',
    'security_group_id' => '${SECURITY_GROUP_ID}',
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
echo "Resource dependencies demo is active" >> /var/log/user-data.log