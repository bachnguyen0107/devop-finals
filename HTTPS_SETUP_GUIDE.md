# HTTPS Setup Guide for WSL - Certbot with Docker

## 🚀 Quick Start (Recommended)

1. **Update the script with your details:**
   ```bash
   # Edit setup-https-fixed.sh and update:
   DOMAIN="your-domain.com"
   EMAIL="your-email@example.com"
   ```

2. **Make it executable and run:**
   ```bash
   chmod +x setup-https-fixed.sh
   ./setup-https-fixed.sh
   ```

## 📋 Manual Step-by-Step Guide

### Prerequisites
- Domain pointing to your server IP
- Ports 80 and 443 open
- Docker and Docker Compose installed

### Step 1: Install Certbot
```bash
sudo apt update
sudo apt install -y certbot
```

### Step 2: Prepare SSL Directories
```bash
mkdir -p ssl/letsencrypt
mkdir -p ssl/certbot
```

### Step 3: Stop Current Services
```bash
docker-compose down
```

### Step 4: Create Temporary HTTP Config
Create `nginx-temp.conf`:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    location / {
        return 302 http://localhost:3000$request_uri;
    }
}
```

### Step 5: Start Temporary Nginx
```bash
docker run -d --name temp-nginx \
  -p 80:80 \
  -v $(pwd)/nginx-temp.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/ssl/certbot:/var/www/certbot \
  nginx:latest
```

### Step 6: Generate Certificate
```bash
sudo certbot certonly --webroot \
  -w $(pwd)/ssl/certbot \
  --email your-email@example.com \
  -d your-domain.com \
  -d www.your-domain.com \
  --expand
```

### Step 7: Copy Certificates
```bash
sudo cp -r /etc/letsencrypt ./ssl/
sudo chown -R $USER:$USER ./ssl/
```

### Step 8: Start HTTPS Services
```bash
docker-compose -f docker-compose-ssl.yml up -d
```

### Step 9: Set Up Auto-Renewal
```bash
# Add to crontab (runs daily at noon)
sudo crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /path/to/project/docker-compose-ssl.yml restart nginx
```

## 🔧 Troubleshooting

### Certificate Generation Fails
```bash
# Check DNS resolution
dig your-domain.com

# Check if port 80 is accessible
curl -I http://your-domain.com

# Check nginx logs
docker logs temp-nginx

# Test challenge directory
curl http://your-domain.com/.well-known/acme-challenge/test
```

### HTTPS Not Working
```bash
# Check certificate files exist
ls -la ssl/letsencrypt/live/your-domain.com/

# Check nginx config
docker exec nginx nginx -t

# Check nginx logs
docker-compose -f docker-compose-ssl.yml logs nginx
```

### Certificate Already Exists
```bash
Error: You have an existing certificate that contains a portion of the domains you requested
```
**Solution**: Add `--expand` flag to include additional domains:
```bash
sudo certbot certonly --webroot -w /path/to/webroot --expand -d domain.com -d www.domain.com
```

## 📊 Verification

Test your HTTPS setup:
```bash
# Check certificate
curl -I https://your-domain.com

# Check SSL rating
curl -s -o /dev/null -w "%{http_code}\n" https://your-domain.com

# Check certbot certificates
sudo certbot certificates
```

## 🔄 Certificate Renewal

Certificates auto-renew every 60 days. To test renewal:
```bash
sudo certbot renew --dry-run
```

## 🚨 Common Issues & Solutions

1. **"Connection refused" during cert generation**
   - Ensure port 80 is open and nginx is running
   - Check firewall: `sudo ufw status`

2. **"Domain not pointing to this server"**
   - Verify DNS: `dig your-domain.com`
   - Wait for DNS propagation (can take 24-48 hours)

3. **"Challenge failed"**
   - Ensure ACME challenge directory is accessible
   - Check nginx configuration for `/.well-known/acme-challenge/`

4. **Permission denied on certificates**
   - Copy certificates to project directory
   - Fix ownership: `sudo chown -R $USER:$USER ssl/`

## 📝 Notes

- Always backup your certificates before major changes
- Test certificate renewal regularly
- Monitor nginx logs for SSL-related errors
- Consider using DNS-01 challenge for wildcard certificates