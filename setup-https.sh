#!/bin/bash

# HTTPS/Let's Encrypt Setup Script
# This script sets up SSL certificates and configures HTTPS

set -e

DOMAIN="devop-midterm2026.online"
EMAIL="admin@devop-midterm2026.online"  # Change this to your email

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HTTPS/Let's Encrypt Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ docker-compose.yml not found${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ docker-compose not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"

# Create SSL directory structure
echo -e "${YELLOW}[2/5] Creating SSL directory structure...${NC}"

mkdir -p ssl/letsencrypt
mkdir -p ssl/certbot

echo -e "${GREEN}✓ SSL directories created${NC}"

# Check if domain is pointing to this server
echo -e "${YELLOW}[3/5] Checking domain DNS resolution...${NC}"

DOMAIN_IP=$(dig +short $DOMAIN | tail -1)
if [ -z "$DOMAIN_IP" ]; then
    echo -e "${RED}✗ Cannot resolve domain $DOMAIN${NC}"
    echo -e "${YELLOW}Make sure your domain is pointing to your EC2 instance IP${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Domain resolves to: $DOMAIN_IP${NC}"

# Copy new Nginx configuration
echo -e "${YELLOW}[4/5] Updating Nginx configuration...${NC}"

if [ ! -f "nginx-ssl.conf" ]; then
    echo -e "${RED}✗ nginx-ssl.conf not found${NC}"
    exit 1
fi

cp nginx-ssl.conf nginx.conf
echo -e "${GREEN}✓ Nginx configuration updated${NC}"

# Stop running services
echo -e "${YELLOW}[5/5] Stopping running services...${NC}"

docker-compose down

# Start with HTTP only first (for certificate generation)
echo -e "${YELLOW}Starting services in HTTP mode for certificate generation...${NC}"

docker-compose up -d

sleep 3

# Generate certificate using Let's Encrypt
echo -e "${YELLOW}Generating SSL certificate for $DOMAIN...${NC}"
echo -e "${YELLOW}This may take a minute...${NC}"

docker-compose exec -T certbot certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    -d "$DOMAIN" \
    -d "www.$DOMAIN"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Certificate generated successfully${NC}"
else
    echo -e "${RED}✗ Certificate generation failed${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  - Check that DNS is properly configured"
    echo -e "  - Check firewall allows port 80 (HTTP)"
    echo -e "  - Check email is correct"
    exit 1
fi

# Restart Nginx with SSL configuration
echo -e "${YELLOW}Restarting Nginx with SSL...${NC}"

docker-compose restart nginx

sleep 3

# Verify certificate
echo -e "${YELLOW}Verifying SSL certificate...${NC}"

if docker-compose exec -T nginx openssl s_client -connect localhost:443 -servername "$DOMAIN" < /dev/null 2>/dev/null | grep -q "subject="; then
    echo -e "${GREEN}✓ SSL certificate verified${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify certificate immediately, may need a moment to settle${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ HTTPS Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Your application is now available at:${NC}"
echo -e "  ${GREEN}https://$DOMAIN${NC}"
echo -e "  ${GREEN}https://www.$DOMAIN${NC}"
echo ""

echo -e "${YELLOW}HTTP traffic is automatically redirected to HTTPS${NC}"
echo ""

echo -e "${YELLOW}Test with:${NC}"
echo -e "  ${GREEN}curl https://$DOMAIN${NC}"
echo -e "  ${GREEN}curl https://www.$DOMAIN${NC}"
echo ""

echo -e "${YELLOW}Certificate Details:${NC}"
docker-compose exec -T certbot certbot certificates

echo ""
echo -e "${YELLOW}Automatic Renewal:${NC}"
echo -e "  Certbot is configured to automatically renew certificates"
echo -e "  Renewal checks happen every 12 hours"
echo -e "  Renewal is attempted 30 days before expiration"
echo ""

echo -e "${YELLOW}To view certificate renewal logs:${NC}"
echo -e "  ${GREEN}docker-compose logs -f certbot${NC}"
echo ""
