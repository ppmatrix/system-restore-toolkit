#!/bin/bash
# Simple script to get timeshift list - to be executed on host

# Change to host root to ensure proper environment
cd /

# Execute timeshift with full path and capture output
if command -v timeshift >/dev/null 2>&1; then
    sudo timeshift --list --scripted 2>&1
else
    echo "Error: timeshift command not found"
    exit 1
fi
