# Phase 2: Technical Report - Evidence Collection Guide

## Overview
This document outlines the evidence needed for the Phase 2 Technical Report, organized by section with instructions on what to capture and how to document it.

---

## Evidence Checklist & Collection Instructions

### 1. Security & Firewall Configuration (Section 5.1)

**What to Capture:**
- [ ] AWS Security Group inbound rules showing only ports 22, 80, 443
- [ ] AWS Security Group outbound rules (allow all)
- [ ] Elastic IP allocation screenshot
- [ ] SSH connection successful (terminal showing `ubuntu@ip-xxx:~$`)

**How to Capture:**
```bash
# Screenshots to take:
# 1. AWS Console → EC2 → Security Groups → Your group → Inbound rules
# 2. AWS Console → EC2 → Security Groups → Your group → Outbound rules
# 3. AWS Console → EC2 → Elastic IPs (show your allocated IP)
# 4. Terminal: 
ssh -i /home/dmin/.ssh/id_rsa ubuntu@54.234.158.141
# Take screenshot of successful connection
```

**Evidence File Names:**
- `security-group-inbound.png`
- `security-group-outbound.png`
- `elastic-ip-allocated.png`
- `ssh-connection-successful.png`

---

### 2. Runtime Environment Setup (Section 5.2)

**What to Capture:**
- [ ] Setup script execution (successful output)
- [ ] Node.js version installed
- [ ] npm version installed
- [ ] Directories created (output of `ls -la`)
- [ ] Package.json and dependencies installed

**How to Capture:**
```bash
# On server, capture these outputs:

# 1. Setup script output (from when you ran ./setup.sh)
# Save this output as text

# 2. Node version
node -v

# 3. npm version
npm -v

# 4. Directories
ls -la ~/product-api | head -20

# 5. Dependencies installed
npm list | head -30

# 6. Application startup (first run)
cd ~/product-api
npm start
# (Take screenshot showing successful output)
```

**Evidence File Names:**
- `setup-script-output.txt` (copy full output)
- `nodejs-version.png`
- `npm-version.png`
- `project-directories.png`
- `dependencies-installed.png`
- `app-startup-successful.png`

---

### 3. Database Configuration & Connectivity (Section 5.3)

**What to Capture:**
- [ ] MongoDB Docker container running
- [ ] Application connected to MongoDB (logs showing "Connected to MongoDB")
- [ ] API returning data from database
- [ ] Database verification (documents in database)

**How to Capture:**
```bash
# On server:

# 1. Docker MongoDB running
sudo docker ps
# Take screenshot showing mongo:6.0 container running

# 2. App logs showing MongoDB connection
pm2 logs product-api | grep -i "connected\|mongodb"
# Or restart app to see connection message
pm2 restart product-api
pm2 logs product-api

# 3. API returning data
curl http://localhost:3000/products | jq . > api-response.json

# 4. MongoDB connection verification
# Create file showing app successfully connected
pm2 logs product-api > mongodb-connection-logs.txt
```

**Evidence File Names:**
- `docker-mongodb-running.png`
- `app-connected-to-mongodb.png`
- `api-products-response.json` (actual API response)
- `mongodb-logs.txt`

---

### 4. Process Management & Auto-Restart (Section 5.4)

**What to Capture:**
- [ ] PM2 running with app listed
- [ ] App running status (online)
- [ ] PM2 startup configured
- [ ] **CRITICAL**: App running after server reboot
- [ ] PM2 process list after reboot

**How to Capture:**
```bash
# BEFORE REBOOT:
# 1. PM2 process list
pm2 list

# 2. App is running
pm2 logs product-api | tail -20

# 3. Save PM2 config
pm2 save

# NOW REBOOT:
sudo reboot

# AFTER REBOOT (wait 30-45 seconds):
# 4. App still running
pm2 list

# 5. Test API works
curl http://localhost:3000/products

# 6. Check logs
pm2 logs product-api | tail -30

# 7. Verify PM2 startup service
sudo systemctl status pm2-ubuntu
```

