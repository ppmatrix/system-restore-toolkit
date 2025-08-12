#!/usr/bin/env python3
"""
System Restore Toolkit - Web Interface (Backups & Timeshift Edition)
Focus: Full System Backups + Timeshift Integration
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
SCRIPT_DIR = "/toolkit"
TOOLKIT_CMD = os.path.join(SCRIPT_DIR, 'system-restore-toolkit')

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
                    cwd=SCRIPT_DIR
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
            cwd=SCRIPT_DIR,
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

def get_timeshift_snapshots():
    """Get Timeshift snapshots by reading from shared JSON file"""
    try:
        import json
        import os
        from datetime import datetime
        
        # Path to the shared JSON file - mounted as part of the project directory
        json_file_path = "/toolkit/shared-data/timeshift-info.json"
        
        # Check if file exists
        if not os.path.exists(json_file_path):
            return {
                'success': False,
                'error': "Timeshift data not available. Run the update script on host.",
                'snapshots': [],
                'summary': []
            }
        
        # Read the JSON file
        with open(json_file_path, 'r') as f:
            data = json.load(f)
        
        # Check if data is recent (within last hour)
        try:
            timestamp_str = data.get('timestamp', '')
            if timestamp_str:
                file_time = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
                now = datetime.now()
                age_seconds = (now - file_time).total_seconds()
                if age_seconds > 3600:  # older than 1 hour
                    data['warning'] = f"Data is {int(age_seconds/60)} minutes old"
        except:
            pass  # ignore timestamp parsing errors
        
        return data
        
    except FileNotFoundError:
        return {
            'success': False,
            'error': "Timeshift data file not found",
            'snapshots': [],
            'summary': []
        }
    except json.JSONDecodeError:
        return {
            'success': False,
            'error': "Failed to parse timeshift data file",
            'snapshots': [],
            'summary': []
        }
    except Exception as e:
        return {
            'success': False,
            'error': f"Error reading timeshift data: {str(e)}",
            'snapshots': [],
            'summary': []
        }

def get_parsed_backups():
    """Get parsed backup information for table display"""
    try:
        backup_result = run_toolkit_command(['list-backups'])
        
        if backup_result.get('success'):
            output = backup_result.get('output', '')
            lines = output.strip().split('\n')
            backups = []
            
            for i, line in enumerate(lines):
                line = line.strip()
                if '.tar.gz' in line and line.startswith('*'):
                    filename = line.replace('*', '').strip()
                    
                    size_info = 'Unknown'
                    if i + 1 < len(lines) and 'Size:' in lines[i + 1]:
                        size_info = lines[i + 1].strip().replace('Size:', '').strip()
                    
                    name_parts = filename.replace('full-backup-', '').replace('.tar.gz', '')
                    formatted_date = 'Unknown'
                    display_name = filename
                    
                    if '_' in name_parts:
                        try:
                            date_part, time_part = name_parts.split('_', 1)
                            formatted_date = f"{date_part[:4]}-{date_part[4:6]}-{date_part[6:8]}"
                            formatted_time = f"{time_part[:2]}:{time_part[2:4]}:{time_part[4:6]}"
                            display_name = f"{formatted_date} {formatted_time}"
                        except:
                            display_name = name_parts
                    
                    backups.append({
                        'filename': filename,
                        'name': display_name,
                        'size': size_info,
                        'type': 'Full System',
                        'date': formatted_date,
                        'raw_name': name_parts
                    })
            
            return {
                'success': True,
                'backups': backups,
                'summary': f"Found {len(backups)} backup(s)"
            }
        else:
            return {
                'success': False,
                'error': backup_result.get('error', 'Failed to get backup information'),
                'backups': []
            }
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'backups': []
        }

@app.route('/')
def dashboard():
    """Main dashboard - Focus on Backups & Timeshift"""
    system_stats = get_system_statistics()
    backups_info = run_toolkit_command(['list-backups'])
    
    # Count backups
    backup_count = 0
    if backups_info['success'] and backups_info['output']:
        for line in backups_info['output'].split('\n'):
            if '*' in line and 'full-backup-' in line and '.tar.gz' in line:
                backup_count += 1
    
    return render_template('dashboard.html', 
                         system_stats=system_stats,
                         backups_info=backups_info,
                         backup_count=backup_count)

@app.route('/backups')
def backups():
    """Full system backups management"""
    backups_info = get_parsed_backups()
    
    # Count backups for backups page
    backup_count = 0
    if backups_info and "success" in backups_info and backups_info["success"] and backups_info.get("backups"):
        backup_count = len(backups_info["backups"])
    return render_template('backups.html', 
                         backups_info=backups_info,
                         backup_count=backup_count)

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
    """Timeshift management with real snapshot data"""
    timeshift_info = get_timeshift_snapshots()
    return render_template('timeshift.html', timeshift_info=timeshift_info)

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
    """View system logs - enhanced with multiple sources"""
    log_dir = os.path.join(SCRIPT_DIR, "logs")
    log_files = []
    
    # 1. Toolkit logs from logs directory
    if os.path.exists(log_dir):
        for filename in sorted(os.listdir(log_dir)):
            if filename.endswith(".log"):
                filepath = os.path.join(log_dir, filename)
                log_files.append({
                    "name": filename,
                    "size": os.path.getsize(filepath),
                    "modified": datetime.fromtimestamp(os.path.getmtime(filepath)),
                    "type": "Toolkit",
                    "description": "Main toolkit operations log"
                })
    
    # 2. Web interface logs
    web_log_dir = os.path.join(SCRIPT_DIR, "web-interface")
    if os.path.exists(web_log_dir):
        for filename in sorted(os.listdir(web_log_dir)):
            if filename.startswith("web-server") and filename.endswith(".log"):
                filepath = os.path.join(web_log_dir, filename)
                log_files.append({
                    "name": f"web-interface/{filename}",
                    "size": os.path.getsize(filepath),
                    "modified": datetime.fromtimestamp(os.path.getmtime(filepath)),
                    "type": "Web Interface",
                    "description": "Web server operations and errors"
                })
    
    # 3. Add virtual log entries for system logs (read-only access)
    log_files.append({
        "name": "system/timeshift.log",
        "size": "Variable",
        "modified": datetime.now(),
        "type": "System",
        "description": "Timeshift operations from system log"
    })
    
    log_files.append({
        "name": "system/backup-operations.log",
        "size": "Variable", 
        "modified": datetime.now(),
        "type": "System",
        "description": "Backup operations from system log"
    })
    
    log_files.append({
        "name": "system/system-events.log",
        "size": "Variable",
        "modified": datetime.now(),
        "type": "System", 
        "description": "General system events related to toolkit"
    })
    
    return render_template("logs.html", log_files=log_files)

@app.route('/api/status')
def api_status():
    """API endpoint for system status - No LVM snapshots"""
    disk_info = run_toolkit_command(['disk-usage'])
    backups_info = run_toolkit_command(['list-backups'])
    timeshift_info = get_timeshift_snapshots()
    
    return jsonify({
        'disk': disk_info,
        'backups': backups_info,
        'timeshift': timeshift_info
    })

@app.route('/api/task/<task_id>')
@app.route("/api/logs/<filename>")
@app.route("/api/logs/<path:filename>")
def api_log_content(filename):
    """Enhanced API endpoint to get log file content from multiple sources"""
    try:
        # Handle different log sources
        if filename.startswith("system/"):
            return get_system_log_content(filename)
        elif filename.startswith("web-interface/"):
            return get_web_interface_log_content(filename)
        else:
            return get_toolkit_log_content(filename)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def get_toolkit_log_content(filename):
    """Get toolkit log content"""
    log_dir = os.path.join(SCRIPT_DIR, "logs")
    log_path = os.path.join(log_dir, filename)
    
    # Security check
    if not filename.endswith(".log") or not os.path.exists(log_path):
        return jsonify({"error": "Log file not found"}), 404
    
    if not os.path.abspath(log_path).startswith(os.path.abspath(log_dir)):
        return jsonify({"error": "Access denied"}), 403
    
    with open(log_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
        if len(lines) > 1000:
            content = "... (showing last 1000 lines)\n" + "".join(lines[-1000:])
        else:
            content = "".join(lines)
    
    return jsonify({
        "success": True,
        "content": content,
        "filename": filename,
        "lines": len(lines),
        "type": "Toolkit Log"
    })

def get_web_interface_log_content(filename):
    """Get web interface log content"""
    # Remove web-interface/ prefix
    actual_filename = filename.replace("web-interface/", "")
    log_path = os.path.join(SCRIPT_DIR, "web-interface", actual_filename)
    
    if not os.path.exists(log_path):
        return jsonify({"error": "Web log file not found"}), 404
    
    with open(log_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
        if len(lines) > 500:
            content = "... (showing last 500 lines)\n" + "".join(lines[-500:])
        else:
            content = "".join(lines)
    
    return jsonify({
        "success": True,
        "content": content,
        "filename": filename,
        "lines": len(lines),
        "type": "Web Interface Log"
    })

def get_system_log_content(filename):
    """Get system log content (filtered)"""
    try:
        if filename == "system/timeshift.log":
            # Get Timeshift-related entries from syslog
            result = subprocess.run(
                ["sudo", "grep", "-i", "timeshift", "/var/log/syslog"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split("\n")
                if len(lines) > 200:
                    content = "... (showing last 200 timeshift entries)\n" + "\n".join(lines[-200:])
                else:
                    content = result.stdout
                return jsonify({
                    "success": True,
                    "content": content,
                    "filename": filename,
                    "lines": len(lines),
                    "type": "System Log (Timeshift)"
                })
            else:
                return jsonify({
                    "success": True,
                    "content": "No Timeshift entries found in system log.",
                    "filename": filename,
                    "lines": 0,
                    "type": "System Log (Timeshift)"
                })
        
        elif filename == "system/backup-operations.log":
            # Get backup-related entries from syslog and toolkit logs
            content_parts = []
            
            # Check syslog for backup-related entries
            result = subprocess.run(
                ["sudo", "grep", "-iE", "(backup|tar|rsync)", "/var/log/syslog"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                syslog_lines = result.stdout.strip().split("\n")[-50:]  # Last 50 entries
                if syslog_lines and syslog_lines[0]:
                    content_parts.append("=== System Log Backup Entries ===")
                    content_parts.extend(syslog_lines)
                    content_parts.append("")
            
            # Check toolkit logs for backup entries
            toolkit_log = os.path.join(SCRIPT_DIR, "logs", f'toolkit-{datetime.now().strftime("%Y%m%d")}.log')
            if os.path.exists(toolkit_log):
                with open(toolkit_log, "r", encoding="utf-8", errors="replace") as f:
                    toolkit_lines = [line.strip() for line in f.readlines() if "backup" in line.lower()]
                    if toolkit_lines:
                        content_parts.append("=== Toolkit Backup Entries ===")
                        content_parts.extend(toolkit_lines[-50:])  # Last 50 entries
            
            content = "\n".join(content_parts) if content_parts else "No backup operations found in logs."
            
            return jsonify({
                "success": True,
                "content": content,
                "filename": filename,
                "lines": len(content_parts),
                "type": "System Log (Backups)"
            })
        
        elif filename == "system/system-events.log":
            # Get general system events related to our toolkit
            result = subprocess.run(
                ["sudo", "grep", "-iE", "(restore|snapshot|toolkit)", "/var/log/syslog"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split("\n")
                if len(lines) > 100:
                    content = "... (showing last 100 system events)\n" + "\n".join(lines[-100:])
                else:
                    content = result.stdout
                return jsonify({
                    "success": True,
                    "content": content,
                    "filename": filename,
                    "lines": len(lines),
                    "type": "System Log (Events)"
                })
            else:
                return jsonify({
                    "success": True,
                    "content": "No system events found related to toolkit operations.",
                    "filename": filename,
                    "lines": 0,
                    "type": "System Log (Events)"
                })
        
        else:
            return jsonify({"error": "Unknown system log type"}), 404
            
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Timeout while reading system logs"}), 500
    except Exception as e:
        return jsonify({"error": f"Error reading system logs: {str(e)}"}), 500

@app.route("/api/logs/<filename>/download")
def api_log_download(filename):
    """API endpoint to download log file"""
    log_dir = os.path.join(SCRIPT_DIR, "logs")
    log_path = os.path.join(log_dir, filename)
    
    if not filename.endswith(".log") or not os.path.exists(log_path):
        return "Log file not found", 404
    
    if not os.path.abspath(log_path).startswith(os.path.abspath(log_dir)):
        return "Access denied", 403
    
    return send_file(log_path, as_attachment=True)

def api_task_status(task_id):
    """API endpoint for task status"""
    task = task_manager.get_task(task_id)
    if task:
        return jsonify(task)
    else:
        return jsonify({'error': 'Task not found'}), 404


@app.route('/delete-timeshift', methods=['POST'])
def delete_timeshift():
    """Delete Timeshift snapshot"""
    snapshot_name = request.form.get('snapshot_name')
    
    if not snapshot_name:
        flash('No snapshot name provided', 'error')
        return redirect(url_for('timeshift'))
    
    try:
        result = subprocess.run(
            ['sudo', '/host/var/lib/snapd/hostfs/usr/bin/timeshift', '--delete', '--snapshot', snapshot_name, '--yes'],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == 0:
            flash(f'Timeshift snapshot "{snapshot_name}" deleted successfully!', 'success')
        else:
            flash(f'Failed to delete snapshot: {result.stderr}', 'error')
            
    except subprocess.TimeoutExpired:
        flash('Timeout while deleting snapshot', 'error')
    except Exception as e:
        flash(f'Error deleting snapshot: {str(e)}', 'error')
    
    return redirect(url_for('timeshift'))

@app.route('/api/timeshift-info')
@app.route("/api/timeshift-snapshots")
def api_timeshift_snapshots():
    """API endpoint for Timeshift snapshots count"""
    return jsonify(get_timeshift_snapshots())
@app.route("/restore-timeshift", methods=["POST"])
def restore_timeshift():
    """Restore Timeshift snapshot with safety checks"""
    snapshot_name = request.form.get("snapshot_name")
    confirmation = request.form.get("confirmation")
    
    if not snapshot_name:
        flash("No snapshot name provided", "error")
        return redirect(url_for("timeshift"))
    
    if confirmation != "I UNDERSTAND THE RISKS":
        flash("Restoration cancelled - confirmation text not matched", "error")
        return redirect(url_for("timeshift"))
    
    try:
        # For safety, we will only prepare the restore command but not execute it
        # This is too dangerous to run via web interface
        flash(f"For safety, snapshot restoration must be done manually:", "warning")
        flash(f"Run: sudo /host/var/lib/snapd/hostfs/usr/bin/timeshift --restore --snapshot \"{snapshot_name}\"", "info")
        flash("System will reboot automatically after restoration", "info")
        
    except Exception as e:
        flash(f"Error preparing restore: {str(e)}", "error")
    
    return redirect(url_for("timeshift"))

def api_timeshift_info():
    """API endpoint for Timeshift information"""
    return jsonify(get_timeshift_snapshots())


def get_system_statistics():
    """Get comprehensive system statistics with host system access"""
    try:
        stats = {}
        
        # Use host proc/sys paths if available
        host_proc = os.getenv('HOST_PROC', '/proc')
        host_sys = os.getenv('HOST_SYS', '/sys')
        
        # System Information - Use host system files
        try:
            # Try to get real hostname from host
            if os.path.exists('/etc/hostname'):
                with open('/etc/hostname', 'r') as f:
                    stats['hostname'] = f.read().strip()
            else:
                stats['hostname'] = subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
        except:
            stats['hostname'] = 'Unknown'
            
        try:
            stats['kernel'] = subprocess.run(['uname', '-r'], capture_output=True, text=True).stdout.strip()
        except:
            try:
                with open(f'{host_proc}/version', 'r') as f:
                    version_line = f.read().strip()
                    # Extract kernel version from /proc/version
                    parts = version_line.split()
                    if len(parts) >= 3:
                        stats['kernel'] = parts[2]
                    else:
                        stats['kernel'] = 'Unknown'
            except:
                stats['kernel'] = 'Unknown'
            
        # Uptime - Use host proc
        try:
            uptime_output = subprocess.run(['uptime', '-p'], capture_output=True, text=True).stdout.strip()
            stats['uptime'] = uptime_output.replace('up ', '')
        except:
            try:
                with open(f'{host_proc}/uptime', 'r') as f:
                    uptime_seconds = float(f.read().split()[0])
                    days = int(uptime_seconds // 86400)
                    hours = int((uptime_seconds % 86400) // 3600)
                    minutes = int((uptime_seconds % 3600) // 60)
                    
                    uptime_parts = []
                    if days > 0:
                        uptime_parts.append(f"{days} day{'s' if days != 1 else ''}")
                    if hours > 0:
                        uptime_parts.append(f"{hours} hour{'s' if hours != 1 else ''}")
                    if minutes > 0:
                        uptime_parts.append(f"{minutes} minute{'s' if minutes != 1 else ''}")
                    
                    stats['uptime'] = ', '.join(uptime_parts) if uptime_parts else 'Less than a minute'
            except:
                stats['uptime'] = 'Unknown'
        
        # OS Information - Use host OS release files
        try:
            # Try multiple OS release files
            os_files = ['/etc/os-release', '/etc/lsb-release']
            for os_file in os_files:
                try:
                    if os.path.exists(os_file):
                        with open(os_file, 'r') as f:
                            content = f.read()
                            if 'PRETTY_NAME=' in content:
                                for line in content.split('\n'):
                                    if line.startswith('PRETTY_NAME='):
                                        stats['os'] = line.split('=')[1].strip('"')
                                        break
                                break
                            elif 'DISTRIB_DESCRIPTION=' in content:
                                for line in content.split('\n'):
                                    if line.startswith('DISTRIB_DESCRIPTION='):
                                        stats['os'] = line.split('=')[1].strip('"')
                                        break
                                break
                except:
                    continue
            else:
                # Fallback to lsb_release command
                try:
                    os_info = subprocess.run(['lsb_release', '-d'], capture_output=True, text=True).stdout.strip()
                    stats['os'] = os_info.split('\t')[1] if '\t' in os_info else 'Linux'
                except:
                    stats['os'] = 'Linux'
        except:
            stats['os'] = 'Linux'
        
        # CPU Information - Use host proc
        try:
            cpu_info = subprocess.run(['lscpu'], capture_output=True, text=True).stdout
            cpu_name = ''
            cpu_cores = ''
            for line in cpu_info.split('\n'):
                if 'Model name:' in line:
                    cpu_name = line.split(':')[1].strip()
                elif 'CPU(s):' in line and not 'NUMA' in line and not 'On-line' in line:
                    cpu_cores = line.split(':')[1].strip()
            stats['cpu'] = f"{cpu_name} ({cpu_cores} cores)" if cpu_name and cpu_cores else 'Unknown'
        except:
            try:
                # Read from host /proc/cpuinfo
                with open(f'{host_proc}/cpuinfo', 'r') as f:
                    cpuinfo = f.read()
                    
                cpu_name = 'Unknown'
                cpu_count = 0
                
                for line in cpuinfo.split('\n'):
                    if line.startswith('model name'):
                        cpu_name = line.split(':')[1].strip()
                    elif line.startswith('processor'):
                        cpu_count += 1
                
                if cpu_name != 'Unknown' and cpu_count > 0:
                    stats['cpu'] = f"{cpu_name} ({cpu_count} cores)"
                else:
                    stats['cpu'] = 'Unknown'
            except:
                stats['cpu'] = 'Unknown'
        
        # Memory Information - Use host proc
        try:
            mem_info = subprocess.run(['free', '-h'], capture_output=True, text=True).stdout
            mem_lines = mem_info.split('\n')
            for line in mem_lines:
                if line.startswith('Mem:'):
                    parts = line.split()
                    if len(parts) >= 3:
                        total = parts[1]
                        used = parts[2]
                        # Convert units to GB for display (Gi -> GB)
                        total_display = total.replace("Gi", "GB").replace("Mi", "MB")
                        used_display = used.replace("Gi", "GB").replace("Mi", "MB")
                        stats["memory"] = f"{used_display} / {total_display}"
                        
                        # Calculate percentage for progress bar
                        try:
                            # Parse numeric values for percentage calculation
                            total_val = float(total.replace("Gi", "").replace("Mi", "").replace("G", "").replace("M", ""))
                            used_val = float(used.replace("Gi", "").replace("Mi", "").replace("G", "").replace("M", ""))
                            # Adjust for unit differences (Mi to Gi conversion if needed)
                            if "Mi" in used and "Gi" in total:
                                used_val = used_val / 1024
                            elif "Mi" in total and "Gi" in used:
                                total_val = total_val / 1024
                            stats["memory_percent"] = int((used_val / total_val) * 100)
                        except:
                            stats["memory_percent"] = 38  # Default fallback
                    break
        except:
            try:
                # Read from host /proc/meminfo
                with open(f'{host_proc}/meminfo', 'r') as f:
                    meminfo = f.read()
                    
                mem_total_kb = 0
                mem_available_kb = 0
                
                for line in meminfo.split('\n'):
                    if line.startswith('MemTotal:'):
                        mem_total_kb = int(line.split()[1])
                    elif line.startswith('MemAvailable:'):
                        mem_available_kb = int(line.split()[1])
                
                if mem_total_kb > 0:
                    mem_used_kb = mem_total_kb - mem_available_kb
                    
                    # Convert to human readable
                    def kb_to_human(kb):
                        if kb >= 1024 * 1024:
                            return f"{kb / (1024 * 1024):.1f}GB"
                        elif kb >= 1024:
                            return f"{kb / 1024:.1f}MB"
                        else:
                            return f"{kb}KB"
                    
                    stats['memory'] = f"{kb_to_human(mem_used_kb)} / {kb_to_human(mem_total_kb)}"
                    stats['memory_percent'] = int((mem_used_kb / mem_total_kb) * 100)
                else:
                    stats['memory'] = 'Unknown'
                    stats["memory_percent"] = 0
            except:
                stats['memory'] = 'Unknown'
                stats["memory_percent"] = 0
        
        # Disk Usage
        try:
            disk_info = subprocess.run(['df', '-h', '/'], capture_output=True, text=True).stdout
            disk_lines = disk_info.split('\n')
            for line in disk_lines[1:]:  # Skip header
                if line.strip():
                    parts = line.split()
                    if len(parts) >= 5:
                        stats['disk_total'] = parts[1]
                        stats['disk_used'] = parts[2]
                        stats['disk_available'] = parts[3]
                        stats['disk_percent'] = parts[4]
                    break
        except:
            stats['disk_total'] = stats['disk_used'] = stats['disk_available'] = stats['disk_percent'] = 'Unknown'
        
        # GPU Information - Enhanced with host access
        try:
            # Check if nvidia-smi is available (mounted from host)
            nvidia_check = subprocess.run(['which', 'nvidia-smi'], capture_output=True, text=True)
            
            if nvidia_check.returncode == 0:
                # Get detailed NVIDIA GPU information
                gpu_detailed_info = subprocess.run([
                    'nvidia-smi', '--query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu,utilization.memory,temperature.gpu,power.draw,power.limit', 
                    '--format=csv,noheader,nounits'
                ], capture_output=True, text=True, timeout=5)
                
                if gpu_detailed_info.returncode == 0 and gpu_detailed_info.stdout.strip():
                    gpus = []
                    for line in gpu_detailed_info.stdout.strip().split('\n'):
                        parts = [p.strip() for p in line.split(',')]
                        if len(parts) >= 9:
                            gpu_info = {
                                'name': parts[0],
                                'memory_total': int(parts[1]) if parts[1].isdigit() else 0,
                                'memory_used': int(parts[2]) if parts[2].isdigit() else 0,
                                'memory_free': int(parts[3]) if parts[3].isdigit() else 0,
                                'utilization_gpu': int(parts[4]) if parts[4].isdigit() else 0,
                                'utilization_memory': int(parts[5]) if parts[5].isdigit() else 0,
                                'temperature': int(parts[6]) if parts[6].isdigit() else 0,
                                'power_draw': float(parts[7]) if parts[7].replace('.', '').isdigit() else 0.0,
                                'power_limit': float(parts[8]) if parts[8].replace('.', '').isdigit() else 0.0
                            }
                            gpus.append(gpu_info)
                    
                    stats['gpu_detailed'] = True
                    stats['gpus'] = gpus
                    stats['gpu'] = f"{len(gpus)} x {gpus[0]['name']}" if len(gpus) > 1 and all(g['name'] == gpus[0]['name'] for g in gpus) else ', '.join([g['name'] for g in gpus])
                else:
                    # Fallback to basic nvidia-smi
                    gpu_basic_info = subprocess.run(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader,nounits'], 
                                                  capture_output=True, text=True, timeout=5)
                    if gpu_basic_info.returncode == 0 and gpu_basic_info.stdout.strip():
                        gpus = gpu_basic_info.stdout.strip().split('\n')
                        stats['gpu_detailed'] = False
                        stats['gpu'] = ', '.join(gpus)
                    else:
                        stats['gpu_detailed'] = False
                        stats['gpu'] = 'NVIDIA GPU (details unavailable)'
            else:
                # Try lspci for other GPUs
                gpu_info = subprocess.run(['lspci'], capture_output=True, text=True, timeout=5)
                gpu_lines = []
                for line in gpu_info.stdout.split('\n'):
                    if 'VGA' in line or 'Display' in line or '3D' in line:
                        # Extract GPU name
                        parts = line.split(': ')
                        if len(parts) > 1:
                            gpu_name = parts[1].split(' [')[0]  # Remove bracketed info
                            gpu_lines.append(gpu_name)
                stats['gpu_detailed'] = False
                stats['gpu'] = ', '.join(gpu_lines) if gpu_lines else 'None detected'
        except:
            stats['gpu_detailed'] = False
            stats['gpu'] = 'Unknown'

        
        # Load Average - Use host proc
        try:
            load_info = subprocess.run(['uptime'], capture_output=True, text=True).stdout
            if 'load average:' in load_info:
                load_part = load_info.split('load average:')[1].strip()
                stats['load_average'] = load_part
            else:
                stats['load_average'] = 'Unknown'
        except:
            try:
                with open(f'{host_proc}/loadavg', 'r') as f:
                    loadavg = f.read().strip()
                    # First three values are 1min, 5min, 15min averages
                    parts = loadavg.split()[:3]
                    stats['load_average'] = ', '.join(parts)
            except:
                stats['load_average'] = 'Unknown'
        
        # Temperature - Enhanced with host sensors access
        try:
            temp_info = subprocess.run(['sensors'], capture_output=True, text=True, timeout=5)
            if temp_info.returncode == 0:
                temp_lines = []
                for line in temp_info.stdout.split('\n'):
                    if 'Core' in line and '°C' in line:
                        temp_lines.append(line.strip())
                stats['temperature'] = '; '.join(temp_lines[:2]) if temp_lines else 'Not available'  # Show first 2 cores
            else:
                stats['temperature'] = 'Not available'
        except:
            # Try to read from host thermal zones
            try:
                temp_zones = []
                import glob
                for thermal_file in glob.glob(f'{host_sys}/class/thermal/thermal_zone*/temp'):
                    try:
                        with open(thermal_file, 'r') as f:
                            temp_millicelsius = int(f.read().strip())
                            temp_celsius = temp_millicelsius / 1000.0
                            zone_num = thermal_file.split('thermal_zone')[1].split('/')[0]
                            temp_zones.append(f"Zone {zone_num}: {temp_celsius:.1f}°C")
                    except:
                        continue
                
                if temp_zones:
                    stats['temperature'] = '; '.join(temp_zones[:2])  # Show first 2 zones
                else:
                    stats['temperature'] = 'Not available'
            except:
                stats['temperature'] = 'Not available'
            
        return {
            'success': True,
            'stats': stats
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'stats': {}
        }
if __name__ == '__main__':
    # Check if toolkit exists
    if not os.path.exists(TOOLKIT_CMD):
        print(f"Error: Toolkit not found at {TOOLKIT_CMD}")
        print("WARNING: Toolkit will be checked at runtime")
    
    print("🌐 System Restore Toolkit Web Interface (Backups & Timeshift)")
    print("=============================================================")
    print("Starting web server...")
    print(f"Toolkit path: {SCRIPT_DIR}")
    print("Access the web interface at: http://localhost:5000")
    print()
    print("✅ Features:")
    print("   • 💾 Full System Backups")
    print("   • 🕐 Timeshift Integration")
    print("   • 📋 Log Management")
    print("   • 📊 System Monitoring")
    print()
    print("❌ Removed: LVM Snapshots (insufficient volume group space)")
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)



@app.route('/api/refresh-timeshift', methods=['POST'])
def refresh_timeshift():
    """Trigger timeshift data refresh by calling the host script"""
    try:
        # Execute the host update script
        result = subprocess.run([
            'python3', '/toolkit/host-scripts/update-timeshift-data.py'
        ], capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': 'Timeshift data refreshed successfully',
                'output': result.stdout.strip()
            })
        else:
            return jsonify({
                'success': False,
                'error': f'Failed to refresh: {result.stderr.strip() or "Unknown error"}',
                'output': result.stdout.strip()
            })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Error: {str(e)}'
        })
