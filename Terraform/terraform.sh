#!/bin/bash
# Terraform launcher for Unix/Linux/macOS

if [ -z "$1" ]; then
    cat <<EOF
Terraform Launcher for Kubernetes
================================
Usage: ./terraform.sh [command] [args]

Commands:
  init      - Initialize Terraform (Kubernetes Provider)
  validate  - Validate Terraform files
  plan      - Create and show plan
  apply     - Apply Infrastructure to K8s
  destroy   - Remove Infrastructure from K8s
  clean     - Remove state files
  show      - Show current state
  help      - Show this help message

Examples:
  ./terraform.sh init
  ./terraform.sh plan
  ./terraform.sh apply
  ./terraform.sh destroy

EOF
    exit 0
fi

# Check if terraform exists
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform not found in PATH"
    echo "Please run: chmod +x setup.sh && ./setup.sh"
    echo ""
    echo "Or download from: https://www.terraform.io/downloads"
    exit 1
fi

cmd=$1
shift

case "$cmd" in
    init)
        terraform init
        ;;
    validate)
        terraform validate
        ;;
    plan)
        terraform plan -out=tfplan
        ;;
    apply)
        if [ -f tfplan ]; then
            terraform apply tfplan
        else
            terraform apply -auto-approve
        fi
        ;;
    destroy)
        terraform destroy
        ;;
    clean)
        rm -rf .terraform .terraform.lock.hcl
        rm -f terraform.tfstate* tfplan *.backup
        echo "Cleaned up Terraform files"
        ;;
    show)
        terraform show
        ;;
    help|--help|-h)
        $0  # Call script with no args to show help
        ;;
    *)
        terraform "$cmd" "$@"
        ;;
esac
