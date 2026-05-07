#!/bin/bash
# Setup script for Terraform (Linux/macOS)

set -e

TERRAFORM_VERSION="1.15.1"
TERRAFORM_DIR="$HOME/.local/bin"
OS_TYPE=$(uname -s)
ARCH=$(uname -m)

# Determine OS and architecture
if [ "$OS_TYPE" = "Darwin" ]; then
  OS="darwin"
  if [ "$ARCH" = "arm64" ]; then
    ARCH="arm64"
  else
    ARCH="amd64"
  fi
elif [ "$OS_TYPE" = "Linux" ]; then
  OS="linux"
  if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
  else
    ARCH="amd64"
  fi
else
  echo "Unsupported OS: $OS_TYPE"
  exit 1
fi

echo "Detected: $OS_TYPE ($ARCH)"

# Create directory if not exists
mkdir -p "$TERRAFORM_DIR"

# Download and install Terraform
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
TERRAFORM_ZIP="$TERRAFORM_DIR/terraform_${TERRAFORM_VERSION}.zip"

echo "Downloading Terraform from $TERRAFORM_URL..."
curl -fsSL "$TERRAFORM_URL" -o "$TERRAFORM_ZIP"

echo "Extracting Terraform..."
unzip -o "$TERRAFORM_ZIP" -d "$TERRAFORM_DIR"
rm "$TERRAFORM_ZIP"

# Add to PATH if not already there
if ! grep -q "$TERRAFORM_DIR" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"\$PATH:$TERRAFORM_DIR\"" >> "$HOME/.bashrc"
  echo "Added $TERRAFORM_DIR to PATH in ~/.bashrc"
fi

if ! grep -q "$TERRAFORM_DIR" "$HOME/.zshrc" 2>/dev/null; then
  echo "export PATH=\"\$PATH:$TERRAFORM_DIR\"" >> "$HOME/.zshrc"
  echo "Added $TERRAFORM_DIR to PATH in ~/.zshrc"
fi

# Verify installation
export PATH="$PATH:$TERRAFORM_DIR"
echo ""
echo "Installation complete!"
terraform -version
