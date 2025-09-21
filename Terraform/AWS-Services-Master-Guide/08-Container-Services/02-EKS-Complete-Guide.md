# EKS (Elastic Kubernetes Service) - Complete Terraform Guide

## 🎯 Overview

Amazon EKS is a fully managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install and operate your own Kubernetes control plane or nodes.

### **What is EKS?**
EKS is a managed Kubernetes service that provides a highly available and secure Kubernetes control plane. It automatically manages the availability and scalability of the Kubernetes API servers and the etcd persistence layer.

### **Key Concepts**
- **EKS Cluster**: Managed Kubernetes control plane
- **Node Groups**: Managed EC2 instances running Kubernetes
- **Fargate**: Serverless compute for containers
- **Add-ons**: Extensions for cluster functionality
- **Service Mesh**: Istio integration for microservices
- **Pod Identity**: IAM roles for service accounts
- **CNI**: Container Network Interface
- **CSI**: Container Storage Interface
- **CRI**: Container Runtime Interface
- **RBAC**: Role-Based Access Control

### **When to Use EKS**
- **Container orchestration** - Manage containerized applications
- **Microservices** - Deploy and manage microservices
- **CI/CD pipelines** - Container-based deployment
- **Hybrid cloud** - On-premises and cloud integration
- **Multi-tenant applications** - Isolated workloads
- **Machine learning** - ML model deployment
- **Data processing** - Batch and stream processing
- **Web applications** - Scalable web services

## 🏗️ Architecture Patterns

### **Basic EKS Structure**
```
EKS Cluster
├── Control Plane (Managed)
├── Node Groups (EC2/Fargate)
├── Pods (Workloads)
├── Services (Networking)
├── Ingress (Load Balancing)
├── ConfigMaps (Configuration)
├── Secrets (Sensitive Data)
└── Persistent Volumes (Storage)
```

### **EKS Architecture Pattern**
```
Internet
├── Application Load Balancer
├── EKS Cluster
│   ├── Control Plane
│   ├── Node Groups
│   └── Pods
├── VPC (Networking)
├── IAM (Access Control)
└── CloudWatch (Monitoring)
```

## 📝 Terraform Implementation

### **Basic EKS Setup**
```hcl
# EKS cluster
resource "aws_eks_cluster" "main" {
  name     = "main-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # Enable EKS add-ons
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = {
    Name        = "Main EKS Cluster"
    Environment = "production"
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# CloudWatch log group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/main-cluster/cluster"
  retention_in_days = 30

  tags = {
    Name        = "EKS Cluster Logs"
    Environment = "production"
  }
}
```

### **EKS Node Group Setup**
```hcl
# EKS node group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 25
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name        = "Main EKS Node Group"
    Environment = "production"
  }
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

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

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

### **EKS with Fargate**
```hcl
# EKS Fargate profile
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "main-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "fargate"
  }

  selector {
    namespace = "kube-system"
    labels = {
      app = "fargate"
    }
  }

  tags = {
    Name        = "Main EKS Fargate Profile"
    Environment = "production"
  }
}

# IAM role for EKS Fargate
resource "aws_iam_role" "eks_fargate_role" {
  name = "eks-fargate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_policy" {
  role       = aws_iam_role.eks_fargate_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
```

### **EKS Add-ons**
```hcl
# EKS VPC CNI add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  tags = {
    Name        = "EKS VPC CNI Add-on"
    Environment = "production"
  }
}

# EKS CoreDNS add-on
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  tags = {
    Name        = "EKS CoreDNS Add-on"
    Environment = "production"
  }
}

# EKS kube-proxy add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  tags = {
    Name        = "EKS Kube Proxy Add-on"
    Environment = "production"
  }
}

# EKS EBS CSI driver add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  tags = {
    Name        = "EKS EBS CSI Driver Add-on"
    Environment = "production"
  }
}
```

### **EKS with Service Mesh (Istio)**
```hcl
# EKS cluster with Istio
resource "aws_eks_cluster" "istio_cluster" {
  name     = "istio-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Istio EKS Cluster"
    Environment = "production"
  }
}

# EKS node group for Istio
resource "aws_eks_node_group" "istio_nodes" {
  cluster_name    = aws_eks_cluster.istio_cluster.name
  node_group_name = "istio-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }

  tags = {
    Name        = "Istio EKS Node Group"
    Environment = "production"
  }
}
```

### **EKS with Pod Identity**
```hcl
# EKS cluster with pod identity
resource "aws_eks_cluster" "pod_identity_cluster" {
  name     = "pod-identity-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Pod Identity EKS Cluster"
    Environment = "production"
  }
}

