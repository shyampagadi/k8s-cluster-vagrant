# Problem 34: Career Preparation and Portfolio Development
# Comprehensive portfolio infrastructure showcasing all skills

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

# Local values for portfolio infrastructure
locals {
  # Portfolio project configuration
  portfolio_projects = {
    personal_website = {
      name        = "personal-website"
      description = "Personal portfolio website"
      tech_stack  = ["React", "Node.js", "PostgreSQL"]
      domain      = var.personal_domain
    }
    
    microservices_demo = {
      name        = "microservices-demo"
      description = "Microservices architecture demonstration"
      tech_stack  = ["Go", "Python", "Redis", "MongoDB"]
      domain      = var.demo_domain
    }
    
    ml_platform = {
      name        = "ml-platform"
      description = "Machine learning platform"
      tech_stack  = ["Python", "TensorFlow", "Jupyter", "MinIO"]
      domain      = var.ml_domain
    }
  }
  
  # Skills demonstration tags
  skills_tags = {
    TerraformSkills     = "Advanced"
    KubernetesSkills    = "Expert"
    AWSSkills          = "Expert"
    DevOpsSkills       = "Advanced"
    SecuritySkills     = "Intermediate"
    MonitoringSkills   = "Advanced"
    CICDSkills         = "Advanced"
    IaCSkills          = "Expert"
    CloudNativeSkills  = "Advanced"
    ContainerSkills    = "Expert"
  }
  
  common_tags = merge(var.tags, local.skills_tags, {
    Purpose     = "CareerPortfolio"
    Owner       = var.candidate_name
    Contact     = var.candidate_email
    LinkedIn    = var.linkedin_profile
    GitHub      = var.github_profile
    ManagedBy   = "Terraform"
    LastUpdated = timestamp()
  })
}

# EKS cluster for portfolio applications
resource "aws_eks_cluster" "portfolio" {
  name     = "${var.candidate_name}-portfolio-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-cluster"
    Skill = "Kubernetes,EKS,ContainerOrchestration"
  })
}

# VPC for portfolio infrastructure
resource "aws_vpc" "portfolio" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-vpc"
    Skill = "Networking,VPC,AWS"
  })
}

# Subnets across multiple AZs
resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.portfolio.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-public-${count.index + 1}"
    Type = "Public"
    "kubernetes.io/cluster/${aws_eks_cluster.portfolio.name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.portfolio.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-private-${count.index + 1}"
    Type = "Private"
    "kubernetes.io/cluster/${aws_eks_cluster.portfolio.name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway and NAT Gateways
resource "aws_internet_gateway" "portfolio" {
  vpc_id = aws_vpc.portfolio.id

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-igw"
  })
}

resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "portfolio" {
  count = 3

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-nat-${count.index + 1}"
  })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.portfolio.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.portfolio.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.portfolio.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.portfolio[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-private-rt-${count.index + 1}"
  })
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# IAM roles for EKS
resource "aws_iam_role" "eks_cluster" {
  name = "${var.candidate_name}-eks-cluster-role"

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

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-eks-cluster-role"
    Skill = "IAM,Security,AWS"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_node_group" {
  name = "${var.candidate_name}-eks-node-group-role"

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

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-eks-node-group-role"
  })
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

# EKS Node Group
resource "aws_eks_node_group" "portfolio" {
  cluster_name    = aws_eks_cluster.portfolio.name
  node_group_name = "${var.candidate_name}-portfolio-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-nodes"
    Skill = "AutoScaling,EC2,Kubernetes"
  })
}

# Configure Kubernetes provider
data "aws_eks_cluster_auth" "portfolio" {
  name = aws_eks_cluster.portfolio.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.portfolio.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.portfolio.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.portfolio.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.portfolio.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.portfolio.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.portfolio.token
  }
}

# Kubernetes namespaces for portfolio projects
resource "kubernetes_namespace" "portfolio_projects" {
  for_each = local.portfolio_projects

  metadata {
    name = each.value.name
    labels = {
      project     = each.value.name
      description = each.value.description
      managed-by  = "terraform"
    }
    annotations = {
      "tech-stack" = join(",", each.value.tech_stack)
    }
  }
}

