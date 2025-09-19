#!/bin/bash
# User data script for EC2 instance
# This script demonstrates advanced loop usage

echo "Hello from EC2 instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Instance Type: ${instance_type}" >> /home/ec2-user/hello.txt
echo "Instance Index: ${instance_index}" >> /home/ec2-user/hello.txt
echo "This instance was created using advanced loops!" >> /home/ec2-user/hello.txt
echo "Timestamp: $(date)" >> /home/ec2-user/hello.txt