**Evidence File Names:**
- `pm2-list-before-reboot.png`
- `pm2-logs-before-reboot.png`
- `pm2-list-after-reboot.png` ⭐ **CRITICAL**
- `api-works-after-reboot.png`
- `pm2-startup-service-status.png`

---

### 5. Reverse Proxy Configuration (Section 5.5)

**What to Capture:**
- [ ] Nginx installed and running
- [ ] Nginx configuration file showing proxy settings
- [ ] HTTP traffic successfully routed (curl from local machine)
- [ ] Nginx configuration test passing

**How to Capture:**
```bash
# On server:

# 1. Nginx version and status
nginx -v
sudo systemctl status nginx

# 2. Show complete Nginx config
cat /etc/nginx/sites-available/product-api

# 3. Nginx configuration test
sudo nginx -t

# 4. From LOCAL machine, test proxy:
curl http://54.234.158.141   # Should return HTML/JSON
curl -v http://54.234.158.141 2>&1 | head -30  # Show headers

# 5. Check Nginx logs
sudo tail -20 /var/log/nginx/product-api-access.log
```

**Evidence File Names:**
- `nginx-version-status.png`
- `nginx-config-file.txt` (copy full content)
- `nginx-test-successful.png`
- `nginx-reverse-proxy-working.png` (curl output from local machine)
- `nginx-logs.txt`

---

### 6. HTTPS Configuration with Let's Encrypt (Section 5.5 - Domain & SSL)

**What to Capture:**
- [ ] Let's Encrypt certificate installed for domain
- [ ] Domain name configured in Nginx
- [ ] HTTPS connection working with valid certificate
- [ ] HTTP redirects to HTTPS
- [ ] Certificate auto-renewal configured

**How to Capture:**
```bash
# On server:

# 1. Certificate files exist (Let's Encrypt)
sudo ls -la /etc/letsencrypt/live/devop-midterm2026.online/

# 2. Certificate details
sudo openssl x509 -in /etc/letsencrypt/live/devop-midterm2026.online/fullchain.pem -text -noout | head -30

# 3. Certbot certificates list
sudo certbot certificates

# 4. Nginx domain configuration
sudo cat /etc/nginx/sites-available/product-api

# 5. Nginx configuration test
sudo nginx -t

# 6. From LOCAL machine:
curl -v https://devop-midterm2026.online/products  # HTTPS works with valid cert
curl http://devop-midterm2026.online                 # HTTP redirects to HTTPS (follow 301)

# 7. Check auto-renewal status
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

**Evidence File Names:**
- `letsencrypt-certificate-files.png` (ls output of cert directory)
- `ssl-certificate-details.txt` (openssl output)
- `certbot-certificates-list.png` (sudo certbot certificates)
- `nginx-config-with-domain.txt` (full config)
- `nginx-test-successful.png`
- `https-with-domain-working.png` (curl -v output)
- `http-redirect-https.png` (curl output showing 301 redirect)
- `certbot-auto-renewal-status.png` (systemctl status certbot.timer)

---

## Complete Evidence Package Structure

```
docs/
├── technical-report/
│   ├── 5-1-security/
│   │   ├── security-group-inbound.png
│   │   ├── security-group-outbound.png
│   │   ├── elastic-ip-allocated.png
│   │   └── ssh-connection-successful.png
│   ├── 5-2-runtime/
│   │   ├── setup-script-output.txt
│   │   ├── nodejs-version.png
│   │   ├── npm-version.png
│   │   ├── project-directories.png
│   │   ├── dependencies-installed.png
│   │   └── app-startup-successful.png
│   ├── 5-3-database/
│   │   ├── docker-mongodb-running.png
│   │   ├── app-connected-to-mongodb.png
│   │   ├── api-products-response.json
│   │   └── mongodb-logs.txt
│   ├── 5-4-process-management/
│   │   ├── pm2-list-before-reboot.png
│   │   ├── pm2-logs-before-reboot.png
│   │   ├── pm2-list-after-reboot.png ⭐
│   │   ├── api-works-after-reboot.png
│   │   └── pm2-startup-service-status.png
│   ├── 5-5-reverse-proxy/
│   │   ├── nginx-version-status.png
│   │   ├── nginx-config-file.txt
│   │   ├── nginx-test-successful.png
│   │   ├── nginx-reverse-proxy-working.png
│   │   └── nginx-logs.txt
│   └── 5-5-https/
│       ├── ssl-certificate-created.png
│       ├── ssl-certificate-details.txt
│       ├── nginx-https-config.txt
│       ├── https-working.png
│       └── http-redirect-https.png
└── EVIDENCE-SUMMARY.md
```

---

## Screenshot Collection Workflow

### Quick Collection Commands

```bash
# Save everything to a file for easy copy-paste to report

