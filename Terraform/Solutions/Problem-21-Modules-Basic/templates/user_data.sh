#!/bin/bash
# User data script for EC2 instance
# This script demonstrates module usage in user data

echo "Hello from EC2 instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Logs Bucket: ${bucket_name}" >> /home/ec2-user/hello.txt
echo "This instance was created using Terraform modules!" >> /home/ec2-user/hello.txt
