# 📁 Backups Directory

This directory can be used to store local configuration backups and metadata.

## Current System Backup Location

Your main system backups are stored in: `/home/paulo/system_backups/`

Current backup:
- `post_setup_tools_20250807_141617/` - System state after setup_tools.sh execution

## System-wide Backup Locations

- **Timeshift snapshots**: `/timeshift/snapshots/` (or configured location)
- **Full system backups**: `/backup/` (created by full_system_backup.sh)
- **Local config backups**: `/home/paulo/system_backups/`

## Usage

This local `backups/` directory can be used for:
- Quick configuration exports
- Project-specific system state documentation
- Test restore scripts
- Backup metadata and logs

## Quick Backup Creation

From the toolkit root directory:
```bash
# Document current state
./scripts/current_system_state.sh > backups/state_$(date +%Y%m%d_%H%M%S).txt

# Create package list backup  
dpkg --get-selections > backups/packages_$(date +%Y%m%d_%H%M%S).txt
```
