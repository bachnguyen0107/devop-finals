# EC2 Deployment Guide

## Overview
Your project has been successfully uploaded to EC2 instance at **13.229.76.119**

## Current Setup
✅ Project files uploaded to `~/devop-finals/`
✅ Docker installed (v29.3.0)
✅ Docker Compose installed (v2.40.2)
✅ Nginx reverse proxy configured
✅ `.env` file created for production

## Important: Building the Docker Image

Before starting services, you need to build your web application Docker image:

```bash
# SSH into EC2
ssh -i ~/.ssh/id_rsa ubuntu@13.229.76.119

# Navigate to project
cd ~/devop-finals

# Build the Docker image (replace DOCKERHUB_USERNAME with your actual username)
docker build -t DOCKERHUB_USERNAME/devop-midterm-web:1.0.0 .

# Or if you haven't pushed to Docker Hub yet, just build locally:
docker build -t devop-midterm-web:1.0.0 .
```

Then update the `docker-compose.yml` if using local image:
```yaml
services:
  web:
    image: devop-midterm-web:1.0.0  # Remove DOCKERHUB_USERNAME/ prefix
```

## Deployment Steps

### 1. SSH into your instance
```bash
ssh -i ~/.ssh/id_rsa ubuntu@13.229.76.119
```

### 2. Navigate to project
```bash
cd ~/devop-finals
```

### 3. Build the Docker image
```bash
docker build -t devop-midterm-web:1.0.0 .
```

### 4. Update docker-compose.yml (if needed)
```bash
# If using local image, replace the image line in docker-compose.yml
sed -i 's|DOCKERHUB_USERNAME/devop-midterm-web:1.0.0|devop-midterm-web:1.0.0|g' docker-compose.yml
```

### 5. Create SSL directory for Let's Encrypt certificates
```bash
mkdir -p ssl
```

### 6. Start all services
```bash
docker-compose up -d
```

### 7. Verify services are running
```bash
docker-compose ps
docker-compose logs -f nginx  # Watch Nginx logs
docker-compose logs -f web    # Watch Web app logs
```

## Testing the Deployment

### Check if application is running
```bash
curl http://localhost/       # Web UI
curl http://localhost/api    # API endpoint (if available)
curl http://localhost/health # Health check endpoint
```

Or access from your browser:
- **Public IP**: http://13.229.76.119

## Service Information

| Service | Port | Access |
|---------|------|--------|
| Nginx (Reverse Proxy) | 80, 443 | Public |
| Node.js Web App | 3000 | Internal (via Nginx) |
| MongoDB | 27017 | Internal |

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart specific service
docker-compose restart web

# Remove all containers and volumes (CAUTION!)
docker-compose down -v

# Check disk usage
docker system df
```

## Next Steps for Production

1. **Update EC2 Security Groups**
   - Allow port 80 (HTTP) - already needed for Let's Encrypt
   - Allow port 443 (HTTPS) - for HTTPS traffic
   - Allow port 22 (SSH) - for management

2. **Configure HTTPS with Let's Encrypt**
   - Update Nginx configuration to handle SSL
   - Use Certbot for automatic certificate management

3. **Set up Domain Name**
   - Register a domain
   - Point DNS records to your EC2 instance IP
   - Update Nginx server_name directive

4. **Container Horizontal Scaling**
   - Update docker-compose.yml to run multiple web service replicas
   - Configure load balancing in Nginx

## Troubleshooting

### Docker Compose command not found
```bash
sudo /usr/local/bin/docker-compose up -d
```

### Permission denied error
```bash
# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu
# Then log out and log back in
```

### Port 80/443 already in use
```bash
sudo lsof -i :80
sudo lsof -i :443
```

## Support
For detailed Nginx configuration or SSL setup, refer to the main README.md in the project.
