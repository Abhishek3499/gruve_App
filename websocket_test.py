#!/usr/bin/env python3
"""
WebSocket Connection Tester
Tests WebSocket endpoint with various authentication methods
"""

import asyncio
import websockets
import json
from datetime import datetime

# ============================================================================
# Configuration
# ============================================================================
WS_URL = "ws://zg7h02xx-8001.inc1.devtunnels.ms/ws"
JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmODM4Njc1OC0yYTBkLTQ0NzMtOTlhNC1iN2QyOGY2YjlmYTkiLCJpYXQiOjE3Nzg0OTI1NzEsImV4cCI6MTc3OTA5NzQzMSwidHlwIjoiYWNjZXNzIn0.gkuL2C8UltT0zzYNtw_Dd02QhxgSOwrQlCZYu7Brao8"

# ============================================================================
# Test 1: Query Parameter Authentication
# ============================================================================
async def test_query_auth():
    print("\n" + "="*80)
    print("TEST 1: WebSocket with Query Parameter Authentication")
    print("="*80)
    
    url = f"{WS_URL}?token={JWT_TOKEN}"
    print(f"📍 Connecting to: {url[:80]}...")
    
    try:
        async with websockets.connect(url) as websocket:
            print("✅ Connection established!")
            
            # Send ping
            ping_msg = {"type": "ping", "timestamp": int(datetime.utcnow().timestamp())}
            await websocket.send(json.dumps(ping_msg))
            print(f"📤 Sent: {ping_msg}")
            
            # Receive response
            response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
            print(f"📥 Received: {response}")
            
            print("✅ TEST 1 PASSED")
            return True
    
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Connection failed with status code: {e.status_code}")
        print(f"   Headers: {e.headers}")
        return False
    
    except asyncio.TimeoutError:
        print("❌ Timeout waiting for response")
        return False
    
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False

# ============================================================================
# Test 2: Header Authentication
# ============================================================================
async def test_header_auth():
    print("\n" + "="*80)
    print("TEST 2: WebSocket with Authorization Header")
    print("="*80)
    
    print(f"📍 Connecting to: {WS_URL}")
    
    try:
        headers = {
            "Authorization": f"Bearer {JWT_TOKEN}",
            "Origin": "http://zg7h02xx-8001.inc1.devtunnels.ms",
            "User-Agent": "GruveApp/1.0"
        }
        print(f"📋 Headers: {headers}")
        
        async with websockets.connect(WS_URL, extra_headers=headers) as websocket:
            print("✅ Connection established!")
            
            # Send ping
            ping_msg = {"type": "ping", "timestamp": int(datetime.utcnow().timestamp())}
            await websocket.send(json.dumps(ping_msg))
            print(f"📤 Sent: {ping_msg}")
            
            # Receive response
            response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
            print(f"📥 Received: {response}")
            
            print("✅ TEST 2 PASSED")
            return True
    
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Connection failed with status code: {e.status_code}")
        print(f"   Headers: {e.headers}")
        return False
    
    except asyncio.TimeoutError:
        print("❌ Timeout waiting for response")
        return False
    
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False

# ============================================================================
# Test 3: HTTP Upgrade Check
# ============================================================================
async def test_http_upgrade():
    print("\n" + "="*80)
    print("TEST 3: HTTP Upgrade Request")
    print("="*80)
    
    import aiohttp
    
    url = WS_URL.replace("ws://", "http://")
    print(f"📍 Testing HTTP endpoint: {url}")
    
    try:
        async with aiohttp.ClientSession() as session:
            headers = {
                "Connection": "Upgrade",
                "Upgrade": "websocket",
                "Sec-WebSocket-Version": "13",
                "Sec-WebSocket-Key": "dGhlIHNhbXBsZSBub25jZQ==",
                "Authorization": f"Bearer {JWT_TOKEN}",
                "Origin": "http://zg7h02xx-8001.inc1.devtunnels.ms"
            }
            
            async with session.get(url, headers=headers) as response:
                print(f"📊 Status Code: {response.status}")
                print(f"📋 Headers: {dict(response.headers)}")
                
                if response.status == 101:
                    print("✅ Server supports WebSocket upgrade")
                    return True
                elif response.status == 403:
                    print("❌ 403 Forbidden - Authentication issue")
                    body = await response.text()
                    print(f"   Response body: {body}")
                    return False
                elif response.status == 404:
                    print("❌ 404 Not Found - Endpoint doesn't exist")
                    return False
                else:
                    print(f"❌ Unexpected status code: {response.status}")
                    return False
    
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False

