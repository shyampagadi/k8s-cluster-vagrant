# EC2 (Elastic Compute Cloud) - Complete Terraform Guide

## 🎯 Overview

Amazon Elastic Compute Cloud (EC2) is the foundation of AWS compute services. It provides resizable compute capacity in the cloud, allowing you to launch virtual machines (instances) with various configurations. EC2 is essential for most AWS deployments and provides the compute foundation for applications.

### **What is EC2?**
EC2 is a web service that provides secure, resizable compute capacity in the cloud. It's designed to make web-scale cloud computing easier for developers by providing a simple web service interface to obtain and configure capacity with minimal friction.

### **Key Concepts**
- **Instances**: Virtual machines running on AWS infrastructure
- **AMIs**: Amazon Machine Images that serve as templates for instances
- **Instance Types**: Different combinations of CPU, memory, storage, and networking capacity
- **Security Groups**: Virtual firewalls that control traffic to instances
- **Key Pairs**: Secure login information for instances
- **EBS**: Elastic Block Store for persistent storage
- **Auto Scaling**: Automatic scaling of instances based on demand

### **When to Use EC2**
- **Web applications** - Hosting web servers and applications
- **Database servers** - Running database instances
- **Development environments** - Testing and development
- **Legacy applications** - Migrating on-premises applications
- **High-performance computing** - CPU or memory-intensive workloads
- **Custom software** - Applications requiring specific OS or software

## 🏗️ Architecture Patterns

### **Basic EC2 Structure**
```
EC2 Instance
├── Instance Type (t3.micro, t3.small, etc.)
├── AMI (Amazon Linux, Ubuntu, Windows, etc.)
├── Security Group (Firewall rules)
├── Key Pair (SSH access)
├── EBS Volume (Storage)
└── VPC Subnet (Network placement)
```

### **Multi-Tier Application Pattern**
```
Web Tier (Public Subnets)
├── Web Server 1 (t3.small)
├── Web Server 2 (t3.small)
└── Load Balancer

Application Tier (Private Subnets)
├── App Server 1 (t3.medium)
├── App Server 2 (t3.medium)
└── Auto Scaling Group

Database Tier (Private Subnets)
├── Database Server (t3.large)
└── Read Replica (t3.medium)
```

### **High Availability Pattern**
```
Multi-AZ Deployment
├── AZ-1
│   ├── Web Server 1
│   ├── App Server 1
│   └── Database Primary
├── AZ-2
│   ├── Web Server 2
│   ├── App Server 2
│   └── Database Replica
└── Load Balancer (Cross-AZ)
```

## 📝 Terraform Implementation

### **Basic EC2 Instance**
```hcl
# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  # Network configuration
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  # Storage configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    
    tags = {
      Name        = "Web Server Root Volume"
      Environment = "production"
    }
  }
  
  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name = "web-app"
    environment = "production"
  }))
  
  tags = {
    Name        = "Web Server"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **EC2 Instance with EBS Volume**
```hcl
# Create EBS volume
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.web.availability_zone
  size              = 100
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name        = "Data Volume"
    Environment = "production"
  }
}

# Attach EBS volume to instance
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.web.id
}

# EC2 instance with additional storage
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  
  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }
  
  # Additional EBS volume
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    
    tags = {
      Name        = "App Data Volume"
      Environment = "production"
    }
  }
  
  tags = {
    Name        = "App Server"
    Environment = "production"
  }
}
```

### **Auto Scaling Group**
```hcl
# Launch template
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name = "web-app"
    environment = "production"
  }))
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
      encrypted             = true
    }
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "Web Server"
      Environment = "production"
      Project     = "web-app"
    }
  }
  
  tags = {
    Name        = "Web Launch Template"
    Environment = "production"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "Web ASG Instance"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "web_scale_up" {
  name                   = "web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# CloudWatch alarms for scaling
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "web-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  
  alarm_actions = [aws_autoscaling_policy.web_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "web-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  
  alarm_actions = [aws_autoscaling_policy.web_scale_down.arn]
}
```

### **Spot Instances**
```hcl
# Spot instance request
resource "aws_spot_instance_request" "spot" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  spot_price    = "0.01"
  spot_type     = "one-time"
  wait_for_fulfillment = true
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name = "spot-app"
    environment = "production"
  }))
  
  tags = {
    Name        = "Spot Instance"
    Environment = "production"
    Type        = "Spot"
  }
}

