# Application Deployment & Runtime Setup (Section 5.2)

## Overview
This document describes how the runtime environment was prepared on the Ubuntu cloud server using the Phase 1 automation script and manual steps.

---

## Runtime Environment Preparation

### Server Details
- **Provider**: AWS Learner Lab
- **Instance Type**: t2.micro
- **OS**: Ubuntu 22.04 LTS
- **Public IP**: 54.234.158.141
- **Elastic IP**: Assigned

---

## Step 1: Automation Script Execution

### Transfer Setup Script
```bash
# Local machine
cd /home/dmin/devopp_midterm/devop-midterm
scp -i /home/dmin/.ssh/id_rsa scripts/setup.sh ubuntu@54.234.158.141:~/setup.sh
```

### Execute on Server
```bash
# On server
ssh -i /home/dmin/.ssh/id_rsa ubuntu@54.234.158.141
./setup.sh
```

### Script Execution Results
✅ **Successfully Installed:**
- Node.js: v18.20.8
- npm: v10.8.2
- OS Packages: curl, wget, git, build-essential
- Directories: public/uploads, logs, docs, scripts
- Configuration files: .env, .gitignore

⚠️ **Expected Error**: npm install failed initially (application source not present)
- This was expected as package.json wasn't on server yet
- Resolved in Step 2

**Script Output Summary:**
```
[SUCCESS] Node.js found: v18.20.8
[SUCCESS] npm found: v10.8.2
[SUCCESS] Directory public/uploads: OK
[SUCCESS] Directory logs: OK
[SUCCESS] Directory docs: OK
[SUCCESS] Directory scripts: OK
[SUCCESS] .env file: OK
```

---

## Step 2: Application Source Code Transfer

### Transfer Project Files
```bash
# Local machine
cd /home/dmin/devopp_midterm/devop-midterm

# Create target directory on server
ssh -i /home/dmin/.ssh/id_rsa ubuntu@54.234.158.141 "mkdir -p ~/product-api"

# Transfer entire project
scp -i /home/dmin/.ssh/id_rsa -r . ubuntu@54.234.158.141:~/product-api/
```

### Files Transferred
```
main.js
package.json
package-lock.json
controllers/
models/
routes/
services/
validators/
views/
public/
docs/
scripts/
.env.example
.gitignore
README.md
```

---

## Step 3: Dependency Installation

### Execute on Server
```bash
# On server
cd ~/product-api
npm install
```

### Installation Results
✅ **Successfully Installed**: 161 packages
- Express.js 4.18.2
- Mongoose 7.0.0
- EJS 3.1.9
- Multer 1.4.5
- express-validator 6.14.3
- dotenv 16.0.0
- uuid 9.0.0
- And 154 dependencies

⚠️ **Security Note**: 
- Multer 1.4.5 has known vulnerabilities (marked as deprecated)
- Version 2.x available as upgrade path
- For learner lab: acceptable; for production: upgrade recommended

**Installation Output:**
```
added 161 packages, and audited 162 packages in 4s
6 vulnerabilities (2 moderate, 4 high)
```

---

## Step 4: Environment Configuration

### .env Setup
```bash
# On server
cd ~/product-api
cat .env
```

### Current Configuration
```
PORT=3000
MONGO_URI=mongodb://localhost:27017/products_db
```

**Note**: MongoDB connection attempted but unavailable in learner lab
- Application gracefully falls back to in-memory data store
- See: Application Initialization below

---

## Step 5: Application Startup Test

### Start Application
```bash
# On server
cd ~/product-api
npm start
```

### Startup Output
```
Created uploads directory at /home/ubuntu/product-api/public/uploads
Failed to connect to MongoDB within 3s — falling back to in-memory database.
Server listening on port http://localhost:3000 — hostname: ip-172-31-27-82
Data source in use: in-memory
```

### Verification
✅ Application started successfully
✅ Running on port 3000
✅ Using in-memory data store (MongoDB unavailable)
✅ Logs displayed correctly

---

## Runtime Environment Summary

