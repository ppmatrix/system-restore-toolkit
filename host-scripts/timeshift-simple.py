#!/usr/bin/env python3
import subprocess
import sys
import os

# Change to root directory to ensure proper environment
os.chdir('/')

try:
    # Execute timeshift with full path
    result = subprocess.run([
        'sudo', 'timeshift', '--list', '--scripted'
    ], capture_output=True, text=True, timeout=30)
    
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    sys.exit(result.returncode)
    
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
