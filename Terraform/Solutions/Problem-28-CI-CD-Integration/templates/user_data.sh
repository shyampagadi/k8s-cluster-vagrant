#!/bin/bash
# User data script for CI/CD runner instance
# This script demonstrates CI/CD integration

echo "Hello from CI/CD Runner!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "CI/CD Enabled: ${cicd_enabled}" >> /home/ec2-user/hello.txt
echo "This instance was created using CI/CD integration!" >> /home/ec2-user/hello.txt