# Spot fleet request
resource "aws_spot_fleet_request" "fleet" {
  iam_fleet_role = aws_iam_role.spot_fleet_role.arn
  
  target_capacity = 2
  allocation_strategy = "diversified"
  
  launch_specification {
    ami           = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    
    subnet_id              = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_security_group.web.id]
    
    user_data = base64encode(templatefile("${path.module}/user_data.sh", {
      app_name = "fleet-app"
      environment = "production"
    }))
    
    tags = {
      Name        = "Spot Fleet Instance"
      Environment = "production"
      Type        = "Spot Fleet"
    }
  }
  
  launch_specification {
    ami           = data.aws_ami.amazon_linux.id
    instance_type = "t3.small"
    
    subnet_id              = aws_subnet.public[1].id
    vpc_security_group_ids = [aws_security_group.web.id]
    
    user_data = base64encode(templatefile("${path.module}/user_data.sh", {
      app_name = "fleet-app"
      environment = "production"
    }))
    
    tags = {
      Name        = "Spot Fleet Instance"
      Environment = "production"
      Type        = "Spot Fleet"
    }
  }
}

# IAM role for spot fleet
resource "aws_iam_role" "spot_fleet_role" {
  name = "spot-fleet-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "spotfleet.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "spot_fleet_policy" {
  role       = aws_iam_role.spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
```

## 🔧 Configuration Options

### **Instance Configuration**
```hcl
resource "aws_instance" "custom" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Network configuration
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  
  # Storage configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.delete_on_termination
    encrypted             = var.encrypted
  }
  
  # Additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.additional_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_type = ebs_block_device.value.volume_type
      volume_size = ebs_block_device.value.volume_size
      encrypted   = ebs_block_device.value.encrypted
    }
  }
  
  # User data
  user_data = var.user_data
  
  # IAM instance profile
  iam_instance_profile = var.iam_instance_profile
  
  # Key pair
  key_name = var.key_name
  
  # Monitoring
  monitoring = var.monitoring
  
  # Placement
  availability_zone = var.availability_zone
  
  tags = merge(var.common_tags, {
    Name = var.instance_name
  })
}
```

### **Advanced Instance Configuration**
```hcl
resource "aws_instance" "advanced" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  
  # Network configuration
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  
  # Storage configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    
    tags = {
      Name        = "Advanced Instance Root Volume"
      Environment = "production"
    }
  }
  
  # Additional EBS volumes
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    iops        = 3000
    throughput  = 125
    
    tags = {
      Name        = "Advanced Instance Data Volume"
      Environment = "production"
    }
  }
  
  # User data with advanced configuration
  user_data = base64encode(templatefile("${path.module}/advanced_user_data.sh", {
    app_name     = "advanced-app"
    environment  = "production"
    db_host      = var.database_host
    db_port      = var.database_port
    db_name      = var.database_name
    db_user      = var.database_user
    s3_bucket    = var.s3_bucket
    log_level    = var.log_level
  }))
  
  # IAM instance profile
  iam_instance_profile = aws_iam_instance_profile.app_profile.name
  
  # Key pair
  key_name = aws_key_pair.app_key.key_name
  
  # Monitoring
  monitoring = true
  
  # Placement
  availability_zone = data.aws_availability_zones.available.names[0]
  
  # Tenancy
  tenancy = "default"
  
  # Hibernation
  hibernation = false
  
  # Credit specification
  credit_specification {
    cpu_credits = "standard"
  }
  
  # Metadata options
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }
  
  tags = {
    Name        = "Advanced Instance"
    Environment = "production"
    Project     = "advanced-app"
  }
}
```

### **Instance with Multiple Network Interfaces**
```hcl
# Network interface
resource "aws_network_interface" "app" {
  subnet_id       = aws_subnet.private[0].id
  security_groups = [aws_security_group.app.id]
  
  tags = {
    Name        = "App Network Interface"
    Environment = "production"
  }
}

