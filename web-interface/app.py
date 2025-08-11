#!/usr/bin/env python3
"""
System Restore Toolkit - Web Interface
A modern web UI for managing system backups and snapshots
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
import threading
import time

app = Flask(__name__)
app.secret_key = 'system-restore-toolkit-secret-key-change-in-production'

# Configuration
TOOLKIT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLKIT_CMD = os.path.join(TOOLKIT_PATH, 'system-restore-toolkit')

class TaskManager:
    """Simple task manager for long-running operations"""
    def __init__(self):
        self.tasks = {}
    
    def start_task(self, task_id, command, description):
        self.tasks[task_id] = {
            'status': 'running',
            'description': description,
            'start_time': datetime.now(),
            'output': [],
            'error': None
        }
        
        def run_task():
            try:
                process = subprocess.Popen(
                    command, 
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.PIPE,
                    text=True,
                    cwd=TOOLKIT_PATH
                )
                
                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break
                    if output:
                        self.tasks[task_id]['output'].append(output.strip())
                
                rc = process.poll()
                if rc == 0:
                    self.tasks[task_id]['status'] = 'completed'
                else:
                    self.tasks[task_id]['status'] = 'failed'
                    self.tasks[task_id]['error'] = process.stderr.read()
                    
            except Exception as e:
                self.tasks[task_id]['status'] = 'failed'
                self.tasks[task_id]['error'] = str(e)
        
        thread = threading.Thread(target=run_task)
        thread.start()
        return task_id
    
    def get_task(self, task_id):
        return self.tasks.get(task_id)

task_manager = TaskManager()

def run_toolkit_command(command):
    """Execute toolkit command and return result"""
    try:
        result = subprocess.run(
            [TOOLKIT_CMD] + command,
            capture_output=True,
            text=True,
            cwd=TOOLKIT_PATH,
            timeout=30
        )
        return {
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        }
    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'output': '',
            'error': 'Command timed out'
        }
    except Exception as e:
        return {
            'success': False,
            'output': '',
            'error': str(e)
        }

@app.route('/')
def dashboard():
    """Main dashboard"""
    # Get system status
    disk_info = run_toolkit_command(['disk-usage'])
    
    return render_template('dashboard.html', 
                         disk_info=disk_info)

@app.route('/snapshots')
def snapshots():
    """LVM Snapshots management"""
    snapshots_info = run_toolkit_command(['list-snapshots'])
    return render_template('snapshots.html', 
                         snapshots_info=snapshots_info)

@app.route('/backups')
def backups():
    """Full system backups management"""
    backups_info = run_toolkit_command(['list-backups'])
    return render_template('backups.html', 
                         backups_info=backups_info)

@app.route('/create-snapshot', methods=['POST'])
def create_snapshot():
    """Create new LVM snapshot"""
    description = request.form.get('description', 'Web UI snapshot')
    
    task_id = f"snapshot_{int(time.time())}"
    task_manager.start_task(
        task_id,
        [TOOLKIT_CMD, 'create-snapshot', description],
        f"Creating snapshot: {description}"
    )
    
    flash(f'Snapshot creation started. Task ID: {task_id}', 'info')
    return redirect(url_for('snapshots'))

@app.route('/create-backup', methods=['POST'])
def create_backup():
    """Create new full system backup"""
    description = request.form.get('description', 'Web UI backup')
    
    task_id = f"backup_{int(time.time())}"
    task_manager.start_task(
        task_id,
        [TOOLKIT_CMD, 'create-backup', description],
        f"Creating backup: {description}"
    )
    
    flash(f'Backup creation started. Task ID: {task_id}', 'info')
    return redirect(url_for('backups'))

@app.route('/timeshift')
def timeshift():
    """Timeshift management"""
    return render_template('timeshift.html')

@app.route('/create-timeshift', methods=['POST'])
def create_timeshift():
    """Create Timeshift backup"""
    description = request.form.get('description', 'Web UI timeshift backup')
    
    result = run_toolkit_command(['timeshift-create', description])
    
    if result['success']:
        flash('Timeshift backup created successfully!', 'success')
    else:
        flash(f'Timeshift backup failed: {result["error"]}', 'error')
    
    return redirect(url_for('timeshift'))

@app.route('/logs')
def logs():
    """View system logs"""
    log_dir = os.path.join(TOOLKIT_PATH, 'logs')
    log_files = []
    
    if os.path.exists(log_dir):
        for filename in sorted(os.listdir(log_dir)):
            if filename.endswith('.log'):
                filepath = os.path.join(log_dir, filename)
                log_files.append({
                    'name': filename,
                    'size': os.path.getsize(filepath),
                    'modified': datetime.fromtimestamp(os.path.getmtime(filepath))
                })
    
    return render_template('logs.html', log_files=log_files)

@app.route('/api/status')
def api_status():
    """API endpoint for system status"""
    disk_info = run_toolkit_command(['disk-usage'])
    snapshots_info = run_toolkit_command(['list-snapshots'])
    backups_info = run_toolkit_command(['list-backups'])
    
    return jsonify({
        'disk': disk_info,
        'snapshots': snapshots_info,
        'backups': backups_info
    })

@app.route('/api/task/<task_id>')
def api_task_status(task_id):
    """API endpoint for task status"""
    task = task_manager.get_task(task_id)
    if task:
        return jsonify(task)
    else:
        return jsonify({'error': 'Task not found'}), 404

if __name__ == '__main__':
    # Check if toolkit exists
    if not os.path.exists(TOOLKIT_CMD):
        print(f"Error: Toolkit not found at {TOOLKIT_CMD}")
        sys.exit(1)
    
    print("🌐 System Restore Toolkit Web Interface")
    print("=====================================")
    print("Starting web server...")
    print(f"Toolkit path: {TOOLKIT_PATH}")
    print("Access the web interface at: http://localhost:5000")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
