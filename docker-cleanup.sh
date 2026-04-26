#!/bin/bash

# Comprehensive Docker Cleanup Script

echo "🧹 Cleaning up Docker environment..."

# Stop all containers
echo "🛑 Stopping containers..."
docker stop $(docker ps -q) 2>/dev/null || echo "   No running containers"

# Remove all containers
echo "🗑️  Removing containers..."
docker rm -f $(docker ps -a -q) 2>/dev/null || echo "   No containers to remove"

# Remove dangling images
echo "🖼️  Cleaning up images..."
docker image prune -f 2>/dev/null || echo "   No images to clean"

# Remove dangling volumes
echo "💾 Cleaning up volumes..."
docker volume prune -f 2>/dev/null || echo "   No volumes to clean"

# Show current state
echo ""
echo "📊 Current Docker state:"
docker ps -a
echo ""
echo "🐳 Docker is ready for fresh deployment!"