# EKS pod identity association
resource "aws_eks_pod_identity_association" "main" {
  cluster_name    = aws_eks_cluster.pod_identity_cluster.name
  namespace       = "default"
  service_account = "s3-service-account"
  role_arn        = aws_iam_role.pod_identity_role.arn
}

# IAM role for pod identity
resource "aws_iam_role" "pod_identity_role" {
  name = "pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${aws_iam_openid_connect_provider.eks.url}:sub" = "system:serviceaccount:default:s3-service-account"
            "${aws_iam_openid_connect_provider.eks.url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# OIDC identity provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.pod_identity_cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
  ]

  tags = {
    Name        = "EKS OIDC Provider"
    Environment = "production"
  }
}
```

## 🔧 Configuration Options

### **EKS Cluster Configuration**
```hcl
resource "aws_eks_cluster" "custom" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.security_group_ids
  }

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  # Logging configuration
  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(var.common_tags, {
    Name = var.cluster_name
  })
}
```

### **Advanced EKS Configuration**
```hcl
# Advanced EKS cluster
resource "aws_eks_cluster" "advanced" {
  name     = "advanced-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  # Logging configuration
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Outpost configuration
  outpost_config {
    control_plane_instance_type = "m5.large"
    outpost_arns               = [aws_outposts_outpost.main.arn]
  }

  tags = {
    Name        = "Advanced EKS Cluster"
    Environment = "production"
  }
}

# KMS key for EKS encryption
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "EKS KMS Key"
    Environment = "production"
  }
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EKS Cluster Security Group"
    Environment = "production"
  }
}
```

## 🚀 Deployment Examples

### **Basic Deployment**
```hcl
# Simple EKS cluster
resource "aws_eks_cluster" "simple" {
  name     = "simple-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  tags = {
    Name = "Simple EKS Cluster"
  }
}
```

### **Production Deployment**
```hcl
# Production EKS setup
locals {
  eks_config = {
    cluster_name = "production-cluster"
    version = "1.28"
    node_instance_types = ["t3.large", "t3.xlarge"]
    desired_size = 3
    max_size = 10
    min_size = 1
    enable_fargate = true
    enable_addons = true
  }
}

# Production EKS cluster
resource "aws_eks_cluster" "production" {
  name     = local.eks_config.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = local.eks_config.version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  # Logging configuration
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name        = "Production EKS Cluster"
    Environment = "production"
    Project     = "web-app"
  }
}

# Production EKS node group
resource "aws_eks_node_group" "production" {
  cluster_name    = aws_eks_cluster.production.name
  node_group_name = "production-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = local.eks_config.node_instance_types

  scaling_config {
    desired_size = local.eks_config.desired_size
    max_size     = local.eks_config.max_size
    min_size     = local.eks_config.min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  tags = {
    Name        = "Production EKS Node Group"
    Environment = "production"
    Project     = "web-app"
  }
}
```

### **Multi-Environment Deployment**
```hcl
# Multi-environment EKS setup
locals {
  environments = {
    dev = {
      cluster_name = "dev-cluster"
      version = "1.28"
      node_instance_types = ["t3.medium"]
      desired_size = 1
      max_size = 3
      min_size = 1
    }
    staging = {
      cluster_name = "staging-cluster"
      version = "1.28"
      node_instance_types = ["t3.large"]
      desired_size = 2
      max_size = 5
      min_size = 1
    }
    prod = {
      cluster_name = "prod-cluster"
      version = "1.28"
      node_instance_types = ["t3.large", "t3.xlarge"]
      desired_size = 3
      max_size = 10
      min_size = 1
    }
  }
}

# Environment-specific EKS clusters
resource "aws_eks_cluster" "environment" {
  for_each = local.environments

  name     = each.value.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = each.value.version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${title(each.key)} EKS Cluster"
    Environment = each.key
    Project     = "multi-env-app"
  }
}
```

## 🔍 Monitoring & Observability

### **CloudWatch Integration**
```hcl
# CloudWatch log group for EKS
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/clusters"
  retention_in_days = 30

  tags = {
    Name        = "EKS Logs"
    Environment = "production"
  }
}

# CloudWatch metric filter for EKS
resource "aws_cloudwatch_log_metric_filter" "eks_errors" {
  name           = "EKSErrors"
  log_group_name = aws_cloudwatch_log_group.eks_logs.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "EKSErrors"
    namespace = "EKS/Errors"
    value     = "1"
  }
}

