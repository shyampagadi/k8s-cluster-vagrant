#!/bin/bash

# User Data Script for Locals and Functions Demo
# This script demonstrates local values and functions in Terraform

# Set variables from Terraform
APP_NAME="${app_name}"
ENVIRONMENT="${environment}"
INSTANCE_ID="${instance_id}"
INSTANCE_COUNT="${instance_count}"
INSTANCE_TYPE="${instance_type}"
AVAILABILITY_ZONES="${availability_zones}"
SUBNET_CIDRS="${subnet_cidrs}"

# Log script execution
echo "Starting user data script for ${APP_NAME} in ${ENVIRONMENT}" >> /var/log/user-data.log
echo "Instance ID: ${INSTANCE_ID}" >> /var/log/user-data.log
echo "Instance Count: ${INSTANCE_COUNT}" >> /var/log/user-data.log
echo "Instance Type: ${INSTANCE_TYPE}" >> /var/log/user-data.log
echo "Availability Zones: ${AVAILABILITY_ZONES}" >> /var/log/user-data.log
echo "Subnet CIDRs: ${SUBNET_CIDRS}" >> /var/log/user-data.log
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
        .locals { background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 10px 0; }
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
        <p class="status">✓ Locals and functions demo is active</p>
    </div>
    
    <div class="locals">
        <h2>Terraform Locals and Functions Demo</h2>
        <p>This page demonstrates Terraform local values and built-in functions:</p>
        
        <div class="type">
            <h3>Local Values</h3>
            <ul>
                <li><strong>Computed Values:</strong> Values computed from other variables</li>
                <li><strong>Reusable Expressions:</strong> Expressions used multiple times</li>
                <li><strong>Complex Calculations:</strong> Complex calculations and transformations</li>
                <li><strong>Data Transformations:</strong> Transform data for different purposes</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>String Functions</h3>
            <ul>
                <li><strong>upper:</strong> Convert to uppercase</li>
                <li><strong>lower:</strong> Convert to lowercase</li>
                <li><strong>title:</strong> Convert to title case</li>
                <li><strong>reverse:</strong> Reverse string</li>
                <li><strong>replace:</strong> Replace substrings</li>
                <li><strong>split:</strong> Split string into list</li>
                <li><strong>join:</strong> Join list into string</li>
                <li><strong>substr:</strong> Extract substring</li>
                <li><strong>trim:</strong> Remove whitespace</li>
                <li><strong>format:</strong> Format string</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Numeric Functions</h3>
            <ul>
                <li><strong>abs:</strong> Absolute value</li>
                <li><strong>ceil:</strong> Ceiling function</li>
                <li><strong>floor:</strong> Floor function</li>
                <li><strong>log:</strong> Logarithm</li>
                <li><strong>max:</strong> Maximum value</li>
                <li><strong>min:</strong> Minimum value</li>
                <li><strong>pow:</strong> Power function</li>
                <li><strong>signum:</strong> Sign function</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Collection Functions</h3>
            <ul>
                <li><strong>alltrue:</strong> All values true</li>
                <li><strong>anytrue:</strong> Any value true</li>
                <li><strong>chunklist:</strong> Chunk list</li>
                <li><strong>coalesce:</strong> First non-null value</li>
                <li><strong>compact:</strong> Remove null values</li>
                <li><strong>concat:</strong> Concatenate lists</li>
                <li><strong>contains:</strong> Check containment</li>
                <li><strong>distinct:</strong> Remove duplicates</li>
                <li><strong>element:</strong> Get element by index</li>
                <li><strong>index:</strong> Get index of element</li>
                <li><strong>keys:</strong> Get map keys</li>
                <li><strong>length:</strong> Get length</li>
                <li><strong>lookup:</strong> Lookup value</li>
                <li><strong>map:</strong> Create map</li>
                <li><strong>matchkeys:</strong> Match keys</li>
                <li><strong>merge:</strong> Merge maps</li>
                <li><strong>range:</strong> Create range</li>
                <li><strong>reverse:</strong> Reverse list</li>
                <li><strong>setintersection:</strong> Set intersection</li>
                <li><strong>setproduct:</strong> Set product</li>
                <li><strong>setsubtract:</strong> Set subtraction</li>
                <li><strong>setunion:</strong> Set union</li>
                <li><strong>slice:</strong> Slice list</li>
                <li><strong>sort:</strong> Sort list</li>
                <li><strong>sum:</strong> Sum values</li>
                <li><strong>transpose:</strong> Transpose matrix</li>
                <li><strong>values:</strong> Get map values</li>
                <li><strong>zipmap:</strong> Zip map</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>Encoding Functions</h3>
            <ul>
                <li><strong>base64encode:</strong> Base64 encode</li>
                <li><strong>base64decode:</strong> Base64 decode</li>
                <li><strong>base64gzip:</strong> Base64 gzip</li>
                <li><strong>base64gunzip:</strong> Base64 gunzip</li>
                <li><strong>csvdecode:</strong> CSV decode</li>
                <li><strong>jsonencode:</strong> JSON encode</li>
                <li><strong>jsondecode:</strong> JSON decode</li>
                <li><strong>urlencode:</strong> URL encode</li>
                <li><strong>urldecode:</strong> URL decode</li>
                <li><strong>yamlencode:</strong> YAML encode</li>
                <li><strong>yamldecode:</strong> YAML decode</li>
            </ul>
        </div>
        
        <div class="type">
            <h3>File Functions</h3>
            <ul>
                <li><strong>file:</strong> Read file</li>
                <li><strong>filebase64:</strong> Read file as base64</li>
                <li><strong>filebase64sha256:</strong> SHA256 of base64 file</li>
                <li><strong>filebase64sha512:</strong> SHA512 of base64 file</li>
                <li><strong>fileexists:</strong> Check file exists</li>
                <li><strong>filemd5:</strong> MD5 of file</li>
                <li><strong>filesha1:</strong> SHA1 of file</li>
                <li><strong>filesha256:</strong> SHA256 of file</li>
                <li><strong>filesha512:</strong> SHA512 of file</li>
                <li><strong>pathexpand:</strong> Expand path</li>
                <li><strong>templatefile:</strong> Template file</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Advanced Function Usage</h3>
            <ul>
                <li><strong>Function Combinations:</strong> Combine multiple functions</li>
                <li><strong>Complex Transformations:</strong> Complex data transformations</li>
                <li><strong>Performance Optimization:</strong> Optimize performance with functions</li>
                <li><strong>Data Validation:</strong> Validate data with functions</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Production Strategies</h3>
            <ul>
                <li><strong>Production-Grade Functions:</strong> Production-ready function usage</li>
                <li><strong>Function Validation:</strong> Validate function results</li>
                <li><strong>Comprehensive Monitoring:</strong> Monitor function performance</li>
                <li><strong>Cost Optimization:</strong> Optimize costs with functions</li>
            </ul>
        </div>
        
        <div class="advanced">
            <h3>Current Configuration</h3>
            <ul>
                <li><strong>App Name:</strong> ${APP_NAME}</li>
                <li><strong>Environment:</strong> ${ENVIRONMENT}</li>
                <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
                <li><strong>Instance Count:</strong> ${INSTANCE_COUNT}</li>
                <li><strong>Instance Type:</strong> ${INSTANCE_TYPE}</li>
                <li><strong>Availability Zones:</strong> ${AVAILABILITY_ZONES}</li>
                <li><strong>Subnet CIDRs:</strong> ${SUBNET_CIDRS}</li>
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
        <h2>Locals and Functions Benefits</h2>
        <p>Benefits of using local values and functions in Terraform:</p>
        <ul>
            <li><strong>Code Reusability:</strong> Reuse expressions and calculations</li>
            <li><strong>Data Transformation:</strong> Transform data for different purposes</li>
            <li><strong>Performance Optimization:</strong> Optimize performance with functions</li>
            <li><strong>Maintainability:</strong> Improve code maintainability</li>
        </ul>
    </div>
    
    <div class="info">
        <h2>Best Practices</h2>
        <p>Best practices for local values and functions:</p>
        <ul>
            <li><strong>Use Meaningful Names:</strong> Use descriptive names for local values</li>
            <li><strong>Document Functions:</strong> Document function usage and purpose</li>
            <li><strong>Test Functions:</strong> Test function results</li>
            <li><strong>Optimize Performance:</strong> Optimize function performance</li>
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
echo "<h2>Locals and Functions Demo</h2>";
echo "<hr>";
echo "<h3>Local Values and Functions Information</h3>";
echo "<p><strong>App Name:</strong> ${APP_NAME}</p>";
echo "<p><strong>Environment:</strong> ${ENVIRONMENT}</p>";
echo "<p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>";
echo "<p><strong>Instance Count:</strong> ${INSTANCE_COUNT}</p>";
echo "<p><strong>Instance Type:</strong> ${INSTANCE_TYPE}</p>";
echo "<p><strong>Availability Zones:</strong> ${AVAILABILITY_ZONES}</p>";
echo "<p><strong>Subnet CIDRs:</strong> ${SUBNET_CIDRS}</p>";
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
    'locals_functions_demo' => 'active',
    'instance_count' => '${INSTANCE_COUNT}',
    'instance_type' => '${INSTANCE_TYPE}',
    'availability_zones' => '${AVAILABILITY_ZONES}',
    'subnet_cidrs' => '${SUBNET_CIDRS}',
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
echo "Locals and functions demo is active" >> /var/log/user-data.log