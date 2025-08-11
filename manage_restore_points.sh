#!/bin/bash

# System Restore Point Manager (Clean Version - No Emojis)
set -e

VG_NAME="ubuntu-vg"
BACKUP_DIR="/backup"

show_help() {
    echo "System Restore Point Manager"
    echo "=============================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list-snapshots     List all LVM snapshots"
    echo "  list-backups       List all full system backups"
    echo "  create-snapshot    Create LVM snapshot (fast)"
    echo "  create-backup      Create full system backup (comprehensive)"
    echo "  remove-snapshot    Remove an LVM snapshot"
    echo "  remove-backup      Remove a full system backup"
    echo "  disk-usage         Show disk usage information"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create-snapshot 'Before installing Docker'"
    echo "  $0 create-backup 'Before major system upgrade'"
    echo "  $0 list-snapshots"
    echo ""
}

list_snapshots() {
    echo "LVM Snapshots:"
    echo "=============="
    if sudo lvs | grep -q snapshot; then
        echo ""
        sudo lvs | grep snapshot | while read line; do
            snapshot_name=$(echo $line | awk '{print $1}')
            snapshot_size=$(echo $line | awk '{print $4}')
            snapshot_used=$(echo $line | awk '{print $6}')
            echo "   * $snapshot_name"
            echo "     Size: $snapshot_size, Used: $snapshot_used"
        done
        
        echo ""
        echo "Snapshot Log:"
        if [ -f "/var/log/system-snapshots.log" ]; then
            sudo tail -10 /var/log/system-snapshots.log | sed 's/^/      /'
        else
            echo "      No snapshot log found"
        fi
    else
        echo "   No snapshots found"
    fi
    echo ""
}

