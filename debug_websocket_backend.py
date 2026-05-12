#!/usr/bin/env python3
"""
WebSocket Backend Debugging Tool
Finds ALL WebSocket endpoints and running processes
"""

import os
import sys
import subprocess
import psutil
import socket
import requests
from pathlib import Path

def find_all_websocket_files():
    """Find all Python files containing WebSocket endpoints"""
    print("🔍 Searching for ALL WebSocket files...")
    
    websocket_files = []
    current_dir = Path(".")
    
    # Search in current directory and subdirectories
    for file_path in current_dir.rglob("*.py"):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if any(keyword in content for keyword in ['@app.websocket', 'WebSocket(', 'websocket_endpoint']):
                    websocket_files.append(file_path)
                    print(f"📁 Found WebSocket file: {file_path}")
                    
                    # Show WebSocket endpoints in file
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if '@app.websocket' in line:
                            print(f"   → Line {i+1}: {line.strip()}")
                        if '"type": "connected"' in line:
                            print(f"   → Line {i+1}: FOUND 'connected' message: {line.strip()}")
                        if '"conversation_id is required"' in line:
                            print(f"   → Line {i+1}: FOUND conversation_id validation: {line.strip()}")
        except Exception as e:
            print(f"❌ Error reading {file_path}: {e}")
    
    return websocket_files

def find_running_python_processes():
    """Find all running Python processes"""
    print("\n🔍 Searching for running Python processes...")
    
    python_processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if 'python' in proc.info['name'].lower():
                cmdline = ' '.join(proc.info['cmdline'] or [])
                if 'websocket' in cmdline.lower() or 'uvicorn' in cmdline.lower() or '8001' in cmdline:
                    python_processes.append(proc.info)
                    print(f"🔄 Running Python process:")
                    print(f"   PID: {proc.info['pid']}")
                    print(f"   Command: {cmdline}")
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    return python_processes

def check_port_8001():
    """Check what's running on port 8001"""
    print("\n🔍 Checking port 8001...")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex(('localhost', 8001))
        sock.close()
        
        if result == 0:
            print("✅ Port 8001 is OPEN")
            
            # Try to identify what's running
            try:
                response = requests.get("http://localhost:8001/health", timeout=2)
                print(f"📊 Health check response: {response.status_code}")
                print(f"📊 Response body: {response.text}")
            except:
                print("❌ Health check failed - not a HTTP server")
                
            # Check if it's WebSocket
            try:
                import websockets
                print("🔌 Testing WebSocket connection...")
                # This would need actual WebSocket client test
            except ImportError:
                print("⚠️ websockets library not available for testing")
        else:
            print("❌ Port 8001 is CLOSED")
            
    except Exception as e:
        print(f"❌ Error checking port 8001: {e}")

def check_docker_containers():
    """Check for running Docker containers"""
    print("\n🔍 Checking Docker containers...")
    
    try:
        result = subprocess.run(['docker', 'ps'], capture_output=True, text=True)
        if result.returncode == 0:
            lines = result.stdout.split('\n')
            for line in lines:
                if 'websocket' in line.lower() or '8001' in line or 'gruve' in line.lower():
                    print(f"🐳 Found container: {line}")
        else:
            print("❌ Docker not available or no containers running")
    except FileNotFoundError:
        print("❌ Docker command not found")

def check_uvicorn_processes():
    """Specifically check for uvicorn processes"""
    print("\n🔍 Checking for uvicorn processes...")
    
    try:
        result = subprocess.run(['tasklist'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'uvicorn' in line.lower() or 'python' in line.lower():
                print(f"🔄 Process: {line}")
    except:
        print("❌ Could not check processes")

def main():
    print("="*80)
    print("🔍 WEBSOCKET BACKEND DEBUGGING TOOL")
    print("="*80)
    
    # 1. Find all WebSocket files
    websocket_files = find_all_websocket_files()
    
    # 2. Check running processes
    python_processes = find_running_python_processes()
    
    # 3. Check port 8001
    check_port_8001()
    
    # 4. Check Docker containers
    check_docker_containers()
    
    # 5. Check uvicorn specifically
    check_uvicorn_processes()
    
    print("\n" + "="*80)
    print("📊 SUMMARY")
    print("="*80)
    print(f"WebSocket files found: {len(websocket_files)}")
    print(f"Python processes running: {len(python_processes)}")
    
    if websocket_files:
        print("\n📁 WebSocket files to investigate:")
        for file in websocket_files:
            print(f"   - {file}")
    
    print("\n🔧 NEXT STEPS:")
    print("1. Kill any running Python/uvicorn processes")
    print("2. Stop any Docker containers")
    print("3. Run the correct backend file")
    print("4. Verify with frontend test")

if __name__ == "__main__":
    main()
