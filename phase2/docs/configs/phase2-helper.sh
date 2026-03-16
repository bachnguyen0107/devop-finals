#!/bin/bash

################################################################################
# Phase 2 Deployment Helper Script
# Purpose: Quick reference commands for common Phase 2 operations
# Location: ~/product-api/scripts/phase2-helper.sh (optional)
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

################################################################################
# MongoDB Docker Management
################################################################################

start_mongodb() {
    log_info "Starting MongoDB container..."
    sudo docker run -d \
      --name mongodb \
      -p 27017:27017 \
      mongo:6.0
    log_success "MongoDB started"
}

stop_mongodb() {
    log_info "Stopping MongoDB container..."
    sudo docker stop mongodb
    sudo docker rm mongodb
    log_success "MongoDB stopped"
}

mongodb_status() {
    log_info "MongoDB status:"
    sudo docker ps | grep mongo
}

################################################################################
# PM2 Process Management
################################################################################

start_app_pm2() {
    log_info "Starting app with PM2..."
    pm2 start main.js --name "product-api"
    pm2 save
    log_success "App started with PM2"
}

stop_app_pm2() {
    log_info "Stopping app..."
    pm2 stop product-api
    log_success "App stopped"
}

restart_app_pm2() {
    log_info "Restarting app..."
    pm2 restart product-api
    log_success "App restarted"
}

app_status() {
    log_info "App status:"
    pm2 list
}

app_logs() {
    log_info "App logs:"
    pm2 logs product-api
}

################################################################################
# Nginx Reverse Proxy
################################################################################

nginx_status() {
    log_info "Nginx status:"
    sudo systemctl status nginx
}

nginx_reload() {
    log_info "Reloading Nginx..."
    sudo nginx -t && sudo systemctl reload nginx
    log_success "Nginx reloaded"
}

nginx_logs() {
    log_info "Nginx access logs (last 20 lines):"
    sudo tail -20 /var/log/nginx/product-api-access.log
}

################################################################################
# Health Checks
################################################################################

health_check() {
    log_info "Running health checks..."
    echo ""
    
    # Check MongoDB
    echo -n "MongoDB: "
    if sudo docker ps | grep mongo > /dev/null; then
        log_success "Running"
    else
        log_error "Not running"
    fi
    
    # Check PM2 app
    echo -n "App (PM2): "
    if pm2 list | grep "online" > /dev/null; then
        log_success "Online"
    else
        log_error "Not online"
    fi
    
    # Check Nginx
    echo -n "Nginx: "
    if sudo systemctl is-active nginx > /dev/null; then
        log_success "Active"
    else
        log_error "Not active"
    fi
    
    # Check API
    echo -n "API (localhost:3000): "
    if curl -s http://localhost:3000/products > /dev/null; then
        log_success "Responding"
    else
        log_error "Not responding"
    fi
    
    echo ""
}

################################################################################
# Main Menu
################################################################################

show_menu() {
    echo ""
    echo -e "${BLUE}=== Phase 2 Deployment Helper ===${NC}"
    echo ""
    echo "MongoDB:"
    echo "  1. Start MongoDB"
    echo "  2. Stop MongoDB"
    echo "  3. Check MongoDB status"
    echo ""
    echo "Application (PM2):"
    echo "  4. Start app with PM2"
    echo "  5. Stop app"
    echo "  6. Restart app"
    echo "  7. Check app status"
    echo "  8. Show app logs"
    echo ""
    echo "Nginx:"
    echo "  9. Check Nginx status"
    echo " 10. Reload Nginx"
    echo " 11. Show Nginx logs"
    echo ""
    echo "Health Checks:"
    echo " 12. Full health check"
    echo ""
    echo " 0. Exit"
    echo ""
}

# Interactive menu (if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    while true; do
        show_menu
        read -p "Select option: " choice
        
        case $choice in
            1) start_mongodb ;;
            2) stop_mongodb ;;
            3) mongodb_status ;;
            4) start_app_pm2 ;;
            5) stop_app_pm2 ;;
            6) restart_app_pm2 ;;
            7) app_status ;;
            8) app_logs ;;
            9) nginx_status ;;
            10) nginx_reload ;;
            11) nginx_logs ;;
            12) health_check ;;
            0) log_info "Exiting"; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac
        
        read -p "Press Enter to continue..."
    done
fi
