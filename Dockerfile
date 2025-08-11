FROM ubuntu:24.04

LABEL maintainer="System Restore Toolkit"
LABEL description="System backup and restore toolkit for Ubuntu LVM systems"
LABEL version="2.0"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install required packages
RUN apt-get update && apt-get install -y \
    bash coreutils util-linux lvm2 tar gzip rsync \
    lsof htop iotop curl wget grep sed gawk findutils \
    lsb-release sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create toolkit user
RUN useradd -m -s /bin/bash toolkit && \
    usermod -aG sudo toolkit

# Create necessary directories
RUN mkdir -p /opt/system-restore-toolkit \
             /var/backups/system-restore-toolkit \
             /var/log/system-restore-toolkit

# Copy toolkit files
COPY . /opt/system-restore-toolkit/

# Set working directory
WORKDIR /opt/system-restore-toolkit

# Make scripts executable
RUN chmod +x system-restore-toolkit manage_restore_points.sh \
             restore-toolkit switch-display-mode.sh \
             scripts/*.sh lib/common.sh

# Create symlinks for global access
RUN ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/system-restore-toolkit && \
    ln -sf /opt/system-restore-toolkit/system-restore-toolkit /usr/local/bin/rt

# Create configuration
RUN echo 'BACKUP_DIR="/var/backups/system-restore-toolkit"' > /etc/system-restore-toolkit.conf && \
    echo 'LOG_DIR="/var/log/system-restore-toolkit"' >> /etc/system-restore-toolkit.conf

# Create entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD system-restore-toolkit disk-usage >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["help"]

VOLUME ["/var/backups/system-restore-toolkit", "/var/log/system-restore-toolkit"]
