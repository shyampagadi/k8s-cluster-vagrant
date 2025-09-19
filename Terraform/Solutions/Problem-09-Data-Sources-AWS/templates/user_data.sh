#!/bin/bash

# User Data Script for Data Sources Demo
# This script demonstrates data source usage in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
AMI_ID="${ami_id}"
VPC_ID="${vpc_id}"
EXTERNAL_DATA='${external_data}'
CONFIG_DATA='${config_data}'

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "AMI ID: ${AMI_ID}" >> /var/log/user-data.log
echo "VPC ID: ${VPC_ID}" >> /var/log/user-data.log
echo "External Data: ${EXTERNAL_DATA}" >> /var/log/user-data.log
echo "Config Data: ${CONFIG_DATA}" >> /var/log/user-data.log
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
        .data-sources { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .type { background-color: #f0f8ff; padding: 10px; border-radius: 3px; margin: 5px 0; }
        .external { background-color: #fff8f0; padding: 10px; border-radius: 3px; margin: 5px 0; }
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
        <p class="status">✓ Data sources demo is active</p>
    </div>
    
    <div class="data-sources">
        <h2>Terraform Data Sources Demo</h2>
        <p>This page demonstrates Terraform data source usage:</p>
        
        <div class="type">
            <h3>AWS Data Sources</h3>
            <ul>
                <li><strong>AMI Discovery:</strong> data.aws_ami.ubuntu.id</li>
                <li><strong>AZ Discovery:</strong> data.aws_availability_zones.available.names</li>
                <li><strong>Account Info:</strong> data.aws_caller_identity.current.account_id</li>
                <li><strong>Region Info:</strong> data.aws_region.current.name</li>
                <li><strong>VPC Info:</strong> data.aws_vpc.default.id</li>
                <li><strong>Subnet Info:</strong> data.aws_subnet.default.id</li>
            </ul>
        </div>
        
        <div class="external">
            <h3>External Data Sources</h3>
            <ul>
                <li><strong>HTTP API:</strong> data.http.external_api.body</li>
                <li><strong>Local File:</strong> data.local_file.config_file.content</li>
                <li><strong>JSON File:</strong> data.local_file.json_file.content</li>
                <li><strong>External Command:</strong> data.external.external_command.result</li>
            </ul>
        </div>
        
        <div class="external">
            <h3>Data Source Usage Examples</h3>
            <ul>
                <li><strong>Resource Configuration:</strong> ami = data.aws_ami.ubuntu.id</li>
                <li><strong>Local Values:</strong> ami_id = data.aws_ami.ubuntu.id</li>
                <li><strong>Outputs:</strong> output "ami_id" { value = data.aws_ami.ubuntu.id }</li>
                <li><strong>Filtering:</strong> filter { name = "name"; values = ["ubuntu-*"] }</li>
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
        <h2>Data Source Filtering</h2>
        <p>Data sources can be filtered using:</p>
        <ul>
            <li><strong>Most Recent:</strong> most_recent = true</li>
            <li><strong>Owners:</strong> owners = ["099720109477"]</li>
            <li><strong>Filters:</strong> filter { name = "name"; values = ["ubuntu-*"] }</li>
            <li><strong>State:</strong> state = "available"</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Data Source Dependencies</h2>
        <p>Data sources can have dependencies:</p>
        <ul>
            <li><strong>Implicit:</strong> Through resource references</li>
            <li><strong>Explicit:</strong> Using depends_on</li>
            <li><strong>Order:</strong> Consider data source order and timing</li>
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
echo "<h2>Data Sources Demo</h2>";
echo "<hr>";
echo "<h3>Data Source Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>AMI ID:</strong> ${AMI_ID}</p>";
echo "<p><strong>VPC ID:</strong> ${VPC_ID}</p>";
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
    'data_sources_demo' => 'active',
    'ami_id' => '${AMI_ID}',
    'vpc_id' => '${VPC_ID}',
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
echo "Data sources demo is active" >> /var/log/user-data.log
