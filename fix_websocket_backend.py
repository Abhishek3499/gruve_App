#!/usr/bin/env python3
"""
PRODUCTION-LEVEL WEBSOCKET BACKEND FIX
Comprehensive solution to migrate to new event-router architecture
"""

import os
import sys
import subprocess
import time
import json
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are installed"""
    print("🔍 Checking dependencies...")
    
    required_packages = ['fastapi', 'uvicorn', 'websockets', 'python-jose']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} missing")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n📦 Installing missing packages: {missing_packages}")
        try:
            subprocess.run([sys.executable, '-m', 'pip', 'install'] + missing_packages, 
                         check=True)
            print("✅ Dependencies installed")
        except subprocess.CalledProcessError:
            print("❌ Failed to install dependencies")
            return False
    
    return True

def backup_old_backend():
    """Backup any existing backend files"""
    print("\n💾 Backing up existing backend files...")
    
    backup_dir = Path("backend_backup")
    backup_dir.mkdir(exist_ok=True)
    
    backed_up = []
    for file_path in Path(".").glob("*websocket*.py"):
        if file_path.name not in ['backend_websocket_event_handler.py', 'backend_websocket_reference.py']:
            backup_path = backup_dir / file_path.name
            file_path.rename(backup_path)
            backed_up.append(str(backup_path))
            print(f"💾 Backed up: {file_path.name}")
    
    return backed_up

def create_production_startup_script():
    """Create production startup script"""
    print("\n📝 Creating production startup script...")
    
    startup_script = '''#!/usr/bin/env python3
"""
Production WebSocket Server Startup
Starts the correct backend with proper configuration
"""

import subprocess
import sys
import os

def start_backend():
    """Start the production WebSocket backend"""
    
    print("🚀 Starting Gruve WebSocket Server - Production")
    print("="*50)
    print("📍 WebSocket endpoint: ws://localhost:8001/ws")
    print("🔑 Authentication: JWT token required")
    print("📝 Event types: heartbeat, send_message")
    print("="*50)
    
    # Set environment variables
    os.environ.setdefault("PYTHONPATH", ".")
    
    # Start the correct backend file
    try:
        subprocess.run([
            sys.executable, 
            "backend_websocket_event_handler.py"
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start backend: {e}")
        return False
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
        return True
    
    return True

if __name__ == "__main__":
    start_backend()
'''
    
    with open("start_production_backend.py", "w") as f:
        f.write(startup_script)
    
    print("✅ Created start_production_backend.py")

def create_monitoring_script():
    """Create monitoring script to track backend health"""
    print("\n📊 Creating monitoring script...")
    
    monitor_script = '''#!/usr/bin/env python3
"""
WebSocket Backend Health Monitor
Monitors the backend and provides debugging info
"""

import requests
import json
import time
import asyncio
import websockets

async def monitor_backend():
    """Monitor backend health and WebSocket functionality"""
    
    print("🔍 Monitoring WebSocket Backend Health")
    print("="*50)
    
    # Check HTTP health endpoint
    try:
        response = requests.get("http://localhost:8001/health", timeout=5)
        if response.status_code == 200:
            print("✅ HTTP health check passed")
            health_data = response.json()
            print(f"📊 Active connections: {health_data.get('active_connections', 0)}")
        else:
            print(f"❌ HTTP health check failed: {response.status_code}")
    except:
        print("❌ Could not reach HTTP health endpoint")
    
    # Test WebSocket connection
    try:
        async with websockets.connect("ws://localhost:8001/ws") as websocket:
            print("✅ WebSocket connection successful")
            
            # Wait for connection message
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                message = json.loads(response)
                msg_type = message.get("type")
                
                if msg_type == "connection_established":
                    print("✅ Using NEW backend (connection_established)")
                elif msg_type == "connected":
                    print("❌ Using OLD backend (connected)")
                else:
                    print(f"⚠️ Unknown message type: {msg_type}")
                    
            except asyncio.TimeoutError:
                print("⚠️ No connection message received")
                
    except Exception as e:
        print(f"❌ WebSocket connection failed: {e}")

def main():
    while True:
        try:
            asyncio.run(monitor_backend())
        except KeyboardInterrupt:
            print("\n👋 Monitoring stopped")
            break
        except Exception as e:
            print(f"❌ Monitoring error: {e}")
        
        print("\n⏰ Waiting 30 seconds before next check...")
        time.sleep(30)

if __name__ == "__main__":
    main()
'''
    
    with open("monitor_backend.py", "w") as f:
        f.write(monitor_script)
    
    print("✅ Created monitor_backend.py")

def create_frontend_test_script():
    """Create script to test frontend integration"""
    print("\n📱 Creating frontend test script...")
    
    frontend_test = '''#!/usr/bin/env python3
"""
Frontend Integration Test
Tests the Flutter app WebSocket integration
"""

import asyncio
import websockets
import json
import time

async def test_frontend_integration():
    """Test WebSocket integration as Flutter app would"""
    
    print("📱 Testing Frontend WebSocket Integration")
    print("="*50)
    
    # Simulate Flutter app connection
    try:
        async with websockets.connect("ws://localhost:8001/ws?token=test_token") as websocket:
            print("✅ Connected (simulating Flutter app)")
            
            # Wait for connection message
            response = await websocket.recv()
            message = json.loads(response)
            print(f"📨 Connection message: {message}")
            
            # Test heartbeat (Flutter sends this)
            heartbeat = {
                "type": "heartbeat",
                "action": "ping",
                "timestamp": int(time.time() * 1000)
            }
            
            await websocket.send(json.dumps(heartbeat))
            print(f"📤 Sent heartbeat: {heartbeat}")
            
            response = await websocket.recv()
            pong = json.loads(response)
            
            if pong.get("type") == "pong":
                print("✅ Heartbeat working - Flutter will be happy!")
            elif pong.get("type") == "error":
                print(f"❌ Heartbeat failed: {pong}")
                print("❌ Flutter app will show connection errors")
            
            # Test message (Flutter sends this)
            message = {
                "type": "send_message",
                "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
                "content": "Hello from Flutter",
                "sender_id": "flutter_user"
            }
            
            await websocket.send(json.dumps(message))
            print(f"📤 Sent message: {message}")
            
            response = await websocket.recv()
            msg_response = json.loads(response)
            
            if msg_response.get("type") == "message_received":
                print("✅ Message working - Flutter chat will work!")
            else:
                print(f"❌ Message failed: {msg_response}")
            
            print("\n🎉 Frontend integration test completed!")
            
    except Exception as e:
        print(f"❌ Frontend test failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_frontend_integration())
'''
    
    with open("test_frontend_integration.py", "w") as f:
        f.write(frontend_test)
    
    print("✅ Created test_frontend_integration.py")

def main():
    print("="*80)
    print("🔧 PRODUCTION WEBSOCKET BACKEND FIX")
    print("="*80)
    
    # Step 1: Check dependencies
    if not check_dependencies():
        print("❌ Cannot proceed - missing dependencies")
        return
    
    # Step 2: Backup old files
    backup_old_backend()
    
    # Step 3: Create production scripts
    create_production_startup_script()
    create_monitoring_script()
    create_frontend_test_script()
    
    print("\n" + "="*80)
    print("✅ PRODUCTION FIX COMPLETE")
    print("="*80)
    print("\n📋 NEXT STEPS:")
    print("1. Stop any running backend processes:")
    print("   python kill_backend_processes.py")
    print("\n2. Start the production backend:")
    print("   python start_production_backend.py")
    print("\n3. Monitor the backend health:")
    print("   python monitor_backend.py")
    print("\n4. Test frontend integration:")
    print("   python test_frontend_integration.py")
    print("\n5. Test with your Flutter app")
    print("\n🎯 EXPECTED RESULTS:")
    print("✅ Frontend receives: 'connection_established'")
    print("✅ Heartbeat works without conversation_id")
    print("✅ Messages work with conversation_id")
    print("✅ No more 'conversation_id is required' errors")

if __name__ == "__main__":
    main()
