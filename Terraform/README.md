# Terraform: Docker Infrastructure

This directory contains Terraform configuration to build and run Docker containers for:
- **nginx** (reverse proxy/web server)
- **backend** (Node.js app from `../backend`)
- **frontend** (HTML/static from `../frontend`)

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

### Step 2: Configure Variables (optional)

Copy the example variables file and customize:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### Step 3: Initialize & Apply

**Using Make (Linux/macOS):**
```bash
make init
make plan
make apply
```

**Using Terraform directly:**
```bash
cd Terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Auto-approve (no confirmation):**
```bash
terraform apply -auto-approve
```

## Default Configuration

- **Frontend:** http://localhost:3000 (port 3000)
- **Backend:** http://localhost:3001 (port 3001)
- **Nginx:** http://localhost:8000 (port 8000)

## Override Variables at Runtime

```bash
terraform apply \
  -var 'backend_external_port=3001' \
  -var 'frontend_external_port=3000' \
  -auto-approve
```

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

- Docker daemon running
  - Linux: `/var/run/docker.sock` accessible
  - macOS: Docker Desktop running
  - Windows: Docker Desktop running (WSL2 backend recommended)
- Terraform 1.0+
- Network access to download Docker images

## Troubleshooting

**Docker connection error:**
- Ensure Docker daemon is running (`docker ps` works)
- On Windows, check Docker Desktop is active
- If using remote Docker, set `docker_host` in `terraform.tfvars`

**Port already in use:**
- Change port in `terraform.tfvars` (e.g., `backend_external_port = 3002`)
- Or stop existing containers: `docker ps` then `docker stop <container>`

**Permission denied (Linux):**
- Add user to docker group: `sudo usermod -aG docker $USER`
- Then log out and log back in

## Outputs

After `terraform apply`, view outputs:
```bash
terraform output
# Show specific output:
terraform output backend_container_id
terraform output frontend_external_port
```

## Git Workflow

These files are safe to commit:
- `*.tf` files ✓
- `terraform.tfvars.example` ✓
- `.gitignore`, `setup.sh`, `setup.ps1`, `Makefile` ✓

These are **NOT** committed (in `.gitignore`):
- `terraform.tfvars` (contains local settings)
- `.terraform/` (local cache)
- `terraform.tfstate*` (local state)
- `tfplan` (temporary plan files)

