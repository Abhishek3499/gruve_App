#!/usr/bin/env python3
"""
Test the correct WebSocket backend implementation
"""

import asyncio
import websockets
import json
import time

async def test_websocket_backend():
    """Test the WebSocket backend with heartbeat and message events"""
    
    print("🔌 Testing WebSocket backend...")
    print("="*50)
    
    # Test both potential endpoints
    endpoints = [
        "ws://localhost:8001/ws",
        "ws://127.0.0.1:8001/ws"
    ]
    
    for endpoint in endpoints:
        print(f"\n🔍 Testing endpoint: {endpoint}")
        
        try:
            async with websockets.connect(endpoint) as websocket:
                print("✅ Connected successfully")
                
                # Wait for connection message
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Connection message: {response}")
                    
                    # Parse and check message type
                    message = json.loads(response)
                    msg_type = message.get("type")
                    
                    if msg_type == "connection_established":
                        print("✅ CORRECT: Using new backend (connection_established)")
                    elif msg_type == "connected":
                        print("❌ WRONG: Using old backend (connected)")
                    else:
                        print(f"⚠️ Unknown message type: {msg_type}")
                        
                except asyncio.TimeoutError:
                    print("⚠️ No connection message received")
                
                # Test heartbeat (should NOT require conversation_id)
                print("\n💓 Testing heartbeat...")
                heartbeat_msg = {
                    "type": "heartbeat",
                    "action": "ping", 
                    "timestamp": int(time.time() * 1000)
                }
                
                await websocket.send(json.dumps(heartbeat_msg))
                print(f"📤 Sent: {heartbeat_msg}")
                
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Response: {response}")
                    
                    message = json.loads(response)
                    if message.get("type") == "pong":
                        print("✅ Heartbeat working correctly")
                    elif message.get("type") == "error" and "conversation_id" in response:
                        print("❌ WRONG: Heartbeat incorrectly requires conversation_id")
                    else:
                        print(f"⚠️ Unexpected heartbeat response: {response}")
                        
                except asyncio.TimeoutError:
                    print("❌ No response to heartbeat")
                
                # Test message (SHOULD require conversation_id)
                print("\n💬 Testing message (valid)...")
                message_msg = {
                    "type": "send_message",
                    "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
                    "content": "Test message",
                    "sender_id": "test_user"
                }
                
                await websocket.send(json.dumps(message_msg))
                print(f"📤 Sent: {message_msg}")
                
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Response: {response}")
                    
                    message = json.loads(response)
                    if message.get("type") == "message_received":
                        print("✅ Message handling working correctly")
                    else:
                        print(f"⚠️ Unexpected message response: {response}")
                        
                except asyncio.TimeoutError:
                    print("❌ No response to message")
                
                print(f"\n✅ Tests completed for {endpoint}")
                break  # Exit if we successfully connected
                
        except Exception as e:
            print(f"❌ Failed to connect to {endpoint}: {e}")
            continue

def check_backend_file_running():
    """Check which backend file is actually running"""
    print("\n🔍 Checking which backend file is running...")
    
    import subprocess
    try:
        result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq python.exe'], 
                              capture_output=True, text=True)
        
        lines = result.stdout.split('\n')
        for line in lines:
            if 'python.exe' in line and ('uvicorn' in line or 'websocket' in line):
                print(f"🔄 Found process: {line}")
                
                # Try to get more details
                parts = line.split()
                if len(parts) >= 2:
                    pid = parts[1]
                    try:
                        # Get full command line
                        result2 = subprocess.run(['wmic', 'process', 'where', f'processid={pid}', 'get', 'commandline'], 
                                               capture_output=True, text=True)
                        print(f"📝 Command: {result2.stdout}")
                    except:
                        pass
    except:
        print("❌ Could not check running processes")

async def main():
    print("="*80)
    print("🧪 WEBSOCKET BACKEND TESTING")
    print("="*80)
    
    # Check what's currently running
    check_backend_file_running()
    
    # Test the WebSocket endpoint
    await test_websocket_backend()
    
    print("\n" + "="*80)
    print("📊 TEST SUMMARY")
    print("="*80)
    print("If you see:")
    print("✅ 'connection_established' → Your NEW backend is running")
    print("❌ 'connected' → OLD backend is still running")
    print("❌ 'conversation_id is required' for heartbeat → OLD validation active")
    print("\n🔧 To fix:")
    print("1. Run: python kill_backend_processes.py")
    print("2. Run: python backend_websocket_event_handler.py")
    print("3. Test again with: python test_correct_backend.py")

if __name__ == "__main__":
    asyncio.run(main())