# 1. Node & npm versions
{
  echo "=== Node Version ===" 
  node -v
  echo "=== npm Version ==="
  npm -v
} > /tmp/versions.txt

# 2. Nginx config
sudo cat /etc/nginx/sites-available/product-api > /tmp/nginx-config.txt

# 3. Nginx test
sudo nginx -t > /tmp/nginx-test.txt 2>&1

# 4. PM2 status
pm2 list > /tmp/pm2-list.txt

# 5. API test
curl http://localhost:3000/products > /tmp/api-response.json

# 6. Transfer to local machine
scp -i /home/dmin/.ssh/id_rsa ubuntu@54.234.158.141:/tmp/*.txt /home/dmin/Downloads/
scp -i /home/dmin/.ssh/id_rsa ubuntu@54.234.158.141:/tmp/api-response.json /home/dmin/Downloads/
```

---

## Critical Evidence: Server Reboot Test

**Most Important for Assessment:**

The server reboot test proves:
1. ✅ PM2 auto-start working
2. ✅ Application survives server restart
3. ✅ Persistence requirement met
4. ✅ Production-ready deployment

**Screenshot Sequence:**
1. Before reboot: `pm2 list` showing app online
2. Run: `sudo reboot`
3. After reboot (wait ~30s): `pm2 list` showing app online again
4. Verify: `curl http://localhost:3000/products` returns data
5. **SAVE ALL SCREENSHOTS WITH TIMESTAMPS**

---

## How to Take Screenshots

### Linux Terminal Screenshots
```bash
# Use screenshot tool
gnome-screenshot -f ~/reboot-test-$(date +%s).png

# Or copy terminal output to file
pm2 list | tee ~/pm2-list-after-reboot.txt
```

### Windows Local Machine
- Press **Print Screen** or **Windows+Shift+S**
- Paste into Paint/Snip & Sketch

### macOS
- Press **Cmd+Shift+5**
- Select window/area

---

## Evidence Organization Tips

1. **Use descriptive filenames** with dates/times
2. **Keep terminal output** in .txt files
3. **Screenshot order matters** - show progression
4. **Include timestamps** when possible
5. **Add annotations** to complex screenshots (highlight key parts)

---

## Final Checklist for Technical Report

- [ ] All 5.1 screenshots collected
- [ ] All 5.2 output captured
- [ ] All 5.3 database evidence gathered
- [ ] **5.4 reboot test evidence** (most critical)
- [ ] Nginx configuration documented
- [ ] HTTPS status captured
- [ ] Files organized in `/docs/technical-report/`
- [ ] Evidence summary document created
- [ ] All evidence uploaded/committed

---

## Next Steps

1. Collect all evidence systematically (follow the workflow above)
2. Organize into `/docs/technical-report/` directory
3. Create `EVIDENCE-SUMMARY.md` listing all proof
4. Include evidence in technical report submission
5. Commit everything to git

**Remember: Clear, timestamped evidence = full marks!** 📸✅
