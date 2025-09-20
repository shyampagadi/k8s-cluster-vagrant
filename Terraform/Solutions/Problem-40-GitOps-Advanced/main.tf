# Problem 40: GitOps Advanced with ArgoCD and Flux
# Complete GitOps implementation for Kubernetes

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for existing EKS cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Namespace for GitOps tools
resource "kubernetes_namespace" "gitops" {
  metadata {
    name = "gitops"
    labels = {
      name = "gitops"
      type = "system"
    }
  }
}

# ArgoCD Installation
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"
  namespace  = kubernetes_namespace.gitops.metadata[0].name

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        config = {
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
          "server.rbac.log.enforce.enable" = "false"
          "exec.enabled" = "true"
          "admin.enabled" = "true"
          "timeout.reconciliation" = "180s"
        }
      }
      
      controller = {
        replicas = 1
        resources = {
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }
      
      repoServer = {
        replicas = 2
        resources = {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
    })
  ]
}

# Flux Installation
resource "helm_release" "flux" {
  count = var.enable_flux ? 1 : 0
  
  name       = "flux-system"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.10.2"
  namespace  = kubernetes_namespace.gitops.metadata[0].name

  values = [
    yamlencode({
      controllers = {
        source = {
          create = true
        }
        kustomize = {
          create = true
        }
        helm = {
          create = true
        }
        notification = {
          create = true
        }
      }
    })
  ]
}

# ArgoCD Application for demo app
resource "kubernetes_manifest" "argocd_application" {
  count = var.enable_argocd ? 1 : 0
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "demo-application"
      namespace = kubernetes_namespace.gitops.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repository_url
        targetRevision = "HEAD"
        path           = "k8s-manifests"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
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

# Flux GitRepository
resource "kubernetes_manifest" "flux_git_repository" {
  count = var.enable_flux ? 1 : 0
  
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1beta2"
    kind       = "GitRepository"
    metadata = {
      name      = "demo-repo"
      namespace = kubernetes_namespace.gitops.metadata[0].name
    }
    spec = {
      interval = "1m"
      ref = {
        branch = "main"
      }
      url = var.git_repository_url
    }
  }

  depends_on = [helm_release.flux]
}

# Flux Kustomization
resource "kubernetes_manifest" "flux_kustomization" {
  count = var.enable_flux ? 1 : 0
  
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1beta2"
    kind       = "Kustomization"
    metadata = {
      name      = "demo-app"
      namespace = kubernetes_namespace.gitops.metadata[0].name
    }
    spec = {
      interval = "5m"
      path     = "./k8s-manifests"
      prune    = true
      sourceRef = {
        kind = "GitRepository"
        name = "demo-repo"
      }
    }
  }

  depends_on = [kubernetes_manifest.flux_git_repository]
}

# RBAC for GitOps
resource "kubernetes_cluster_role" "gitops_admin" {
  metadata {
    name = "gitops-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "gitops_admin" {
  metadata {
    name = "gitops-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.gitops_admin.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = kubernetes_namespace.gitops.metadata[0].name
  }
}

# Monitoring for GitOps
resource "kubernetes_service_monitor" "argocd" {
  count = var.enable_argocd && var.enable_monitoring ? 1 : 0
  
  metadata {
    name      = "argocd-metrics"
    namespace = kubernetes_namespace.gitops.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "argocd-metrics"
      }
    }

    endpoints {
      port = "metrics"
    }
  }
}