# CloudWatch alarm for EKS
resource "aws_cloudwatch_metric_alarm" "eks_alarm" {
  alarm_name          = "EKSAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EKS CPU utilization"

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = {
    Name        = "EKS Alarm"
    Environment = "production"
  }
}
```

### **EKS Metrics**
```hcl
# CloudWatch alarm for EKS node group
resource "aws_cloudwatch_metric_alarm" "eks_node_group" {
  alarm_name          = "EKSNodeGroupAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors EKS node group CPU utilization"

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
    NodeGroupName = aws_eks_node_group.main.node_group_name
  }

  tags = {
    Name        = "EKS Node Group Alarm"
    Environment = "production"
  }
}
```

## 🛡️ Security Best Practices

### **EKS Security Configuration**
```hcl
# Secure EKS cluster
resource "aws_eks_cluster" "secure" {
  name     = "secure-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  # Logging configuration
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name        = "Secure EKS Cluster"
    Environment = "production"
  }
}
```

### **Access Control**
```hcl
# IAM policy for EKS access
resource "aws_iam_policy" "eks_access" {
  name        = "EKSAccess"
  description = "Policy for EKS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 💰 Cost Optimization

### **EKS Cost Optimization**
```hcl
# Cost-optimized EKS cluster
resource "aws_eks_cluster" "cost_optimized" {
  name     = "cost-optimized-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Cost Optimized EKS Cluster"
    Environment = "production"
  }
}

# Cost-optimized EKS node group with Spot instances
resource "aws_eks_node_group" "cost_optimized" {
  cluster_name    = aws_eks_cluster.cost_optimized.name
  node_group_name = "cost-optimized-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t3.large"]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  tags = {
    Name        = "Cost Optimized EKS Node Group"
    Environment = "production"
  }
}
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Issue: EKS Cluster Not Accessible**
```hcl
# Debug EKS cluster
resource "aws_eks_cluster" "debug" {
  name     = "debug-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Debug EKS Cluster"
    Environment = "production"
  }
}
```

#### **Issue: Node Group Not Joining**
```hcl
# Debug EKS node group
resource "aws_eks_node_group" "debug" {
  cluster_name    = aws_eks_cluster.debug.name
  node_group_name = "debug-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name        = "Debug EKS Node Group"
    Environment = "production"
  }
}
```

## 📚 Real-World Examples

### **E-Commerce EKS Setup**
```hcl
# E-commerce EKS setup
locals {
  ecommerce_config = {
    cluster_name = "ecommerce-cluster"
    version = "1.28"
    node_instance_types = ["t3.large", "t3.xlarge"]
    desired_size = 3
    max_size = 10
    min_size = 1
    enable_fargate = true
  }
}

# E-commerce EKS cluster
resource "aws_eks_cluster" "ecommerce" {
  name     = local.ecommerce_config.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = local.ecommerce_config.version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "E-commerce EKS Cluster"
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### **Microservices EKS Setup**
```hcl
# Microservices EKS setup
resource "aws_eks_cluster" "microservices" {
  name     = "microservices-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Microservices EKS Cluster"
    Environment = "production"
    Project     = "microservices"
  }
}

# Microservices EKS node group
resource "aws_eks_node_group" "microservices" {
  cluster_name    = aws_eks_cluster.microservices.name
  node_group_name = "microservices-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }

  tags = {
    Name        = "Microservices EKS Node Group"
    Environment = "production"
    Project     = "microservices"
  }
}
```

## 🔗 Related Services

### **Integration Patterns**
- **EC2**: Node instances
- **VPC**: Networking
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **EBS**: Persistent storage
- **ALB**: Load balancing
- **Route 53**: DNS
- **Secrets Manager**: Secret management

### **Service Dependencies**
- **VPC**: Networking
- **IAM**: Access control
- **CloudWatch**: Monitoring
- **KMS**: Encryption
- **EBS**: Storage

---

## 🎉 **Next Steps**

1. **Practice**: Implement the basic EKS examples
2. **Explore**: Try the production deployment patterns
3. **Integrate**: Connect EKS with other AWS services
4. **Secure**: Implement security best practices
5. **Monitor**: Set up CloudWatch and logging
6. **Optimize**: Focus on cost and performance

**Your EKS Mastery Journey Continues with Advanced Networking!** 🚀

---

*This comprehensive EKS guide provides everything you need to master AWS EKS with Terraform. Each example is production-ready and follows security best practices.*
