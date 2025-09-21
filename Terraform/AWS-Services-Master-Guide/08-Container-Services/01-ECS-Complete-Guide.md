# ECS (Elastic Container Service) - Complete Terraform Guide

## 🎯 Overview

Amazon Elastic Container Service (ECS) is a fully managed container orchestration service that makes it easy to run, stop, and manage Docker containers on a cluster. ECS eliminates the need to install and operate your own container orchestration software.

### **What is ECS?**
ECS is a highly scalable, high-performance container orchestration service that supports Docker containers and allows you to easily run applications on a managed cluster of Amazon EC2 instances.

### **Key Concepts**
- **Clusters**: Logical grouping of container instances
- **Task Definitions**: Blueprint for your application
- **Tasks**: Running instances of task definitions
- **Services**: Maintains desired number of tasks
- **Container Instances**: EC2 instances running ECS agent
- **Fargate**: Serverless compute for containers
- **Service Discovery**: Automatic service registration
- **Load Balancing**: Distribute traffic across tasks
- **Auto Scaling**: Scale services based on metrics

### **When to Use ECS**
- **Container orchestration** - Run Docker containers at scale
- **Microservices architecture** - Deploy microservices
- **CI/CD pipelines** - Automated deployments
- **Serverless containers** - Use Fargate for serverless
- **Hybrid deployments** - Mix EC2 and Fargate
- **Service discovery** - Automatic service registration
- **Load balancing** - Distribute traffic
- **Auto scaling** - Scale based on demand

## 🏗️ Architecture Patterns

### **Basic ECS Structure**
```
ECS Cluster
├── Task Definitions (Application Blueprints)
├── Services (Maintain Desired Tasks)
├── Tasks (Running Containers)
├── Container Instances (EC2/Fargate)
├── Load Balancers (Traffic Distribution)
└── Auto Scaling (Dynamic Scaling)
```

### **Fargate vs EC2 Pattern**
```
ECS Cluster
├── Fargate Tasks (Serverless)
│   ├── No Server Management
│   ├── Pay Per Task
│   └── Automatic Scaling
└── EC2 Tasks (Managed Instances)
    ├── Server Management
    ├── Pay Per Instance
    └── Manual Scaling
```

## 📝 Terraform Implementation

### **Basic ECS Setup**
```hcl
# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Main ECS Cluster"
    Environment = "production"
  }
}

# ECS cluster capacity providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Task definition
resource "aws_ecs_task_definition" "main" {
  family                   = "main-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "main-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "Main Task Definition"
    Environment = "production"
  }
}

# ECS service
resource "aws_ecs_service" "main" {
  name            = "main-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "main-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs]

  tags = {
    Name        = "Main ECS Service"
    Environment = "production"
  }
}
```

### **ECS with Auto Scaling**
```hcl
# ECS service with auto scaling
resource "aws_ecs_service" "scaled" {
  name            = "scaled-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "main-container"
    container_port   = 80
  }

  tags = {
    Name        = "Scaled ECS Service"
    Environment = "production"
  }
}

# Auto scaling target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.scaled.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto scaling policy
resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "ecs-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

### **ECS with Service Discovery**
```hcl
# Service discovery namespace
resource "aws_service_discovery_private_dns_namespace" "ecs" {
  name        = "ecs.local"
  description = "ECS service discovery namespace"
  vpc         = aws_vpc.main.id

  tags = {
    Name        = "ECS Service Discovery Namespace"
    Environment = "production"
  }
}

# Service discovery service
resource "aws_service_discovery_service" "ecs" {
  name = "ecs-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30

  tags = {
    Name        = "ECS Service Discovery Service"
    Environment = "production"
  }
}

# ECS service with service discovery
resource "aws_ecs_service" "discovered" {
  name            = "discovered-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip  = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ecs.arn
  }

  tags = {
    Name        = "Discovered ECS Service"
    Environment = "production"
  }
}
```

### **ECS with EC2 Launch Type**
```hcl
# ECS cluster for EC2
resource "aws_ecs_cluster" "ec2" {
  name = "ec2-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "EC2 ECS Cluster"
    Environment = "production"
  }
}

# ECS cluster capacity providers for EC2
resource "aws_ecs_cluster_capacity_providers" "ec2" {
  cluster_name = aws_ecs_cluster.ec2.name

  capacity_providers = ["EC2"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "EC2"
  }
}

# EC2 capacity provider
resource "aws_ecs_capacity_provider" "ec2" {
  name = "EC2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = {
    Name        = "EC2 Capacity Provider"
    Environment = "production"
  }
}

# Auto Scaling Group for ECS
resource "aws_autoscaling_group" "ecs" {
  name                = "ecs-autoscaling-group"
  vpc_zone_identifier  = aws_subnet.private[*].id
  target_group_arns    = [aws_lb_target_group.ecs.arn]
  health_check_type    = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 10
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tags = {
    Name        = "ECS Auto Scaling Group"
    Environment = "production"
  }
}

