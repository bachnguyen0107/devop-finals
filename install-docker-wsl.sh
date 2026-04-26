#!/bin/bash

# Install Docker Directly in WSL
# This bypasses Docker Desktop integration issues

set -e

echo "🐳 Installing Docker Directly in WSL"
echo "===================================="

# Check if already installed
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "✅ Docker is already installed and working"
    docker --version
    exit 0
fi

echo "📦 Installing Docker..."

# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

echo "✅ Docker installed successfully!"
echo ""
echo "🔄 IMPORTANT: You need to log out and log back in for group changes to take effect"
echo "   Or run: newgrp docker"
echo ""
echo "🧪 Test Docker: docker --version"
echo "🧪 Test daemon: docker info"
echo ""
echo "After logging back in, run: ./setup-https-docker.sh"