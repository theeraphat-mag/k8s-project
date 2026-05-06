terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # ใช้ config จากเครื่องที่รัน Jenkins/Terraform
}

# 1. จัดการ Namespace หลักของโปรเจค
resource "kubernetes_namespace" "monkeypop" {
  metadata {
    name = "monkeypop"
  }
}

# 2. จัดการ ConfigMap สำหรับแอปพลิเคชัน
resource "kubernetes_config_map" "backend_config" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.monkeypop.metadata[0].name
  }

  data = {
    REDIS_URL = "redis://redis:6379"
  }
}

# 3. จัดการ Secret (เช่น API Key) เพื่อความปลอดภัย
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
