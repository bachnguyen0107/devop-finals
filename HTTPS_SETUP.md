# HTTPS & Let's Encrypt Setup Guide

## Overview

This guide explains how to set up HTTPS with Let's Encrypt SSL certificates for your application at `devop-midterm2026.online`.

## Prerequisites

1. **Domain registered and DNS configured**
   - Domain: `devop-midterm2026.online`
   - DNS A record should point to your EC2 instance IP: `54.234.158.141`

2. **EC2 instance with Docker and Docker Compose**
   - Already installed on your instance

3. **Port 80 (HTTP) accessible**
   - Required for Let's Encrypt ACME challenge validation

## Quick Setup

### Step 1: Update DNS Records

Make sure your domain DNS records point to your EC2 instance:

```
A Record:
  Domain: devop-midterm2026.online
  Type: A
  Value: 54.234.158.141
  TTL: 3600

CNAME Record (optional):
  Domain: www.devop-midterm2026.online
  Type: CNAME
  Value: devop-midterm2026.online
```

Verify DNS is working:
```bash
# On your local machine
nslookup devop-midterm2026.online
dig devop-midterm2026.online
```

### Step 2: Upload Updated Files to EC2

From your local machine, upload the new HTTPS configuration files:

```bash
scp -i ~/.ssh/id_rsa /home/dmin/devopp_final/devop-finals/nginx-ssl.conf ubuntu@54.234.158.141:~/devop-finals/
scp -i ~/.ssh/id_rsa /home/dmin/devopp_final/devop-finals/docker-compose-ssl.yml ubuntu@54.234.158.141:~/devop-finals/
scp -i ~/.ssh/id_rsa /home/dmin/devopp_final/devop-finals/setup-https.sh ubuntu@54.234.158.141:~/devop-finals/
```

### Step 3: Run Setup Script on EC2

```bash
# SSH into EC2
ssh -i ~/.ssh/id_rsa ubuntu@54.234.158.141

# Navigate to project
cd ~/devop-finals

# Make script executable
chmod +x setup-https.sh

# Run the setup (this will generate and configure SSL certificates)
bash setup-https.sh
```

The script will:
1. Create SSL directory structure
2. Verify domain DNS resolution
3. Update Nginx configuration
4. Generate SSL certificate from Let's Encrypt
5. Configure automatic certificate renewal
6. Restart services with HTTPS enabled

### Step 4: Verify HTTPS is Working

```bash
# Test HTTPS connection
curl https://devop-midterm2026.online/

# Check SSL certificate
openssl s_client -connect devop-midterm2026.online:443

# View certificate details on server
docker-compose exec certbot certbot certificates
```

## Architecture

### Services

1. **Nginx** - Reverse proxy with SSL/TLS termination
2. **Certbot** - Automatic certificate renewal daemon
3. **Web Application** (3 replicas) - Behind reverse proxy
4. **MongoDB** - Database

### SSL Flow

```
Internet
   ↓
[HTTPS 443]
   ↓
Nginx (SSL Termination)
   ↓
HTTP 3000 (Internal Network)
   ↓
Web App Replicas (1, 2, 3)
   ↓
MongoDB
```

## Configuration Files

### nginx-ssl.conf

Key features:
- **HTTP to HTTPS Redirect** - All HTTP traffic redirected to HTTPS
- **ACME Challenge Support** - Let's Encrypt validation
- **Modern SSL/TLS** - TLSv1.2 and TLSv1.3 only
- **Security Headers** - HSTS, X-Frame-Options, CSP, etc.
- **Load Balancing** - Routes to all 3 web replicas
- **Gzip Compression** - Enabled for efficiency

### docker-compose-ssl.yml

Key additions:
- **Certbot Service** - Automatically renews certificates
- **Volume Mounts** - Shares certificates and challenge directory between Nginx and Certbot
- **Entrypoint** - Certbot runs renewal check every 12 hours

## Certificate Management

### View Certificate Status

```bash
# On your EC2 instance
docker-compose exec certbot certbot certificates

# Output example:
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Found the following certificates:
#   Certificate Name: devop-midterm2026.online
#   Domains: devop-midterm2026.online, www.devop-midterm2026.online
#   Expiry Date: 2026-07-25 15:23:00+00:00
#   Certificate Path: /etc/letsencrypt/live/devop-midterm2026.online/fullchain.pem
#   Private Key Path: /etc/letsencrypt/live/devop-midterm2026.online/privkey.pem
```

### Manual Certificate Renewal

```bash
# If automatic renewal fails
docker-compose exec certbot certbot renew --force-renewal

# Or for a specific domain
docker-compose exec certbot certbot renew -d devop-midterm2026.online --force-renewal
```

### Certificate Renewal Logs

```bash
# Watch renewal process
docker-compose logs -f certbot

# Check for renewal attempts
docker-compose logs certbot | grep "renewal"
```

