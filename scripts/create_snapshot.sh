#!/bin/bash

# LVM Snapshot Creation Script
set -e

# Configuration
SNAPSHOT_SIZE="50G"  # Adjust based on expected changes
VG_NAME="ubuntu-vg"
LV_NAME="ubuntu-lv"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_NAME="snapshot_${TIMESTAMP}"
DESCRIPTION="$1"

echo "🔍 Creating LVM snapshot for system restore point..."

# Check if description was provided
if [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 'description of restore point'"
    echo "Example: $0 'Before installing new software'"
    exit 1
fi

# Check available space in volume group
echo "📊 Checking available space..."
VG_FREE=$(sudo vgs --noheadings --units g --nosuffix $VG_NAME | awk '{print $7}')
REQUIRED_SIZE=$(echo $SNAPSHOT_SIZE | sed 's/G//')

if (( $(echo "$VG_FREE < $REQUIRED_SIZE" | bc -l) )); then
    echo "⚠️  Warning: Not enough free space in volume group"
    echo "   Available: ${VG_FREE}G, Required: ${REQUIRED_SIZE}G"
    echo "   Consider reducing SNAPSHOT_SIZE or freeing up space"
    exit 1
fi

# Create the snapshot
echo "📸 Creating snapshot: $SNAPSHOT_NAME"
sudo lvcreate -L $SNAPSHOT_SIZE -s -n $SNAPSHOT_NAME /dev/$VG_NAME/$LV_NAME

# Log the snapshot creation
LOGFILE="/var/log/system-snapshots.log"
echo "$(date): Created snapshot $SNAPSHOT_NAME - $DESCRIPTION" | sudo tee -a $LOGFILE

echo "✅ Snapshot created successfully!"
echo "   Name: $SNAPSHOT_NAME"
echo "   Size: $SNAPSHOT_SIZE"
echo "   Description: $DESCRIPTION"
echo ""
echo "📋 Current snapshots:"
sudo lvs | grep snapshot || echo "   (This is your first snapshot)"

echo ""
echo "🔄 To restore from this snapshot later:"
echo "   sudo ./restore_from_snapshot.sh $SNAPSHOT_NAME"
echo ""
echo "🗑️  To remove this snapshot later:"
echo "   sudo lvremove /dev/$VG_NAME/$SNAPSHOT_NAME"
