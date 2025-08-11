#!/bin/bash

# Timeshift Installation and Setup Script
set -e

echo "⏰ Installing and Configuring Timeshift"
echo "======================================="

# Install Timeshift
echo "📦 Installing Timeshift..."
sudo apt update
sudo apt install -y timeshift

# Create Timeshift configuration
echo "⚙️  Configuring Timeshift..."

# Check if we can use BTRFS or should use rsync
FILESYSTEM=$(findmnt -n -o FSTYPE /)

if [ "$FILESYSTEM" = "btrfs" ]; then
    echo "📁 BTRFS filesystem detected - using BTRFS snapshots"
    BACKEND="btrfs"
else
    echo "📁 Non-BTRFS filesystem ($FILESYSTEM) - using rsync backend"
    BACKEND="rsync"
fi

# Create timeshift configuration directory
sudo mkdir -p /etc/timeshift

# Create basic configuration
cat > /tmp/timeshift_config.json << EOF
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : $([ "$BACKEND" = "btrfs" ] && echo "true" || echo "false"),
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "false",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude_list_default" : [
    "/dev/*",
    "/proc/*",
    "/run/*",
    "/tmp/*",
    "/sys/*",
    "/var/run/*",
    "/var/lock/*",
    "/lost+found",
    "/media/*",
    "/mnt/*",
    "/home/*/.cache",
    "/home/*/.local/share/Trash",
    "/home/*/.gvfs",
    "/home/*/.thumbnails",
    "/home/*/Downloads",
    "/root/.cache",
    "/root/.local/share/Trash",
    "/root/.thumbnails"
  ],
  "exclude_list_user" : [],
  "exclude_list_home" : [
    "/home/*/.cache",
    "/home/*/.local/share/Trash", 
    "/home/*/.gvfs",
    "/home/*/.thumbnails",
    "/home/*/Downloads/*"
  ]
}
EOF

sudo mv /tmp/timeshift_config.json /etc/timeshift/timeshift.json
sudo chmod 644 /etc/timeshift/timeshift.json

echo "✅ Timeshift configured successfully!"
echo ""
echo "🚀 Usage Examples:"
echo ""
echo "Create manual snapshots:"
echo "  sudo timeshift --create --comments 'Before system upgrade'"
echo "  sudo timeshift --create --comments 'Before installing Docker'"
echo ""
echo "List snapshots:"
echo "  sudo timeshift --list"
echo ""
echo "Restore from snapshot:"
echo "  sudo timeshift --restore --snapshot '2025-01-15_18-30-45'"
echo ""
echo "Delete old snapshots:"
echo "  sudo timeshift --delete --snapshot '2025-01-15_18-30-45'"
echo ""
echo "Enable automatic daily snapshots:"
echo "  sudo timeshift --snapshot-device /dev/$(lsblk -no name,mountpoint | grep '/$' | awk '{print $1}')"
echo "  sudo timeshift --schedule-daily --count 7"
echo ""
echo "📚 For GUI management, run: sudo timeshift-gtk"
echo ""

# Show current status
echo "📊 Current Timeshift Status:"
sudo timeshift --list || echo "No snapshots created yet"

echo ""
echo "💡 Pro Tips:"
echo "  • Create snapshots before major system changes"
echo "  • Keep 3-5 recent snapshots to save space"
echo "  • Test restoration process on a non-critical system first"
echo "  • Use descriptive comments for easy identification"
