FROM python:3.11-slim

# Install system dependencies including hardware monitoring tools
RUN apt-get update && apt-get install -y \
    bash \
    sudo \
    procps \
    coreutils \
    curl \
    util-linux \
    pciutils \
    lm-sensors \
    lsb-release \
    udev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy web application
COPY . .

# Create non-root user with sudo access
RUN useradd -m -s /bin/bash webapp && \
    usermod -aG sudo webapp && \
    echo 'webapp ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    chown -R webapp:webapp /app

USER webapp

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Start the application
CMD ["python", "app.py"]