# EC2 instance with network interface
resource "aws_instance" "app_with_eni" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  
  network_interface {
    network_interface_id = aws_network_interface.app.id
    device_index         = 0
  }
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }
  
  tags = {
    Name        = "App Instance with ENI"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple web server
resource "aws_instance" "simple_web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World</h1>" > /var/www/html/index.html
  EOF
  )
  
  tags = {
    Name = "Simple Web Server"
  }
}
```

### **Production Deployment**
```hcl
# Production web application
locals {
  web_instances = {
    "web-1" = {
      subnet_id = aws_subnet.public[0].id
      az        = data.aws_availability_zones.available.names[0]
    }
    "web-2" = {
      subnet_id = aws_subnet.public[1].id
      az        = data.aws_availability_zones.available.names[1]
    }
  }
}

# Production web instances
resource "aws_instance" "web_production" {
  for_each = local.web_instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  availability_zone          = each.value.az
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    throughput            = 125
  }
  
  user_data = base64encode(templatefile("${path.module}/production_user_data.sh", {
    app_name     = "production-app"
    environment  = "production"
    db_host      = aws_db_instance.main.endpoint
    db_port      = aws_db_instance.main.port
    db_name      = aws_db_instance.main.db_name
    s3_bucket    = aws_s3_bucket.app_data.bucket
    log_level    = "INFO"
  }))
  
  iam_instance_profile = aws_iam_instance_profile.web_profile.name
  
  monitoring = true
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  tags = {
    Name        = each.key
    Environment = "production"
    Project     = "production-app"
    Role        = "web-server"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment EC2 setup
locals {
  environments = {
    dev = {
      instance_type = "t3.micro"
      instance_count = 1
      volume_size = 20
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
      volume_size = 30
    }
    prod = {
      instance_type = "t3.medium"
      instance_count = 3
      volume_size = 50
    }
  }
}

# Environment-specific instances
resource "aws_instance" "environment" {
  for_each = local.environments
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  count = each.value.instance_count
  
  subnet_id                   = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.volume_size
    delete_on_termination = true
    encrypted             = true
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name    = "multi-env-app"
    environment = each.key
  }))
  
  tags = {
    Name        = "${each.key}-web-${count.index + 1}"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/app-logs"
  retention_in_days = 30
  
  tags = {
    Name        = "App Logs"
    Environment = "production"
  }
}

# CloudWatch agent configuration
resource "aws_ssm_parameter" "cloudwatch_agent" {
  name  = "/aws/ec2/cloudwatch-agent/config"
  type  = "String"
  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/app.log"
              log_group_name = "/aws/ec2/app-logs"
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
  })
  
  tags = {
    Name        = "CloudWatch Agent Config"
    Environment = "production"
  }
}

# EC2 instance with CloudWatch agent
resource "aws_instance" "monitored" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  
  user_data = base64encode(templatefile("${path.module}/monitored_user_data.sh", {
    log_group_name = aws_cloudwatch_log_group.app_logs.name
    region         = data.aws_region.current.name
  }))
  
  iam_instance_profile = aws_iam_instance_profile.monitored_profile.name
  
  tags = {
    Name        = "Monitored Instance"
    Environment = "production"
  }
}

