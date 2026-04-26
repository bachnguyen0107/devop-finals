#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   DevOps Finals - EC2 Startup${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found!${NC}"
    echo -e "${YELLOW}Please run this script from the project directory${NC}"
    exit 1
fi

# Check Docker
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found! Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"
docker --version

# Check Docker Compose
echo -e "${YELLOW}Checking Docker Compose installation...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose not found! Please install Docker Compose first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"
docker-compose --version

# Create SSL directory if it doesn't exist
echo -e "${YELLOW}Setting up directories...${NC}"
mkdir -p ssl
echo -e "${GREEN}✓ SSL directory ready${NC}"

# Check if image needs to be built
IMAGE_NAME=$(grep -A 2 "web:" docker-compose.yml | grep "image:" | awk '{print $2}')
echo -e "${YELLOW}Checking if Docker image needs to be built...${NC}"
echo -e "${BLUE}Using image: $IMAGE_NAME${NC}"

if [[ "$IMAGE_NAME" == "DOCKERHUB_USERNAME"* ]]; then
    echo -e "${RED}Error: DOCKERHUB_USERNAME not replaced in docker-compose.yml${NC}"
    echo -e "${YELLOW}Please update docker-compose.yml with your actual Docker Hub username or use a local image name${NC}"
    exit 1
fi

# Check if image exists locally
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    if [[ "$IMAGE_NAME" == *"/"* ]] && [[ "$IMAGE_NAME" != "mongo:6.0" ]]; then
        echo -e "${YELLOW}Image $IMAGE_NAME not found locally${NC}"
        echo -e "${YELLOW}Will pull from registry on docker-compose up${NC}"
    else
        echo -e "${YELLOW}Building Docker image locally...${NC}"
        docker build -t "$IMAGE_NAME" .
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Image built successfully${NC}"
        else
            echo -e "${RED}Failed to build image${NC}"
            exit 1
        fi
    fi
fi

# Start services
echo -e "${YELLOW}Starting services with Docker Compose...${NC}"
docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Services started successfully${NC}"
else
    echo -e "${RED}Failed to start services${NC}"
    docker-compose logs
    exit 1
fi

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Check service status
echo -e "${YELLOW}Service Status:${NC}"
docker-compose ps

# Test connectivity
echo -e "${YELLOW}Testing connectivity...${NC}"
if curl -s http://localhost/health > /dev/null; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${YELLOW}⚠ Health check not yet responding (services may still be starting)${NC}"
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Deployment Ready!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${BLUE}Quick Links:${NC}"
echo -e "  Web UI:        ${YELLOW}http://$(hostname -I | awk '{print $1}')${NC}"
echo -e "  Health Check:  ${YELLOW}http://$(hostname -I | awk '{print $1}')/health${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  View logs:     ${YELLOW}docker-compose logs -f${NC}"
echo -e "  Stop services: ${YELLOW}docker-compose down${NC}"
echo -e "  Restart:       ${YELLOW}docker-compose restart${NC}"
echo ""
