# 🏗️ Terraform: Kubernetes Infrastructure

This directory contains Terraform configuration to manage the base infrastructure and configurations for the **MonkeyPop** project on Kubernetes.

## 📌 Resources Managed

- **Namespace:** `monkeypop` (References existing namespace)
- **ConfigMap:** `backend-config` (Stores `REDIS_URL`)
- **Secret:** `backend-secret` (Stores `API_KEY` for backend security)

---

## ⚙️ Prerequisites

- **Terraform:** ≥ 1.x
- **Kubernetes Cluster:** (Minikube, K3s, or Cloud-based)
- **Kubeconfig:** Located at `/var/jenkins_home/.kube/config` (or adjusted in `provider.tf`)

---

## 🏃 Usage

### 1. Initialize Terraform
Downloads the necessary Kubernetes provider.
```bash
terraform init
```

### 2. Plan Changes
Review what Terraform will create or modify.
```bash
terraform plan
```

### 3. Apply Configuration
Deploy the ConfigMap and Secret to your cluster.
```bash
terraform apply -auto-approve
```

---

## 🔧 Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `namespace_name` | Name of the K8s namespace | `monkeypop` |
| `redis_url` | Redis connection string | `redis://redis:6379` |
| `api_key` | API Key for backend auth | `monkey-secret-key` |

---

## 🛠️ Useful Commands

```bash
# Check current status
terraform show

# Format code
terraform fmt

# Destroy resources (Be careful!)
terraform destroy
```

---

## 📝 Configuration Details

- **Provider:** Uses the `hashicorp/kubernetes` provider.
- **State:** Managed locally (`terraform.tfstate`).
- **Security:** `API_KEY` is marked as `sensitive` in `variables.tf`.

