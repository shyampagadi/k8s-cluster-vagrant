# Problem 30: Production Microservices Infrastructure - Complete Deployment Guide

## 🚀 Production-Ready EKS Cluster Architecture

### Enterprise EKS Cluster Design

#### Multi-AZ High Availability Setup
```hcl
# EKS Cluster with production-grade configuration
resource "aws_eks_cluster" "production" {
  name     = "${var.project_name}-production-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_endpoint
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable comprehensive logging
  enabled_cluster_log_types = [
    "api",
    "audit", 
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Encryption at rest
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_encryption.arn
    }
    resources = ["secrets"]
  }

  # Ensure proper IAM roles are created first
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = merge(var.common_tags, {
    Environment = "production"
    Tier        = "control-plane"
    Compliance  = "SOC2-PCI"
  })
}

# Managed Node Groups with different instance types
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.production.name
  node_group_name = "${var.project_name}-system-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  # System workloads node configuration
  instance_types = ["m5.large", "m5.xlarge"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 50

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 3
  }

  update_config {
    max_unavailable_percentage = 25
  }

  # Taints for system workloads
  taint {
    key    = "node-type"
    value  = "system"
    effect = "NO_SCHEDULE"
  }

  labels = {
    "node-type" = "system"
    "workload"  = "system"
  }

  tags = merge(var.common_tags, {
    NodeType = "system"
    Workload = "system"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.production.name
  node_group_name = "${var.project_name}-app-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  # Application workloads node configuration
  instance_types = ["c5.large", "c5.xlarge", "c5.2xlarge"]
  capacity_type  = "SPOT"
  disk_size      = 100

  scaling_config {
    desired_size = 6
    max_size     = 20
    min_size     = 3
  }

  update_config {
    max_unavailable_percentage = 25
  }

  labels = {
    "node-type" = "application"
    "workload"  = "application"
  }

  tags = merge(var.common_tags, {
    NodeType = "application"
    Workload = "application"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# Fargate profile for serverless workloads
resource "aws_eks_fargate_profile" "serverless" {
  cluster_name           = aws_eks_cluster.production.name
  fargate_profile_name   = "${var.project_name}-serverless-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn
  subnet_ids            = var.private_subnet_ids

  selector {
    namespace = "serverless"
    labels = {
      "compute-type" = "fargate"
    }
  }

  selector {
    namespace = "batch-jobs"
    labels = {
      "compute-type" = "fargate"
    }
  }

  tags = var.common_tags
}
```

### Service Mesh Implementation with Istio

#### Istio Control Plane Configuration
```hcl
# Helm provider for Istio installation
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.production.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.production.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.production.token
  }
}

# Istio base installation
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  version    = var.istio_version

  create_namespace = true

  set {
    name  = "global.meshID"
    value = "mesh1"
  }

  set {
    name  = "global.meshConfig.defaultConfig.proxyStatsMatcher.inclusionRegexps"
    value = ".*_cx_.*|.*_rq_.*|.*_rbac_.*"
  }

  depends_on = [aws_eks_node_group.system]
}

# Istio control plane (istiod)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = var.istio_version

  set {
    name  = "global.meshID"
    value = "mesh1"
  }

  set {
    name  = "global.network"
    value = "network1"
  }

  # Enable telemetry v2
  set {
    name  = "telemetry.v2.enabled"
    value = "true"
  }

  # Configure resource limits
  set {
    name  = "pilot.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "pilot.resources.requests.memory"
    value = "2048Mi"
  }

  depends_on = [helm_release.istio_base]
}

# Istio ingress gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-ingress"
  version    = var.istio_version

  create_namespace = true

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  # Configure resource limits
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "2000m"
  }

  set {
    name  = "resources.limits.memory"
    value = "1024Mi"
  }

  depends_on = [helm_release.istiod]
}
```

### Advanced Monitoring and Observability Stack

#### Prometheus and Grafana Setup
```hcl
# Prometheus Operator via Helm
resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = var.prometheus_operator_version

  create_namespace = true

  # Prometheus configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "30d"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "100Gi"
  }

  # Grafana configuration
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "gp3"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  # AlertManager configuration
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = "10Gi"
  }

  # Enable service monitors for Istio
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [aws_eks_node_group.system]
}

# Jaeger for distributed tracing
resource "helm_release" "jaeger" {
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = "tracing"
  version    = var.jaeger_version

  create_namespace = true

  # Use Elasticsearch as storage backend
  set {
    name  = "storage.type"
    value = "elasticsearch"
  }

  set {
    name  = "storage.elasticsearch.host"
    value = aws_elasticsearch_domain.tracing.endpoint
  }

  set {
    name  = "storage.elasticsearch.port"
    value = "443"
  }

  set {
    name  = "storage.elasticsearch.scheme"
    value = "https"
  }

  # Configure resource limits
  set {
    name  = "collector.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "collector.resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [
    aws_eks_node_group.system,
    aws_elasticsearch_domain.tracing
  ]
}

# Elasticsearch for log aggregation and tracing
resource "aws_elasticsearch_domain" "tracing" {
  domain_name           = "${var.project_name}-tracing"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type            = "t3.medium.elasticsearch"
    instance_count           = 3
    dedicated_master_enabled = true
    master_instance_type     = "t3.small.elasticsearch"
    master_instance_count    = 3
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 100
  }

  vpc_options {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.elasticsearch.id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.elasticsearch.arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.elasticsearch_master.arn
    }
  }

  tags = merge(var.common_tags, {
    Service = "tracing"
    Type    = "elasticsearch"
  })
}
```