# ============================================================================
# Test 4: Token Validation
# ============================================================================
def test_token_validation():
    print("\n" + "="*80)
    print("TEST 4: JWT Token Validation")
    print("="*80)
    
    import base64
    
    try:
        # Split token
        parts = JWT_TOKEN.split('.')
        if len(parts) != 3:
            print(f"❌ Invalid token format: {len(parts)} parts (expected 3)")
            return False
        
        print(f"✅ Token has correct format (3 parts)")
        
        # Decode header
        header_padded = parts[0] + '=' * (4 - len(parts[0]) % 4)
        header = json.loads(base64.urlsafe_b64decode(header_padded))
        print(f"📋 Header: {header}")
        
        # Decode payload
        payload_padded = parts[1] + '=' * (4 - len(parts[1]) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_padded))
        print(f"📋 Payload: {payload}")
        
        # Check expiration
        exp = payload.get('exp')
        iat = payload.get('iat')
        sub = payload.get('sub')
        
        if exp:
            exp_date = datetime.fromtimestamp(exp)
            now = datetime.utcnow()
            is_expired = now > exp_date
            
            print(f"⏰ Issued at: {datetime.fromtimestamp(iat) if iat else 'N/A'}")
            print(f"⏰ Expires at: {exp_date}")
            print(f"⏰ Current time: {now}")
            print(f"⏰ Time until expiry: {exp_date - now}")
            
            if is_expired:
                print(f"❌ TOKEN IS EXPIRED!")
                return False
            else:
                print(f"✅ Token is valid (not expired)")
        
        if sub:
            print(f"👤 User ID: {sub}")
        
        print("✅ TEST 4 PASSED")
        return True
    
    except Exception as e:
        print(f"❌ Error decoding token: {e}")
        return False

# ============================================================================
# Test 5: Network Connectivity
# ============================================================================
async def test_network():
    print("\n" + "="*80)
    print("TEST 5: Network Connectivity")
    print("="*80)
    
    import aiohttp
    
    # Test HTTP endpoint
    http_url = WS_URL.replace("ws://", "http://").replace("/ws", "/health")
    print(f"📍 Testing HTTP endpoint: {http_url}")
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(http_url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                print(f"✅ HTTP connection successful: {response.status}")
                if response.status == 200:
                    body = await response.json()
                    print(f"📊 Response: {body}")
                return True
    
    except aiohttp.ClientConnectorError:
        print("❌ Cannot connect to server - check if server is running")
        return False
    
    except asyncio.TimeoutError:
        print("❌ Connection timeout - server not responding")
        return False
    
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False

# ============================================================================
# Main Test Runner
# ============================================================================
async def run_all_tests():
    print("\n" + "="*80)
    print("🧪 WEBSOCKET CONNECTION DIAGNOSTIC TOOL")
    print("="*80)
    print(f"🎯 Target: {WS_URL}")
    print(f"🔑 Token: {JWT_TOKEN[:30]}...")
    print("="*80)
    
    results = {}
    
    # Run tests
    results['token_validation'] = test_token_validation()
    results['network'] = await test_network()
    results['http_upgrade'] = await test_http_upgrade()
    results['query_auth'] = await test_query_auth()
    results['header_auth'] = await test_header_auth()
    
    # Summary
    print("\n" + "="*80)
    print("📊 TEST SUMMARY")
    print("="*80)
    
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\n📈 Results: {passed}/{total} tests passed")
    
    # Recommendations
    print("\n" + "="*80)
    print("💡 RECOMMENDATIONS")
    print("="*80)
    
    if not results['token_validation']:
        print("❌ Token is invalid or expired - generate a new token")
    
    if not results['network']:
        print("❌ Cannot reach server - check:")
        print("   1. Server is running on port 8001")
        print("   2. DevTunnels is active and forwarding")
        print("   3. Firewall allows connections")
    
    if not results['http_upgrade']:
        print("❌ HTTP upgrade failed - check:")
        print("   1. Backend accepts WebSocket upgrade")
        print("   2. CORS configuration allows origin")
        print("   3. Authentication middleware")
    
    if not results['query_auth'] and not results['header_auth']:
        print("❌ Both authentication methods failed - check:")
        print("   1. Backend accepts token from query OR header")
        print("   2. Token validation logic")
        print("   3. Backend calls websocket.accept() before validation")
    
    if passed == total:
        print("✅ All tests passed! WebSocket connection should work.")
    
    print("="*80)

# ============================================================================
# Run Tests
# ============================================================================
if __name__ == "__main__":
    try:
        asyncio.run(run_all_tests())
    except KeyboardInterrupt:
        print("\n\n⚠️ Tests interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")

"""
USAGE:
------
1. Install dependencies:
   pip install websockets aiohttp

2. Update JWT_TOKEN with your current token

3. Run tests:
   python websocket_test.py

4. Review results and follow recommendations
"""
