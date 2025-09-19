#!/bin/bash
# User data script for cost-optimized instance
# This script demonstrates cost optimization patterns

echo "Hello from Cost-Optimized Instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Cost Optimized: ${cost_optimized}" >> /home/ec2-user/hello.txt
echo "This instance was created using cost optimization patterns!" >> /home/ec2-user/hello.txt
