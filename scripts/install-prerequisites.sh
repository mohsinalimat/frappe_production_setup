#!/bin/bash

# ==============================================================================
# Frappe Docker - Prerequisites Installation Script
# ==============================================================================
# This script installs Docker, Docker Compose, and Git on Ubuntu/Debian
# ==============================================================================

set -e

echo "=========================================="
echo "Frappe Docker - Prerequisites Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Please run as root or with sudo"
    echo "Usage: sudo ./install-prerequisites.sh"
    exit 1
fi

# Update package list
echo "📦 Updating package list..."
apt-get update

# Install basic dependencies
echo "📦 Installing basic dependencies..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✅ Docker is already installed ($(docker --version))"
else
    echo "🐳 Installing Docker..."
    
    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Enable Docker service
    systemctl enable docker
    systemctl start docker
    
    echo "✅ Docker installed successfully ($(docker --version))"
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose is already installed ($(docker compose version))"
else
    echo "⚠️  Docker Compose plugin not found. Installing..."
    apt-get install -y docker-compose-plugin
fi

# Check Git
if command -v git &> /dev/null; then
    echo "✅ Git is already installed ($(git --version))"
else
    echo "📦 Installing Git..."
    apt-get install -y git
fi

# Add current user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    echo "👤 Adding user $SUDO_USER to docker group..."
    usermod -aG docker "$SUDO_USER"
    echo "⚠️  Please log out and log back in for group changes to take effect"
fi

echo ""
echo "=========================================="
echo "✅ All prerequisites installed successfully!"
echo "=========================================="
echo ""
echo "Installed versions:"
docker --version
docker compose version
git --version
echo ""
echo "🎉 You're ready to deploy Frappe/ERPNext!"
echo ""
echo "Next steps:"
echo "1. Configure your .env file: cp .env.example .env && nano .env"
echo "2. (Optional) Edit apps.json to include custom apps"
echo "3. (Optional) Build custom image: ./scripts/build-image.sh"
echo "4. Deploy: ./scripts/deploy-production.sh"
echo ""
