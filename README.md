# 🐳 System Restore Toolkit v2.0

A modernized, containerized system backup and restore toolkit for Ubuntu Linux systems with LVM support and professional web interface.

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

[![GitHub release](https://img.shields.io/github/release/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/releases)
[![GitHub stars](https://img.shields.io/github/stars/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/issues)
[![GitHub license](https://img.shields.io/github/license/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/blob/main/LICENSE)
[![Bash](https://img.shields.io/badge/bash-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

## ✨ What's New in v2.0

### 🌐 **Professional Web Interface** (Enhanced!)
- **📊 Real-time System Monitoring**: CPU, memory, disk usage, GPU stats with live progress bars
- **🎨 Dark/Light Mode Toggle**: Professional theme switching with persistent user preferences  
- **💾 Complete Backup Management**: Full lifecycle management for system backups
- **🕐 Advanced Timeshift Integration**: Interactive snapshot management with safety controls
- **📋 Comprehensive Log Viewer**: Dynamic log loading with search and download capabilities
- **📱 Responsive Design**: Mobile-friendly interface with Bootstrap 5
- **🛡️ Safety-First Approach**: Manual command execution for critical operations
- **🚀 RESTful API**: Complete API endpoints for automation and integration

### 🔧 **System Enhancements**
- 🐳 **Full Docker support** with containerized deployment
- 🔧 **Refactored codebase** with improved error handling and logging
- 📚 **Unified command interface** with the new `system-restore-toolkit` command
- 🛡️ **Enhanced safety** with better validation and rollback capabilities
- 📊 **Better monitoring** with detailed logging and system state reporting

## 🚀 Quick Start

### Web Interface Access
```bash
# Start the web interface
cd web-interface
python app.py

# Access at: http://localhost:5000
# Features: Dashboard, Backups, Timeshift, Logs
```

### Option 1: Docker (Recommended)
```bash
# Clone the repository
git clone https://github.com/ppmatrix/system-restore-toolkit.git
cd system-restore-toolkit

# Build and run with Docker Compose
docker-compose up -d

# Use the toolkit
docker exec -it restore-toolkit system-restore-toolkit help
```

### Option 2: System Installation
```bash
# Install system-wide
./install.sh --system

# Use from anywhere
system-restore-toolkit help

# Start web interface
setup-web-interface.sh
```

## 🎯 Features

### 🌐 Web Interface
- **📊 System Dashboard**: Real-time monitoring with CPU, memory, disk, and GPU statistics
- **💾 Backup Management**: Create, list, restore, and delete full system backups
- **🕐 Timeshift Integration**: Complete snapshot lifecycle management
- **📋 Log Viewer**: Dynamic log loading with real-time content viewing
- **🎨 Theme Support**: Professional dark/light mode toggle with persistence
- **📱 Responsive UI**: Bootstrap 5-based interface for all devices
- **🔒 Security Focus**: Manual command execution for critical operations
- **🚀 API Endpoints**: RESTful API for automation and third-party integration

### 📸 LVM Snapshots
- **Fast creation** and restoration
- **Space-efficient** copy-on-write technology
- **Instant rollback** capabilities

### 💾 Full System Backups
- **Complete system** backup and restore
- **Incremental backups** with compression
- **Disaster recovery** ready

### 🕐 Timeshift Integration
- **Automated scheduling** with Timeshift
- **User-friendly interface** for system restoration
- **BTRFS and ext4** filesystem support

### 🐳 Docker Support
- **Containerized toolkit** for consistent environments
- **Host system access** for backup operations
- **Portable deployment** across systems

## 📖 Usage

### Basic Commands
```bash
# Show help
system-restore-toolkit help

# Create snapshot with description
system-restore-toolkit create-snapshot "Before system update"

# List all snapshots
system-restore-toolkit list-snapshots

# Create full system backup
system-restore-toolkit create-backup "Weekly backup"

# Check disk usage
system-restore-toolkit disk-usage

# Generate system state report
system-restore-toolkit system-state
```

### Short Aliases
```bash
# Use short alias
rt help
rt create-snapshot "Quick backup"

# Direct commands
snapshot-list
backup-list
disk-check
```

### Docker Commands
```bash
# Build Docker image
system-restore-toolkit docker-build

# Run in container
system-restore-toolkit docker-run create-snapshot "Container backup"

# Using docker-compose
docker-compose exec system-restore-toolkit rt help
```

## 🛠️ Installation

### Prerequisites
- **Ubuntu 20.04+** (tested on Ubuntu 24.04)
- **LVM setup** for snapshot functionality
- **Sudo privileges** for system operations
- **Docker** (optional, for containerized deployment)

### Installation Methods

#### 1. Automated Installation
```bash
# Check system requirements
./install.sh --check

# Install system-wide
./install.sh --system

# Setup Docker environment
./install.sh --docker
```

#### 2. Manual Installation
```bash
# Copy to system directory
sudo cp -r . /opt/system-restore-toolkit/

# Create symlinks
sudo ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/rt

# Set permissions
sudo chmod +x /opt/system-restore-toolkit/system-restore-toolkit
```

#### 3. Docker Installation
```bash
# Clone the repository
git clone https://github.com/ppmatrix/system-restore-toolkit.git
cd system-restore-toolkit

# Build and start with Docker Compose
docker-compose up -d

# Use the toolkit
docker exec -it restore-toolkit system-restore-toolkit help

# Alternative: Build image manually
docker build -t system-restore-toolkit .

# Run with host access
docker run --rm -it --privileged \
    -v /:/host \
    system-restore-toolkit help
```
```

## 📁 Project Structure
📂backups
 ┣ 📜README.md
 ┗ 📜full-backup-20250811_201654.tar.gz
📂configs
 ┗ 📜timeshift.json
📂host-scripts
 ┣ 📜timeshift-list.sh
 ┣ 📜timeshift-proxy.sh
 ┣ 📜timeshift-simple.py
 ┣ 📜timeshift-to-json.py
 ┗ 📜update-timeshift-data.py
📂lib
 ┗ 📜common.sh
📂logs
 ┣ 📜README.md
 ┣ 📜toolkit-20250811.log
📂scripts
 ┣ 📜current_system_state.sh
 ┗ 📜setup_timeshift.sh
📂shared-data
 ┗ 📜timeshift-info.json
📂web-interface
 ┣ 📂backups
 ┣ 📂logs
 ┣ 📂static
 ┃  ┣ 📂css
 ┃  ┃  ┗ 📜style.css
 ┃  ┣ 📂images
 ┃  ┃  ┗ 📜STRlogo.png
 ┃  ┗ 📂js
 ┃     ┗ 📜app.js
 ┗ 📂templates
    ┣ 📜backups.html
    ┣ 📜base.html
    ┣ 📜dashboard.html
    ┣ 📜dashboard.html.backup
    ┣ 📜logs.html
    ┗ 📜timeshift.html
