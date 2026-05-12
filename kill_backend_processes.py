#!/usr/bin/env python3
"""
Kill all running backend processes to prepare for clean restart
"""

import subprocess
import psutil
import os

def kill_python_processes():
    """Kill all Python processes that might be running WebSocket servers"""
    print("🔥 Killing Python processes...")
    
    killed = []
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmdline = ' '.join(proc.info['cmdline'] or [])
            if ('python' in proc.info['name'].lower() and 
                ('websocket' in cmdline.lower() or 
                 'uvicorn' in cmdline.lower() or 
                 '8001' in cmdline or
                 'backend' in cmdline.lower())):
                
                print(f"🔥 Killing PID {proc.info['pid']}: {cmdline}")
                proc.kill()
                killed.append(proc.info['pid'])
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    return killed

def kill_uvicorn_specifically():
    """Kill uvicorn processes specifically"""
    print("\n🔥 Killing uvicorn processes...")
    
    try:
        # Windows tasklist and taskkill
        result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq python.exe'], 
                              capture_output=True, text=True)
        
        lines = result.stdout.split('\n')
        for line in lines:
            if 'python.exe' in line and ('uvicorn' in line or 'websocket' in line):
                # Extract PID from tasklist output
                parts = line.split()
                if len(parts) >= 2:
                    pid = parts[1]
                    try:
                        subprocess.run(['taskkill', '/PID', pid, '/F'], 
                                      capture_output=True, text=True)
                        print(f"🔥 Killed uvicorn process PID: {pid}")
                    except:
                        pass
    except:
        print("❌ Could not kill uvicorn processes")

def stop_docker_containers():
    """Stop any Docker containers running WebSocket servers"""
    print("\n🐳 Stopping Docker containers...")
    
    try:
        # Find containers with websocket/gruve/8001
        result = subprocess.run(['docker', 'ps', '-q'], capture_output=True, text=True)
        if result.returncode == 0:
            container_ids = result.stdout.strip().split('\n')
            for container_id in container_ids:
                if container_id:
                    # Check container details
                    inspect_result = subprocess.run(['docker', 'inspect', container_id], 
                                                 capture_output=True, text=True)
                    if 'websocket' in inspect_result.stdout.lower() or '8001' in inspect_result.stdout:
                        print(f"🐳 Stopping container: {container_id}")
                        subprocess.run(['docker', 'stop', container_id], capture_output=True)
    except:
        print("❌ Docker not available")

def main():
    print("="*80)
    print("🔥 KILLING ALL BACKEND PROCESSES")
    print("="*80)
    
    # Kill Python processes
    killed_pids = kill_python_processes()
    
    # Kill uvicorn specifically
    kill_uvicorn_specifically()
    
    # Stop Docker containers
    stop_docker_containers()
    
    print(f"\n✅ Killed {len(killed_pids)} Python processes")
    print("🔥 All backend processes should be stopped now")
    print("\n🚀 You can now start the correct backend file:")
    print("   python backend_websocket_event_handler.py")

if __name__ == "__main__":
    main()
