# Microservices Infrastructure Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for microservices infrastructure deployment, EKS cluster management, service mesh configuration, and production deployment challenges.

## 📋 Table of Contents

1. [EKS Cluster Issues](#eks-cluster-issues)
2. [Service Mesh Problems](#service-mesh-problems)
3. [Microservices Deployment Issues](#microservices-deployment-issues)
4. [Networking and Security Problems](#networking-and-security-problems)
5. [Monitoring and Observability Issues](#monitoring-and-observability-issues)
6. [Performance and Scaling Problems](#performance-and-scaling-problems)
7. [CI/CD Integration Challenges](#cicd-integration-challenges)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 🚀 EKS Cluster Issues

### Problem: EKS Cluster Creation Failures

**Symptoms:**
```
Error: failed to create EKS cluster: insufficient permissions
```

**Root Causes:**
- Missing IAM permissions
- Incorrect VPC configuration
- Insufficient subnet configuration
- Missing security group rules

**Solutions:**

#### Solution 1: Fix IAM Permissions for EKS
```hcl
# ✅ Comprehensive IAM permissions for EKS
resource "aws_iam_role" "eks_cluster" {
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
  
  tags = {
    Name = "eks-cluster-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# Node group IAM role
resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group-role"
  
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
  
  tags = {
    Name = "eks-node-group-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}
```

#### Solution 2: Fix VPC and Networking Configuration
```hcl
# ✅ Proper VPC configuration for EKS
resource "aws_vpc" "eks" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Public subnets for load balancers
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets for worker nodes
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.eks.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id
  
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.availability_zones)
  
  domain = "vpc"
  
  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "eks" {
  count = length(var.availability_zones)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.eks]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }
  
  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count = length(var.availability_zones)
  
  vpc_id = aws_vpc.eks.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks[count.index].id
  }
  
  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

### Problem: EKS Cluster Node Group Issues

**Symptoms:**
```
Error: failed to create EKS node group: instance type not supported
```

**Root Causes:**
- Unsupported instance types
- Insufficient capacity in availability zones
- Incorrect AMI configuration
- Missing launch template configuration

**Solutions:**

#### Solution 1: Fix Node Group Configuration
```hcl
# ✅ Proper node group configuration
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium", "t3.large"]
  
  scaling_config {
    desired_size = 2
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
    Name = "${var.cluster_name}-general-node-group"
    Environment = var.environment
  }
}

# Compute-optimized node group
resource "aws_eks_node_group" "compute" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "compute"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  
  capacity_type  = "ON_DEMAND"
  instance_types = ["c5.large", "c5.xlarge"]
  
  scaling_config {
    desired_size = 2
    max_size     = 8
    min_size     = 1
  }
  
  update_config {
    max_unavailable_percentage = 25
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
  
  tags = {
    Name = "${var.cluster_name}-compute-node-group"
    Environment = var.environment
  }
}
```

---

## 🕸️ Service Mesh Problems

### Problem: Istio Installation Failures

**Symptoms:**
```
Error: failed to install Istio: namespace not found
```

**Root Causes:**
- Missing namespace configuration
- Incorrect Istio version
- Insufficient permissions
- Missing CRDs

**Solutions:**

#### Solution 1: Fix Istio Installation
```hcl
# ✅ Proper Istio installation
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      name = "istio-system"
      istio-injection = "disabled"
    }
  }
}

resource "kubernetes_config_map" "istio_config" {
  metadata {
    name = "istio-config"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }
  
  data = {
    "mesh" = jsonencode({
      defaultConfig = {
        proxyStatsMatcher = {
          inclusionRegexps = [".*circuit_breakers.*", ".*upstream_rq_retry.*"]
        }
      }
      enablePrometheusMerge = true
      defaultProviders = {
        tracing = ["jaeger"]
        metrics = ["prometheus"]
      }
    })
  }
}

# Istio Gateway
resource "kubernetes_manifest" "istio_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "main-gateway"
      namespace = "istio-system"
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = ["*"]
        },
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = ["*"]
          tls = {
            mode = "SIMPLE"
            credentialName = "istio-ingressgateway-certs"
          }
        }
      ]
    }
  }
}

