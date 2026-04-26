#!/bin/bash

# Docker WSL Integration Checker

echo "🔍 Checking Docker WSL Integration..."
echo ""

# Check if running in WSL
if [ -z "$WSL_DISTRO_NAME" ]; then
    echo "❌ Not running in WSL"
    exit 1
fi

echo "✅ Running in WSL: $WSL_DISTRO_NAME"

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "✅ Docker is available"
    docker --version
else
    echo "❌ Docker not found in WSL"
    echo ""
    echo "📋 To fix this:"
    echo "1. Open Docker Desktop on Windows"
    echo "2. Go to Settings (⚙️) > Resources > WSL Integration"
    echo "3. Enable integration for '$WSL_DISTRO_NAME'"
    echo "4. Click 'Apply & Restart'"
    echo "5. Wait for Docker Desktop to restart"
    echo "6. Try again: wsl docker --version"
    exit 1
fi

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    echo "✅ docker-compose is available"
    docker-compose --version
else
    echo "⚠️  docker-compose not found"
    echo "   You can use 'docker compose' (newer version) or install it:"
    echo "   sudo apt install -y docker-compose"
fi

# Check Docker daemon
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon not accessible"
    echo "   Make sure Docker Desktop is running on Windows"
fi

echo ""
echo "🎉 Docker integration looks good!"
echo "You can now run: ./setup-https-docker.sh"