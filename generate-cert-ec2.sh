#!/bin/bash

# Certificate Generation on EC2 Server
# Run this script ON YOUR EC2 INSTANCE, not locally

set -e

DOMAIN="devop-midterm2026.online"
EMAIL="523k0010@student.tdtu.edu.vn"

echo "🔐 Generating SSL Certificate on EC2"
echo "===================================="

# Install Certbot
echo "📦 Installing Certbot..."
sudo apt update
sudo apt install -y certbot

# Create webroot directory
echo "📁 Creating webroot directory..."
sudo mkdir -p /var/www/certbot

# Stop any running web services temporarily
echo "🛑 Stopping web services..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true

# Kill any processes on port 80
sudo fuser -k 80/tcp 2>/dev/null || true

# Start temporary nginx for certificate generation
echo "🌐 Starting temporary nginx for ACME challenge..."

sudo bash -c "cat > /tmp/nginx-temp.conf << 'EOF'
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }

    location / {
        return 200 'Certificate generation in progress...';
        add_header Content-Type text/plain;
    }
}
EOF"

# Start temporary nginx
sudo docker run -d --name cert-gen-nginx \
  -p 80:80 \
  -v /tmp/nginx-temp.conf:/etc/nginx/conf.d/default.conf:ro \
  -v /var/www/certbot:/var/www/certbot \
  nginx:latest

# Wait for nginx to start
sleep 5

# Generate certificate
echo "🔐 Generating certificate..."
sudo certbot certonly --webroot \
  -w /var/www/certbot \
  --non-interactive \
  --agree-tos \
  --expand \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

# Check if certificate was generated
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "❌ Certificate generation failed!"
    echo "📄 Check logs: sudo cat /var/log/letsencrypt/letsencrypt.log"
    exit 1
fi

echo "✅ Certificate generated successfully!"

# Copy certificates to project directory (if it exists)
if [ -d "/home/ubuntu/devop-finals/ssl" ]; then
    echo "📋 Copying certificates to project directory..."
    sudo cp -r /etc/letsencrypt /home/ubuntu/devop-finals/ssl/
    sudo chown -R ubuntu:ubuntu /home/ubuntu/devop-finals/ssl/
fi

# Stop temporary nginx
echo "🛑 Stopping temporary nginx..."
sudo docker stop cert-gen-nginx
sudo docker rm cert-gen-nginx

# Set up auto-renewal
echo "🔄 Setting up auto-renewal..."
sudo crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet --post-hook 'systemctl reload nginx'"; } | sudo crontab -

echo ""
echo "🎉 Certificate setup complete!"
echo "📍 Certificates are in: /etc/letsencrypt/live/$DOMAIN/"
echo "🔧 Next: Deploy your application with the certificates"