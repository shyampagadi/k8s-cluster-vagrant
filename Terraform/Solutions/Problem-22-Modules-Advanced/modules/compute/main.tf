# Compute Module
# This module creates EC2 instances and auto scaling groups

# Data source to get the latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create launch template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-${var.project_suffix}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_ids.web]

  user_data = base64encode(templatefile("${path.module}/../templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    instance_type = var.instance_type
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-instance-${var.project_suffix}"
      Environment = var.environment
      Project     = var.project_name
      Module      = "compute"
    }
  }

  tags = {
    Name        = "${var.project_name}-lt-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "compute"
  }
}

# Create auto scaling group
resource "aws_autoscaling_group" "main" {
  count = var.enable_auto_scaling ? 1 : 0

  name                = "${var.project_name}-asg-${var.project_suffix}"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = []
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-${var.project_suffix}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Module"
    value               = "compute"
    propagate_at_launch = true
  }
}

# Create scaling policy
resource "aws_autoscaling_policy" "scale_up" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.project_name}-scale-up-${var.project_suffix}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

resource "aws_autoscaling_policy" "scale_down" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.project_name}-scale-down-${var.project_suffix}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

# Create CloudWatch alarms for scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_auto_scaling ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-high-${var.project_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_auto_scaling ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-low-${var.project_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }
}

# Create standalone instances (if auto scaling is disabled)
resource "aws_instance" "standalone" {
  count = var.enable_auto_scaling ? 0 : var.desired_capacity

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.security_group_ids.web]

  user_data = base64encode(templatefile("${path.module}/../templates/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    instance_type = var.instance_type
  }))

  tags = {
    Name        = "${var.project_name}-standalone-${count.index + 1}-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "compute"
  }
}
