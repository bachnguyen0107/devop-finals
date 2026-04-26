#!/bin/bash

# HTTPS Setup Script for WSL - Alternative Version
# This version works without docker-compose by using docker commands directly

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
echo -e "${BLUE}  HTTPS Setup (Direct Docker Commands)${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found!${NC}"
    echo -e "${YELLOW}Please enable Docker Desktop WSL integration:${NC}"
    echo "1. Open Docker Desktop"
    echo "2. Go to Settings > Resources > WSL Integration"
    echo "3. Enable integration for your Ubuntu distro"
    echo "4. Restart Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✓ Docker is available${NC}"

# Step 1: Install Certbot
echo -e "${YELLOW}Step 1: Installing Certbot...${NC}"
sudo apt update
sudo apt install -y certbot

# Step 2: Create SSL directories
echo -e "${YELLOW}Step 2: Creating SSL directories...${NC}"
mkdir -p ssl/letsencrypt
mkdir -p ssl/certbot

# Step 3: Stop any running containers
echo -e "${YELLOW}Step 3: Stopping running containers...${NC}"
docker stop $(docker ps -q) 2>/dev/null || true

# Step 4: Create temporary nginx config
echo -e "${YELLOW}Step 4: Creating temporary nginx config...${NC}"
cat > nginx-temp.conf << 'EOF'
server {
    listen 80;
    server_name devop-midterm2026.online www.devop-midterm2026.online;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    location / {
        return 302 http://localhost:3000$request_uri;
    }
}
EOF

# Step 5: Start temporary nginx
echo -e "${YELLOW}Step 5: Starting temporary nginx...${NC}"
docker run -d --name temp-nginx \
  -p 80:80 \
  -v $(pwd)/nginx-temp.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/ssl/certbot:/var/www/certbot \
  nginx:latest

sleep 3

# Step 6: Generate certificate
echo -e "${YELLOW}Step 6: Generating SSL certificate...${NC}"
sudo certbot certonly --webroot \
  -w $(pwd)/ssl/certbot \
  --non-interactive \
  --agree-tos \  --expand \  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${RED}Certificate generation failed!${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "1. Check DNS: dig $DOMAIN"
    echo "2. Check port 80: curl -I http://$DOMAIN"
    echo "3. Check nginx: docker logs temp-nginx"
    exit 1
fi

echo -e "${GREEN}✓ Certificate generated successfully${NC}"

# Step 7: Stop temp nginx
echo -e "${YELLOW}Step 7: Stopping temporary nginx...${NC}"
docker stop temp-nginx
docker rm temp-nginx

# Step 8: Copy certificates
echo -e "${YELLOW}Step 8: Copying certificates...${NC}"
sudo cp -r /etc/letsencrypt ./ssl/
sudo chown -R $(id -u):$(id -g) ./ssl/

# Step 9: Start services manually
echo -e "${YELLOW}Step 9: Starting services...${NC}"

# Start MongoDB
docker run -d --name devop_midterm_mongo \
  -v $(pwd)/mongo_data:/data/db \
  mongo:6.0

# Start web app
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

echo -e "${GREEN}✓ HTTPS setup complete!${NC}"
echo -e "${GREEN}Your site should be available at: https://$DOMAIN${NC}"

# Create a simple management script
cat > manage-services.sh << 'EOF'
#!/bin/bash
case "$1" in
    start)
        echo "Starting services..."
        docker start devop_midterm_mongo devop_midterm_web devop_midterm_nginx devop_midterm_certbot
        ;;
    stop)
        echo "Stopping services..."
        docker stop devop_midterm_certbot devop_midterm_nginx devop_midterm_web devop_midterm_mongo
        ;;
    restart)
        echo "Restarting services..."
        docker restart devop_midterm_mongo devop_midterm_web devop_midterm_nginx devop_midterm_certbot
        ;;
    logs)
        echo "Showing logs for: $2"
        docker logs "devop_midterm_$2"
        ;;
    status)
        echo "Service status:"
        docker ps --filter "name=devop_midterm_"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs <service>|status}"
        echo "Services: mongo, web, nginx, certbot"
        ;;
esac
EOF

chmod +x manage-services.sh

echo ""
echo -e "${YELLOW}Management commands:${NC}"
echo "./manage-services.sh start    # Start all services"
echo "./manage-services.sh stop     # Stop all services"
echo "./manage-services.sh status   # Check service status"
echo "./manage-services.sh logs nginx  # View nginx logs"