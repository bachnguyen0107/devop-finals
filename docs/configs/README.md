# Phase 2 Configuration Reference

## Overview
This directory contains backup/reference configurations for Phase 2 Traditional Deployment components.

## Files

### 1. `nginx-product-api.conf`
**Purpose**: Nginx reverse proxy configuration
**Location on server**: `/etc/nginx/sites-available/product-api`
**What it does**:
- Listens on port 80 (HTTP)
- Listens on port 443 (HTTPS - with self-signed cert)
- Redirects HTTP → HTTPS
- Reverse proxy to app on port 3000
- Handles SSL/TLS encryption
- Logs requests to `/var/log/nginx/product-api-access.log`

**To use**:
```bash
# Copy to server
scp -i ~/.ssh/id_rsa nginx-product-api.conf ubuntu@SERVER_IP:/tmp/

# On server
sudo cp /tmp/nginx-product-api.conf /etc/nginx/sites-available/product-api
sudo ln -s /etc/nginx/sites-available/product-api /etc/nginx/sites-enabled/product-api
sudo nginx -t
sudo systemctl reload nginx
```

---

### 2. `ecosystem.config.js`
**Purpose**: PM2 process manager configuration
**Location on server**: `~/product-api/ecosystem.config.js` (optional)
**What it does**:
- Defines app startup settings
- Auto-restart on crash
- Memory limits
- Logging configuration
- Watch/ignore patterns

**To use**:
```bash
# Instead of: pm2 start main.js --name "product-api"
# Run: pm2 start ecosystem.config.js
```

---

### 3. `docker-compose.yml`
**Purpose**: Docker Compose configuration for MongoDB + App
**Location on server**: `~/product-api/docker-compose.yml` (optional)
**What it does**:
- Defines MongoDB service (mongo:6.0)
- Defines Node.js app service
- Creates volume for MongoDB data persistence
- Creates network for service communication
- Manages ports and environment variables

**To use**:
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f
```

---

### 4. `phase2-helper.sh`
**Purpose**: Helper script for common operations
**Location on server**: `~/product-api/scripts/phase2-helper.sh` (optional)
**What it does**:
- Start/stop MongoDB
- Start/stop/restart/monitor app
- Reload Nginx
- Full health checks

**To use**:
```bash
chmod +x phase2-helper.sh
./phase2-helper.sh

# Or run specific commands:
./phase2-helper.sh start_mongodb
./phase2-helper.sh health_check
./phase2-helper.sh restart_app_pm2
```

---

## Quick Reference: Phase 2 Commands

### MongoDB (Docker)
```bash
# Start MongoDB
sudo docker run -d --name mongodb -p 27017:27017 mongo:6.0

# Stop MongoDB
sudo docker stop mongodb
sudo docker rm mongodb

# Check status
sudo docker ps | grep mongo
```

### Application (PM2)
```bash
# Start with PM2
pm2 start main.js --name "product-api"

# Configure auto-start
pm2 startup
pm2 save

# Check status
pm2 list
pm2 logs product-api

# Restart
pm2 restart product-api
```

### Nginx (Reverse Proxy)
```bash
# Test configuration
sudo nginx -t

# Reload (apply changes)
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx

# View logs
sudo tail -20 /var/log/nginx/product-api-access.log
```

### SSL Certificate (Self-Signed)
```bash
# Create certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/self-signed.key \
  -out /etc/ssl/certs/self-signed.crt \
  -subj "/C=VN/ST=State/L=City/O=Org/CN=54.234.158.141"
```

---

## Environment Variables (.env)

```bash
# Application configuration
PORT=3000

# Database connection
MONGO_URI=mongodb://localhost:27017/products_db
```

---

## Health Check Commands

```bash
# All services running?
sudo docker ps | grep mongo
pm2 list
sudo systemctl status nginx

# API responsive?
curl http://localhost:3000/products

# Reverse proxy working?
curl http://localhost  # Via Nginx
curl http://54.234.158.141  # Via public IP

# HTTPS working?
curl -k https://54.234.158.141
```

---

## Deployment Checklist

- [ ] MongoDB running in Docker
- [ ] Application started with PM2
- [ ] PM2 configured for auto-start
- [ ] Nginx installed and running
- [ ] Reverse proxy routing traffic to app
- [ ] SSL certificate installed
- [ ] All ports accessible from outside
- [ ] Health checks passing
- [ ] Tested server reboot - app auto-starts

---

## Troubleshooting

### App won't start
```bash
pm2 logs product-api  # Check logs
pm2 delete product-api  # Remove old process
pm2 start main.js --name "product-api"  # Restart
```

### MongoDB not connecting
```bash
sudo docker ps  # Check if running
sudo docker logs mongodb  # Check MongoDB logs
curl http://localhost:27017  # Try connecting
```

### Nginx not forwarding
```bash
sudo nginx -t  # Test syntax
sudo systemctl reload nginx  # Reload
sudo tail -20 /var/log/nginx/product-api-error.log  # Check errors
```

### Port already in use
```bash
sudo lsof -i :3000  # Find process
sudo lsof -i :80    # Find Nginx
kill -9 <PID>  # Kill process
```

---

## Related Documentation

- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Deployment steps
- [SECURITY.md](../SECURITY.md) - Security configuration
- [EVIDENCE-COLLECTION.md](../EVIDENCE-COLLECTION.md) - Report evidence guide

---

**Last Updated**: March 15, 2026
**Phase**: 2 - Traditional Deployment
