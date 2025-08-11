# 🐳 System Restore Toolkit v2.0

A modernized, containerized system backup and restore toolkit for Ubuntu Linux systems with LVM support.

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

[![GitHub release](https://img.shields.io/github/release/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/releases)
[![GitHub stars](https://img.shields.io/github/stars/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/issues)
[![GitHub license](https://img.shields.io/github/license/ppmatrix/system-restore-toolkit.svg?style=for-the-badge)](https://github.com/ppmatrix/system-restore-toolkit/blob/main/LICENSE)
[![Bash](https://img.shields.io/badge/bash-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

## ✨ What's New in v2.0

- 🐳 **Full Docker support** with containerized deployment
- 🔧 **Refactored codebase** with improved error handling and logging
- 📚 **Unified command interface** with the new `system-restore-toolkit` command
- 🛡️ **Enhanced safety** with better validation and rollback capabilities
- 📊 **Better monitoring** with detailed logging and system state reporting

## 🚀 Quick Start

### Option 1: Docker (Recommended)
```bash
# Clone the repository
git clone <your-repo-url>
cd system-restore-toolkit

# Build and run with Docker
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
rt create-snapshot "My backup"
```

## 🎯 Features

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
# Build image
docker build -t system-restore-toolkit .

# Run with host access
docker run --rm -it --privileged \
    -v /:/host \
    system-restore-toolkit help
```

## 📁 Project Structure

```
system-restore-toolkit/
├── 🐳 Docker Files
│   ├── Dockerfile              # Container definition
│   ├── docker-compose.yml      # Service orchestration
│   └── .dockerignore          # Docker ignore rules
│
├── 🔧 Core Scripts
│   ├── system-restore-toolkit  # Main entry point (NEW)
│   ├── lib/common.sh          # Shared functions (NEW)
│   └── manage_restore_points.sh # Legacy script
│
├── 📜 Individual Scripts
│   ├── scripts/
│   │   ├── create_snapshot.sh
│   │   ├── restore_from_snapshot.sh
│   │   ├── full_system_backup.sh
│   │   ├── current_system_state.sh
│   │   └── setup_timeshift.sh
│
├── ⚙️ Configuration
│   └── configs/
│       └── timeshift.json
│
├── 📊 Data Directories
│   ├── backups/               # Backup storage
│   └── logs/                  # Log files (NEW)
│
├── 🚀 Installation & Docs
│   ├── install.sh            # Installation script (NEW)
│   ├── README.md             # This file
│   ├── RESTORE_POINT_GUIDE.md
│   └── GLOBAL_ACCESS.md
│
└── 🛠️ Git & CI
    ├── .gitignore
    └── .dockerignore
```

## 🔧 Configuration

### System Configuration (`/etc/system-restore-toolkit.conf`)
```bash
# Directories
BACKUP_DIR="/var/backups/system-restore-toolkit"
LOG_DIR="/var/log/system-restore-toolkit"

# Default settings
DEFAULT_SNAPSHOT_SIZE="5G"
RETENTION_DAYS="30"
```

### Docker Environment Variables
```yaml
environment:
  - TZ=UTC
  - BACKUP_RETENTION_DAYS=30
  - LOG_LEVEL=INFO
```

## 📊 Monitoring & Logging

### Log Files
- **Main log**: `/var/log/system-restore-toolkit/toolkit-YYYYMMDD.log`
- **Snapshots**: `/var/log/system-restore-toolkit/snapshots.log`
- **Backups**: `/var/log/system-restore-toolkit/backups.log`

### Health Checks
```bash
# System status
system-restore-toolkit disk-usage

# Docker health check
docker-compose ps
```

## 🆘 Emergency Recovery

### From LVM Snapshot
```bash
# Boot from live media
# Identify snapshot
sudo lvs

# Mount and restore
sudo mkdir /mnt/snapshot
sudo mount /dev/vg/snapshot-name /mnt/snapshot
# Follow restoration guide...
```

### From Full Backup
```bash
# Boot from live media
# Extract backup
sudo tar -xzf backup-file.tar.gz -C /mnt/restore/
# Follow restoration guide...
```

## 🔄 Migration from v1.0

```bash
# Backup existing configuration
cp -r /old/system-restore-toolkit ~/backup-old-toolkit

# Install v2.0
./install.sh --system

# Migrate backups
sudo mv ~/backup-old-toolkit/backups/* /var/backups/system-restore-toolkit/
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both native and Docker installations
5. Submit a pull request

## 📝 License

Open source - adapt and modify as needed for your environment.

## 🎯 Compatibility

- ✅ **Ubuntu 24.04** Noble (primary)
- ✅ **Ubuntu 22.04** Jammy
- ✅ **Ubuntu 20.04** Focal
- ✅ **Docker** environments
- ✅ **LVM** storage systems
- ✅ **Cloud instances** (AWS, GCP, Azure)
- ✅ **Physical servers**

## 📞 Support

- 📖 Read the [Restore Point Guide](RESTORE_POINT_GUIDE.md)
- 🔍 Check the logs: `system-restore-toolkit disk-usage`
- 🐳 Docker issues: `docker logs restore-toolkit`

---

**Version**: 2.0  
**Created**: August 2025  
**Environment**: Ubuntu 24.04, Docker-ready  
**Status**: Production Ready ✅

Built with ❤️ for reliable system administration