# Virtual Service
resource "kubernetes_manifest" "istio_virtual_service" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "main-virtual-service"
      namespace = "default"
    }
    spec = {
      hosts = ["*"]
      gateways = ["main-gateway"]
      http = [
        {
          match = [
            {
              uri = {
                prefix = "/api"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "api-service"
                port = {
                  number = 80
                }
              }
            }
          ]
        }
      ]
    }
  }
}
```

#### Solution 2: Fix Service Mesh Configuration
```hcl
# ✅ Service mesh configuration
resource "kubernetes_manifest" "istio_destination_rule" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "DestinationRule"
    metadata = {
      name      = "api-destination-rule"
      namespace = "default"
    }
    spec = {
      host = "api-service"
      trafficPolicy = {
        connectionPool = {
          tcp = {
            maxConnections = 100
          }
          http = {
            http1MaxPendingRequests = 10
            maxRequestsPerConnection = 2
          }
        }
        circuitBreaker = {
          consecutiveErrors = 3
          interval = "30s"
          baseEjectionTime = "30s"
        }
      }
    }
  }
}

# Peer Authentication
resource "kubernetes_manifest" "istio_peer_authentication" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = "default"
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

# Authorization Policy
resource "kubernetes_manifest" "istio_authorization_policy" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "api-authorization"
      namespace = "default"
    }
    spec = {
      selector = {
        matchLabels = {
          app = "api"
        }
      }
      rules = [
        {
          from = [
            {
              source = {
                principals = ["cluster.local/ns/default/sa/api-service-account"]
              }
            }
          ]
          to = [
            {
              operation = {
                methods = ["GET", "POST"]
                paths = ["/api/*"]
              }
            }
          ]
        }
      ]
    }
  }
}
```

---

## 🚀 Microservices Deployment Issues

### Problem: Microservices Deployment Failures

**Symptoms:**
```
Error: failed to deploy microservice: image pull failed
```

**Root Causes:**
- Missing image pull secrets
- Incorrect image references
- Insufficient permissions
- Missing service accounts

**Solutions:**

#### Solution 1: Fix Microservices Deployment
```hcl
# ✅ Proper microservices deployment
resource "kubernetes_namespace" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      name = "microservices"
      istio-injection = "enabled"
    }
  }
}

# Service Account
resource "kubernetes_service_account" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.microservices.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.microservice[each.key].arn
    }
  }
}

# ConfigMap
resource "kubernetes_config_map" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = "${each.key}-config"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  
  data = each.value.config
}

# Secret
resource "kubernetes_secret" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = "${each.key}-secret"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  
  data = each.value.secrets
  
  type = "Opaque"
}

