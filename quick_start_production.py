#!/usr/bin/env python3
"""
Quick Start - Deploy All Production Fixes
Run this to apply all fixes at once
"""

import subprocess
import sys
import os
import time

def print_header(text):
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60)

def run_command(cmd, description):
    print(f"\n🔄 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} - SUCCESS")
            return True
        else:
            print(f"❌ {description} - FAILED")
            print(f"Error: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ {description} - ERROR: {e}")
        return False

def main():
    print_header("🚀 GRUVE APP - PRODUCTION FIX DEPLOYMENT")
    
    # Step 1: Stop old backend
    print_header("Step 1: Stop Old Backend")
    if sys.platform == "win32":
        run_command('taskkill /F /IM python.exe /FI "WINDOWTITLE eq *websocket*"', "Stop old backend")
    else:
        run_command('pkill -f "python.*websocket"', "Stop old backend")
    
    time.sleep(2)
    
    # Step 2: Check dependencies
    print_header("Step 2: Check Dependencies")
    
    dependencies = ['fastapi', 'uvicorn', 'python-jose', 'pydantic']
    missing = []
    
    for dep in dependencies:
        try:
            __import__(dep.replace('-', '_'))
            print(f"✅ {dep} installed")
        except ImportError:
            print(f"❌ {dep} missing")
            missing.append(dep)
    
    if missing:
        print(f"\n📦 Installing missing dependencies: {missing}")
        run_command(f'{sys.executable} -m pip install {" ".join(missing)}', "Install dependencies")
    
    # Step 3: Start production backend
    print_header("Step 3: Start Production Backend")
    
    backend_file = "backend_production_websocket.py"
    
    if not os.path.exists(backend_file):
        print(f"❌ Backend file not found: {backend_file}")
        print("Please ensure backend_production_websocket.py exists")
        return
    
    print(f"\n🚀 Starting backend: {backend_file}")
    print("📍 WebSocket endpoint: ws://localhost:8001/ws")
    print("\n⚠️  Backend will run in this terminal")
    print("⚠️  Press Ctrl+C to stop")
    print("\n" + "=" * 60)
    
    try:
        subprocess.run([sys.executable, backend_file])
    except KeyboardInterrupt:
        print("\n\n👋 Backend stopped by user")
    
    # Step 4: Cleanup
    print_header("Cleanup")
    print("✅ All processes stopped")

if __name__ == "__main__":
    main()
