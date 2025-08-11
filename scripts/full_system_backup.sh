#!/bin/bash

# Complete System Backup Script
set -e

# Configuration
BACKUP_DIR="/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="system_backup_${TIMESTAMP}"
DESCRIPTION="$1"

echo "💾 Complete System Backup Script"
echo "================================="

# Check if description was provided
if [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 'backup description'"
    echo "Example: $0 'Before major system upgrade'"
    exit 1
fi

# Create backup directory
sudo mkdir -p "$BACKUP_DIR"
FULL_BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
sudo mkdir -p "$FULL_BACKUP_PATH"

echo "📂 Backup location: $FULL_BACKUP_PATH"
echo "📝 Description: $DESCRIPTION"
echo ""

# Check available space
echo "💽 Checking available space..."
BACKUP_PARTITION=$(df "$BACKUP_DIR" | tail -1 | awk '{print $1}')
AVAILABLE_SPACE=$(df -BG "$BACKUP_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
USED_SPACE=$(df -BG / | tail -1 | awk '{print $3}' | sed 's/G//')

echo "   Root filesystem used: ${USED_SPACE}G"
echo "   Backup destination available: ${AVAILABLE_SPACE}G"

if (( AVAILABLE_SPACE < USED_SPACE )); then
    echo "⚠️  Warning: May not have enough space for complete backup"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🚀 Starting backup process..."

# 1. System configuration backup
echo "📋 Backing up system configuration..."
sudo mkdir -p "$FULL_BACKUP_PATH/system_config"

# Package lists
sudo dpkg --get-selections > "$FULL_BACKUP_PATH/system_config/installed_packages.txt"
sudo apt-mark showmanual > "$FULL_BACKUP_PATH/system_config/manually_installed.txt"

# System information
uname -a > "$FULL_BACKUP_PATH/system_config/system_info.txt"
lsb_release -a >> "$FULL_BACKUP_PATH/system_config/system_info.txt" 2>/dev/null || true

# Network configuration
sudo cp -r /etc/netplan "$FULL_BACKUP_PATH/system_config/" 2>/dev/null || true
sudo cp /etc/hosts "$FULL_BACKUP_PATH/system_config/" 2>/dev/null || true
sudo cp /etc/resolv.conf "$FULL_BACKUP_PATH/system_config/" 2>/dev/null || true

# SSH configuration
sudo cp -r /etc/ssh "$FULL_BACKUP_PATH/system_config/" 2>/dev/null || true

# User account information
sudo cp /etc/passwd /etc/group /etc/shadow /etc/gshadow "$FULL_BACKUP_PATH/system_config/"

# Crontabs
sudo crontab -l > "$FULL_BACKUP_PATH/system_config/root_crontab.txt" 2>/dev/null || echo "No root crontab"
crontab -l > "$FULL_BACKUP_PATH/system_config/user_crontab.txt" 2>/dev/null || echo "No user crontab"

# 2. Docker backup (if exists)
if command -v docker &> /dev/null; then
    echo "🐳 Backing up Docker data..."
    sudo mkdir -p "$FULL_BACKUP_PATH/docker"
    
    # Docker images
    docker images --format "table {{.Repository}}:{{.Tag}}" | tail -n +2 > "$FULL_BACKUP_PATH/docker/images_list.txt"
    
    # Docker volumes
    sudo tar -czf "$FULL_BACKUP_PATH/docker/volumes.tar.gz" -C /var/lib/docker/volumes . 2>/dev/null || echo "No Docker volumes to backup"
    
    # Docker compose files from projects
    find "$HOME/projects" -name "docker-compose.yml" -exec cp {} "$FULL_BACKUP_PATH/docker/" \; 2>/dev/null || true
fi

# 3. Home directory backup
echo "🏠 Backing up home directory..."
sudo tar -czf "$FULL_BACKUP_PATH/home_directory.tar.gz" \
    --exclude="$HOME/.cache" \
    --exclude="$HOME/.local/share/Trash" \
    --exclude="$HOME/.*/.cache" \
    --exclude="$HOME/.npm" \
    --exclude="$HOME/.cargo/registry" \
    --exclude="$HOME/.rustup/toolchains/*/lib" \
    -C /home . 2>/dev/null

# 4. Create restore script
cat > "$FULL_BACKUP_PATH/RESTORE_INSTRUCTIONS.md" << 'EOF'
# System Restore Instructions

This backup contains:
- System configuration files
- Package lists
- Home directories
- Docker data (if applicable)

## Quick Restore Process:

### 1. Boot from Ubuntu Live Media
- Use the same Ubuntu version as when backup was created

### 2. Prepare the system:
```bash
sudo apt update
sudo apt install lvm2
sudo vgscan
sudo vgchange -ay
```

### 3. Mount the backup:
```bash
sudo mkdir -p /mnt/backup
# Mount your backup drive to /mnt/backup
```

### 4. Restore packages:
```bash
sudo apt update
sudo dpkg --set-selections < /mnt/backup/system_config/installed_packages.txt
sudo apt-get dselect-upgrade
```

### 5. Restore system configuration:
```bash
sudo cp -r /mnt/backup/system_config/netplan/* /etc/netplan/
sudo cp /mnt/backup/system_config/hosts /etc/
sudo cp -r /mnt/backup/system_config/ssh/* /etc/ssh/
```

### 6. Restore home directories:
```bash
sudo tar -xzf /mnt/backup/home_directory.tar.gz -C /home/
```

### 7. Restore Docker (if applicable):
```bash
sudo systemctl start docker
sudo tar -xzf /mnt/backup/docker/volumes.tar.gz -C /var/lib/docker/volumes/
# Recreate containers using your docker-compose files
```

### 8. Final steps:
```bash
sudo update-grub
sudo reboot
```
EOF

# Create backup metadata
cat > "$FULL_BACKUP_PATH/backup_metadata.json" << EOF
{
  "backup_name": "$BACKUP_NAME",
  "description": "$DESCRIPTION",
  "timestamp": "$TIMESTAMP",
  "date": "$(date)",
  "hostname": "$(hostname)",
  "ubuntu_version": "$(lsb_release -d | cut -f2)",
  "kernel": "$(uname -r)",
  "backup_size": "$(du -sh "$FULL_BACKUP_PATH" | cut -f1)",
  "backup_path": "$FULL_BACKUP_PATH"
}
EOF

# Set permissions
sudo chown -R root:root "$FULL_BACKUP_PATH"
sudo chmod -R 755 "$FULL_BACKUP_PATH"

# Final summary
BACKUP_SIZE=$(sudo du -sh "$FULL_BACKUP_PATH" | cut -f1)

echo ""
echo "✅ Backup completed successfully!"
echo "   Location: $FULL_BACKUP_PATH"
echo "   Size: $BACKUP_SIZE"
echo "   Description: $DESCRIPTION"
echo ""
echo "📄 Restore instructions: $FULL_BACKUP_PATH/RESTORE_INSTRUCTIONS.md"

# Log the backup
LOGFILE="/var/log/system-backups.log"
echo "$(date): Created backup $BACKUP_NAME - $DESCRIPTION - Size: $BACKUP_SIZE" | sudo tee -a $LOGFILE

echo ""
echo "🔍 To list all backups:"
echo "   ls -la $BACKUP_DIR/"
echo ""
echo "🗑️  To remove this backup later:"
echo "   sudo rm -rf $FULL_BACKUP_PATH"
