#!/bin/bash
set -euo pipefail

echo "System Restore Toolkit v2.0 - Docker Edition"
echo "============================================="

# Check if running with proper privileges
if [[ ! -d /host/proc ]] 2>/dev/null; then
    echo "WARNING: Host filesystem not mounted at /host"
    echo "For full functionality, run with: -v /:/host"
fi

# Check if running privileged
if [[ ! -c /dev/mapper/control ]] 2>/dev/null; then
    echo "WARNING: LVM device mapper not accessible"
    echo "For LVM snapshots, run with: --privileged"
fi

# If no command provided, show help
if [[ $# -eq 0 ]]; then
    exec system-restore-toolkit help
fi

# Execute the command
exec system-restore-toolkit "$@"