# Deployment
resource "kubernetes_deployment" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.microservices.metadata[0].name
    labels = {
      app = each.key
    }
  }
  
  spec {
    replicas = each.value.replicas
    
    selector {
      match_labels = {
        app = each.key
      }
    }
    
    template {
      metadata {
        labels = {
          app = each.key
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.microservice[each.key].metadata[0].name
        
        container {
          name  = each.key
          image = each.value.image
          
          port {
            container_port = each.value.port
          }
          
          env {
            name = "SERVICE_NAME"
            value = each.key
          }
          
          env {
            name = "SERVICE_PORT"
            value = tostring(each.value.port)
          }
          
          resources {
            requests = {
              cpu    = each.value.resources.requests.cpu
              memory = each.value.resources.requests.memory
            }
            limits = {
              cpu    = each.value.resources.limits.cpu
              memory = each.value.resources.limits.memory
            }
          }
          
          liveness_probe {
            http_get {
              path = "/health"
              port = each.value.port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/ready"
              port = each.value.port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Service
resource "kubernetes_service" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.microservices.metadata[0].name
    labels = {
      app = each.key
    }
  }
  
  spec {
    selector = {
      app = each.key
    }
    
    port {
      port        = each.value.port
      target_port = each.value.port
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }
}
```

#### Solution 2: Fix Image Pull Secrets
```hcl
# ✅ Image pull secrets
resource "kubernetes_secret" "image_pull_secret" {
  metadata {
    name      = "image-pull-secret"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  
  type = "kubernetes.io/dockerconfigjson"
  
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_url}" = {
          username = var.registry_username
          password = var.registry_password
          auth     = base64encode("${var.registry_username}:${var.registry_password}")
        }
      }
    })
  }
}

# Update service account with image pull secret
resource "kubernetes_service_account" "microservice_with_secret" {
  for_each = var.microservices
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.microservices.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.microservice[each.key].arn
    }
  }
  
  image_pull_secret {
    name = kubernetes_secret.image_pull_secret.metadata[0].name
  }
}
```

---

## 🌐 Networking and Security Problems

### Problem: Network Policy Issues

**Symptoms:**
```
Error: network policy violation: traffic blocked
```

**Root Causes:**
- Missing network policies
- Incorrect policy configuration
- Insufficient security groups
- Missing service mesh policies

**Solutions:**

#### Solution 1: Fix Network Policies
```hcl
# ✅ Network policies
resource "kubernetes_network_policy" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = "${each.key}-network-policy"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  
  spec {
    pod_selector {
      match_labels = {
        app = each.key
      }
    }
    
    policy_types = ["Ingress", "Egress"]
    
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "istio-system"
          }
        }
      }
      
      from {
        pod_selector {
          match_labels = {
            app = each.value.allowed_ingress
          }
        }
      }
      
      ports {
        port     = each.value.port
        protocol = "TCP"
      }
    }
    
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "istio-system"
          }
        }
      }
      
      to {
        pod_selector {
          match_labels = {
            app = each.value.allowed_egress
          }
        }
      }
      
      ports {
        port     = each.value.port
        protocol = "TCP"
      }
    }
  }
}

# Security Group for EKS
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = aws_vpc.eks.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_security_group" "eks_node_group" {
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = aws_vpc.eks.id
  
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
  
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.cluster_name}-node-group-sg"
  }
}
```

---

## 📊 Monitoring and Observability Issues

### Problem: Monitoring Setup Failures

**Symptoms:**
```
Error: failed to setup monitoring: Prometheus not accessible
```

**Root Causes:**
- Missing monitoring namespace
- Incorrect Prometheus configuration
- Insufficient permissions
- Missing service discovery

**Solutions:**

#### Solution 1: Fix Monitoring Setup
```hcl
# ✅ Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Prometheus ConfigMap
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval = "15s"
        evaluation_interval = "15s"
      }
      
      rule_files = [
        "/etc/prometheus/rules/*.yml"
      ]
      
      scrape_configs = [
        {
          job_name = "prometheus"
          static_configs = [
            {
              targets = ["localhost:9090"]
            }
          ]
        },
        {
          job_name = "kubernetes-apiservers"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
            }
          ]
          scheme = "https"
          tls_config = {
            ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          }
          bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
              action = "keep"
              regex = "default;kubernetes;https"
            }
          ]
        },
        {
          job_name = "kubernetes-nodes"
          kubernetes_sd_configs = [
            {
              role = "node"
            }
          ]
          scheme = "https"
          tls_config = {
            ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          }
          bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          relabel_configs = [
            {
              action = "labelmap"
              regex = "__meta_kubernetes_node_label_(.+)"
            }
            {
              target_label = "__address__"
              replacement = "kubernetes.default.svc:443"
            }
            {
              source_labels = ["__meta_kubernetes_node_name"]
              regex = "(.+)"
              target_label = "__metrics_path__"
              replacement = "/api/v1/nodes/${1}/proxy/metrics"
            }
          ]
        }
      ]
    })
  }
}

