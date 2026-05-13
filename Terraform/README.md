# Terraform: Kubernetes Infrastructure

This directory contains Terraform configuration for the Kubernetes resources that Jenkins prepares before deployment:
- **Namespace** for the application
- **ConfigMap** for backend runtime settings
- **Secret** for backend credentials

Terraform is used here as the infrastructure bootstrap layer, not as the application deploy tool. The application pods themselves are applied by Ansible and Kubernetes manifests.

## Quick Start

### Step 1: Install Terraform

**Linux/macOS:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows (PowerShell as Administrator):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1
```

**Or manually:** Download from https://www.terraform.io/downloads

### Step 2: Initialize & Apply

```bash
cd Terraform
terraform init
terraform validate
terraform apply -auto-approve
```

## What Terraform Manages

- `Namespace`: `monkeypop`
- `ConfigMap`: `backend-config`
- `Secret`: `backend-secret`

These objects are shared inputs for the backend deploy stage in Jenkins.

## Cleanup

Remove all resources:
```bash
terraform destroy
# or with Make:
make destroy
```

Clean local state files:
```bash
make clean
```

## Useful Commands

```bash
# Validate syntax
terraform validate
make validate

# Format files
terraform fmt -recursive
make fmt

# Show current state
terraform show
make status

# Create plan file (for review before apply)
terraform plan -out=tfplan

# Apply specific plan
terraform apply tfplan
```

## Requirements

- Kubernetes cluster access from the Jenkins host
- `kubectl` configured for the target cluster
- Terraform 1.0+
- Network access to the Kubernetes API server

## Troubleshooting

**Kubernetes connection error:**
- Ensure Jenkins can read `/var/jenkins_home/.kube/config`
- Confirm the target namespace exists or is created before apply
- Check cluster access with `kubectl get ns`

**Terraform state error:**
- Run `terraform init` again if the provider lock file changes
- Use `terraform fmt -recursive` before committing changes

## Outputs

This configuration does not create runtime app containers. It provisions the Kubernetes objects that the Jenkins pipeline deploys into.

## Cleanup

```bash
terraform destroy -auto-approve
```

