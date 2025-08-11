#!/bin/bash

# LVM Snapshot Restoration Script
set -e

VG_NAME="ubuntu-vg"
LV_NAME="ubuntu-lv"
SNAPSHOT_NAME="$1"

echo "⚠️  DANGER: System Restore Operation ⚠️"
echo ""

# Check if snapshot name was provided
if [ -z "$SNAPSHOT_NAME" ]; then
    echo "Usage: $0 snapshot_name"
    echo ""
    echo "Available snapshots:"
    sudo lvs | grep snapshot || echo "   No snapshots found"
    exit 1
fi

# Verify snapshot exists
if ! sudo lvs | grep -q "$SNAPSHOT_NAME"; then
    echo "❌ Error: Snapshot '$SNAPSHOT_NAME' not found"
    echo ""
    echo "Available snapshots:"
    sudo lvs | grep snapshot || echo "   No snapshots found"
    exit 1
fi

# Show snapshot details
echo "📋 Snapshot Details:"
sudo lvs /dev/$VG_NAME/$SNAPSHOT_NAME

echo ""
echo "🔥 WARNING: This will:"
echo "   - Restore your ENTIRE SYSTEM to the snapshot state"
echo "   - LOSE ALL CHANGES made after the snapshot was created"
echo "   - Require a system reboot"
echo ""
echo "📅 Snapshot creation time:"
sudo lvs --noheadings -o lv_time /dev/$VG_NAME/$SNAPSHOT_NAME

echo ""
read -p "Are you ABSOLUTELY SURE you want to proceed? (type 'YES' to continue): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "❌ Operation cancelled"
    exit 1
fi

echo ""
echo "🔄 Starting restoration process..."

# Unmount filesystems (this will require a rescue environment in practice)
echo "⚠️  NOTE: Full system restoration requires booting from live media"
echo "   This script prepares the restoration, but you need to:"
echo "   1. Boot from Ubuntu Live USB/CD"
echo "   2. Run this command in the live environment:"
echo ""
echo "   sudo lvconvert --merge /dev/$VG_NAME/$SNAPSHOT_NAME"
echo ""
echo "   3. Reboot into restored system"

# Log the restoration intent
LOGFILE="/var/log/system-snapshots.log"
echo "$(date): Restoration initiated for snapshot $SNAPSHOT_NAME" | sudo tee -a $LOGFILE

echo ""
echo "🚀 Ready for restoration! Boot from live media and run the merge command above."
