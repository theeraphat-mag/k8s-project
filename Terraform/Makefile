.PHONY: help setup init plan apply destroy validate fmt clean

TERRAFORM := terraform
TF_DIR := $(shell pwd)

help:
	@echo "Terraform Management Commands"
	@echo "========================================"
	@echo "make setup       - Install Terraform"
	@echo "make init        - Initialize Terraform"
	@echo "make validate    - Validate Terraform files"
	@echo "make fmt         - Format Terraform files"
	@echo "make plan        - Create Terraform plan"
	@echo "make apply       - Apply Terraform changes"
	@echo "make destroy     - Destroy infrastructure"
	@echo "make clean       - Remove Terraform state/cache"
	@echo ""

setup:
	@echo "Setting up Terraform..."
	@if [ -f setup.sh ]; then \
		chmod +x setup.sh; \
		./setup.sh; \
	else \
		echo "setup.sh not found!"; \
		exit 1; \
	fi

init:
	$(TERRAFORM) init

validate:
	$(TERRAFORM) validate

fmt:
	$(TERRAFORM) fmt -recursive

plan:
	$(TERRAFORM) plan -out=tfplan

apply: plan
	$(TERRAFORM) apply tfplan

apply-auto:
	$(TERRAFORM) apply -auto-approve

destroy:
	$(TERRAFORM) destroy

clean:
	rm -rf .terraform terraform.tfstate* tfplan *.backup
	@echo "Cleaned up Terraform state and plan files"

status:
	@echo "Terraform State:"
	@$(TERRAFORM) show -no-color || echo "No state file found"
