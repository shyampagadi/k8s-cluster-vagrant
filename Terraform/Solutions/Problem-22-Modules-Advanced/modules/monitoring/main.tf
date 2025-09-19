# Monitoring Module
# This module creates CloudWatch log groups and alarms

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ec2/${var.project_name}-${var.project_suffix}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-log-group-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "monitoring"
  }
}

# Create CloudWatch log stream
resource "aws_cloudwatch_log_stream" "main" {
  name           = "application-logs"
  log_group_name = aws_cloudwatch_log_group.main.name
}

# Create CloudWatch alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-${var.project_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []

  tags = {
    Name        = "${var.project_name}-high-cpu-alarm-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "monitoring"
  }
}

# Create CloudWatch alarm for low CPU
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu-${var.project_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []

  tags = {
    Name        = "${var.project_name}-low-cpu-alarm-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "monitoring"
  }
}

# Create CloudWatch alarm for high memory
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-high-memory-${var.project_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 memory utilization"
  alarm_actions       = []

  tags = {
    Name        = "${var.project_name}-high-memory-alarm-${var.project_suffix}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "monitoring"
  }
}

# Create CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard-${var.project_suffix}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-west-2"
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      }
    ]
  })
}
