# Phase 3 — Dockerized Deployment with Docker Compose (Production)

**Group Domain:** `devop-midterm2026.online`  
**Web Image (Docker Hub):** `mhiu180105/devop-midterm-web:1.0.0`  
**Server (public IP example used during deployment):** `54.234.158.141`  
**Host OS:** Ubuntu (e.g., 24.04)  
**Deployment directory on server:** `~/devop-midterm-phase3`

---

## 1. Phase Objective (Strict Requirements)

Phase 3 migrates the system from a traditional host-based deployment (Phase 2) to a fully containerized deployment using **Docker** and **Docker Compose**, on the **same Ubuntu server**.

### Mandatory requirements satisfied in Phase 3
- Web application runs in a Docker container.
- MongoDB runs in a Docker container (`mongo:6.0`).
- Docker Compose orchestrates the full stack (at least 2 services: `web` + `mongo`).
- The server **does NOT build** the web image from source.  
  It **pulls a pre-built image from Docker Hub**: `mhiu180105/devop-midterm-web:1.0.0`.
- Nginx remains on the host (from Phase 2). Only the upstream target is updated/kept to forward requests to the web container.
- Persistence is ensured using Docker volumes:
  - MongoDB data persistence
  - Uploaded files persistence (`public/uploads`)
- Services include restart policies and can recover after container restarts and server reboot.
- The application remains accessible via HTTPS through: `https://devop-midterm2026.online`

---

## 2. Phase 3 Architecture Overview

**Public traffic flow:**

Internet (HTTPS)  
→ **Nginx (host)**  
→ reverse proxy to `http://localhost:3000` (host published port)  
→ **Web container** (`devop_midterm_web`)  
→ internal Docker network connection to **MongoDB container** (`devop_midterm_mongo`)

---

## 3. Phase 3 Deliverables in Repository

This `phase3/` directory contains:
- `Dockerfile` — production Dockerfile used to build the web image locally
- `docker-compose.yml` — compose definition (web + mongo + volumes + restart policies)
- `.env.example` — environment template (do not commit real secrets)
- `README.md` — this guide
- `evidence/` — screenshots/logs required for the technical report and demo

> Note: The real `.env` file used on the server must **not** be committed to git.

---

## 4. Local Build & Push (Docker Hub) — Web Image

### 4.1 Prerequisites (local machine)
Verify:
```bash
docker --version
docker compose version
```

### 4.2 Build the web image locally
Run from repository root:
```bash
docker build -f phase3/Dockerfile -t devop-midterm-web:local .
```

Optional smoke test (web may fall back to in-memory if no MongoDB is provided locally):
```bash
docker run --rm -p 3000:3000 --name devop-test devop-midterm-web:local
# Open http://localhost:3000
```

### 4.3 Tag and push to Docker Hub
Login:
```bash
docker login
```

Tag:
```bash
docker tag devop-midterm-web:local mhiu180105/devop-midterm-web:1.0.0
docker tag devop-midterm-web:local mhiu180105/devop-midterm-web:latest
```

Push:
```bash
docker push mhiu180105/devop-midterm-web:1.0.0
docker push mhiu180105/devop-midterm-web:latest
```

**Evidence to capture (Phase 3 report):**
- `docker build` output
- `docker push` output
- Docker Hub repository page (tags visible)

---

## 5. Server Setup (Ubuntu) — Docker & Docker Compose

### 5.1 Verify Docker and Compose on server
SSH to server:
```bash
ssh ubuntu@54.234.158.141
```

Verify:
```bash
docker --version
docker compose version
sudo systemctl status docker --no-pager
```

If `docker ps` fails due to permission, add user to docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
docker ps
```

---

## 6. Deploy with Docker Compose (Server Pulls Image from Docker Hub)

### 6.1 Create the deployment directory
```bash
mkdir -p ~/devop-midterm-phase3
cd ~/devop-midterm-phase3
```

### 6.2 Copy compose and env template to server (from local machine)
From local machine:
```bash
scp -i <KEY>.pem phase3/docker-compose.yml ubuntu@54.234.158.141:~/devop-midterm-phase3/docker-compose.yml
scp -i <KEY>.pem phase3/.env.example ubuntu@54.234.158.141:~/devop-midterm-phase3/.env
```

### 6.3 Configure environment variables on server
Edit `.env`:
```bash
cd ~/devop-midterm-phase3
nano .env
```

Recommended values:
```env
PORT=3000
MONGO_URI=mongodb://mongo:27017/products_db
```

Verify:
```bash
cat .env
```

### 6.4 Ensure Compose pulls web image from registry (NO build on server)
Verify in `docker-compose.yml` that web uses `image:` and not `build:`:
- ✅ `image: mhiu180105/devop-midterm-web:1.0.0`
- ❌ no `build: .`

Check:
```bash
grep -n "build:" docker-compose.yml || echo "OK: no build directive"
grep -n "image:" docker-compose.yml
```

### 6.5 Stop Phase 2 process manager (PM2) to avoid port conflict (Required)
Phase 3 must not run the app using PM2/systemd.

Check if port 3000 is in use:
```bash
sudo lsof -nP -iTCP:3000 -sTCP:LISTEN
```

If PM2 is running:
```bash
pm2 list
pm2 stop product-api
pm2 save
# optional cleanup:
pm2 delete product-api
pm2 save
```

### 6.6 Pull and start services
```bash
cd ~/devop-midterm-phase3

