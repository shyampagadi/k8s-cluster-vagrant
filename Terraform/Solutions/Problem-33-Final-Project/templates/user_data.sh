#!/bin/bash
# User data script for final project instance
# This script demonstrates comprehensive Terraform solution

echo "Hello from Final Project Instance!" > /home/ec2-user/hello.txt
echo "Project: ${project_name}" >> /home/ec2-user/hello.txt
echo "Environment: ${environment}" >> /home/ec2-user/hello.txt
echo "Final Project: ${final_project}" >> /home/ec2-user/hello.txt
echo "This instance was created using comprehensive Terraform patterns!" >> /home/ec2-user/hello.txt
echo "Congratulations on completing the Terraform course!" >> /home/ec2-user/hello.txt
