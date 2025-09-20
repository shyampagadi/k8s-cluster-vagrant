#!/bin/bash
# User data script for EC2 instances

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
    <title>${project_name} - Instance ${instance_index}</title>
</head>
<body>
    <h1>Welcome to ${project_name}</h1>
    <p>This is instance ${instance_index}</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
</body>
</html>
EOF

# Restart web server
systemctl restart httpd
