#!/bin/bash
# User data script for disaster recovery instance
# This script demonstrates disaster recovery patterns

echo "Hello from Disaster Recovery Instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Region: ${region}" >> /home/ec2-user/hello.txt
echo "DR Enabled: ${dr_enabled}" >> /home/ec2-user/hello.txt
echo "This instance was created using disaster recovery patterns!" >> /home/ec2-user/hello.txt
