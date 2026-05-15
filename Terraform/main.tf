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
    name = "monkeypop"
  }
}

# 2. Manage the backend ConfigMap.
resource "kubernetes_config_map" "backend_config" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  data = {
    REDIS_URL = "redis://redis:6379"
  }
}

# 3. Manage the backend Secret.
resource "kubernetes_secret" "backend_secret" {
  metadata {
    name      = "backend-secret"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  data = {
    API_KEY = "monkey-secret-key"
  }

  type = "Opaque"
}