# IAM role for CloudWatch agent
resource "aws_iam_role" "monitored_role" {
  name = "monitored-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "monitored_policy" {
  role       = aws_iam_role.monitored_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "monitored_profile" {
  name = "monitored-instance-profile"
  role = aws_iam_role.monitored_role.name
}
```

### **Custom Metrics**
```hcl
# CloudWatch custom metric
resource "aws_cloudwatch_metric_alarm" "custom_metric" {
  alarm_name          = "custom-metric-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CustomMetric"
  namespace           = "Custom/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors custom application metric"
  
  dimensions = {
    InstanceId = aws_instance.monitored.id
  }
  
  tags = {
    Name        = "Custom Metric Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **Security Groups**
```hcl
# Restrictive security group
resource "aws_security_group" "restrictive" {
  name_prefix = "restrictive-"
  vpc_id      = aws_vpc.main.id
  
  # Allow HTTP from specific IP ranges
  ingress {
    description = "HTTP from office"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  # Allow HTTPS from specific IP ranges
  ingress {
    description = "HTTPS from office"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  # Allow SSH from specific IP ranges
  ingress {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Office IP range
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Restrictive Security Group"
    Environment = "production"
  }
}
```

### **Encryption**
```hcl
# KMS key for EBS encryption
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "EBS Encryption Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs-encryption"
  target_key_id = aws_kms_key.ebs.key_id
}

# EC2 instance with encrypted EBS
resource "aws_instance" "encrypted" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
    kms_key_id           = aws_kms_key.ebs.arn
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    kms_key_id  = aws_kms_key.ebs.arn
  }
  
  tags = {
    Name        = "Encrypted Instance"
    Environment = "production"
  }
}
```

### **IAM Roles and Policies**
```hcl
# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for EC2 instance
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2-instance-policy"
  description = "Policy for EC2 instance"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
```

## 💰 Cost Optimization

### **Reserved Instances**
```hcl
# Reserved instance
resource "aws_ec2_capacity_reservation" "reserved" {
  instance_type     = "t3.medium"
  instance_platform = "Linux/UNIX"
  availability_zone = data.aws_availability_zones.available.names[0]
  instance_count    = 1
  
  tags = {
    Name        = "Reserved Instance"
    Environment = "production"
  }
}
```

### **Spot Instances for Cost Optimization**
```hcl
# Spot instance for cost optimization
resource "aws_spot_instance_request" "cost_optimized" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  
  spot_price    = "0.05"
  spot_type     = "one-time"
  wait_for_fulfillment = true
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name = "cost-optimized-app"
    environment = "production"
  }))
  
  tags = {
    Name        = "Cost Optimized Spot Instance"
    Environment = "production"
    Type        = "Spot"
  }
}
```

### **Auto Scaling for Cost Optimization**
```hcl
# Auto Scaling Group with cost optimization
resource "aws_autoscaling_group" "cost_optimized" {
  name                = "cost-optimized-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  
  min_size         = 1
  max_size         = 5
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.cost_optimized.id
    version = "$Latest"
  }
  
  # Mixed instance policy for cost optimization
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cost_optimized.id
        version            = "$Latest"
      }
      
      override {
        instance_type = "t3.small"
      }
      
      override {
        instance_type = "t3.medium"
      }
    }
    
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 50
      spot_allocation_strategy                 = "diversified"
    }
  }
  
  tag {
    key                 = "Name"
    value               = "Cost Optimized ASG Instance"
    propagate_at_launch = true
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Instance Not Accessible**
```hcl
# Debug security group
resource "aws_security_group" "debug" {
  name_prefix = "debug-"
  vpc_id      = aws_vpc.main.id
  
  # Allow all traffic for debugging
  ingress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "Debug Security Group"
    Environment = "production"
  }
}

# Debug instance
resource "aws_instance" "debug" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.debug.id]
  associate_public_ip_address = true
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Debug Server</h1>" > /var/www/html/index.html
  EOF
  )
  
  tags = {
    Name        = "Debug Instance"
    Environment = "production"
  }
}
```

#### **Issue: EBS Volume Not Attaching**
```hcl
# Debug EBS volume attachment
resource "aws_ebs_volume" "debug" {
  availability_zone = aws_instance.debug.availability_zone
  size              = 20
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name        = "Debug EBS Volume"
    Environment = "production"
  }
}

