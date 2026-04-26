#!/bin/bash

# HTTPS Setup Script for WSL - Step-by-Step Certbot Configuration
# This script provides a reliable way to set up HTTPS with Let's Encrypt

set -e

# Configuration - CHANGE THESE VALUES
DOMAIN="devop-midterm2026.online"
EMAIL="523k0010@student.tdtu.edu.vn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HTTPS Setup Guide for WSL${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Install Certbot
echo -e "${YELLOW}Step 1: Installing Certbot...${NC}"
sudo apt update
sudo apt install -y certbot

# Step 2: Stop your current services
echo -e "${YELLOW}Step 2: Stopping current services...${NC}"
docker-compose down

# Step 3: Create temporary HTTP-only nginx config for certificate generation
echo -e "${YELLOW}Step 3: Creating temporary HTTP config...${NC}"
cat > nginx-temp.conf << 'EOF'
server {
    listen 80;
    server_name devop-midterm2026.online www.devop-midterm2026.online;

    # Let's Encrypt challenge directory
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    # Temporary redirect - will be replaced after cert generation
    location / {
        return 302 http://devop-midterm2026.online:3000$request_uri;
    }
}
EOF

# Step 4: Start temporary nginx for certificate generation
echo -e "${YELLOW}Step 4: Starting temporary nginx...${NC}"
docker run -d --name temp-nginx \
  -p 80:80 \
  -v $(pwd)/nginx-temp.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/ssl/certbot:/var/www/certbot:ro \
  nginx:latest

# Wait for nginx to start
sleep 5

# Step 5: Generate certificate
echo -e "${YELLOW}Step 5: Generating SSL certificate...${NC}"
sudo certbot certonly --webroot \
  -w $(pwd)/ssl/certbot \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

# Check if certificate was generated
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${RED}Certificate generation failed!${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "1. Check DNS: dig $DOMAIN"
    echo "2. Check firewall: ufw status"
    echo "3. Check nginx: docker logs temp-nginx"
    exit 1
fi

echo -e "${GREEN}✓ Certificate generated successfully${NC}"

# Step 6: Stop temporary nginx
echo -e "${YELLOW}Step 6: Stopping temporary nginx...${NC}"
docker stop temp-nginx
docker rm temp-nginx

# Step 7: Copy certificates to project directory
echo -e "${YELLOW}Step 7: Copying certificates...${NC}"
sudo cp -r /etc/letsencrypt ./ssl/
sudo chown -R $(id -u):$(id -g) ./ssl/

# Step 8: Start services with HTTPS
echo -e "${YELLOW}Step 8: Starting services with HTTPS...${NC}"
docker-compose -f docker-compose-ssl.yml up -d

# Step 9: Set up auto-renewal
echo -e "${YELLOW}Step 9: Setting up auto-renewal...${NC}"
sudo crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f $(pwd)/docker-compose-ssl.yml restart nginx"; } | sudo crontab -

echo -e "${GREEN}✓ HTTPS setup complete!${NC}"
echo -e "${GREEN}Your site should now be available at: https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test HTTPS: curl -I https://$DOMAIN"
echo "2. Check renewal: sudo certbot certificates"
echo "3. Monitor logs: docker-compose -f docker-compose-ssl.yml logs -f nginx"