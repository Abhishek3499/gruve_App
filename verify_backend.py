#!/usr/bin/env python3
"""
Quick Backend Verification Script
Tests if backend_websocket_event_handler.py is running and responding correctly
"""

import asyncio
import websockets
import json
import sys
from datetime import datetime

# Test configuration
BACKEND_URL = "ws://zg7h02xx-8001.inc1.devtunnels.ms/ws"
TEST_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0X3VzZXIiLCJleHAiOjk5OTk5OTk5OTl9.test"  # Dummy token

async def test_backend():
    print("=" * 80)
    print("🔍 Backend Verification Test")
    print("=" * 80)
    print(f"📡 Testing: {BACKEND_URL}")
    print()
    
    try:
        # Connect to WebSocket
        print("🔌 Connecting to backend...")
        uri = f"{BACKEND_URL}?token={TEST_TOKEN}"
        
        async with websockets.connect(uri) as websocket:
            print("✅ Connected successfully!")
            print()
            
            # Wait for connection message
            print("⏳ Waiting for connection message...")
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                data = json.loads(message)
                print(f"📨 Received: {json.dumps(data, indent=2)}")
                
                if data.get('type') == 'connection_established':
                    print("✅ NEW backend detected (event handler)")
                elif data.get('type') == 'connected':
                    print("⚠️  OLD backend detected (requires conversation_id)")
                else:
                    print(f"⚠️  Unknown connection type: {data.get('type')}")
                print()
            except asyncio.TimeoutError:
                print("⏰ No connection message received (timeout)")
                print()
            
            # Test 1: Send heartbeat (should NOT require conversation_id)
            print("=" * 80)
            print("TEST 1: Heartbeat (NO conversation_id)")
            print("=" * 80)
            
            heartbeat = {
                "type": "heartbeat",
                "action": "ping",
                "timestamp": int(datetime.utcnow().timestamp() * 1000)
            }
            
            print(f"📤 Sending: {json.dumps(heartbeat, indent=2)}")
            await websocket.send(json.dumps(heartbeat))
            
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                response_data = json.loads(response)
                print(f"📨 Received: {json.dumps(response_data, indent=2)}")
                
                if response_data.get('type') == 'pong':
                    print("✅ PASS: Heartbeat works without conversation_id")
                    print(f"   Response time: {response_data.get('response_time')}ms")
                elif response_data.get('type') == 'error':
                    print("❌ FAIL: Backend requires conversation_id for heartbeat")
                    print(f"   Error: {response_data.get('message')}")
                    print("   👉 You're connected to the OLD backend!")
                else:
                    print(f"⚠️  Unexpected response type: {response_data.get('type')}")
                print()
            except asyncio.TimeoutError:
                print("⏰ No response received (timeout)")
                print()
            
            # Test 2: Send message (SHOULD require conversation_id)
            print("=" * 80)
            print("TEST 2: Message (WITH conversation_id)")
            print("=" * 80)
            
            message_event = {
                "type": "send_message",
                "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
                "content": "Test message",
                "sender_id": "test_user",
                "timestamp": int(datetime.utcnow().timestamp() * 1000)
            }
            
            print(f"📤 Sending: {json.dumps(message_event, indent=2)}")
            await websocket.send(json.dumps(message_event))
            
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                response_data = json.loads(response)
                print(f"📨 Received: {json.dumps(response_data, indent=2)}")
                
                if response_data.get('type') == 'message_received':
                    print("✅ PASS: Message sent successfully")
                    print(f"   Message ID: {response_data.get('message_id')}")
                elif response_data.get('type') == 'error':
                    print("❌ FAIL: Message validation error")
                    print(f"   Error: {response_data.get('message')}")
                else:
                    print(f"⚠️  Unexpected response type: {response_data.get('type')}")
                print()
            except asyncio.TimeoutError:
                print("⏰ No response received (timeout)")
                print()
            
            # Test 3: Send heartbeat without conversation_id (should work)
            print("=" * 80)
            print("TEST 3: Verify heartbeat still works")
            print("=" * 80)
            
            heartbeat2 = {
                "type": "heartbeat",
                "action": "ping",
                "timestamp": int(datetime.utcnow().timestamp() * 1000)
            }
            
            print(f"📤 Sending: {json.dumps(heartbeat2, indent=2)}")
            await websocket.send(json.dumps(heartbeat2))
            
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                response_data = json.loads(response)
                print(f"📨 Received: {json.dumps(response_data, indent=2)}")
                
                if response_data.get('type') == 'pong':
                    print("✅ PASS: Heartbeat still works")
                else:
                    print(f"❌ FAIL: Unexpected response: {response_data.get('type')}")
                print()
            except asyncio.TimeoutError:
                print("⏰ No response received (timeout)")
                print()
            
            print("=" * 80)
            print("🎉 Backend verification complete!")
            print("=" * 80)
            
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Connection failed: Invalid status code {e.status_code}")
        print("   👉 Check if backend is running")
        print("   👉 Verify authentication token")
        sys.exit(1)
    except websockets.exceptions.WebSocketException as e:
        print(f"❌ WebSocket error: {e}")
        print("   👉 Check if backend is running on correct port")
        print("   👉 Verify URL is correct")
        sys.exit(1)
    except ConnectionRefusedError:
        print("❌ Connection refused")
        print("   👉 Backend is not running!")
        print("   👉 Start backend: python backend_websocket_event_handler.py")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    print()
    asyncio.run(test_backend())
    print()
