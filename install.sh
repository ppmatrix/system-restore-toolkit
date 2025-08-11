#!/bin/bash

# System Restore Toolkit Installation Script
# Version: 2.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
        log_warning "This toolkit is designed for Ubuntu Linux"
    fi
    
    # Check for required commands
    local missing_commands=()
    for cmd in bash tar gzip sudo df; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    # Check for LVM
    if ! command -v lvcreate &> /dev/null; then
        log_warning "LVM tools not found. Install with: sudo apt-get install lvm2"
    fi
    
    log_success "Requirements check passed"
}

# Install system-wide
install_system() {
    log_info "Installing System Restore Toolkit system-wide..."
    
    local install_dir="/opt/system-restore-toolkit"
    
    # Create installation directory
    sudo mkdir -p "$install_dir"
    
    # Copy files
    sudo cp -r . "$install_dir/"
    
    # Set permissions
    sudo chown -R root:root "$install_dir"
    sudo chmod +x "$install_dir/system-restore-toolkit"
    sudo chmod +x "$install_dir/scripts"/*.sh
    sudo chmod +x "$install_dir/lib/common.sh"
    
    # Create symlinks
    sudo ln -sf "$install_dir/system-restore-toolkit" /usr/local/bin/system-restore-toolkit
    sudo ln -sf "$install_dir/system-restore-toolkit" /usr/local/bin/rt
    
    # Create configuration directory
    sudo mkdir -p /etc/system-restore-toolkit
    
    # Create default configuration
    if [[ ! -f /etc/system-restore-toolkit.conf ]]; then
        sudo tee /etc/system-restore-toolkit.conf > /dev/null << 'CONFIG'
# System Restore Toolkit Configuration

# Directories
BACKUP_DIR="/var/backups/system-restore-toolkit"
LOG_DIR="/var/log/system-restore-toolkit"

# Default settings
DEFAULT_SNAPSHOT_SIZE="5G"
RETENTION_DAYS="30"
CONFIG
    fi
    
    # Create directories
    sudo mkdir -p /var/backups/system-restore-toolkit
    sudo mkdir -p /var/log/system-restore-toolkit
    
    log_success "System installation completed"
    log_info "You can now use 'system-restore-toolkit' or 'rt' from anywhere"
}

# Docker installation
install_docker() {
    log_info "Setting up Docker environment..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker first"
        return 1
    fi
    
    # Build Docker image
    log_info "Building Docker image..."
    docker build -t system-restore-toolkit:latest .
    
    # Create necessary directories
    mkdir -p logs backups
    
    log_success "Docker setup completed"
    log_info "Use 'docker-compose up -d' to start the container"
    log_info "Or use 'system-restore-toolkit docker-run [command]'"
}

# Show usage
show_help() {
    cat << 'HELP'
System Restore Toolkit Installation
===================================

USAGE:
    ./install.sh [OPTION]

OPTIONS:
    --system        Install system-wide (requires sudo)
    --docker        Setup Docker environment
    --check         Check system requirements only
    --help          Show this help

EXAMPLES:
    ./install.sh --system       # Install for all users
    ./install.sh --docker       # Setup Docker container
    ./install.sh --check        # Check requirements

After installation:
    system-restore-toolkit help
    rt create-snapshot "My snapshot"
HELP
}

# Main installation logic
main() {
    case "${1:-}" in
        --system)
            check_requirements
            install_system
            ;;
        --docker)
            check_requirements
            install_docker
            ;;
        --check)
            check_requirements
            ;;
        --help|help|-h)
            show_help
            ;;
        "")
            log_info "System Restore Toolkit Installer"
            echo ""
            show_help
            echo ""
            read -p "Install system-wide? [y/N]: " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                check_requirements
                install_system
            fi
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
