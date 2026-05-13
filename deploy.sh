#!/bin/bash

# EC2 Configuration
EC2_IP="13.229.76.119"
EC2_USER="ubuntu"
SSH_KEY="/home/dmin/.ssh/id_rsa"
PROJECT_PATH="/home/dmin/devopp_final/devop-finals"
REMOTE_PATH="/home/ubuntu/devop-finals"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment to EC2...${NC}"

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "echo 'SSH connection successful'" 
if [ $? -ne 0 ]; then
    echo -e "${RED}SSH connection failed${NC}"
    exit 1
fi

# Create remote directory
echo -e "${YELLOW}Creating remote directory...${NC}"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "mkdir -p $REMOTE_PATH"

# Upload project files
echo -e "${YELLOW}Uploading project files...${NC}"
scp -i "$SSH_KEY" -r "$PROJECT_PATH"/* "$EC2_USER@$EC2_IP:$REMOTE_PATH/"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Project uploaded successfully${NC}"
else
    echo -e "${RED}Upload failed${NC}"
    exit 1
fi

# Create .env file on remote if it doesn't exist
echo -e "${YELLOW}Setting up environment...${NC}"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" << 'EOF'
    if [ ! -f ~/devop-finals/.env ]; then
        cat > ~/devop-finals/.env << 'ENVFILE'
PORT=3000
MONGO_URI=mongodb://mongo:27017/products_db
NODE_ENV=production
ENVFILE
        echo "Created .env file"
    fi
EOF

# Verify files were uploaded
echo -e "${YELLOW}Verifying upload...${NC}"
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "ls -la $REMOTE_PATH | head -20"

echo -e "${GREEN}Deployment preparation complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. SSH into your instance: ssh -i ~/.ssh/id_rsa ubuntu@13.229.76.119"
echo "2. Navigate to project: cd ~/devop-finals"
echo "3. Start services: docker-compose up -d"
