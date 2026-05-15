terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path = "/var/jenkins_home/.kube/config"
}

# 1. Create or manage the application namespace.
resource "kubernetes_namespace" "monkeypop" {
  metadata {
    name = var.namespace_name
  }
}

# 2. Manage the backend ConfigMap.
resource "kubernetes_config_map" "backend_config" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  data = {
    REDIS_URL = var.redis_url
  }
}

# 3. Manage the backend Secret.
resource "kubernetes_secret" "backend_secret" {
  metadata {
    name      = "backend-secret"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  data = {
    API_KEY = var.api_key
  }

  type = "Opaque"
}

# 4. Manage Redis persistent storage.
resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata {
    name      = "redis-pvc"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# 5. Manage Redis as the shared data service for leaderboard storage.
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name    = "redis"
          image   = "redis:alpine"
          command = ["redis-server", "--appendonly", "yes"]

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# 6. Manage the Redis service used by the backend.
resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }
  }
}
