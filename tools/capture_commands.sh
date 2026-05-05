#!/usr/bin/env bash
set -e
mkdir -p evidence

# 1. Save terraform apply last output if available
if [ -f ../../terraform_apply_output.txt ]; then
  cp ../../terraform_apply_output.txt evidence/terraform_apply.txt || true
fi

# 2. Capture docker-compose ps
docker-compose -f docker-compose.yml ps > evidence/docker_compose_ps.txt 2>&1 || true

# 3. Capture nginx access log sample (if exists)
if [ -f ./logs/nginx/access.log ]; then
  tail -n 200 ./logs/nginx/access.log > evidence/nginx_access_sample.txt || true
elif [ -f /var/log/nginx/access.log ]; then
  sudo tail -n 200 /var/log/nginx/access.log > evidence/nginx_access_sample.txt || true
fi

# 4. Capture nginx access as PNG
if command -v convert >/dev/null 2>&1; then
  cat evidence/nginx_access_sample.txt | ./tools/terminal_to_png.sh evidence/nginx_access_sample.png || true
fi

# 5. Grafana and Prometheus screenshots (requires node and puppeteer dependencies)
# Usage examples (run interactively):
# node tools/screenshot_grafana.js http://localhost:3001 http://localhost:3001 evidence/grafana_dashboard.png
# node tools/screenshot_prometheus.js http://localhost:9090/targets evidence/prometheus_targets.png

echo "Created evidence/ with available text dumps. For Grafana/Prometheus screenshots run the Node scripts as needed."