### GitOps with ArgoCD

#### ArgoCD Installation and Configuration
```hcl
# ArgoCD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = var.argocd_version

  create_namespace = true

  # Server configuration
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internal"
  }

  # Enable RBAC
  set {
    name  = "server.rbacConfig.policy\\.default"
    value = "role:readonly"
  }

  # Configure OIDC authentication
  set {
    name  = "server.config.oidc\\.config"
    value = yamlencode({
      name         = "AWS SSO"
      issuer       = var.oidc_issuer_url
      clientId     = var.oidc_client_id
      clientSecret = var.oidc_client_secret
      requestedScopes = ["openid", "profile", "email"]
      requestedIDTokenClaims = {
        groups = {
          essential = true
        }
      }
    })
  }

  # Repository credentials
  set {
    name  = "configs.repositories.private-repo"
    value = yamlencode({
      url      = var.git_repository_url
      password = var.git_token
      username = var.git_username
    })
  }

  # Configure resource limits
  set {
    name  = "controller.resources.limits.cpu"
    value = "2000m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "2Gi"
  }

  depends_on = [aws_eks_node_group.system]
}

# ArgoCD Application for microservices
resource "kubernetes_manifest" "microservices_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "microservices"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.microservices_repo_url
        targetRevision = "HEAD"
        path           = "k8s/overlays/production"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "microservices"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
```

### Security and Compliance

#### Pod Security Standards and Network Policies
```hcl
# Pod Security Policy (deprecated, using Pod Security Standards)
resource "kubernetes_manifest" "pod_security_policy" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "microservices"
      labels = {
        "pod-security.kubernetes.io/enforce" = "restricted"
        "pod-security.kubernetes.io/audit"   = "restricted"
        "pod-security.kubernetes.io/warn"    = "restricted"
      }
    }
  }
}

# Network Policy for microservices isolation
resource "kubernetes_network_policy" "microservices_isolation" {
  metadata {
    name      = "microservices-isolation"
    namespace = "microservices"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "microservice"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from Istio proxy
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "istio-system"
          }
        }
      }
    }

    # Allow ingress from same namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "microservices"
          }
        }
      }
    }

    # Allow egress to DNS
    egress {
      to {}
      ports {
        protocol = "UDP"
        port     = "53"
      }
    }

    # Allow egress to Kubernetes API
    egress {
      to {}
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }

    # Allow egress to same namespace
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "microservices"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.pod_security_policy]
}

# Falco for runtime security monitoring
resource "helm_release" "falco" {
  name       = "falco"
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  namespace  = "falco-system"
  version    = var.falco_version

  create_namespace = true

  # Enable gRPC output for integration
  set {
    name  = "falco.grpc.enabled"
    value = "true"
  }

  set {
    name  = "falco.grpcOutput.enabled"
    value = "true"
  }

  # Configure custom rules
  set {
    name  = "customRules.rules-custom\\.yaml"
    value = file("${path.module}/falco-rules.yaml")
  }

  # Resource limits
  set {
    name  = "resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [aws_eks_node_group.system]
}
```

### Disaster Recovery and Backup

#### Velero for Cluster Backup
```hcl
# S3 bucket for Velero backups
resource "aws_s3_bucket" "velero_backups" {
  bucket = "${var.project_name}-velero-backups-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.common_tags, {
    Purpose = "disaster-recovery"
    Service = "velero"
  })
}

resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.velero.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# IAM role for Velero
resource "aws_iam_role" "velero" {
  name = "${var.project_name}-velero-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:velero:velero"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# Velero installation
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = "velero"
  version    = var.velero_version

  create_namespace = true

  # AWS plugin configuration
  set {
    name  = "configuration.provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = aws_s3_bucket.velero_backups.bucket
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "configuration.backupStorageLocation.config.kmsKeyId"
    value = aws_kms_key.velero.arn
  }

  # Service account annotations for IRSA
  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.velero.arn
  }

  # Schedule daily backups
  set {
    name  = "schedules.daily.schedule"
    value = "0 2 * * *"
  }

  set {
    name  = "schedules.daily.template.ttl"
    value = "720h" # 30 days
  }

  depends_on = [
    aws_eks_node_group.system,
    aws_iam_role_policy_attachment.velero
  ]
}
```

This comprehensive guide provides enterprise-grade production deployment patterns for microservices infrastructure with advanced security, monitoring, and disaster recovery capabilities.