### Installed Components
| Component | Version | Status |
|-----------|---------|--------|
| Node.js | 18.20.8 | ✅ |
| npm | 10.8.2 | ✅ |
| Express | 4.18.2 | ✅ |
| Mongoose | 7.0.0 | ✅ |
| MongoDB | N/A | Not available in learner lab |

### Directories Created
```
~/product-api/
├── node_modules/          (161 packages)
├── public/
│   ├── uploads/           (for user images)
│   ├── css/
│   ├── js/
│   └── images/
├── controllers/
├── models/
├── routes/
├── services/
├── validators/
├── views/
├── logs/                  (for application logs)
├── docs/                  (documentation)
├── scripts/               (automation scripts)
├── main.js
├── package.json
└── package-lock.json
```

### Data Persistence
Since MongoDB is unavailable:
- **Data Storage**: In-memory (volatile)
- **Persistence**: Lost on application restart
- **Workaround**: For production, deploy MongoDB or use cloud database

---

## Manual Steps Performed

### 1. Directory Creation
```bash
mkdir -p ~/product-api
```
- Script couldn't transfer to non-existent directory
- Created manually before code transfer

### 2. Application Startup
```bash
npm start
```
- Started application manually to verify functionality
- Confirmed HTML output and port binding
- To be managed by PM2 (next phase)

### 3. Local Connectivity Test
```bash
curl http://localhost:3000/
```
- Confirmed application responds to HTTP requests
- Returns HTML dashboard
- Port 3000 access restricted internally (not in security group)

---

## Issues & Resolutions

### Issue 1: npm install Failed During Script
**Problem**: Script attempted npm install before package.json existed
**Solution**: Transfer application code first, then run npm install manually
**Resolution**: ✅ Resolved - 161 packages installed successfully

### Issue 2: Port 3000 Inaccessible from Outside
**Problem**: curl from external IP failed (54.234.158.141:3000 timeout)
**Reason**: Security group doesn't include port 3000
**Solution**: Use Nginx reverse proxy (port 80 → 3000) in Phase 2.3
**Status**: Expected behavior - to be addressed in Section 5.3

### Issue 3: MongoDB Connection Failed
**Problem**: Application couldn't connect to MongoDB
**Reason**: MongoDB not installed in learner lab
**Solution**: Application gracefully falls back to in-memory data store
**Status**: ✅ Acceptable for learner lab - application functional

---

## Checklist: Section 5.2 Complete ✅

- [x] Automation script transferred to cloud server
- [x] Script executed without critical errors
- [x] Node.js runtime installed (v18.20.8)
- [x] npm installed (v10.8.2)
- [x] OS packages installed (curl, wget, git, build-essential)
- [x] Required directories created
- [x] Application source code transferred
- [x] Dependencies installed (161 packages)
- [x] .env configured
- [x] Application starts successfully
- [x] Manual steps documented

---

## Next Steps: Section 5.3

The runtime environment is now ready. Next steps:
1. **Process Management**: Set up PM2 to keep app running
2. **Reverse Proxy**: Configure Nginx (port 80 → 3000)
3. **HTTPS**: Optional SSL/TLS configuration
4. **Systemd Service**: Ensure app starts on server reboot

See: **Section 5.3 instructions** for process management configuration.

---

## Troubleshooting

### Application won't start
```bash
# Check Node.js
node -v

# Check npm
npm -v

# Reinstall dependencies
rm -rf node_modules
npm install

# Check .env exists
cat .env
```

### Port already in use
```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill process
kill -9 <PID>
```

### Permission errors
```bash
# Ensure correct ownership
cd ~/product-api
ls -la

# Fix permissions if needed
sudo chown -R ubuntu:ubuntu ~/product-api
```

---

## References
- Node.js Deployment: https://nodejs.org/en/docs/guides/
- npm Documentation: https://docs.npmjs.com/
- Express.js: https://expressjs.com/
- Application README: [../README.md](../README.md)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Security: [SECURITY.md](SECURITY.md)
