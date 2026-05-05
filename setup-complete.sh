#!/bin/bash
set -e

echo "=========================================="
echo "  DevOps Finals - Complete EC2 Setup"
echo "=========================================="

cd ~/devop-finals

# Step 1: Update docker-compose.yml
echo "Step 1: Updating docker-compose.yml..."
sed -i 's|DOCKERHUB_USERNAME/devop-midterm-web:1.0.0|devop-midterm-web:1.0.0|g' docker-compose.yml
echo "✓ Updated"

# Step 2: Create SSL directory
echo "Step 2: Creating SSL directory..."
mkdir -p ssl
echo "✓ Created"

# Step 3: Build Docker image
echo "Step 3: Building Docker image (this may take a few minutes)..."
docker build -t devop-midterm-web:1.0.0 .
if [ $? -eq 0 ]; then
    echo "✓ Image built successfully"
else
    echo "✗ Failed to build image"
    exit 1
fi

# Step 4: Verify image
echo "Step 4: Verifying Docker image..."
docker images | grep devop-midterm-web
echo "✓ Image verified"

# Step 5: Start services
echo "Step 5: Starting Docker Compose services..."
docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✓ Services started"
else
    echo "✗ Failed to start services"
    docker-compose logs
    exit 1
fi

# Step 6: Wait for services
echo "Step 6: Waiting for services to be ready..."
sleep 5

# Step 7: Check service status
echo "Step 7: Service Status:"
docker-compose ps
echo ""

# Step 8: Test connectivity
echo "Step 8: Testing connectivity..."
if curl -s http://localhost/health > /dev/null 2>&1; then
    echo "✓ Application is responding"
else
    echo "⚠ Application may still be starting..."
fi

echo ""
echo "=========================================="
echo "  ✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Your application is running at:"
echo "  http://13.212.58.182/"
echo ""
echo "Useful commands:"
echo "  View logs:     docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart:       docker-compose restart"
echo ""