list_backups() {
    echo "Full System Backups:"
    echo "===================="
    if [ -d "$BACKUP_DIR" ] && [ "$(sudo ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo ""
        sudo find "$BACKUP_DIR" -maxdepth 1 -name "system_backup_*" -type d | sort | while read backup_path; do
            backup_name=$(basename "$backup_path")
            backup_size=$(sudo du -sh "$backup_path" 2>/dev/null | cut -f1)
            
            echo "   * $backup_name"
            echo "     Size: $backup_size"
            
            if [ -f "$backup_path/backup_metadata.json" ]; then
                description=$(sudo cat "$backup_path/backup_metadata.json" | grep '"description"' | cut -d'"' -f4)
                date=$(sudo cat "$backup_path/backup_metadata.json" | grep '"date"' | cut -d'"' -f4)
                echo "     Description: $description"
                echo "     Created: $date"
            fi
            echo ""
        done
        
        echo "Backup Log:"
        if [ -f "/var/log/system-backups.log" ]; then
            sudo tail -5 /var/log/system-backups.log | sed 's/^/      /'
        else
            echo "      No backup log found"
        fi
    else
        echo "   No backups found"
    fi
    echo ""
}

show_disk_usage() {
    echo "Disk Usage Information:"
    echo "======================"
    echo ""
    echo "Root filesystem:"
    df -h / | tail -1 | awk '{printf "   Used: %s, Available: %s, Usage: %s\n", $3, $4, $5}'
    
    echo ""
    echo "LVM Volume Group:"
    sudo vgs "$VG_NAME" | tail -1 | awk '{printf "   Total: %s, Free: %s\n", $6, $7}'
    
    if [ -d "$BACKUP_DIR" ]; then
        echo ""
        echo "Backup directory:"
        df -h "$BACKUP_DIR" | tail -1 | awk '{printf "   Used: %s, Available: %s, Usage: %s\n", $3, $4, $5}'
        
        if [ "$(sudo ls -A $BACKUP_DIR 2>/dev/null)" ]; then
            echo ""
            echo "Backup sizes:"
            sudo du -sh "$BACKUP_DIR"/* 2>/dev/null | sed 's/^/   /' || true
        fi
    fi
    
    echo ""
    echo "Snapshot usage:"
    if sudo lvs | grep -q snapshot; then
        sudo lvs | grep snapshot | awk '{printf "   %s: %s used of %s\n", $1, $6, $4}'
    else
        echo "   No snapshots found"
    fi
    echo ""
}

remove_snapshot() {
    echo "Remove LVM Snapshot"
    echo "=================="
    
    if ! sudo lvs | grep -q snapshot; then
        echo "   No snapshots found to remove"
        return
    fi
    
    echo ""
    echo "Available snapshots:"
    sudo lvs | grep snapshot | awk '{print "   " $1}'
    echo ""
    
    read -p "Enter snapshot name to remove: " SNAPSHOT_NAME
    
    if [ -z "$SNAPSHOT_NAME" ]; then
        echo "ERROR: No snapshot name provided"
        return
    fi
    
    if ! sudo lvs | grep -q "$SNAPSHOT_NAME"; then
        echo "ERROR: Snapshot '$SNAPSHOT_NAME' not found"
        return
    fi
    
    echo ""
    echo "WARNING: This will permanently delete snapshot '$SNAPSHOT_NAME'"
    read -p "Are you sure? (y/N): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        sudo lvremove -f "/dev/$VG_NAME/$SNAPSHOT_NAME"
        echo "SUCCESS: Snapshot '$SNAPSHOT_NAME' removed successfully"
        
        # Log the removal
        LOGFILE="/var/log/system-snapshots.log"
        echo "$(date): Removed snapshot $SNAPSHOT_NAME" | sudo tee -a $LOGFILE >/dev/null
    else
        echo "Operation cancelled"
    fi
}

remove_backup() {
    echo "Remove Full System Backup"
    echo "========================"
    
    if [ ! -d "$BACKUP_DIR" ] || [ ! "$(sudo ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo "   No backups found to remove"
        return
    fi
    
    echo ""
    echo "Available backups:"
    sudo find "$BACKUP_DIR" -maxdepth 1 -name "system_backup_*" -type d | sort | while read backup_path; do
        backup_name=$(basename "$backup_path")
        backup_size=$(sudo du -sh "$backup_path" 2>/dev/null | cut -f1)
        echo "   $backup_name ($backup_size)"
    done
    echo ""
    
    read -p "Enter backup name to remove: " BACKUP_NAME
    
    if [ -z "$BACKUP_NAME" ]; then
        echo "ERROR: No backup name provided"
        return
    fi
    
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    if [ ! -d "$BACKUP_PATH" ]; then
        echo "ERROR: Backup '$BACKUP_NAME' not found"
        return
    fi
    
    BACKUP_SIZE=$(sudo du -sh "$BACKUP_PATH" | cut -f1)
    echo ""
    echo "WARNING: This will permanently delete backup '$BACKUP_NAME' ($BACKUP_SIZE)"
    read -p "Are you sure? (y/N): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        sudo rm -rf "$BACKUP_PATH"
        echo "SUCCESS: Backup '$BACKUP_NAME' removed successfully"
        
        # Log the removal
        LOGFILE="/var/log/system-backups.log"
        echo "$(date): Removed backup $BACKUP_NAME" | sudo tee -a $LOGFILE >/dev/null
    else
        echo "Operation cancelled"
    fi
}

# Main script logic
case "${1:-help}" in
    "list-snapshots")
        list_snapshots
        ;;
    "list-backups")
        list_backups
        ;;
    "create-snapshot")
        shift
        ./scripts/create_snapshot.sh "$@"
        ;;
    "create-backup")
        shift
        ./scripts/full_system_backup.sh "$@"
        ;;
    "remove-snapshot")
        remove_snapshot
        ;;
    "remove-backup")
        remove_backup
        ;;
    "disk-usage")
        show_disk_usage
        ;;
    "help"|*)
        show_help
        ;;
esac