resource "aws_volume_attachment" "debug" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.debug.id
  instance_id = aws_instance.debug.id
  
  # Force detach if needed
  force_detach = true
}
```

#### **Issue: User Data Not Executing**
```hcl
# Debug user data
resource "aws_instance" "user_data_debug" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Log user data execution
    echo "User data started at $(date)" >> /var/log/user-data.log
    
    # Update system
    yum update -y
    
    # Install packages
    yum install -y httpd
    
    # Start services
    systemctl start httpd
    systemctl enable httpd
    
    # Create test page
    echo "<h1>User Data Debug Server</h1>" > /var/www/html/index.html
    
    # Log completion
    echo "User data completed at $(date)" >> /var/log/user-data.log
  EOF
  )
  
  tags = {
    Name        = "User Data Debug Instance"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **Web Application Stack**
```hcl
# Complete web application stack
locals {
  web_app_config = {
    instance_type = "t3.small"
    instance_count = 2
    volume_size = 30
    environment = "production"
  }
}

# Web application instances
resource "aws_instance" "web_app" {
  count = local.web_app_config.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.web_app_config.instance_type
  
  subnet_id                   = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = local.web_app_config.volume_size
    delete_on_termination = true
    encrypted             = true
  }
  
  user_data = base64encode(templatefile("${path.module}/web_app_user_data.sh", {
    app_name     = "web-app"
    environment  = local.web_app_config.environment
    db_host      = aws_db_instance.main.endpoint
    db_port      = aws_db_instance.main.port
    db_name      = aws_db_instance.main.db_name
    s3_bucket    = aws_s3_bucket.app_data.bucket
    redis_host   = aws_elasticache_cluster.main.cache_nodes[0].address
  }))
  
  iam_instance_profile = aws_iam_instance_profile.web_app_profile.name
  
  tags = {
    Name        = "Web App ${count.index + 1}"
    Environment = local.web_app_config.environment
    Project     = "web-app"
    Role        = "web-server"
  }
}
```

### **Database Server**
```hcl
# Database server instance
resource "aws_instance" "database" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  
  subnet_id                   = aws_subnet.database[0].id
  vpc_security_group_ids      = [aws_security_group.database.id]
  associate_public_ip_address = false
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
  }
  
  user_data = base64encode(templatefile("${path.module}/database_user_data.sh", {
    db_type     = "mysql"
    db_version  = "8.0"
    db_name     = "app_database"
    db_user     = "app_user"
    backup_s3_bucket = aws_s3_bucket.database_backups.bucket
  }))
  
  iam_instance_profile = aws_iam_instance_profile.database_profile.name
  
  tags = {
    Name        = "Database Server"
    Environment = "production"
    Project     = "web-app"
    Role        = "database-server"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **VPC**: Network placement and security
- **EBS**: Persistent storage
- **S3**: Object storage and backups
- **RDS**: Managed database services
- **ELB**: Load balancing
- **Auto Scaling**: Automatic scaling
- **CloudWatch**: Monitoring and logging
- **IAM**: Access control and roles

### **Service Dependencies**
- **Security Groups**: Network security
- **Key Pairs**: SSH access
- **IAM Roles**: Service permissions
- **EBS Volumes**: Storage
- **VPC Subnets**: Network placement
- **Route Tables**: Network routing

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic EC2 examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect EC2 with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and monitoring
6. **Optimize**: Focus on cost and performance

**Your EC2 Mastery Journey Continues with S3!** 🚀

---

*This comprehensive EC2 guide provides everything you need to master AWS Elastic Compute Cloud with Terraform. Each example is production-ready and follows security best practices.*
