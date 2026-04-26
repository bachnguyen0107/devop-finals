#!/bin/bash

# Deploy HTTPS Application with Existing Certificates
# Run this after generating certificates on EC2

set -e

DOMAIN="devop-midterm2026.online"
EMAIL="523k0010@student.tdtu.edu.vn"

echo "🚀 Deploying HTTPS Application"
echo "=============================="

# Check if certificates exist
if [ ! -d "ssl/letsencrypt/live/$DOMAIN" ]; then
    echo "❌ Certificates not found!"
    echo "📋 You need to:"
    echo "1. Generate certificates on your EC2 server first"
    echo "2. Copy them to ssl/letsencrypt/ directory"
    echo "3. Or run: ./generate-cert-ec2.sh on your EC2 server"
    exit 1
fi

echo "✅ Certificates found"

# Stop any running services
echo "🛑 Stopping existing services..."
docker stop $(docker ps -q) 2>/dev/null || true

# Start services with HTTPS
echo "🌐 Starting services with HTTPS..."

# Start MongoDB
docker run -d --name devop_midterm_mongo \
  -v $(pwd)/mongo_data:/data/db \
  mongo:6.0

# Build and start web app
echo "🏗️  Building web application..."
docker build -t devop-midterm-web:1.0.0 .

docker run -d --name devop_midterm_web \
  --env-file .env \
  -v $(pwd)/public/uploads:/app/public/uploads \
  -v $(pwd)/logs:/app/logs \
  --link devop_midterm_mongo:mongo \
  devop-midterm-web:1.0.0

# Start nginx with SSL
docker run -d --name devop_midterm_nginx \
  -p 80:80 -p 443:443 \
  -v $(pwd)/nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/ssl/letsencrypt:/etc/letsencrypt:ro \
  -v $(pwd)/ssl/certbot:/var/www/certbot:ro \
  --link devop_midterm_web:web \
  nginx:latest

# Start certbot for renewal
docker run -d --name devop_midterm_certbot \
  -v $(pwd)/ssl/letsencrypt:/etc/letsencrypt \
  -v $(pwd)/ssl/certbot:/var/www/certbot \
  --link devop_midterm_nginx:nginx \
  certbot/certbot:latest \
  sh -c 'trap exit TERM; while :; do certbot renew --webroot -w /var/www/certbot --quiet --post-hook "docker exec devop_midterm_nginx nginx -s reload"; sleep 12h & wait $${!}; done;'

echo "✅ HTTPS deployment complete!"
echo ""
echo "🌐 Test your HTTPS setup:"
echo "   curl -I https://$DOMAIN"
echo "   curl -I http://$DOMAIN (should redirect to HTTPS)"
echo ""
echo "📊 Check service status:"
echo "   docker ps"
echo ""
echo "📋 Management commands:"
echo "   ./manage-services.sh status"
echo "   ./manage-services.sh logs nginx"