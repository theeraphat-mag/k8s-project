# Terraform: Kubernetes Infrastructure

This directory contains Terraform configuration for the base Kubernetes infrastructure used by the MonkeyPop project.

Terraform is responsible for shared infrastructure resources. Ansible is responsible only for deploying the frontend and backend application workloads.

## Resources Managed

- **Namespace:** `monkeypop`
- **ConfigMap:** `backend-config` stores `REDIS_URL`
- **Secret:** `backend-secret` stores `API_KEY`
- **PersistentVolumeClaim:** `redis-pvc` stores Redis data
- **Deployment:** `redis` runs Redis for leaderboard storage
- **Service:** `redis` exposes Redis inside the Kubernetes cluster

## Prerequisites

- Terraform 1.x or newer
- A running Kubernetes cluster
- Kubeconfig available at `/var/jenkins_home/.kube/config`

## Usage

Initialize Terraform:

```bash
terraform init
```

Review changes:

```bash
terraform plan
```

Apply infrastructure:

```bash
terraform apply -auto-approve
```

## Variables

| Variable | Description | Default |
|---|---|---|
| `namespace_name` | Kubernetes namespace name | `monkeypop` |
| `redis_url` | Redis connection string used by backend | `redis://redis:6379` |
| `api_key` | API key for backend authentication | `monkey-secret-key` |

## Useful Commands

```bash
terraform show
terraform fmt
terraform validate
terraform destroy
```

## Responsibility Split

| Tool | Responsibility |
|---|---|
| Terraform | Namespace, ConfigMap, Secret, Redis PVC, Redis Deployment, Redis Service |
| Ansible | Backend Deployment/Service and Frontend Deployment/Service |

