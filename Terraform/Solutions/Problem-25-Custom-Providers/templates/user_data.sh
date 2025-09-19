#!/bin/bash
# User data script for EC2 instance
# This script demonstrates custom provider usage

echo "Hello from EC2 instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "This instance was created using custom providers!" >> /home/ec2-user/hello.txt