# Portfolio applications deployment
resource "kubernetes_deployment" "portfolio_apps" {
  for_each = local.portfolio_projects

  metadata {
    name      = each.value.name
    namespace = kubernetes_namespace.portfolio_projects[each.key].metadata[0].name
    labels = {
      app = each.value.name
    }
  }

  spec {
    replicas = var.app_replicas[each.key]

    selector {
      match_labels = {
        app = each.value.name
      }
    }

    template {
      metadata {
        labels = {
          app = each.value.name
        }
      }

      spec {
        container {
          image = var.app_images[each.key]
          name  = each.value.name

          port {
            container_port = var.app_ports[each.key]
          }

          resources {
            limits = {
              cpu    = var.app_resources[each.key].cpu_limit
              memory = var.app_resources[each.key].memory_limit
            }
            requests = {
              cpu    = var.app_resources[each.key].cpu_request
              memory = var.app_resources[each.key].memory_request
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_ports[each.key]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = var.app_ports[each.key]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Services for portfolio applications
resource "kubernetes_service" "portfolio_apps" {
  for_each = local.portfolio_projects

  metadata {
    name      = each.value.name
    namespace = kubernetes_namespace.portfolio_projects[each.key].metadata[0].name
  }

  spec {
    selector = {
      app = each.value.name
    }

    port {
      name        = "http"
      port        = 80
      target_port = var.app_ports[each.key]
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Ingress for external access
resource "kubernetes_ingress_v1" "portfolio_apps" {
  for_each = { for k, v in local.portfolio_projects : k => v if v.domain != null }

  metadata {
    name      = each.value.name
    namespace = kubernetes_namespace.portfolio_projects[each.key].metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/health"
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate.portfolio.arn
      "alb.ingress.kubernetes.io/ssl-policy"       = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
    }
  }

  spec {
    rule {
      host = each.value.domain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.portfolio_apps[each.key].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.portfolio.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [aws_eks_node_group.portfolio]
}

# Monitoring stack with Prometheus and Grafana
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "51.2.0"

  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        enabled = true
        service = {
          type = "LoadBalancer"
        }
        adminPassword = var.grafana_admin_password
        dashboardProviders = {
          dashboardproviders = {
            apiVersion = 1
            providers = [
              {
                name    = "default"
                orgId   = 1
                folder  = ""
                type    = "file"
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
      }
      prometheus = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [aws_eks_node_group.portfolio]
}

# ACM certificate for HTTPS
resource "aws_acm_certificate" "portfolio" {
  domain_name       = var.primary_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.primary_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-cert"
    Skill = "SSL,Security,ACM"
  })
}

# Route53 hosted zone
resource "aws_route53_zone" "portfolio" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.primary_domain

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-zone"
    Skill = "DNS,Route53"
  })
}

# S3 bucket for portfolio assets
resource "aws_s3_bucket" "portfolio_assets" {
  bucket = "${var.candidate_name}-portfolio-assets-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-assets"
    Skill = "S3,Storage"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "portfolio_assets" {
  bucket = aws_s3_bucket.portfolio_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio_assets" {
  bucket = aws_s3_bucket.portfolio_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront distribution for portfolio website
resource "aws_cloudfront_distribution" "portfolio" {
  origin {
    domain_name = aws_s3_bucket.portfolio_assets.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.portfolio_assets.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portfolio.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = var.cloudfront_aliases

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.portfolio_assets.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.portfolio.arn
    ssl_support_method  = "sni-only"
  }

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-cdn"
    Skill = "CloudFront,CDN,Performance"
  })
}

resource "aws_cloudfront_origin_access_identity" "portfolio" {
  comment = "Portfolio OAI"
}

# CodeCommit repository for portfolio code
resource "aws_codecommit_repository" "portfolio" {
  repository_name = "${var.candidate_name}-portfolio-repo"
  description     = "Portfolio applications source code"

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-repo"
    Skill = "Git,CodeCommit,VersionControl"
  })
}

# CloudWatch dashboard for portfolio monitoring
resource "aws_cloudwatch_dashboard" "portfolio" {
  dashboard_name = "${var.candidate_name}-portfolio-dashboard"

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
            ["AWS/EKS", "cluster_failed_request_count", "ClusterName", aws_eks_cluster.portfolio.name],
            ["AWS/EKS", "cluster_request_total", "ClusterName", aws_eks_cluster.portfolio.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EKS Cluster Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.portfolio.id],
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", aws_cloudfront_distribution.portfolio.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"  # CloudFront metrics are in us-east-1
          title   = "CloudFront Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.candidate_name}-portfolio-dashboard"
    Skill = "Monitoring,CloudWatch,Observability"
  })
}
