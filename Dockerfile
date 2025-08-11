FROM ubuntu:24.04

LABEL maintainer="System Restore Toolkit"
LABEL description="System backup and restore toolkit for Ubuntu LVM systems"
LABEL version="2.0"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install required packages
RUN apt-get update && apt-get install -y \
    # Core tools
    bash \
    coreutils \
    util-linux \
    # LVM tools
    lvm2 \
    # Backup tools
    tar \
    gzip \
    rsync \
    # System monitoring
    lsof \
    htop \
    iotop \
    # Network tools
    curl \
    wget \
    # Text processing
    grep \
    sed \
    awk \
    # File operations
    findutils \
    # Timeshift (if available in repos)
    software-properties-common \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Try to install Timeshift from PPA (optional)
RUN add-apt-repository -y ppa:teejee2008/timeshift && \
    apt-get update && \
    apt-get install -y timeshift && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* || \
    echo "Timeshift not available, skipping..."

# Create toolkit user
RUN useradd -m -s /bin/bash toolkit && \
    usermod -aG sudo toolkit

# Create necessary directories
RUN mkdir -p /opt/system-restore-toolkit \
             /var/backups/system-restore-toolkit \
             /var/log/system-restore-toolkit \
             /etc/system-restore-toolkit

# Set permissions
RUN chown -R toolkit:toolkit /opt/system-restore-toolkit \
                              /var/backups/system-restore-toolkit \
                              /var/log/system-restore-toolkit

# Copy toolkit files
COPY . /opt/system-restore-toolkit/

# Set working directory
WORKDIR /opt/system-restore-toolkit

# Make scripts executable
RUN chmod +x system-restore-toolkit \
             manage_restore_points.sh \
             restore-toolkit \
             switch-display-mode.sh \
             scripts/*.sh \
             lib/common.sh

# Create symlinks for global access
RUN ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/system-restore-toolkit && \
    ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/rt && \
    ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/snapshot-list && \
    ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/backup-list && \
    ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/disk-check

# Create default configuration
RUN cat > /etc/system-restore-toolkit.conf << 'CONFIG'
# System Restore Toolkit Configuration
# Generated for Docker environment

# Directories
BACKUP_DIR="/var/backups/system-restore-toolkit"
LOG_DIR="/var/log/system-restore-toolkit"

# Default settings
DEFAULT_SNAPSHOT_SIZE="5G"
RETENTION_DAYS="30"

# Host mount point (when running in container)
HOST_ROOT="/host"
CONFIG

# Create entrypoint script
RUN cat > /usr/local/bin/toolkit-entrypoint << 'ENTRYPOINT'
#!/bin/bash
set -euo pipefail

echo "System Restore Toolkit v2.0 - Docker Edition"
echo "============================================="

# Check if running with proper privileges
if [[ ! -d /host/proc ]]; then
    echo "WARNING: Host filesystem not mounted at /host"
    echo "For full functionality, run with: -v /:/host"
fi

# Check if running privileged
if [[ ! -c /dev/mapper/control ]]; then
    echo "WARNING: LVM device mapper not accessible"
    echo "For LVM snapshots, run with: --privileged"
fi

# If no command provided, show help
if [[ $# -eq 0 ]]; then
    exec system-restore-toolkit help
fi

# Execute the command
exec system-restore-toolkit "$@"
ENTRYPOINT

RUN chmod +x /usr/local/bin/toolkit-entrypoint

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD system-restore-toolkit disk-usage > /dev/null || exit 1

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/toolkit-entrypoint"]

# Default command
CMD ["help"]

# Metadata
EXPOSE 8080/tcp
VOLUME ["/var/backups/system-restore-toolkit", "/var/log/system-restore-toolkit"]