# Prometheus Deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }
      
      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.45.0"
          
          port {
            container_port = 9090
          }
          
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        
        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Prometheus Service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    selector = {
      app = "prometheus"
    }
    
    port {
      port        = 9090
      target_port = 9090
    }
    
    type = "ClusterIP"
  }
}
```

#### Solution 2: Fix Grafana Setup
```hcl
# ✅ Grafana setup
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      
      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:10.0.0"
          
          port {
            container_port = 3000
          }
          
          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = var.grafana_password
          }
          
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        
        volume {
          name = "grafana-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Grafana Service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    selector = {
      app = "grafana"
    }
    
    port {
      port        = 3000
      target_port = 3000
    }
    
    type = "ClusterIP"
  }
}
```

---

## ⚡ Performance and Scaling Problems

### Problem: Auto-scaling Issues

**Symptoms:**
```
Error: horizontal pod autoscaler failed: metrics not available
```

**Root Causes:**
- Missing metrics server
- Incorrect HPA configuration
- Insufficient metrics
- Missing cluster autoscaler

**Solutions:**

#### Solution 1: Fix Auto-scaling Configuration
```hcl
# ✅ Metrics Server
resource "kubernetes_deployment" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "metrics-server"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "metrics-server"
        }
      }
      
      spec {
        container {
          name  = "metrics-server"
          image = "k8s.gcr.io/metrics-server/metrics-server:v0.6.1"
          
          args = [
            "--cert-dir=/tmp",
            "--secure-port=4443",
            "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
            "--kubelet-use-node-status-port",
            "--metric-resolution=15s"
          ]
          
          port {
            name           = "https"
            container_port = 4443
            protocol       = "TCP"
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler" "microservice" {
  for_each = var.microservices
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }
  
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = each.key
    }
    
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas
    
    target_cpu_utilization_percentage = each.value.target_cpu_utilization
  }
}

# Cluster Autoscaler
resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaler-role"
  
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

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler-policy"
  role = aws_iam_role.cluster_autoscaler.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.cluster_autoscaler.metadata[0].name
        
        container {
          name  = "cluster-autoscaler"
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v1.24.0"
          
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}",
            "--balance-similar-node-groups",
            "--skip-nodes-with-system-pods=false"
          ]
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: EKS Cluster Debugging
```bash
# ✅ Debug EKS cluster
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --region $AWS_REGION

# ✅ Debug Kubernetes resources
kubectl get nodes
kubectl get pods --all-namespaces
kubectl describe node $NODE_NAME
kubectl logs $POD_NAME -n $NAMESPACE
```

### Technique 2: Service Mesh Debugging
```bash
# ✅ Debug Istio
kubectl get pods -n istio-system
kubectl logs -n istio-system -l app=istiod
kubectl logs -n istio-system -l app=istio-proxy

# ✅ Debug service mesh traffic
istioctl proxy-config cluster $POD_NAME -n $NAMESPACE
istioctl proxy-config route $POD_NAME -n $NAMESPACE
```

### Technique 3: Microservices Debugging
```bash
# ✅ Debug microservices
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl describe deployment $DEPLOYMENT_NAME
kubectl logs deployment/$DEPLOYMENT_NAME
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Microservices Testing
```hcl
# ✅ Test microservices in isolation
# tests/test_microservices.tf
resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name      = "test-microservice"
    namespace = kubernetes_namespace.test.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "test-microservice"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "test-microservice"
        }
      }
      
      spec {
        container {
          name  = "test"
          image = "nginx:latest"
          
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
```

### Strategy 2: Microservices Monitoring
```bash
# ✅ Monitor microservices performance
kubectl top nodes
kubectl top pods --all-namespaces
kubectl get hpa --all-namespaces
```

### Strategy 3: Microservices Documentation
```markdown
# ✅ Document microservices patterns
## Microservice: API Service

### Purpose
Handles API requests and responses.

### Configuration
```hcl
resource "kubernetes_deployment" "api" {
  # Deployment configuration...
}
```

### Usage
1. Deploy to EKS cluster
2. Configure service mesh
3. Set up monitoring
4. Configure auto-scaling
```

---

## 📞 Getting Help

### Internal Resources
- Review microservices documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review microservices documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Design for Scale**: Plan microservices architecture before implementation
- **Implement Service Mesh**: Use service mesh for traffic management
- **Monitor Continuously**: Implement comprehensive monitoring
- **Automate Deployments**: Use CI/CD for deployment automation
- **Test Thoroughly**: Test microservices in isolation
- **Optimize Performance**: Implement auto-scaling and optimization
- **Secure Infrastructure**: Implement security best practices
- **Document Everything**: Maintain clear microservices documentation

Remember: Microservices infrastructure requires careful planning, comprehensive implementation, and continuous monitoring. Proper implementation ensures reliable, scalable, and maintainable containerized applications.
