#!/usr/bin/env python3
"""
Host-side timeshift wrapper that outputs JSON for the web interface
"""

import subprocess
import json
import sys
import os

def get_timeshift_data():
    try:
        # Execute timeshift on the host
        result = subprocess.run([
            'sudo', 'timeshift', '--list', '--scripted'
        ], capture_output=True, text=True, timeout=30, cwd='/')
        
        if result.returncode != 0:
            return {
                'success': False,
                'error': f"Timeshift command failed: {result.stderr.strip() or 'Unknown error'}",
                'snapshots': [],
                'summary': []
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
            'summary': summary_lines or [f"{len(snapshots)} snapshots available"]
        }
        
    except subprocess.TimeoutExpired:
        return {'success': False, 'error': "Command timeout", 'snapshots': [], 'summary': []}
    except Exception as e:
        return {'success': False, 'error': str(e), 'snapshots': [], 'summary': []}

def main():
    data = get_timeshift_data()
    print(json.dumps(data, indent=2))

if __name__ == '__main__':
    main()
