#!/bin/bash
# User data script for security monitoring instance
# This script demonstrates advanced security patterns

echo "Hello from Security Monitor!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Security Enabled: ${security_enabled}" >> /home/ec2-user/hello.txt
echo "This instance was created using advanced security patterns!" >> /home/ec2-user/hello.txt
