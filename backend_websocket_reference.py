# Backend WebSocket Implementation Reference
# This file shows the CORRECT way to handle WebSocket connections with JWT authentication

"""
FastAPI WebSocket Server - Production Ready
Handles authentication via query parameter OR Authorization header
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, Header, status
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, Dict
import jwt
import json
from datetime import datetime

app = FastAPI(title="Gruve WebSocket API")

# ============================================================================
# CORS Configuration - CRITICAL for WebSocket connections
# ============================================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://zg7h02xx-8001.inc1.devtunnels.ms",
        "http://localhost:*",
        "*"  # Remove in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# Active WebSocket Connections Manager
# ============================================================================
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"✅ User {user_id} connected. Total connections: {len(self.active_connections)}")
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            print(f"❌ User {user_id} disconnected. Total connections: {len(self.active_connections)}")
    
    async def send_personal_message(self, message: dict, user_id: str):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_json(message)
    
    async def broadcast(self, message: dict):
        for connection in self.active_connections.values():
            await connection.send_json(message)

manager = ConnectionManager()

# ============================================================================
# JWT Token Validation
# ============================================================================
SECRET_KEY = "your-secret-key-here"  # Use environment variable in production
ALGORITHM = "HS256"

def validate_jwt_token(token: str) -> Optional[dict]:
    """
    Validate JWT token and return user data
    Returns None if token is invalid or expired
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        # Check expiration
        exp = payload.get("exp")
        if exp and datetime.utcnow().timestamp() > exp:
            print(f"❌ Token expired: {exp}")
            return None
        
        user_id = payload.get("sub")
        if not user_id:
            print("❌ Token missing 'sub' claim")
            return None
        
        print(f"✅ Token validated for user: {user_id}")
        return {
            "user_id": user_id,
            "exp": exp,
            "iat": payload.get("iat"),
            "type": payload.get("type")
        }
    
    except jwt.ExpiredSignatureError:
        print("❌ Token expired (ExpiredSignatureError)")
        return None
    except jwt.InvalidTokenError as e:
        print(f"❌ Invalid token: {e}")
        return None
    except Exception as e:
        print(f"❌ Token validation error: {e}")
        return None

# ============================================================================
# WebSocket Endpoint - PRODUCTION READY
# ============================================================================
@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None),  # Accept token from query string
    authorization: Optional[str] = Header(None)  # Accept token from header
):
    """
    WebSocket endpoint with flexible authentication
    Accepts token from either:
    1. Query parameter: /ws?token=<jwt>
    2. Authorization header: Bearer <jwt>
    """
    
    print("\n" + "="*80)
    print("🔌 NEW WEBSOCKET CONNECTION ATTEMPT")
    print("="*80)
    
    # ========================================================================
    # STEP 1: Extract authentication token
    # ========================================================================
    auth_token = None
    auth_source = None
    
    # Try Authorization header first (preferred method)
    if authorization:
        if authorization.startswith("Bearer "):
            auth_token = authorization.replace("Bearer ", "").strip()
            auth_source = "header"
            print(f"🔑 Token from Authorization header: {auth_token[:20]}...")
        else:
            print(f"⚠️ Invalid Authorization header format: {authorization[:50]}")
    
    # Fallback to query parameter
    if not auth_token and token:
        auth_token = token.strip()
        auth_source = "query"
        print(f"🔑 Token from query parameter: {auth_token[:20]}...")
    
    # ========================================================================
    # STEP 2: Accept WebSocket connection BEFORE validation
    # CRITICAL: Must accept() before any async operations or validation
    # ========================================================================
    await websocket.accept()
    print("✅ WebSocket connection accepted")
    
    # ========================================================================
    # STEP 3: Validate authentication
    # ========================================================================
    if not auth_token:
        print("❌ No authentication token provided")
        await websocket.close(code=1008, reason="Missing authentication token")
        return
    
    print(f"🔍 Validating token from {auth_source}...")
    user_data = validate_jwt_token(auth_token)
    
    if not user_data:
        print("❌ Token validation failed")
        await websocket.close(code=1008, reason="Invalid or expired token")
        return
    
    user_id = user_data["user_id"]
    print(f"✅ User authenticated: {user_id}")
    
    # ========================================================================
    # STEP 4: Register connection
    # ========================================================================
    manager.active_connections[user_id] = websocket
    print(f"📊 Total active connections: {len(manager.active_connections)}")
    
    # Send connection confirmation
    await websocket.send_json({
        "type": "connection_established",
        "user_id": user_id,
        "timestamp": datetime.utcnow().isoformat(),
        "message": "WebSocket connection successful"
    })
    
    # ========================================================================
    # STEP 5: Message handling loop
    # ========================================================================
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            print(f"📨 Received from {user_id}: {data[:100]}")
            
            try:
                message = json.loads(data)
                message_type = message.get("type")
                
                # Handle different message types
                if message_type == "ping":
                    # Respond to heartbeat
                    await websocket.send_json({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    })
                    print(f"💓 Heartbeat from {user_id}")
                
                elif message_type == "message":
                    # Handle chat message
                    conversation_id = message.get("conversation_id")
                    content = message.get("content")
                    
                    print(f"💬 Message in conversation {conversation_id}: {content}")
                    
                    # Echo back or process message
                    await websocket.send_json({
                        "type": "message_received",
                        "conversation_id": conversation_id,
                        "timestamp": datetime.utcnow().isoformat(),
                        "status": "delivered"
                    })
                
                else:
                    print(f"⚠️ Unknown message type: {message_type}")
                    await websocket.send_json({
                        "type": "error",
                        "message": f"Unknown message type: {message_type}"
                    })
            
            except json.JSONDecodeError:
                print(f"❌ Invalid JSON from {user_id}")
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON format"
                })
    
    # ========================================================================
    # STEP 6: Handle disconnection
    # ========================================================================
    except WebSocketDisconnect:
        print(f"🔌 User {user_id} disconnected normally")
        manager.disconnect(user_id)
    
    except Exception as e:
        print(f"❌ Error in WebSocket connection for {user_id}: {e}")
        manager.disconnect(user_id)
        try:
            await websocket.close(code=1011, reason="Internal server error")
        except:
            pass

