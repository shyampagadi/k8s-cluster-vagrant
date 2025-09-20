# Problem 35: Kubernetes Fundamentals with Terraform
# Complete Kubernetes resource management using Terraform

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

# Configure Kubernetes provider
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

# Namespace for applications
resource "kubernetes_namespace" "applications" {
  metadata {
    name = var.application_namespace
    labels = {
      name        = var.application_namespace
      environment = var.environment
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  data = {
    "database.properties" = <<-EOT
      host=${var.database_host}
      port=${var.database_port}
      name=${var.database_name}
      EOT
    "app.properties" = <<-EOT
      debug=${var.debug_mode}
      log_level=${var.log_level}
      max_connections=${var.max_connections}
      EOT
  }
}

# Secret for sensitive data
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  type = "Opaque"

  data = {
    database_username = base64encode(var.database_username)
    database_password = base64encode(var.database_password)
    api_key          = base64encode(var.api_key)
  }
}

# Persistent Volume Claim
resource "kubernetes_persistent_volume_claim" "app_storage" {
  metadata {
    name      = "app-storage"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class
  }
}

# Deployment for web application
resource "kubernetes_deployment" "web_app" {
  metadata {
    name      = "web-app"
    namespace = kubernetes_namespace.applications.metadata[0].name
    labels = {
      app = "web-app"
    }
  }

  spec {
    replicas = var.web_app_replicas

    selector {
      match_labels = {
        app = "web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-app"
        }
      }

      spec {
        container {
          image = var.web_app_image
          name  = "web-app"

          port {
            container_port = 8080
            name          = "http"
          }

          env {
            name = "DATABASE_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "database.properties"
              }
            }
          }

          env {
            name = "DATABASE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_username"
              }
            }
          }

          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_password"
              }
            }
          }

          volume_mount {
            name       = "app-storage"
            mount_path = "/data"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/config"
          }

          resources {
            limits = {
              cpu    = var.web_app_cpu_limit
              memory = var.web_app_memory_limit
            }
            requests = {
              cpu    = var.web_app_cpu_request
              memory = var.web_app_memory_request
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "app-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.app_storage.metadata[0].name
          }
        }

        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.app_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for web application
resource "kubernetes_service" "web_app" {
  metadata {
    name      = "web-app-service"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    selector = {
      app = "web-app"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Ingress for external access
resource "kubernetes_ingress_v1" "web_app" {
  metadata {
    name      = "web-app-ingress"
    namespace = kubernetes_namespace.applications.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/health"
    }
  }

  spec {
    rule {
      host = var.app_domain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.web_app.metadata[0].name
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

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "web_app" {
  metadata {
    name      = "web-app-hpa"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.web_app.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }
}

# StatefulSet for database
resource "kubernetes_stateful_set" "database" {
  metadata {
    name      = "database"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    service_name = "database-headless"
    replicas     = var.database_replicas

    selector {
      match_labels = {
        app = "database"
      }
    }

    template {
      metadata {
        labels = {
          app = "database"
        }
      }

      spec {
        container {
          name  = "database"
          image = var.database_image

          port {
            container_port = 5432
            name          = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = var.database_name
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_username"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_password"
              }
            }
          }

          volume_mount {
            name       = "database-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            limits = {
              cpu    = var.database_cpu_limit
              memory = var.database_memory_limit
            }
            requests = {
              cpu    = var.database_cpu_request
              memory = var.database_memory_request
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "database-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        
        resources {
          requests = {
            storage = var.database_storage_size
          }
        }

        storage_class_name = var.storage_class
      }
    }
  }
}

# Headless service for StatefulSet
resource "kubernetes_service" "database_headless" {
  metadata {
    name      = "database-headless"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    selector = {
      app = "database"
    }

    port {
      name = "postgres"
      port = 5432
    }

    cluster_ip = "None"
  }
}

# Regular service for database
resource "kubernetes_service" "database" {
  metadata {
    name      = "database-service"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    selector = {
      app = "database"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# Job for database initialization
resource "kubernetes_job" "db_init" {
  metadata {
    name      = "db-init"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = {
          app = "db-init"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name  = "db-init"
          image = "postgres:13"

          command = [
            "psql",
            "-h", "database-service",
            "-U", "$(POSTGRES_USER)",
            "-d", "$(POSTGRES_DB)",
            "-c", "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(100));"
          ]

          env {
            name  = "POSTGRES_DB"
            value = var.database_name
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_username"
              }
            }
          }

          env {
            name  = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "database_password"
              }
            }
          }
        }
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    kubernetes_stateful_set.database,
    kubernetes_service.database
  ]
}

# CronJob for database backup
resource "kubernetes_cron_job_v1" "db_backup" {
  metadata {
    name      = "db-backup"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    schedule = var.backup_schedule

    job_template {
      metadata {
        labels = {
          app = "db-backup"
        }
      }

      spec {
        template {
          metadata {
            labels = {
              app = "db-backup"
            }
          }

          spec {
            restart_policy = "OnFailure"

            container {
              name  = "db-backup"
              image = "postgres:13"

              command = [
                "sh",
                "-c",
                "pg_dump -h database-service -U $POSTGRES_USER $POSTGRES_DB > /backup/backup-$(date +%Y%m%d-%H%M%S).sql"
              ]

              env {
                name  = "POSTGRES_DB"
                value = var.database_name
              }

              env {
                name = "POSTGRES_USER"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.app_secrets.metadata[0].name
                    key  = "database_username"
                  }
                }
              }

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.app_secrets.metadata[0].name
                    key  = "database_password"
                  }
                }
              }

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }
            }

            volume {
              name = "backup-storage"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim.app_storage.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}

# Network Policy for security
resource "kubernetes_network_policy" "app_network_policy" {
  metadata {
    name      = "app-network-policy"
    namespace = kubernetes_namespace.applications.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "web-app"
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

      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "database"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    egress {
      to {}

      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    egress {
      to {}

      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

# Service Monitor for Prometheus
resource "kubernetes_manifest" "web_app_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "web-app-monitor"
      namespace = kubernetes_namespace.applications.metadata[0].name
      labels = {
        app = "web-app"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "web-app"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/metrics"
        }
      ]
    }
  }
}
