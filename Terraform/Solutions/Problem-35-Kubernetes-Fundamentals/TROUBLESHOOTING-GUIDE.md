# Kubernetes Fundamentals Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for Kubernetes implementations, EKS cluster management, container orchestration issues, and application deployment challenges.

## 📋 Table of Contents

1. [EKS Cluster Issues](#eks-cluster-issues)
2. [Container Deployment Problems](#container-deployment-problems)
3. [Networking and Service Issues](#networking-and-service-issues)
4. [Storage and Persistence Problems](#storage-and-persistence-problems)
5. [Security and RBAC Challenges](#security-and-rbac-challenges)
6. [Monitoring and Observability Issues](#monitoring-and-observability-issues)
7. [Scaling and Performance Problems](#scaling-and-performance-problems)
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

#### Solution 1: Fix IAM Permissions
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
```

#### Solution 2: Fix VPC Configuration
```hcl
# ✅ Proper VPC configuration for EKS
resource "aws_vpc" "eks" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "eks-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "eks-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.eks.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "eks-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

---

## 🐳 Container Deployment Problems

### Problem: Container Deployment Failures

**Symptoms:**
```
Error: container deployment failed: image pull failed
```

**Root Causes:**
- Missing image pull secrets
- Incorrect image references
- Insufficient permissions
- Missing service accounts

**Solutions:**

#### Solution 1: Fix Container Deployment
```hcl
# ✅ Proper container deployment configuration
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "app-deployment"
    namespace = "default"
    labels = {
      app = "app"
    }
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "app"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "app"
        }
      }
      
      spec {
        container {
          name  = "app"
          image = "nginx:latest"
          
          port {
            container_port = 80
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
          
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}
```

#### Solution 2: Fix Image Pull Secrets
```hcl
# ✅ Image pull secrets configuration
resource "kubernetes_secret" "image_pull_secret" {
  metadata {
    name      = "image-pull-secret"
    namespace = "default"
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

resource "kubernetes_service_account" "app" {
  metadata {
    name      = "app-service-account"
    namespace = "default"
  }
  
  image_pull_secret {
    name = kubernetes_secret.image_pull_secret.metadata[0].name
  }
}
```

---

## 🌐 Networking and Service Issues

### Problem: Service Networking Failures

**Symptoms:**
```
Error: service networking failed: unable to reach pods
```

**Root Causes:**
- Incorrect service configuration
- Missing network policies
- DNS resolution issues
- Load balancer configuration problems

**Solutions:**

#### Solution 1: Fix Service Configuration
```hcl
# ✅ Proper service configuration
resource "kubernetes_service" "app" {
  metadata {
    name      = "app-service"
    namespace = "default"
    labels = {
      app = "app"
    }
  }
  
  spec {
    selector = {
      app = "app"
    }
    
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "app" {
  metadata {
    name      = "app-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
  
  spec {
    rule {
      host = "app.example.com"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.app.metadata[0].name
            service_port = 80
          }
        }
      }
    }
  }
}
```

#### Solution 2: Fix Network Policies
```hcl
# ✅ Network policies configuration
resource "kubernetes_network_policy" "app" {
  metadata {
    name      = "app-network-policy"
    namespace = "default"
  }
  
  spec {
    pod_selector {
      match_labels = {
        app = "app"
      }
    }
    
    policy_types = ["Ingress", "Egress"]
    
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "default"
          }
        }
      }
      
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }
    
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "default"
          }
        }
      }
      
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }
  }
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Kubernetes Debugging
```bash
# ✅ Debug Kubernetes resources
kubectl get nodes
kubectl get pods --all-namespaces
kubectl describe node $NODE_NAME
kubectl logs $POD_NAME -n $NAMESPACE
kubectl exec -it $POD_NAME -- /bin/bash
```

### Technique 2: EKS Debugging
```bash
# ✅ Debug EKS cluster
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --region $AWS_REGION
kubectl get nodes -o wide
kubectl top nodes
kubectl top pods --all-namespaces
```

### Technique 3: Application Debugging
```bash
# ✅ Debug application issues
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod $POD_NAME
kubectl logs $POD_NAME --previous
kubectl port-forward $POD_NAME 8080:80
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Kubernetes Testing
```hcl
# ✅ Test Kubernetes in isolation
resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name      = "test-deployment"
    namespace = kubernetes_namespace.test.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "test"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "test"
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

### Strategy 2: Kubernetes Monitoring
```bash
# ✅ Monitor Kubernetes performance
kubectl top nodes
kubectl top pods --all-namespaces
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## 📞 Getting Help

### Internal Resources
- Review Kubernetes documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review Kubernetes documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Design for Scale**: Plan Kubernetes architecture before implementation
- **Implement Security**: Apply security best practices
- **Monitor Continuously**: Implement comprehensive monitoring
- **Test Thoroughly**: Test Kubernetes configurations
- **Document Everything**: Maintain clear Kubernetes documentation
- **Optimize Performance**: Implement performance optimization
- **Handle Errors**: Implement robust error handling
- **Scale Appropriately**: Design for enterprise scale

Remember: Kubernetes requires careful planning, comprehensive implementation, and continuous monitoring. Proper implementation ensures reliable, scalable, and maintainable containerized applications.
