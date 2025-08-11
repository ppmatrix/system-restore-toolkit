# 🛡️ System Restore Toolkit

A comprehensive collection of system backup and restore point tools for Ubuntu Linux systems with LVM.

## 🎯 Purpose

This toolkit provides multiple strategies for creating and managing system restore points:
- **LVM Snapshots** (fast, space-efficient)
- **Timeshift** (user-friendly, reliable)
- **Full System Backups** (comprehensive disaster recovery)
- **Configuration Backups** (quick setup restoration)

## 📁 Project Structure

```
system-restore-toolkit/
├── README.md                      # This file
├── RESTORE_POINT_GUIDE.md         # Complete strategy guide
├── manage_restore_points.sh       # 🔧 Main management script
├── scripts/
│   ├── create_snapshot.sh         # Create LVM snapshots
│   ├── restore_from_snapshot.sh   # Restore from LVM snapshots
│   ├── full_system_backup.sh      # Complete system backup
│   ├── current_system_state.sh    # Document system state
│   └── setup_timeshift.sh         # Install/configure Timeshift
├── configs/
│   └── timeshift.json            # Timeshift configuration template
└── backups/
    └── README.md                 # Backup storage info
```

## 🚀 Quick Start

### 1. Global Access (Works from anywhere!)
```bash
# Super quick access with aliases
rt help                    # Show all commands
disk-check                 # Check disk usage
backup-list               # List all backups

# Or use the full command
restore-toolkit help
restore-toolkit disk-usage
```

### 2. Create Your First Restore Point
```bash
# Using Timeshift (recommended - works from anywhere)
sudo timeshift --create --comments "Initial restore point"

# Or using the toolkit (from anywhere)
rt create-snapshot "Description here"
```

### 3. Check System Status (from anywhere)
```bash
disk-check                 # Quick disk usage
backup-list               # List all backups 
snapshot-list             # List all snapshots
```

## 📚 Available Commands

### **Global Commands** (work from anywhere)

| Global Command | Alias | Description |
|----------------|-------|-------------|
| `restore-toolkit help` | `rt help` | Show all available commands |
| `restore-toolkit list-snapshots` | `snapshot-list` | List LVM snapshots |
| `restore-toolkit list-backups` | `backup-list` | List full system backups |
| `restore-toolkit create-snapshot` | `rt create-snapshot` | Create LVM snapshot |
| `restore-toolkit create-backup` | `rt create-backup` | Create full backup |
| `restore-toolkit disk-usage` | `disk-check` | Show disk usage info |

### **Local Commands** (from project directory)

| Local Command | Description |
|---------------|-------------|
| `./manage_restore_points.sh help` | Direct script access |
| `./scripts/current_system_state.sh` | Document current system state |
| `./restore-toolkit help` | Local launcher script |

## ⚙️ System Requirements

- **OS**: Ubuntu 22.04+ (tested on Ubuntu 24.04)
- **Storage**: LVM setup (for snapshots)
- **Privileges**: sudo access required
- **Dependencies**: Automatically installed by setup scripts

## 🛠️ Installation & Setup

This toolkit is ready to use, but if you need to set up Timeshift:

```bash
./scripts/setup_timeshift.sh
```

## 📖 Documentation

- **Complete Guide**: See `RESTORE_POINT_GUIDE.md`
- **System State**: Run `./scripts/current_system_state.sh`

## 🎯 Use Cases

### Regular Development (from anywhere)
```bash
# Quick system check before changes
disk-check

# Before installing new software
sudo timeshift --create --comments "Before installing Docker"

# Create snapshot using toolkit
rt create-snapshot "Before installing new AI framework"
```

### System Maintenance (from anywhere)
```bash
# Before major updates
rt create-backup "Before Ubuntu upgrade"
sudo timeshift --create --comments "Before system upgrade"

# Check space before maintenance
disk-check
```

### Project Deployment (from anywhere)
```bash
# Quick backup check before deployment
backup-list

# Create restore point
sudo timeshift --create --comments "Before $(date) deployment"

# Document current state (from project directory)
cd ~/projects/system-restore-toolkit
./scripts/current_system_state.sh > backups/deployment_$(date +%Y%m%d)_state.txt
```

## ⚠️ Important Notes

1. **LVM Snapshots**: Require free space in volume group
2. **Timeshift**: Works with any filesystem (recommended)
3. **Full Backups**: Require external storage or sufficient disk space
4. **Testing**: Always test restore procedures in non-production environment

## 🆘 Emergency Restoration

1. Boot from Ubuntu Live Media
2. Navigate to this toolkit location
3. Follow restoration instructions in `RESTORE_POINT_GUIDE.md`

## 📊 System Compatibility

- ✅ Ubuntu 24.04 Noble
- ✅ LVM storage setup
- ✅ Docker environments
- ✅ AI/ML development systems
- ✅ High-capacity systems (1TB+)

## 🤝 Contributing

This toolkit was created specifically for the TensorCore development environment but can be adapted for other Ubuntu LVM systems.

## 📝 License

Open source - adapt and modify as needed for your environment.

---

**Created**: August 7, 2025  
**System**: tensorcore (paulo@tensorcore)  
**Environment**: Ubuntu 24.04, 24 cores, 125Gi RAM, 1.8TB storage
