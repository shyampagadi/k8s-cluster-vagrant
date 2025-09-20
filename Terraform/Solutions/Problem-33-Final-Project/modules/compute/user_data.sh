#!/bin/bash
# User data script for final project instances

# Update system
yum update -y

# Install web server
yum install -y httpd

# Start and enable web server
systemctl start httpd
systemctl enable httpd

# Create custom index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .content { background: #ecf0f1; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .info { background: #3498db; color: white; padding: 10px; border-radius: 3px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to ${project_name}</h1>
            <p>Final Project - Enterprise Infrastructure</p>
        </div>
        
        <div class="content">
            <h2>Environment Information</h2>
            <div class="info">Environment: ${environment}</div>
            <div class="info">Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</div>
            <div class="info">Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</div>
            <div class="info">Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</div>
            <div class="info">Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</div>
        </div>
        
        <div class="content">
            <h2>Project Features</h2>
            <ul>
                <li>Multi-environment deployment</li>
                <li>Modular architecture</li>
                <li>Auto scaling</li>
                <li>High availability</li>
                <li>Security best practices</li>
                <li>Monitoring and alerting</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Restart web server
systemctl restart httpd
