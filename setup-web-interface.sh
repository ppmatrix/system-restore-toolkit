#!/bin/bash

# System Restore Toolkit - Web Interface Setup
# This script sets up the web interface for the system restore toolkit

set -euo pipefail

# Colors
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

# Check if we're in the right directory
if [[ ! -f "system-restore-toolkit" ]]; then
    log_error "Please run this script from the system-restore-toolkit directory"
    exit 1
fi

echo "🌐 System Restore Toolkit - Web Interface Setup"
echo "==============================================="
echo ""

# Check requirements
log_info "Checking system requirements..."

# Check Python
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is required but not installed"
    exit 1
fi

# Check pip
if ! command -v pip3 &> /dev/null; then
    log_error "pip3 is required but not installed"
    exit 1
fi

log_success "Python 3 and pip3 are available"

# Setup method selection
echo ""
echo "Choose setup method:"
echo "1) Native installation (install on host system)"
echo "2) Docker installation (containerized)"
echo "3) Development setup (local development server)"
echo ""

read -p "Select option [1-3]: " -r setup_option

case $setup_option in
    1)
        # Native installation
        log_info "Setting up native web interface installation..."
        
        # Install Python dependencies
        log_info "Installing Python dependencies..."
        cd web-interface
        pip3 install -r requirements.txt --user
        
        # Make app executable
        chmod +x app.py
        
        # Create systemd service
        log_info "Creating systemd service..."
        sudo tee /etc/systemd/system/restore-toolkit-web.service > /dev/null << SYSTEMD_SERVICE
[Unit]
Description=System Restore Toolkit Web Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONPATH=$(pwd)
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_SERVICE
        
        # Enable and start service
        sudo systemctl daemon-reload
        sudo systemctl enable restore-toolkit-web
        sudo systemctl start restore-toolkit-web
        
        log_success "Web interface installed as system service"
        log_info "Service status: $(sudo systemctl is-active restore-toolkit-web)"
        log_info "Access at: http://localhost:5000"
        log_info "Manage with: sudo systemctl {start|stop|restart} restore-toolkit-web"
        ;;
        
    2)
        # Docker installation
        log_info "Setting up Docker web interface..."
        
        # Check Docker
        if ! command -v docker &> /dev/null; then
            log_error "Docker is required but not installed"
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            log_error "docker-compose is required but not installed"
            exit 1
        fi
        
        # Build and start containers
        log_info "Building Docker containers..."
        docker-compose build
        
        log_info "Starting services..."
        docker-compose up -d
        
        log_success "Web interface deployed with Docker"
        log_info "Access at: http://localhost:5000"
        log_info "Manage with: docker-compose {up|down|logs|ps}"
        ;;
        
    3)
        # Development setup
        log_info "Setting up development environment..."
        
        cd web-interface
        
        # Install dependencies in virtual environment
        if command -v python3 -m venv &> /dev/null; then
            log_info "Creating virtual environment..."
            python3 -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
            
            log_success "Development environment created"
            log_info "To start development server:"
            echo "  cd web-interface"
            echo "  source venv/bin/activate"
            echo "  python app.py"
            echo ""
            log_info "Access at: http://localhost:5000"
        else
            log_warning "Virtual environment not available, installing globally"
            pip3 install -r requirements.txt --user
            
            log_success "Dependencies installed"
            log_info "To start development server:"
            echo "  cd web-interface"
            echo "  python3 app.py"
        fi
        ;;
        
    *)
        log_error "Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "🎉 Web Interface Setup Complete!"
echo "================================="
echo ""
echo "Features available in the web interface:"
echo "• 📊 System dashboard with real-time status"
echo "• 📸 LVM snapshot creation and management"
echo "• 💾 Full system backup operations"
echo "• 🕐 Timeshift integration"
echo "• 📋 Log file viewing and monitoring"
echo "• 🔄 Real-time task progress tracking"
echo ""
echo "Security Notes:"
echo "• Web interface requires sudo privileges for system operations"
echo "• Default configuration listens on all interfaces (0.0.0.0:5000)"
echo "• Consider using a reverse proxy (nginx/apache) for production"
echo "• Enable HTTPS for secure remote access"
echo ""
echo "For production deployment, consider:"
echo "• Setting up SSL certificates"
echo "• Configuring authentication/authorization"
echo "• Using a WSGI server like Gunicorn"
echo "• Setting up monitoring and logging"
