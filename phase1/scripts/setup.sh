#!/bin/bash

################################################################################
# Setup Script for Product API Application
# Purpose: Install required runtimes, OS packages, and initialize directories
# Usage: ./scripts/setup.sh
################################################################################

set -e  # Exit on error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# System Detection
################################################################################

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="redhat"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    
    log_info "Detected OS: $OS (Distro: $DISTRO)"
}

################################################################################
# Check Prerequisites
################################################################################

check_node() {
    log_info "Checking Node.js installation..."
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        log_success "Node.js found: $NODE_VERSION"
        return 0
    else
        log_warning "Node.js not found"
        return 1
    fi
}

check_npm() {
    log_info "Checking npm installation..."
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm -v)
        log_success "npm found: v$NPM_VERSION"
        return 0
    else
        log_warning "npm not found"
        return 1
    fi
}

check_git() {
    log_info "Checking Git installation..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version)
        log_success "$GIT_VERSION found"
        return 0
    else
        log_warning "Git not found"
        return 1
    fi
}

################################################################################
# Install OS Packages
################################################################################

install_ubuntu_packages() {
    log_info "Installing required packages on Ubuntu/Debian..."
    
    # Update package manager
    log_info "Running apt-get update..."
    sudo apt-get update || log_error "apt-get update failed"
    
    # Install required packages
    local packages="curl wget git build-essential"
    log_info "Installing: $packages"
    sudo apt-get install -y $packages || log_error "Package installation failed"
    
    log_success "Ubuntu/Debian packages installed"
}

install_macos_packages() {
    log_info "Installing required packages on macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || log_error "Homebrew installation failed"
    fi
    
    local packages="curl wget git"
    log_info "Installing: $packages"
    brew install $packages || log_error "Package installation failed"
    
    log_success "macOS packages installed"
}

install_packages() {
    case "$OS" in
        linux)
            case "$DISTRO" in
                debian)
                    install_ubuntu_packages
                    ;;
                redhat)
                    log_warning "Red Hat/CentOS support not fully implemented"
                    ;;
                *)
                    log_warning "Unknown Linux distribution, skipping package installation"
                    ;;
            esac
            ;;
        macos)
            install_macos_packages
            ;;
        *)
            log_warning "Operating system not recognized, skipping package installation"
            ;;
    esac
}

################################################################################
# Install Node.js & npm
################################################################################

install_nodejs() {
    log_info "Checking for Node.js..."
    
    if ! check_node; then
        log_info "Installing Node.js..."
        
        if [[ "$OS" == "linux" && "$DISTRO" == "debian" ]]; then
            # Using NodeSource repository for Debian/Ubuntu
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || log_warning "NodeSource setup failed"
            sudo apt-get install -y nodejs || log_error "Node.js installation failed"
        elif [[ "$OS" == "macos" ]]; then
            brew install node || log_error "Node.js installation failed"
        else
            log_error "Unsupported OS for Node.js installation. Please install manually."
            return 1
        fi
        
        check_node && log_success "Node.js installed successfully"
    fi
}

################################################################################
# Create Necessary Directories
################################################################################

create_directories() {
    log_info "Creating necessary directories..."
    
    local dirs=(
        "public/uploads"
        "logs"
        "docs"
        "scripts"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
}

################################################################################
# Setup Environment
################################################################################

setup_env() {
    log_info "Setting up environment..."
    
    if [ ! -f .env ]; then
        log_info "Creating .env file from template..."
        cat > .env << 'EOF'
# Server Configuration
PORT=3000

# Database Configuration
MONGO_URI=mongodb://localhost:27017/products_db

# Add more environment variables as needed
EOF
        log_success "Created .env file"
        log_warning "Please update .env with your configuration"
    else
        log_info ".env file already exists"
    fi
}

################################################################################
# Install npm Dependencies
################################################################################

install_dependencies() {
    log_info "Installing npm dependencies..."
    
    if [ ! -d node_modules ]; then
        npm install || log_error "npm install failed"
        log_success "Dependencies installed successfully"
    else
        log_info "node_modules already exists, skipping npm install"
        log_info "Run 'npm install' manually if you need to update dependencies"
    fi
}

################################################################################
# Create .gitignore if missing
################################################################################

create_gitignore() {
    log_info "Checking .gitignore..."
    
    if [ ! -f .gitignore ]; then
        log_warning ".gitignore not found, creating basic version..."
        cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
logs/
*.log
public/uploads/
.DS_Store
.idea/
.vscode/
EOF
        log_success "Created .gitignore"
    else
        log_info ".gitignore already exists"
    fi
}

################################################################################
# Verify Installation
################################################################################

verify_installation() {
    log_info "Verifying installation..."
    
    local success=true
    
    # Check Node.js
    if check_node; then
        log_success "Node.js: OK"
    else
        log_error "Node.js: FAILED"
        success=false
    fi
    
    # Check npm
    if check_npm; then
        log_success "npm: OK"
    else
        log_error "npm: FAILED"
        success=false
    fi
    
    # Check npm packages
    if [ -d node_modules ]; then
        log_success "npm packages: OK"
    else
        log_error "npm packages: FAILED"
        success=false
    fi
    
    # Check required directories
    for dir in public/uploads logs docs scripts; do
        if [ -d "$dir" ]; then
            log_success "Directory $dir: OK"
        else
            log_error "Directory $dir: MISSING"
            success=false
        fi
    done
    
    # Check .env
    if [ -f .env ]; then
        log_success ".env file: OK"
    else
        log_error ".env file: MISSING"
        success=false
    fi
    
    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Main Setup Flow
################################################################################

main() {
    log_info "=========================================="
    log_info "Product API - Setup Script"
    log_info "=========================================="
    echo ""
    
    # Detect OS
    detect_os
    echo ""
    
    # Install OS packages
    log_info "Step 1: Installing OS packages..."
    install_packages
    echo ""
    
    # Install Node.js
    log_info "Step 2: Installing Node.js runtime..."
    install_nodejs
    echo ""
    
    # Install dependencies
    log_info "Step 3: Installing npm dependencies..."
    install_dependencies
    echo ""
    
    # Create directories
    log_info "Step 4: Creating necessary directories..."
    create_directories
    echo ""
    
    # Setup environment
    log_info "Step 5: Setting up environment..."
    setup_env
    echo ""
    
    # Create .gitignore
    log_info "Step 6: Checking git configuration..."
    create_gitignore
    echo ""
    
    # Verify installation
    log_info "Step 7: Verifying installation..."
    if verify_installation; then
        log_success "=========================================="
        log_success "Setup completed successfully!"
        log_success "=========================================="
        echo ""
        echo -e "${GREEN}Next steps:${NC}"
        echo "  1. Update your .env file with proper configuration"
        echo "  2. Start MongoDB (if using it): mongod"
        echo "  3. Start the application: npm run dev"
        echo "  4. Open your browser: http://localhost:3000"
        echo ""
        return 0
    else
        log_error "=========================================="
        log_error "Setup encountered errors!"
        log_error "=========================================="
        echo ""
        echo -e "${RED}Please fix the errors above and try again.${NC}"
        echo ""
        return 1
    fi
}

# Run main function
main
exit $?
