#!/bin/bash

# Common functions and utilities for System Restore Toolkit
# Version: 2.0
# Author: System Restore Toolkit

set -euo pipefail

# Colors for output (if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
DEFAULT_BACKUP_DIR="/var/backups/system-restore-toolkit"
DEFAULT_LOG_DIR="/var/log/system-restore-toolkit"
CONFIG_FILE="/etc/system-restore-toolkit.conf"

# Initialize log file (will be set in init_toolkit)
LOG_FILE=""

# Logging functions
log_info() {
    local msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo -e "${BLUE}${msg}${NC}"
    [[ -n "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    local msg="[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo -e "${GREEN}${msg}${NC}"
    [[ -n "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_warning() {
    local msg="[WARNING] $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo -e "${YELLOW}${msg}${NC}"
    [[ -n "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo -e "${RED}${msg}${NC}" >&2
    [[ -n "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if running with sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 1
    fi
}

# Ensure directories exist
ensure_directory() {
    local dir="$1"
    local permissions="${2:-755}"
    
    if [[ ! -d "$dir" ]]; then
        if [[ -w "$(dirname "$dir")" ]] || [[ $EUID -eq 0 ]]; then
            log_info "Creating directory: $dir"
            mkdir -p "$dir"
            chmod "$permissions" "$dir"
        elif command -v sudo &> /dev/null; then
            log_info "Creating directory with sudo: $dir"
            sudo mkdir -p "$dir"
            sudo chmod "$permissions" "$dir"
        else
            log_error "Cannot create directory: $dir (insufficient permissions)"
            return 1
        fi
    fi
}

# Check available disk space
check_disk_space() {
    local path="${1:-.}"
    local required_gb="${2:-5}"
    
    local available_kb
    available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        return 1
    fi
    
    log_info "Disk space check passed. Available: ${available_gb}GB"
    return 0
}

# Validate LVM setup
check_lvm() {
    if ! command -v lvcreate &> /dev/null; then
        log_error "LVM tools not found. Please install lvm2"
        return 1
    fi
    
    if [[ -z "$(sudo vgs --noheadings 2>/dev/null)" ]]; then
        log_error "No LVM volume groups found"
        return 1
    fi
    
    return 0
}

# Get timestamp for backup names
get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Generate backup description with system info
get_system_description() {
    local custom_desc="${1:-}"
    local hostname
    hostname=$(hostname)
    local kernel
    kernel=$(uname -r)
    
    if [[ -n "$custom_desc" ]]; then
        echo "${custom_desc} (${hostname}, kernel ${kernel})"
    else
        echo "System backup from ${hostname}, kernel ${kernel}"
    fi
}

# Cleanup function for traps
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with error code $exit_code"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Load configuration if exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

# Initialize common setup
init_toolkit() {
    load_config
    
    # Set up logging directory - prefer local if system not writable
    LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
    
    if [[ -w "$(dirname "$LOG_DIR")" ]] || [[ $EUID -eq 0 ]]; then
        ensure_directory "$LOG_DIR" "755"
        LOG_FILE="${LOG_DIR}/toolkit-$(date '+%Y%m%d').log"
    else
        # Fall back to local logs directory
        LOG_DIR="./logs"
        ensure_directory "$LOG_DIR" "755"
        LOG_FILE="${LOG_DIR}/toolkit-$(date '+%Y%m%d').log"
    fi
    
    # Set up backup directory
    BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"
    if [[ -w "$(dirname "$BACKUP_DIR")" ]] || [[ $EUID -eq 0 ]]; then
        ensure_directory "$BACKUP_DIR" "755"
    else
        # Fall back to local backups directory  
        BACKUP_DIR="./backups"
        ensure_directory "$BACKUP_DIR" "755"
    fi
    
    log_info "System Restore Toolkit v2.0 initialized"
}
