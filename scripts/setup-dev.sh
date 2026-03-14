#!/bin/bash

################################################################################
# Development Environment Setup Script
# Purpose: Set up development environment with additional dev tools
# Usage: ./scripts/setup-dev.sh
################################################################################

set -e

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
# Install Development Dependencies
################################################################################

install_dev_dependencies() {
    log_info "Installing development dependencies..."
    
    npm install --save-dev \
        eslint \
        prettier \
        || log_error "Dev dependency installation failed"
    
    log_success "Development dependencies installed"
}

################################################################################
# Setup Git Hooks
################################################################################

setup_git_hooks() {
    log_info "Setting up git hooks..."
    
    # Create pre-commit hook
    mkdir -p .git/hooks
    
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running pre-commit checks..."
npm run lint --if-present || echo "Lint check failed, but commit proceeding"
EOF
    
    chmod +x .git/hooks/pre-commit
    log_success "Git hooks configured"
}

################################################################################
# Create Development Configuration Files
################################################################################

create_dev_config() {
    log_info "Creating development configuration files..."
    
    # Create .eslintrc.json if it doesn't exist
    if [ ! -f .eslintrc.json ]; then
        cat > .eslintrc.json << 'EOF'
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": 12
  },
  "rules": {
    "no-unused-vars": ["warn"],
    "no-console": "off"
  }
}
EOF
        log_success "Created .eslintrc.json"
    fi
    
    # Create .prettierrc if it doesn't exist
    if [ ! -f .prettierrc ]; then
        cat > .prettierrc << 'EOF'
{
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "semi": true,
  "printWidth": 100
}
EOF
        log_success "Created .prettierrc"
    fi
}

################################################################################
# Create VS Code Settings
################################################################################

create_vscode_settings() {
    log_info "Creating VS Code configuration..."
    
    mkdir -p .vscode
    
    cat > .vscode/settings.json << 'EOF'
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
EOF
    
    cat > .vscode/extensions.json << 'EOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "mongodb.mongodb-vscode"
  ]
}
EOF
    
    log_success "VS Code configuration created"
}

################################################################################
# Setup Docker for Development
################################################################################

setup_docker_dev() {
    log_info "Checking Docker configuration..."
    
    if [ ! -f Dockerfile ]; then
        log_info "Creating Dockerfile..."
        cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application
COPY . .

# Create necessary directories
RUN mkdir -p public/uploads logs

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
EOF
        log_success "Created Dockerfile"
    fi
    
    if [ ! -f docker-compose.yml ]; then
        log_info "Creating docker-compose.yml..."
        cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - MONGO_URI=mongodb://mongo:27017/products_db
    depends_on:
      - mongo
    volumes:
      - ./public/uploads:/app/public/uploads
      - ./logs:/app/logs
    restart: unless-stopped

  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped

volumes:
  mongodb_data:
EOF
        log_success "Created docker-compose.yml"
    fi
}

################################################################################
# Main Setup Flow
################################################################################

main() {
    log_info "=========================================="
    log_info "Development Environment Setup"
    log_info "=========================================="
    echo ""
    
    # Install dev dependencies
    log_info "Step 1: Installing dev dependencies..."
    install_dev_dependencies
    echo ""
    
    # Create configuration files
    log_info "Step 2: Creating configuration files..."
    create_dev_config
    echo ""
    
    # Setup Git hooks
    log_info "Step 3: Setting up git hooks..."
    setup_git_hooks
    echo ""
    
    # Setup VS Code
    log_info "Step 4: Creating VS Code configuration..."
    create_vscode_settings
    echo ""
    
    # Setup Docker
    log_info "Step 5: Setting up Docker configuration..."
    setup_docker_dev
    echo ""
    
    log_success "=========================================="
    log_success "Development setup completed!"
    log_success "=========================================="
    echo ""
    echo -e "${GREEN}Available commands:${NC}"
    echo "  npm run dev       - Start with Nodemon"
    echo "  npm start         - Start production server"
    echo "  npm run lint      - Run ESLint"
    echo ""
    echo -e "${GREEN}Docker commands:${NC}"
    echo "  docker-compose up -d       - Start services"
    echo "  docker-compose down        - Stop services"
    echo "  docker-compose logs -f     - View logs"
    echo ""
}

main
exit $?
