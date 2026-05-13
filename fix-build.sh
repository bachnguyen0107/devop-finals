#!/bin/bash
set -e

echo "=========================================="
echo "  Fix: Build and Deploy"
echo "=========================================="

cd ~/devop-finals

echo ""
echo "[1/5] Verifying package-lock.json..."
if [ -f "package-lock.json" ]; then
    echo "✓ package-lock.json found"
    ls -lh package-lock.json
else
    echo "✗ package-lock.json NOT found"
    echo "Attempting to generate it..."
    npm install
fi

echo ""
echo "[2/5] Removing old image (if exists)..."
docker rmi devop-midterm-web:1.0.0 2>/dev/null || true

echo ""
echo "[3/5] Building Docker image..."
docker build -t devop-midterm-web:1.0.0 --progress=plain .

echo ""
echo "[4/5] Verifying image..."
docker images | grep devop-midterm-web

echo ""
echo "[5/5] Starting services..."
docker-compose down 2>/dev/null || true
mkdir -p ssl
docker-compose up -d

echo ""
echo "=========================================="
echo "  Waiting for services..."
sleep 5

echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "Testing health endpoint..."
curl -s http://localhost/health || echo "Health check may still be starting..."

echo ""
echo "=========================================="
echo "  ✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Your application is available at:"
echo "  http://13.229.76.119/"
echo ""
