# Horizontal Scaling Configuration

## Overview
This deployment uses Docker Compose with container-level horizontal scaling to run multiple replicas of the Node.js web application. Nginx acts as a load balancer, distributing traffic across all instances.

## Current Configuration
- **Web Service Replicas**: 3 instances
- **Load Balancing Method**: Least connections (default round-robin also available)
- **Sticky Sessions**: Not enabled (stateless application)

## How It Works

### Service Replication
When you run `docker-compose up -d`, Docker Compose will start 3 separate containers of the `devop-midterm-web` service:
- `devop-finals-web-1`
- `devop-finals-web-2`
- `devop-finals-web-3`

Each instance:
- Connects to the same MongoDB database
- Uses shared volumes for uploads and logs
- Runs independently on port 3000 (internal to Docker network)

### Nginx Load Balancing
Nginx is configured as an upstream with 3 backend servers:
```nginx
upstream web_app {
    server web:3000;
    server web:3000;
    server web:3000;
    least_conn;
}
```

Docker's internal DNS resolves `web:3000` to all 3 instances, and Nginx distributes requests using the least-connections algorithm.

## Scaling Commands

### View Current Services
```bash
docker-compose ps
```

Output shows all running replicas:
```
devop_midterm_nginx     nginx:latest    Up    0.0.0.0:80->80/tcp
devop-finals-web-1      devop-midterm-web:1.0.0    Up    3000/tcp
devop-finals-web-2      devop-midterm-web:1.0.0    Up    3000/tcp
devop-finals-web-3      devop-midterm-web:1.0.0    Up    3000/tcp
devop_midterm_mongo     mongo:6.0       Up    27017/tcp
```

### Scale Up to 5 Replicas
```bash
docker-compose up -d --scale web=5
```

### Scale Down to 2 Replicas
```bash
docker-compose up -d --scale web=2
```

### Restart Services with New Replica Count
```bash
docker-compose down
docker-compose up -d --scale web=4
```

### Monitor Load Distribution
```bash
# Watch Nginx logs to see request distribution
docker-compose logs -f nginx

# Check individual container logs
docker-compose logs devop-finals-web-1
docker-compose logs devop-finals-web-2
docker-compose logs devop-finals-web-3
```

## Performance Testing

### Test Load Balancing
```bash
# Generate multiple requests and watch distribution
for i in {1..50}; do curl http://13.212.58.182/; done

# Watch Nginx logs
docker-compose logs -f nginx | grep "upstream"
```

### Simple Load Test Script
```bash
#!/bin/bash
echo "Testing load balancing across $(docker-compose ps | grep 'web' | wc -l) instances..."

for i in {1..100}; do
    curl -s http://localhost/ > /dev/null &
done

wait
echo "Completed 100 concurrent requests"
```

## Advanced Configuration

### Change Load Balancing Algorithm
Edit `nginx.conf` to use different methods:

**Least Connections (current)**
```nginx
least_conn;
```

**Round-Robin (default)**
```nginx
# Just remove least_conn line
```

**IP Hash (sticky sessions)**
```nginx
ip_hash;
```

**Weighted Round-Robin**
```nginx
server web:3000 weight=3;  # Gets 3x more traffic
server web:3000 weight=1;
server web:3000 weight=1;
```

### Health Checks
Nginx can automatically remove unhealthy backends:
```nginx
upstream web_app {
    server web:3000 max_fails=3 fail_timeout=30s;
    server web:3000 max_fails=3 fail_timeout=30s;
    server web:3000 max_fails=3 fail_timeout=30s;
}
```

## Monitoring & Observability

### Check Container Status
```bash
docker-compose ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"
```

### Monitor Resource Usage
```bash
# Overall container stats
docker stats

# Specific service
docker stats devop-finals-web-1 devop-finals-web-2 devop-finals-web-3
```

### View Shared Volume Usage
```bash
# Check uploads volume
docker exec devop_midterm_nginx ls -lh /devop-finals_uploads_data

# Check logs volume
docker exec devop_midterm_nginx ls -lh /devop-finals_logs_data
```

## Troubleshooting

### Nginx Can't Find Web Containers
If Nginx fails to connect:
```bash
# Verify network
docker network inspect devop-finals_app-network

# Restart nginx
docker-compose restart nginx
```

### Uneven Load Distribution
Check if:
- All replicas are actually running: `docker-compose ps`
- Nginx config has correct number of servers
- Restart: `docker-compose restart nginx`

### Memory Issues with Many Replicas
Monitor memory:
```bash
docker stats
docker system df
```

Reduce replicas if needed:
```bash
docker-compose up -d --scale web=2
```

## Testing Failover

### Kill One Instance
```bash
# Find container ID
docker ps | grep web

# Kill it
docker kill <container_id>

# Nginx continues serving from other instances
# Docker Compose auto-restarts it due to restart: unless-stopped
```

### Observe Automatic Recovery
```bash
# Watch as Docker restarts the container
docker events

# Monitor Nginx handling the failure
docker-compose logs -f nginx
```

## Best Practices

1. **Always use shared volumes** for uploads/logs (enabled by default)
2. **Keep application stateless** - avoid per-instance state
3. **Monitor resource usage** - don't scale beyond available resources
4. **Use health checks** - configure endpoint monitoring
5. **Load test before production** - understand your capacity limits
6. **Document your baseline** - know your 1-replica performance

## Next Steps

- Configure CI/CD for automated deployments
- Add metrics collection (Prometheus)
- Implement distributed logging (ELK Stack)
- Setup alerts for scaling thresholds
- Test under realistic load conditions
