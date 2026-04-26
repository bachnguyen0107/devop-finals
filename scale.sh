#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show menu
show_menu() {
    echo ""
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Horizontal Scaling Manager${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    echo "1. View current replicas"
    echo "2. Scale to N replicas"
    echo "3. Scale up by 1"
    echo "4. Scale down by 1"
    echo "5. Monitor load distribution"
    echo "6. Run load test"
    echo "7. View service status"
    echo "8. View Nginx logs"
    echo "9. Exit"
    echo ""
}

# Get current replica count
get_replica_count() {
    REPLICAS=$(docker-compose ps | grep 'devop-finals-web' | wc -l)
    echo "$REPLICAS"
}

# View current replicas
view_replicas() {
    echo ""
    echo -e "${YELLOW}Current Web Service Replicas:${NC}"
    REPLICAS=$(get_replica_count)
    echo -e "${GREEN}$REPLICAS replicas running${NC}"
    echo ""
    docker-compose ps | grep -E 'devop.*web|CONTAINER'
    echo ""
}

# Scale to specific count
scale_to() {
    REPLICAS=$1
    if [ -z "$REPLICAS" ]; then
        read -p "Enter number of replicas: " REPLICAS
    fi
    
    if ! [[ "$REPLICAS" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid number${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Scaling web service to $REPLICAS replicas...${NC}"
    docker-compose up -d --scale web=$REPLICAS
    
    echo -e "${YELLOW}Waiting for containers to start...${NC}"
    sleep 3
    
    CURRENT=$(get_replica_count)
    echo -e "${GREEN}✓ Now running $CURRENT replicas${NC}"
    view_replicas
}

# Scale up by 1
scale_up() {
    CURRENT=$(get_replica_count)
    NEW=$((CURRENT + 1))
    echo -e "${YELLOW}Scaling up from $CURRENT to $NEW replicas...${NC}"
    scale_to $NEW
}

# Scale down by 1
scale_down() {
    CURRENT=$(get_replica_count)
    if [ $CURRENT -le 1 ]; then
        echo -e "${RED}Cannot scale below 1 replica${NC}"
        return 1
    fi
    NEW=$((CURRENT - 1))
    echo -e "${YELLOW}Scaling down from $CURRENT to $NEW replicas...${NC}"
    scale_to $NEW
}

# Monitor load distribution
monitor_load() {
    echo ""
    echo -e "${YELLOW}Monitoring load distribution (Ctrl+C to stop)...${NC}"
    echo -e "${BLUE}Watch for request distribution across replicas${NC}"
    echo ""
    docker-compose logs -f nginx | grep -E 'GET|POST|PUT|DELETE|upstream'
}

# Run load test
run_load_test() {
    REQUESTS=${1:-100}
    CONCURRENT=${2:-10}
    
    echo ""
    echo -e "${YELLOW}Starting load test...${NC}"
    echo -e "  Total requests: $REQUESTS"
    echo -e "  Concurrent: $CONCURRENT"
    echo ""
    
    # Simple load test
    counter=0
    success=0
    failed=0
    
    for i in $(seq 1 $REQUESTS); do
        curl -s http://localhost/ > /dev/null 2>&1 &
        counter=$((counter + 1))
        
        if [ $counter -ge $CONCURRENT ]; then
            wait
            counter=0
        fi
    done
    
    wait
    echo -e "${GREEN}✓ Load test completed${NC}"
    echo ""
    echo -e "${YELLOW}Checking response times...${NC}"
    (time for i in {1..10}; do curl -s http://localhost/ > /dev/null; done) 2>&1 | grep real
    echo ""
}

# View service status
view_status() {
    echo ""
    echo -e "${YELLOW}Service Status:${NC}"
    docker-compose ps
    echo ""
    
    echo -e "${YELLOW}Container Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}"
    echo ""
}

# View Nginx logs
view_nginx_logs() {
    echo ""
    echo -e "${YELLOW}Nginx Logs (Ctrl+C to stop):${NC}"
    docker-compose logs -f nginx
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Select option (1-9): " choice
        
        case $choice in
            1)
                view_replicas
                ;;
            2)
                read -p "Enter number of replicas: " num
                scale_to $num
                ;;
            3)
                scale_up
                ;;
            4)
                scale_down
                ;;
            5)
                monitor_load
                ;;
            6)
                read -p "Number of requests (default 100): " requests
                requests=${requests:-100}
                read -p "Concurrent requests (default 10): " concurrent
                concurrent=${concurrent:-10}
                run_load_test $requests $concurrent
                ;;
            7)
                view_status
                ;;
            8)
                view_nginx_logs
                ;;
            9)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose not found${NC}"
    exit 1
fi

# Check if we're in the project directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found${NC}"
    echo -e "${YELLOW}Please run this script from the project directory${NC}"
    exit 1
fi

# Run main menu
main
