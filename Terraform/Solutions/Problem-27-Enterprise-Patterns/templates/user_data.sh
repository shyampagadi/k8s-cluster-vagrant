#!/bin/bash
# User data script for enterprise EC2 instance
# This script demonstrates enterprise patterns

echo "Hello from Enterprise EC2 instance!" > /home/ec2-user/hello.txt
echo "Enterprise: ${enterprise_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Region: ${region}" >> /home/ec2-user/hello.txt
echo "This instance was created using enterprise patterns!" >> /home/ec2-user/hello.txt
echo "Timestamp: $(date)" >> /home/ec2-user/hello.txt