# Launch Template for ECS
resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.ecs.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  user_data = base64encode(templatefile("${path.module}/ecs_user_data.sh", {
    cluster_name = aws_ecs_cluster.ec2.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ECS Instance"
      Environment = "production"
    }
  }

  tags = {
    Name        = "ECS Launch Template"
    Environment = "production"
  }
}

# ECS service with EC2 launch type
resource "aws_ecs_service" "ec2" {
  name            = "ec2-service"
  cluster         = aws_ecs_cluster.ec2.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "main-container"
    container_port   = 80
  }

  tags = {
    Name        = "EC2 ECS Service"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **ECS Task Definition Configuration**
```hcl
resource "aws_ecs_task_definition" "custom" {
  family                   = var.family
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = var.container_definitions

  # Volume configuration
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name
      efs_volume_configuration {
        file_system_id = volume.value.efs_file_system_id
        root_directory = volume.value.root_directory
      }
    }
  }

  tags = merge(var.common_tags, {
    Name = var.family
  })
}
```

### **Advanced ECS Configuration**
```hcl
# Advanced ECS cluster
resource "aws_ecs_cluster" "advanced" {
  name = "advanced-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_execute_command.name
      }
    }
  }

  tags = {
    Name        = "Advanced ECS Cluster"
    Environment = "production"
  }
}

# Advanced task definition
resource "aws_ecs_task_definition" "advanced" {
  family                   = "advanced-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "advanced-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]
      secrets = [
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.main.arn
        }
      ]
    }
  ])

  tags = {
    Name        = "Advanced Task Definition"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple ECS setup
resource "aws_ecs_cluster" "simple" {
  name = "simple-cluster"

  tags = {
    Name = "Simple ECS Cluster"
  }
}

resource "aws_ecs_task_definition" "simple" {
  family                   = "simple-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "simple-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}
```

### **Production Deployment**
```hcl
# Production ECS setup
locals {
  ecs_config = {
    cluster_name = "production-cluster"
    task_family = "production-task"
    cpu = "512"
    memory = "1024"
    desired_count = 3
    max_capacity = 10
    min_capacity = 2
  }
}

# Production ECS cluster
resource "aws_ecs_cluster" "production" {
  name = local.ecs_config.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Production ECS Cluster"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production task definition
resource "aws_ecs_task_definition" "production" {
  family                   = local.ecs_config.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.ecs_config.cpu
  memory                   = local.ecs_config.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "production-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "Production Task Definition"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production ECS service
resource "aws_ecs_service" "production" {
  name            = "production-service"
  cluster         = aws_ecs_cluster.production.id
  task_definition = aws_ecs_task_definition.production.arn
  desired_count   = local.ecs_config.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "production-container"
    container_port   = 80
  }

  tags = {
    Name        = "Production ECS Service"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment ECS setup
locals {
  environments = {
    dev = {
      cluster_name = "dev-cluster"
      task_family = "dev-task"
      cpu = "256"
      memory = "512"
      desired_count = 1
    }
    staging = {
      cluster_name = "staging-cluster"
      task_family = "staging-task"
      cpu = "512"
      memory = "1024"
      desired_count = 2
    }
    prod = {
      cluster_name = "prod-cluster"
      task_family = "prod-task"
      cpu = "1024"
      memory = "2048"
      desired_count = 3
    }
  }
}

# Environment-specific ECS clusters
resource "aws_ecs_cluster" "environment" {
  for_each = local.environments

  name = each.value.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${title(each.key)} ECS Cluster"
    Environment = each.key
    Project     = "multi-env-app"
  }
}

# Environment-specific task definitions
resource "aws_ecs_task_definition" "environment" {
  for_each = local.environments

  family                   = each.value.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${each.key}-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${title(each.key)} Task Definition"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/aws/ecs/tasks"
  retention_in_days = 30

  tags = {
    Name        = "ECS Logs"
    Environment = "production"
  }
}

# CloudWatch log group for ECS execute command
resource "aws_cloudwatch_log_group" "ecs_execute_command" {
  name              = "/aws/ecs/execute-command"
  retention_in_days = 30

  tags = {
    Name        = "ECS Execute Command Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for ECS tasks
resource "aws_cloudwatch_log_metric_filter" "ecs_tasks" {
  name           = "ECSTasks"
  log_group_name = aws_cloudwatch_log_group.ecs_logs.name
  pattern        = "[timestamp, request_id, event_name=\"RunTask\", ...]"

  metric_transformation {
    name      = "ECSTasks"
    namespace = "ECS/Tasks"
    value     = "1"
  }
}

# CloudWatch alarm for ECS service
resource "aws_cloudwatch_metric_alarm" "ecs_service" {
  alarm_name          = "ECSServiceAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ECS service"

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = {
    Name        = "ECS Service Alarm"
    Environment = "production"
  }
}
```

### **ECS Insights**
```hcl
# ECS cluster with insights
resource "aws_ecs_cluster" "insights" {
  name = "insights-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Insights ECS Cluster"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **IAM Roles**
```hcl
# ECS execution role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS task role
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECS task role policy
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

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
      }
    ]
  })
}
```

### **Security Groups**
```hcl
# Security group for ECS
resource "aws_security_group" "ecs" {
  name_prefix = "ecs-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ECS Security Group"
    Environment = "production"
  }
}
```

### **Secrets Management**
```hcl
# Secrets Manager secret for ECS
resource "aws_secretsmanager_secret" "ecs_secret" {
  name = "ecs-secret"

  tags = {
    Name        = "ECS Secret"
    Environment = "production"
  }
}

