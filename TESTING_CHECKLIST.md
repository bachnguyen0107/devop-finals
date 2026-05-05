# TESTING CHECKLIST - DevOps Final Project

## Phase 1: Verify EC2 Deployment (Lean Config)
Wait for GitHub Actions to complete, then:

### 1.1 SSH to EC2 and check services
```bash
ssh -i your-key.pem ec2-user@your-ec2-ip
cd devop-finals

# Check running containers
docker ps
# Should show: nginx, web (3 replicas), mongo

# Check services status
docker-compose -f docker-compose.yml ps

# Check disk space (should have 1-1.5GB free)
df -h
```

### 1.2 Verify application on EC2
```bash
# Test nginx is forwarding
curl -I http://your-ec2-ip/
# Should return HTTP 200

# Test API endpoint
curl http://your-ec2-ip/products | jq .
# Should return JSON products array

# Test UI is accessible
curl http://your-ec2-ip/ | grep -i "product" | head -5
# Should contain HTML with product management UI
```

### 1.3 Verify MongoDB persistence
```bash
# Connect to container and check data
docker exec devop_final_mongo mongosh --username admin --password password --authenticationDatabase admin

> use products_db
> db.products.countDocuments()
# Should return count > 0 if data exists, or 0 if fresh

> db.products.findOne()
# Should show sample product or empty
```

---

## Phase 2: Verify CI/CD Pipeline
Go to: https://github.com/bachnguyen0107/devop-finals/actions

### 2.1 Check latest workflow run
- [ ] Click latest run
- [ ] Verify all jobs pass: ✅ build-and-test, ✅ security-scan, ✅ docker-build-push, ✅ deploy
- [ ] Check deployment logs: "Successfully started devop_final_nginx", "Successfully started devop_final_web_1"

### 2.2 Trigger a test deployment
Make a small change locally:
```bash
# Edit any file (e.g., README.md or add a comment to main.js)
echo "# Test deployment $(date)" >> README.md

# Commit and push
git add README.md
git commit -m "Test CI/CD trigger"
git push origin main
```

Then watch GitHub Actions:
- [ ] Workflow starts automatically
- [ ] Passes all stages
- [ ] Deployment completes successfully
- [ ] SSH output shows: "docker-compose pull" + "docker-compose up -d"

---

## Phase 3: Test Monitoring Stack (Local/Demo Setup)
On your local machine or demo server:

### 3.1 Start monitoring services
```bash
cd devop-finals
docker-compose -f docker-compose.yml up -d --build
```

### 3.2 Verify monitoring services
```bash
# Check containers running
docker ps | grep -E "prometheus|grafana|cadvisor"

# All 3 should be running:
# - devop_final_prometheus (port 9090)
# - devop_final_grafana (port 3001)
# - devop_final_cadvisor (port 8080)
```

### 3.3 Verify Prometheus connectivity
```bash
curl http://localhost:9090/api/v1/query?query=up
# Should return JSON with targets
```

### 3.4 Verify Grafana dashboard
- [ ] Open http://localhost:3001
- [ ] Login: admin / admin
- [ ] Check: Settings → Data Sources → Prometheus
- [ ] Should show "Prometheus" datasource with "green" status

### 3.5 Verify cAdvisor
- [ ] Open http://localhost:8080
- [ ] Should show container metrics dashboard
- [ ] Verify it can see running containers

---

## Phase 4: Full End-to-End Test (Deployment + Monitoring)

### 4.1 Local full stack (for testing)
```bash
# Start all services locally
docker-compose -f docker-compose.yml up -d --build

# Check all 8 services running
docker ps | wc -l
# Should show 8 containers (nginx, 3x web, mongo, prometheus, grafana, cadvisor)
```

### 4.2 Test local application
```bash
# Create a test product
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "color": "red",
    "description": "Test description",
    "category": "test"
  }'

# Verify it appears in UI
curl http://localhost:3000 | grep "Test Product"
```

### 4.3 Test monitoring with live data
```bash
# Generate some load on application
for i in {1..100}; do
  curl -s http://localhost:3000/products > /dev/null &
done
wait

# Open Grafana: http://localhost:3001
# - Check Dashboard for container metrics
# - Verify CPU/Memory spikes from load test
# - Check Prometheus: http://localhost:9090
#   - Query: container_memory_usage_bytes
#   - Should show metrics for web containers
```

---

## Phase 5: Failure Recovery & Resilience Test

### 5.1 Test container auto-restart
```bash
# Kill one web container
docker kill devop_final_web_1

# Wait 5 seconds
sleep 5

# Check if it restarted
docker ps | grep devop_final_web
# Should show NEW container_id and different CREATED time
```

