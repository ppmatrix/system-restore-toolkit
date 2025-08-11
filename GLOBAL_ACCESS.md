# 🌍 Global Access Methods

Your System Restore Toolkit is now accessible from **anywhere** on your system!

## 🚀 Command Options (All work from any directory)

### **Method 1: Direct Command** (Recommended)
```bash
restore-toolkit help
restore-toolkit disk-usage  
restore-toolkit list-backups
restore-toolkit create-snapshot "Description"
```

### **Method 2: Super Quick Aliases**
```bash
rt help                    # Short for restore-toolkit
restore help               # Alternative command name
backup-list               # Quick backup listing
snapshot-list             # Quick snapshot listing  
disk-check               # Quick disk usage check
```

### **Method 3: Home Directory Shortcut**
```bash
~/restore-toolkit help
~/restore-toolkit disk-usage
```

### **Method 4: Full Path** (Always works)
```bash
~/projects/system-restore-toolkit/restore-toolkit help
```

## ✨ **Quick Examples**

### **Check System Status** (from anywhere):
```bash
# Any of these work:
rt disk-usage
disk-check
restore-toolkit disk-usage
~/restore-toolkit disk-usage
```

### **List Your Backups** (from anywhere):
```bash
# Any of these work:
backup-list
rt list-backups  
restore-toolkit list-backups
```

### **Create Restore Point** (from anywhere):
```bash
# Timeshift (recommended)
sudo timeshift --create --comments "Before installing XYZ"

# LVM snapshot (if space available)
rt create-snapshot "Before installing XYZ" 

# Full backup
sudo rt create-backup "Before major changes"
```

## 🎯 **Test Your Access**

Try these commands from any directory:

```bash
cd /tmp
rt help                    # Should work
backup-list               # Should work
disk-check                # Should work

cd ~/projects/SACErag  
restore-toolkit help      # Should work from project directories

cd ~
rt disk-usage             # Should work from home
```

## 🛠️ **Technical Details**

**How it works:**
1. **Symbolic link** in `~/.local/bin/restore-toolkit` (in your PATH)
2. **Bash aliases** in `~/.bashrc` for shortcuts
3. **Home directory link** `~/restore-toolkit` for convenience
4. **Original location**: `~/projects/system-restore-toolkit/`

**Path priority:**
1. Bash aliases (rt, restore, backup-list, etc.)
2. Commands in PATH (~/.local/bin/restore-toolkit)  
3. Home directory shortcuts (~/restore-toolkit)

## 🔄 **If You Need to Reinstall**

If the global access stops working:

```bash
# Recreate the PATH symlink
ln -sf ~/projects/system-restore-toolkit/restore-toolkit ~/.local/bin/restore-toolkit

# Reload bash configuration
source ~/.bashrc

# Test
which restore-toolkit
rt help
```

---

**You can now use your restore toolkit from anywhere on your system! 🎉**
