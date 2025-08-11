#!/bin/bash

# Quick System State Documentation
# After running setup_tools.sh successfully

echo "📋 Current System State Documentation"
echo "====================================="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "User: $USER"
echo ""

echo "🐳 Docker Installation:"
docker --version
docker compose version
echo ""

echo "👥 User Groups:"
groups $USER
echo ""

echo "🗂️ Docker Aliases Available:"
source /etc/profile.d/docker_aliases.sh 2>/dev/null || true
alias | grep -E "(docker|^d=|^dc=|^dps=)"
echo ""

echo "📦 System Tools Installed by setup_tools.sh:"
echo "Essential tools:"
for tool in curl wget git htop tree jq tmux mc; do
    if command -v $tool >/dev/null 2>&1; then
        echo "  ✅ $tool - $(command -v $tool)"
    else
        echo "  ❌ $tool - not found"
    fi
done

echo ""
echo "Docker components:"
for tool in docker docker-compose ctop; do
    if command -v $tool >/dev/null 2>&1; then
        echo "  ✅ $tool - $(command -v $tool)"
    else
        echo "  ❌ $tool - not found"
    fi
done

echo ""
echo "📊 System Resources:"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk usage:"
df -h / | tail -1 | awk '{printf "  Root: %s used, %s available (%s)\n", $3, $4, $5}'

echo ""
echo "🗃️ Active Projects:"
ls -la projects/ 2>/dev/null | head -10

echo ""
echo "🚀 Docker Service Status:"
sudo systemctl is-active docker || echo "Docker service not active"
sudo systemctl is-enabled docker || echo "Docker service not enabled"

echo ""
echo "🔧 System State Summary:"
echo "  • setup_tools.sh has been executed successfully"
echo "  • Docker and Docker Compose are installed and working"
echo "  • Essential development tools are available"
echo "  • User is added to docker group"
echo "  • Docker aliases are configured"
echo "  • System is ready for containerized development"

echo ""
echo "💾 This system state captured at: $(date)"
echo "   To restore this state, refer to the backup and restore scripts in:"
echo "   - create_snapshot.sh (LVM snapshots - requires VG free space)"
echo "   - full_system_backup.sh (comprehensive backup)"
echo "   - Timeshift (installed and ready)"
