#!/usr/bin/env python3
"""
Production Fix Verification Test
Tests all fixes to ensure they work correctly
"""

import asyncio
import websockets
import json
import time
import sys

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_test(name):
    print(f"\n{Colors.BLUE}🧪 TEST: {name}{Colors.END}")

def print_pass(message):
    print(f"{Colors.GREEN}✅ PASS: {message}{Colors.END}")

def print_fail(message):
    print(f"{Colors.RED}❌ FAIL: {message}{Colors.END}")

def print_info(message):
    print(f"{Colors.YELLOW}ℹ️  INFO: {message}{Colors.END}")

async def test_heartbeat_no_conversation_id():
    """Test 1: Heartbeat should work WITHOUT conversation_id"""
    print_test("Heartbeat without conversation_id")
    
    try:
        async with websockets.connect("ws://localhost:8001/ws?token=test_token") as ws:
            # Wait for connection message
            conn_msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
            conn_data = json.loads(conn_msg)
            
            if conn_data.get('type') == 'connection_established':
                print_pass("Connection established")
            else:
                print_fail(f"Unexpected connection message: {conn_data}")
                return False
            
            # Send heartbeat WITHOUT conversation_id
            heartbeat = {
                'type': 'heartbeat',
                'action': 'ping',
                'timestamp': int(time.time() * 1000)
            }
            
            await ws.send(json.dumps(heartbeat))
            print_info(f"Sent: {heartbeat}")
            
            # Wait for pong response
            response = await asyncio.wait_for(ws.recv(), timeout=2.0)
            pong = json.loads(response)
            
            print_info(f"Received: {pong}")
            
            if pong.get('type') == 'pong':
                print_pass("Heartbeat working - received pong")
                print_info(f"Response time: {pong.get('response_time')}ms")
                return True
            elif pong.get('type') == 'error':
                print_fail(f"Heartbeat failed with error: {pong.get('message')}")
                return False
            else:
                print_fail(f"Unexpected response: {pong}")
                return False
    
    except asyncio.TimeoutError:
        print_fail("Timeout waiting for response")
        return False
    except Exception as e:
        print_fail(f"Error: {e}")
        return False

async def test_message_requires_conversation_id():
    """Test 2: Message should REQUIRE conversation_id"""
    print_test("Message validation (requires conversation_id)")
    
    try:
        async with websockets.connect("ws://localhost:8001/ws?token=test_token") as ws:
            # Wait for connection
            await ws.recv()
            
            # Test 2a: Send message WITHOUT conversation_id (should fail)
            print_info("Test 2a: Message without conversation_id (should fail)")
            invalid_message = {
                'type': 'send_message',
                'content': 'Hello',
                'sender_id': 'user123'
            }
            
            await ws.send(json.dumps(invalid_message))
            response = await asyncio.wait_for(ws.recv(), timeout=2.0)
            error = json.loads(response)
            
            if error.get('type') == 'error':
                print_pass("Correctly rejected message without conversation_id")
            else:
                print_fail("Should have rejected message without conversation_id")
                return False
            
            # Test 2b: Send message WITH conversation_id (should succeed)
            print_info("Test 2b: Message with conversation_id (should succeed)")
            valid_message = {
                'type': 'send_message',
                'conversation_id': '550e8400-e29b-41d4-a716-446655440000',
                'content': 'Hello',
                'sender_id': 'user123'
            }
            
            await ws.send(json.dumps(valid_message))
            response = await asyncio.wait_for(ws.recv(), timeout=2.0)
            result = json.loads(response)
            
            if result.get('type') == 'message_received':
                print_pass("Message with conversation_id accepted")
                print_info(f"Message ID: {result.get('message_id')}")
                return True
            else:
                print_fail(f"Unexpected response: {result}")
                return False
    
    except Exception as e:
        print_fail(f"Error: {e}")
        return False

async def test_event_routing():
    """Test 3: Event routing happens BEFORE validation"""
    print_test("Event routing architecture")
    
    try:
        async with websockets.connect("ws://localhost:8001/ws?token=test_token") as ws:
            await ws.recv()
            
            # Send multiple event types rapidly
            events = [
                {'type': 'heartbeat', 'action': 'ping', 'timestamp': int(time.time() * 1000)},
                {'type': 'send_message', 'conversation_id': '550e8400-e29b-41d4-a716-446655440000', 
                 'content': 'Test', 'sender_id': 'user123'},
                {'type': 'heartbeat', 'action': 'ping', 'timestamp': int(time.time() * 1000)},
            ]
            
            for event in events:
                await ws.send(json.dumps(event))
            
            # Receive all responses
            responses = []
            for _ in range(len(events)):
                response = await asyncio.wait_for(ws.recv(), timeout=2.0)
                responses.append(json.loads(response))
            
            # Verify responses
            pong_count = sum(1 for r in responses if r.get('type') == 'pong')
            message_count = sum(1 for r in responses if r.get('type') == 'message_received')
            
            if pong_count == 2 and message_count == 1:
                print_pass("Event routing working correctly")
                print_info(f"Received {pong_count} pongs and {message_count} message confirmations")
                return True
            else:
                print_fail(f"Unexpected response counts: {pong_count} pongs, {message_count} messages")
                return False
    
    except Exception as e:
        print_fail(f"Error: {e}")
        return False

async def test_backend_health():
    """Test 4: Backend health endpoint"""
    print_test("Backend health check")
    
    try:
        import requests
        response = requests.get("http://localhost:8001/health", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print_pass("Health endpoint responding")
            print_info(f"Status: {data.get('status')}")
            print_info(f"Active connections: {data.get('connections')}")
            return True
        else:
            print_fail(f"Health check failed: {response.status_code}")
            return False
    
    except Exception as e:
        print_fail(f"Error: {e}")
        return False

async def run_all_tests():
    """Run all tests and report results"""
    print("\n" + "=" * 60)
    print("  🧪 PRODUCTION FIX VERIFICATION TESTS")
    print("=" * 60)
    
    tests = [
        ("Backend Health", test_backend_health),
        ("Heartbeat (no conversation_id)", test_heartbeat_no_conversation_id),
        ("Message Validation", test_message_requires_conversation_id),
        ("Event Routing", test_event_routing),
    ]
    
    results = []
    
    for name, test_func in tests:
        try:
            result = await test_func()
            results.append((name, result))
        except Exception as e:
            print_fail(f"Test crashed: {e}")
            results.append((name, False))
        
        await asyncio.sleep(0.5)  # Brief pause between tests
    
    # Print summary
    print("\n" + "=" * 60)
    print("  📊 TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = f"{Colors.GREEN}✅ PASS{Colors.END}" if result else f"{Colors.RED}❌ FAIL{Colors.END}"
        print(f"{status} - {name}")
    
    print("\n" + "=" * 60)
    print(f"  Results: {passed}/{total} tests passed")
    print("=" * 60)
    
    if passed == total:
        print(f"\n{Colors.GREEN}🎉 ALL TESTS PASSED - Production fixes working!{Colors.END}\n")
        return 0
    else:
        print(f"\n{Colors.RED}⚠️  SOME TESTS FAILED - Check backend configuration{Colors.END}\n")
        return 1

if __name__ == "__main__":
    try:
        exit_code = asyncio.run(run_all_tests())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\n👋 Tests interrupted by user")
        sys.exit(1)
