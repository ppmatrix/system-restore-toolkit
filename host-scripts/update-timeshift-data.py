#!/usr/bin/env python3
"""
Host-side script to update timeshift information in shared file
Run this periodically or on-demand to update timeshift data
"""

import subprocess
import json
import os
import sys

def get_timeshift_data():
    try:
        result = subprocess.run([
            'sudo', 'timeshift', '--list', '--scripted'
        ], capture_output=True, text=True, timeout=30, cwd='/')
        
        if result.returncode != 0:
            return {
                'success': False,
                'error': f"Timeshift command failed: {result.stderr.strip() or 'Unknown error'}",
                'snapshots': [],
                'summary': [],
                'timestamp': subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip()
            }
        
        # Parse the output
        lines = result.stdout.strip().split('\n')
        snapshots = []
        summary_lines = []
        
        parsing_snapshots = False
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Collect summary information
            if any(keyword in line.lower() for keyword in ['device', 'uuid', 'path', 'mode', 'status', 'snapshots', 'free']):
                summary_lines.append(line)
            
            # Look for table separator
            elif '---' in line and len(line) > 10:
                parsing_snapshots = True
                continue
            
            # Parse snapshots
            elif parsing_snapshots and not line.startswith('Num'):
                parts = line.split()
                if len(parts) >= 2:
                    snapshot = {
                        'num': parts[0] if parts[0].isdigit() else '',
                        'name': parts[2] if len(parts) > 2 and parts[1] == '>' else (parts[1] if len(parts) > 1 else ''),
                        'tags': parts[3] if len(parts) > 3 and parts[1] == '>' else '',
                        'description': ' '.join(parts[4:]) if len(parts) > 4 and parts[1] == '>' else ''
                    }
                    if snapshot['num'] and snapshot['name']:
                        snapshots.append(snapshot)
        
        return {
            'success': True,
            'snapshots': snapshots,
            'summary': summary_lines or [f"{len(snapshots)} snapshots available"],
            'timestamp': subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip()
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'snapshots': [],
            'summary': [],
            'timestamp': subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip()
        }

def main():
    # Get the script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    shared_data_file = os.path.join(project_dir, 'shared-data', 'timeshift-info.json')
    
    # Get timeshift data
    data = get_timeshift_data()
    
    # Write to shared file
    os.makedirs(os.path.dirname(shared_data_file), exist_ok=True)
    with open(shared_data_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Updated timeshift data at {data.get('timestamp', 'unknown time')}")
    if not data.get('success'):
        print(f"Error: {data.get('error')}")
        sys.exit(1)
    else:
        print(f"Found {len(data.get('snapshots', []))} snapshots")

if __name__ == '__main__':
    main()