# Task definition with secrets
resource "aws_ecs_task_definition" "with_secrets" {
  family                   = "with-secrets-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "secrets-container"
      image = "nginx:latest"
      secrets = [
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.ecs_secret.arn
        }
      ]
    }
  ])

  tags = {
    Name        = "With Secrets Task Definition"
    Environment = "production"
  }
}
```

## 💰 Cost Optimization

### **Fargate Spot**
```hcl
# ECS cluster with Fargate Spot
resource "aws_ecs_cluster" "fargate_spot" {
  name = "fargate-spot-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Fargate Spot ECS Cluster"
    Environment = "production"
  }
}

# ECS cluster capacity providers for Fargate Spot
resource "aws_ecs_cluster_capacity_providers" "fargate_spot" {
  cluster_name = aws_ecs_cluster.fargate_spot.name

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

# ECS service with Fargate Spot
resource "aws_ecs_service" "fargate_spot" {
  name            = "fargate-spot-service"
  cluster         = aws_ecs_cluster.fargate_spot.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "Fargate Spot ECS Service"
    Environment = "production"
  }
}
```

### **Resource Optimization**
```hcl
# Cost-optimized task definition
resource "aws_ecs_task_definition" "cost_optimized" {
  family                   = "cost-optimized-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "cost-optimized-container"
      image = "nginx:alpine"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "Cost Optimized Task Definition"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: Tasks Not Starting**
```hcl
# Debug ECS cluster
resource "aws_ecs_cluster" "debug" {
  name = "debug-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Debug ECS Cluster"
    Environment = "production"
  }
}

# Debug task definition
resource "aws_ecs_task_definition" "debug" {
  family                   = "debug-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "debug-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "Debug Task Definition"
    Environment = "production"
  }
}
```

#### **Issue: Service Not Scaling**
```hcl
# Debug auto scaling
resource "aws_appautoscaling_target" "debug_target" {
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Debug auto scaling policy
resource "aws_appautoscaling_policy" "debug_policy" {
  name               = "debug-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.debug_target.resource_id
  scalable_dimension = aws_appautoscaling_target.debug_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.debug_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

## 📚 Real-World Examples

### **E-Commerce ECS Setup**
```hcl
# E-commerce ECS setup
locals {
  ecommerce_config = {
    cluster_name = "ecommerce-cluster"
    task_family = "ecommerce-task"
    cpu = "1024"
    memory = "2048"
    desired_count = 3
    max_capacity = 10
    min_capacity = 2
  }
}

# E-commerce ECS cluster
resource "aws_ecs_cluster" "ecommerce" {
  name = local.ecommerce_config.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "E-commerce ECS Cluster"
    Environment = "production"
    Project     = "ecommerce"
  }
}

# E-commerce task definition
resource "aws_ecs_task_definition" "ecommerce" {
  family                   = local.ecommerce_config.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.ecommerce_config.cpu
  memory                   = local.ecommerce_config.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "ecommerce-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]
    }
  ])

  tags = {
    Name        = "E-commerce Task Definition"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices ECS Setup**
```hcl
# Microservices ECS setup
resource "aws_ecs_cluster" "microservices" {
  name = "microservices-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Microservices ECS Cluster"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices task definitions
resource "aws_ecs_task_definition" "microservices" {
  for_each = toset([
    "user-service",
    "product-service",
    "order-service",
    "payment-service"
  ])

  family                   = "${each.value}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${each.value}-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "SERVICE_NAME"
          value = each.value
        }
      ]
    }
  ])

  tags = {
    Name        = "Microservices ${title(each.value)} Task Definition"
    Environment = "production"
    Project     = "microservices"
    Service     = each.value
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **ALB**: Load balancing
- **CloudWatch**: Monitoring and logging
- **Secrets Manager**: Secret management
- **S3**: Object storage
- **RDS**: Database connectivity
- **SNS**: Notifications
- **SQS**: Message queuing
- **Service Discovery**: Service registration

### **Service Dependencies**
- **IAM**: Access control
- **VPC**: Networking
- **EC2**: Container instances
- **CloudWatch**: Monitoring
- **Secrets Manager**: Secret management

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic ECS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect ECS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your ECS Mastery Journey Continues with EFS!** 🚀

---

*This comprehensive ECS guide provides everything you need to master AWS Elastic Container Service with Terraform. Each example is production-ready and follows security best practices.*