docker compose pull
docker compose up -d

docker ps
docker compose logs --tail=100 web
docker compose logs --tail=100 mongo
```

**Evidence to capture:**
- `docker compose pull` output (proves registry pull)
- `docker compose up -d`
- `docker ps`

---

## 7. MongoDB Readiness and “No Fallback” Requirement

This application attempts to connect to MongoDB with a short timeout (3 seconds).  
If MongoDB is not ready, it falls back to in-memory mode.

### 7.1 Verify web container receives correct MONGO_URI
```bash
docker exec -it devop_midterm_web sh -lc 'echo "MONGO_URI=$MONGO_URI"'
```

Expected:
```bash
MONGO_URI=mongodb://mongo:27017/products_db
```

### 7.2 Verify MongoDB is reachable
Check mongo logs:
```bash
docker compose logs --tail=200 mongo
```

Ping MongoDB:
```bash
docker exec -it devop_midterm_mongo mongosh --eval 'db.runCommand({ ping: 1 })'
```

Expected output includes `ok: 1`.

### 7.3 If web fell back to in-memory, restart web after mongo is ready
```bash
docker restart devop_midterm_web
docker compose logs --tail=80 web
```

**Requirement:** Phase 3 must operate with MongoDB container successfully, not in-memory fallback.

---

## 8. Persistence (Mandatory): DB + Uploads

### 8.1 Volumes
Compose defines:
- `mongo_data` → `/data/db`
- `uploads_data` → `/app/public/uploads`
- `logs_data` → `/app/logs`

Verify volumes:
```bash
docker volume ls
```

### 8.2 Persistence tests (must be demonstrated)
1) Create product + upload image via UI (HTTPS).
2) Restart web container:
```bash
docker restart devop_midterm_web
```
Verify uploaded files and data remain.
3) Restart mongo container:
```bash
docker restart devop_midterm_mongo
```
Verify data remains.
4) Restart the stack:
```bash
docker compose down
docker compose up -d
```
Verify data + uploaded files still persist.

**Evidence to capture:**
- before/after screenshots
- `docker ps` output
- `docker volume ls`

---

## 9. Nginx Reverse Proxy (Host-Level) + HTTPS

### 9.1 Verify Nginx is host-level (not in Docker)
```bash
sudo systemctl status nginx --no-pager
docker ps | grep -i nginx || echo "OK: no nginx container"
```

### 9.2 Verify Nginx routes to the containerized web app
Inspect active config:
```bash
sudo nginx -T | grep -n "server_name\|proxy_pass\|ssl_certificate"
```

Expected:
- `server_name devop-midterm2026.online;`
- `proxy_pass http://localhost:3000;` (or `127.0.0.1:3000`)
- Let’s Encrypt cert paths:
  - `/etc/letsencrypt/live/devop-midterm2026.online/fullchain.pem`
  - `/etc/letsencrypt/live/devop-midterm2026.online/privkey.pem`

Reload after changes:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 9.3 HTTPS verification
```bash
curl -I https://devop-midterm2026.online
```

---

## 10. Reliability: Restart Policies and Server Reboot Behavior (Mandatory)

### 10.1 Restart policies
Verify:
```bash
grep -n "restart:" docker-compose.yml
```

Services should use: `restart: unless-stopped` (or `always`).

### 10.2 Docker auto-start on boot
```bash
sudo systemctl enable docker
sudo systemctl is-enabled docker
```

### 10.3 Reboot test
Reboot:
```bash
sudo reboot
```

After reconnect:
```bash
docker ps
curl -I https://devop-midterm2026.online
```

**Evidence required:** `docker ps` after reboot and successful HTTPS response.

---

## 11. Phase 3 Verification Checklist (Final)

- [ ] `docker --version` works on server
- [ ] `docker compose version` works on server
- [ ] Web image is built locally and pushed to Docker Hub
- [ ] Compose on server pulls image `mhiu180105/devop-midterm-web:1.0.0` (no server build)
- [ ] MongoDB runs in Docker (`mongo:6.0`)
- [ ] Web connects to MongoDB via `mongo:27017` (no in-memory fallback)
- [ ] Volumes persist DB data and uploaded files across restarts
- [ ] Nginx remains on host and proxies to `localhost:3000`
- [ ] HTTPS works for `devop-midterm2026.online`
- [ ] Restart policies configured
- [ ] After full server reboot, containers come back and HTTPS works

---

## 12. Evidence Collection Checklist (Recommended)

Store evidence under `phase3/evidence/`:
- Docker/Compose versions (server)
- `docker build` output
- `docker push` output
- Docker Hub repo screenshot (tags)
- `docker compose pull` output (server)
- `docker compose up -d` + `docker ps`
- volume persistence proof (uploads + DB)
- Nginx config proof (`nginx -T` relevant lines) + `nginx -t`
- HTTPS proof (browser lock + `curl -I`)
- reboot proof (`docker ps` after reboot)

---

## 13. Notes

- Do not commit `.env` containing real secrets. Keep `.env.example` only.
- Phase 3 must not rely on PM2/systemd for running the web application.
- The reverse proxy remains host-level; only the upstream points to the containerized web app.