### 5.2 Test MongoDB persistence
```bash
# Create a product (if not done in Phase 4)
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Persistent Product", "price": 50, "color": "blue"}'

# Stop and remove all containers (but keep volumes)
docker-compose down

# Restart
docker-compose up -d

# Check if product still exists
curl http://localhost:3000/products | grep "Persistent Product"
# Should find it!
```

### 5.3 Monitor failure in Grafana
```bash
# While Grafana is open:
# 1. Kill a container: docker kill devop_final_web_2
# 2. Watch Grafana dashboard
# 3. Container should show as "down" initially
# 4. After auto-restart, should show as "up" again
# 5. Check Prometheus alerts (if configured)
```

---

## Phase 6: HTTPS Verification (EC2)

### 6.1 Test HTTPS certificate
```bash
# From any machine, test HTTPS
curl -I https://devop-midterm2026.online/
# Should return HTTP 200 (not 403/404/SSL error)

# Check certificate validity
openssl s_client -connect devop-midterm2026.online:443 -showcerts
# Verify: Issuer, Subject CN, Validity dates
```

### 6.2 Test HTTP → HTTPS redirect (if configured)
```bash
curl -I http://devop-midterm2026.online/
# Should redirect to https://
```

---

## Phase 7: Ready for Live Demo!

### Checklist before showing to instructor:

**EC2 Production:**
- [ ] SSH into EC2 successful
- [ ] `docker ps` shows 4 containers (nginx, 3x web, mongo)
- [ ] `curl http://13.212.58.182/` returns 200
- [ ] Products accessible via browser
- [ ] HTTPS working (if configured)

**GitHub Actions:**
- [ ] Latest deployment succeeded
- [ ] All 4 jobs passed
- [ ] Can trigger new deployment and it passes

**Local Monitoring (for demo):**
- [ ] Prometheus running on :9090
- [ ] Grafana running on :3001 with datasource connected
- [ ] cAdvisor running on :8080
- [ ] Can show metrics from running containers

**Application Functionality:**
- [ ] Create product works
- [ ] List products works
- [ ] Update product works
- [ ] Delete product works
- [ ] Search/filter works
- [ ] Image upload works (optional)

**Resilience Demo:**
- [ ] Can kill a container and show auto-restart
- [ ] Data persists after restart
- [ ] Monitoring shows recovery in Grafana

---

## Quick Test Commands (Copy-Paste Ready)

```bash
# Test 1: App is running
curl -I http://localhost:3000/

# Test 2: Create test product
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","price":10,"color":"red"}'

# Test 3: List products
curl http://localhost:3000/products | jq '.data | length'

# Test 4: Check containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# Test 5: Check Prometheus
curl http://localhost:9090/api/v1/query?query=up | jq '.data.result | length'

# Test 6: Kill and restart container
docker kill $(docker ps -q -f "name=web_1") && sleep 5 && docker ps

# Test 7: Verify data persisted
curl http://localhost:3000/products | jq '.data | length'
```

---

## Demo Script for Instructor (15-20 mins)

1. **Show EC2 Production** (2 mins)
   ```
   SSH to EC2 → docker ps → show 4 running services
  Browser: http://13.212.58.182 → show app working
   ```

2. **Show CI/CD Pipeline** (3 mins)
   ```
   GitHub Actions → show latest successful run
   Make small change → git push → watch Actions run live
   Deployment completes → verify on EC2
   ```

3. **Show Monitoring** (5 mins)
   ```
   Grafana: http://localhost:3001
   Show dashboards with live metrics
   Prometheus: show queries, metrics data
   ```

4. **Show Failure Recovery** (3 mins)
   ```
   Kill a container: docker kill web_2
   Watch Grafana: container goes down
   Wait 5 seconds: container auto-restarts
   Show it's back up in Grafana
   ```

5. **Show Data Persistence** (2 mins)
   ```
   docker-compose down
   docker-compose up -d
   Show data still exists
   ```

---

## Troubleshooting During Test

| Issue | Solution |
|-------|----------|
| EC2 SSH timeout | Check security group allows port 22, verify EC2 is running |
| Services not starting | `docker logs <container_name>`, check `df -h` for disk space |
| Grafana shows "No datasource" | Check Prometheus connectivity: `curl http://prometheus:9090` from inside Grafana container |
| CI/CD job fails | Check GitHub Actions logs, verify `.env` is correct, check EC2 disk space |
| Products not persisting | Check MongoDB volume mounted: `docker volume ls`, `docker inspect mongo_data` |
| HTTPS cert error | Verify cert files in `./ssl/`, check nginx-ssl.conf permissions |

---

## Expected Results After All Tests

✅ EC2 production running lean config
✅ App fully functional on EC2  
✅ CI/CD pipeline working end-to-end
✅ Can deploy changes via git push
✅ Monitoring shows live metrics
✅ Container auto-restart working
✅ Data persists across restarts
✅ All ready for live demonstration

**Estimated time to complete all tests: 30-45 minutes**