# ============================================================================
# Health Check Endpoint
# ============================================================================
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "active_connections": len(manager.active_connections),
        "timestamp": datetime.utcnow().isoformat()
    }

# ============================================================================
# WebSocket Status Endpoint
# ============================================================================
@app.get("/ws/status")
async def websocket_status():
    return {
        "active_connections": len(manager.active_connections),
        "connected_users": list(manager.active_connections.keys()),
        "timestamp": datetime.utcnow().isoformat()
    }

# ============================================================================
# Run Server
# ============================================================================
if __name__ == "__main__":
    import uvicorn
    
    print("\n" + "="*80)
    print("🚀 Starting Gruve WebSocket Server")
    print("="*80)
    print("📍 WebSocket endpoint: ws://localhost:8001/ws")
    print("🔑 Authentication: Query parameter OR Authorization header")
    print("💡 Test with: wscat -c 'ws://localhost:8001/ws?token=YOUR_TOKEN'")
    print("="*80 + "\n")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_level="info",
        access_log=True
    )

# ============================================================================
# TESTING COMMANDS
# ============================================================================
"""
# Install dependencies
pip install fastapi uvicorn python-jose[cryptography] websockets

# Run server
python websocket_server.py

# Test with wscat (install: npm install -g wscat)
wscat -c "ws://localhost:8001/ws?token=YOUR_JWT_TOKEN"

# Test with curl
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8001/ws

# Send test message
{"type": "ping", "timestamp": 1234567890}
{"type": "message", "conversation_id": "123", "content": "Hello"}
"""

# ============================================================================
# COMMON ISSUES & SOLUTIONS
# ============================================================================
"""
1. 403 Forbidden Error:
   - Ensure websocket.accept() is called BEFORE any validation
   - Check CORS configuration includes WebSocket origin
   - Verify token is valid and not expired

2. Connection Timeout:
   - Check firewall/network settings
   - Verify port 8001 is accessible
   - Check DevTunnels is forwarding correctly

3. Token Validation Fails:
   - Verify SECRET_KEY matches token generation
   - Check token expiration time
   - Ensure token format is correct (3 parts separated by dots)

4. CORS Issues:
   - Add client origin to allow_origins
   - Enable allow_credentials=True
   - Check Origin header matches allowed origins
"""
