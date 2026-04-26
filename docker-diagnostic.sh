#!/bin/bash

# Comprehensive Docker WSL Diagnostic Script

echo "🔍 Docker WSL Integration Diagnostic"
echo "===================================="
echo ""

# Check 1: Are we in WSL?
echo "1. WSL Environment Check:"
if [ -z "$WSL_DISTRO_NAME" ]; then
    echo "   ❌ Not running in WSL"
    echo "   Please run this from WSL terminal"
    exit 1
else
    echo "   ✅ Running in WSL: $WSL_DISTRO_NAME"
fi

# Check 2: Is Docker command available?
echo ""
echo "2. Docker Command Check:"
if command -v docker &> /dev/null; then
    echo "   ✅ Docker command found in PATH"
    docker --version 2>/dev/null || echo "   ⚠️  Docker command exists but may not be functional"
else
    echo "   ❌ Docker command not found"
    echo "   📋 Solutions:"
    echo "   a) Enable WSL integration in Docker Desktop"
    echo "   b) Or install Docker directly in WSL:"
    echo "      curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "      sudo sh get-docker.sh"
    echo "      sudo usermod -aG docker $USER"
    exit 1
fi

# Check 3: Can we connect to Docker daemon?
echo ""
echo "3. Docker Daemon Connection:"
if docker info &> /dev/null; then
    echo "   ✅ Docker daemon is accessible"
    echo "   🐳 Docker is working correctly!"
else
    echo "   ❌ Cannot connect to Docker daemon"
    echo ""
    echo "   📋 Troubleshooting steps:"
    echo "   1. Make sure Docker Desktop is RUNNING on Windows"
    echo "   2. In Docker Desktop: Settings → Resources → WSL Integration"
    echo "   3. Enable integration for '$WSL_DISTRO_NAME'"
    echo "   4. Click 'Apply & Restart'"
    echo "   5. Wait for Docker Desktop to fully restart"
    echo "   6. Try again: wsl docker --version"
    echo ""
    echo "   Alternative: Install Docker directly in WSL"
    echo "   Run: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

# Check 4: Docker Compose availability
echo ""
echo "4. Docker Compose Check:"
if command -v docker-compose &> /dev/null; then
    echo "   ✅ docker-compose available"
    docker-compose --version
elif docker compose version &> /dev/null; then
    echo "   ✅ Docker Compose V2 available (docker compose)"
    docker compose version
else
    echo "   ⚠️  No docker-compose found"
    echo "   You can use 'docker compose' or install docker-compose:"
    echo "   sudo apt install -y docker-compose"
fi

# Check 5: Test basic Docker functionality
echo ""
echo "5. Basic Docker Test:"
echo "   Pulling hello-world image..."
if docker run --rm hello-world &> /dev/null; then
    echo "   ✅ Docker can run containers"
else
    echo "   ❌ Docker cannot run containers"
    echo "   Check Docker Desktop settings and try again"
fi

echo ""
echo "🎉 All checks passed! Docker is ready to use."
echo "You can now run: ./setup-https-docker.sh"