## Troubleshooting

### Certificate Generation Failed

**Error**: `Error creating new order :: too many certificates already issued for exact set of domains`

**Solution**: Wait before trying again (rate limiting). Let's Encrypt allows 5 duplicate certificates per week.

---

**Error**: `Challenge failed for domain devop-midterm2026.online`

**Solution**: 
1. Verify DNS resolution: `nslookup devop-midterm2026.online`
2. Check port 80 is accessible: `curl http://devop-midterm2026.online/.well-known/acme-challenge/test`
3. Check firewall rules on EC2 security group (allow port 80)

---

### Certificate Not Found

**Error**: Nginx can't find certificate files

**Solution**:
```bash
# Check certificate files exist
ls -la ssl/letsencrypt/live/devop-midterm2026.online/

# If missing, regenerate
docker-compose exec certbot certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --non-interactive \
    --agree-tos \
    --email admin@devop-midterm2026.online \
    -d devop-midterm2026.online \
    -d www.devop-midterm2026.online
```

---

### HTTPS Not Working After Setup

**Solution**: 
```bash
# Restart Nginx
docker-compose restart nginx

# Check Nginx configuration
docker-compose exec nginx nginx -t

# View Nginx error logs
docker-compose logs nginx | grep error
```

---

### Certificate Expiring Soon

Let's Encrypt certificates are valid for 90 days. Certbot automatically renews 30 days before expiration.

```bash
# Check expiration date
docker-compose exec certbot certbot certificates | grep "Expiry"

# Force renewal if needed
docker-compose exec certbot certbot renew --force-renewal
```

## DNS Records Reference

Your domain should have these DNS records:

```
devop-midterm2026.online     A       54.234.158.141      3600
www.devop-midterm2026.online CNAME   devop-midterm2026.online    3600
```

Check with:
```bash
# From your local machine
dig devop-midterm2026.online
dig www.devop-midterm2026.online
```

## Monitoring

### Check Nginx SSL Status

```bash
# On EC2
docker-compose exec nginx openssl s_client -connect localhost:443 -servername devop-midterm2026.online </dev/null

# From local machine
openssl s_client -connect devop-midterm2026.online:443 -servername devop-midterm2026.online </dev/null
```

### Test Web Application

```bash
# HTTP (redirects to HTTPS)
curl -L http://devop-midterm2026.online/

# HTTPS directly
curl https://devop-midterm2026.online/

# With verbose output
curl -v https://devop-midterm2026.online/
```

### Verify Certificate Chain

```bash
# Check certificate is properly signed
curl -v https://devop-midterm2026.online/ 2>&1 | grep -A 5 "certificate:"
```

## Performance & Security

### SSL/TLS Features Enabled

- ✅ TLS 1.3 (modern encryption)
- ✅ TLS 1.2 (compatibility)
- ✅ HSTS (HTTP Strict Transport Security) - forces HTTPS
- ✅ Strong ciphers only
- ✅ Session caching for performance
- ✅ Perfect Forward Secrecy (PFS)

### Security Headers

```
Strict-Transport-Security: max-age=31536000 (1 year HSTS)
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### Grade Your SSL

Visit https://www.ssllabs.com/ssltest/ and enter your domain to get detailed SSL analysis.

## Automatic Renewal Verification

Certbot is configured to:
1. Check every 12 hours if renewal is needed
2. Automatically renew 30 days before expiration
3. Gracefully reload Nginx after renewal

To verify renewal:
```bash
# Check Certbot logs for recent renewal
docker-compose logs certbot | tail -50

# Look for "renewal" or "not yet due"
```

## Manual Renewal Trigger

If you want to test renewal:
```bash
docker-compose exec certbot certbot renew --force-renewal --dry-run
```

This performs a test renewal without actually changing certificates.

## Switching Between HTTP and HTTPS

### To temporarily disable HTTPS (revert to HTTP only):

```bash
# Restore original docker-compose and nginx config
cp docker-compose-ssl.yml docker-compose.yml
cp nginx-ssl.conf nginx.conf

docker-compose down
docker-compose up -d
```

### To enable HTTPS again:

```bash
# Run setup script
bash setup-https.sh
```

## Advanced: Custom Email

To change the email used for certificate notifications:

Edit `setup-https.sh` and update:
```bash
EMAIL="your-email@example.com"
```

Then run the script again.

## Support & Documentation

- **Let's Encrypt Docs**: https://letsencrypt.org/docs/
- **Certbot Docs**: https://certbot.eff.org/docs/
- **Nginx SSL**: https://nginx.org/en/docs/http/ngx_http_ssl_module.html

## Next Steps

After HTTPS is configured:
1. Verify certificate with https://www.ssllabs.com/ssltest/
2. Set up CI/CD pipeline for automated deployments
3. Configure monitoring and alerting
4. Test failover and recovery scenarios
