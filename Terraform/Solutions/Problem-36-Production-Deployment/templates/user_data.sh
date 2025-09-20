#!/bin/bash
# User data script for production deployment instance
# This script demonstrates production deployment patterns

echo "Hello from Production Instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Deployment Color: ${deployment_color}" >> /home/ec2-user/hello.txt
echo "This instance was created using production deployment patterns!" >> /home/ec2-user/hello.txt
