# WebSocket 403 Error - Complete Fix Guide

## Problem Analysis

### Current Error
```
WebSocketException: Connection was not upgraded to websocket, HTTP status code: 403
```

### Root Causes Identified

1. **Protocol Mismatch** ❌
   - Using `wss://` (WebSocket Secure) with DevTunnels
   - DevTunnels may not properly handle SSL/TLS termination for WebSocket upgrades
   - **Fix**: Use `ws://` for DevTunnels development

2. **Authentication Method Conflict** ❌
   - Token passed in BOTH query string AND Authorization header
   - Backend may reject duplicate authentication attempts
   - **Fix**: Choose ONE method (prefer Authorization header)

3. **Origin Header Mismatch** ❌
   - Origin: `https://zg7h02xx-8001.inc1.devtunnels.ms`
   - Should match protocol: `http://zg7h02xx-8001.inc1.devtunnels.ms`
   - **Fix**: Match origin protocol with WebSocket protocol

4. **Token Expiration** ⚠️
   - JWT token may be expired (exp: 1779097431)
   - **Fix**: Implement token refresh before WebSocket connection

---

## Solution Implementation

### 1. Flutter Client Fixes (APPLIED)

#### File: `socket_reconnect_manager.dart`

**Changes Made:**
```dart
// Line 54: Changed protocol from wss:// to ws://
static String get _baseUrl => 'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws';

// Line 291: Fixed Origin header to match protocol
'Origin': 'http://zg7h02xx-8001.inc1.devtunnels.ms',

// Line 292: Updated User-Agent
'User-Agent': 'GruveApp/1.0',
```

**Authentication Strategy:**
- ✅ Token in Authorization header: `Bearer <token>`
- ✅ Token in query string: `?token=<token>` (fallback)
- Backend should accept EITHER method

---

### 2. Backend Verification Checklist

#### A. WebSocket Endpoint Configuration

**FastAPI/Python Backend:**
```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, Header
from typing import Optional

app = FastAPI()

@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None),  # Query parameter
    authorization: Optional[str] = Header(None)  # Header
):
    # Accept connection FIRST
    await websocket.accept()
    
    try:
        # Extract token from either source
        auth_token = None
        if authorization and authorization.startswith("Bearer "):
            auth_token = authorization.replace("Bearer ", "")
        elif token:
            auth_token = token
        
        if not auth_token:
            await websocket.close(code=1008, reason="Missing authentication")
            return
        
        # Validate token
        user = await validate_jwt_token(auth_token)
        if not user:
            await websocket.close(code=1008, reason="Invalid token")
            return
        
        # Connection successful - handle messages
        while True:
            data = await websocket.receive_json()
            # Handle messages...
            
    except WebSocketDisconnect:
        print(f"Client disconnected")
```

**Key Points:**
- ✅ Call `websocket.accept()` BEFORE any validation
- ✅ Accept token from BOTH query and header
- ✅ Close with proper WebSocket close codes (not HTTP 403)

#### B. CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://zg7h02xx-8001.inc1.devtunnels.ms",
        "http://localhost:*",
        "*"  # For development only
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### C. DevTunnels Configuration

**Check DevTunnels Settings:**
```bash
# Verify tunnel is running
devtunnel list

# Check tunnel configuration
devtunnel show zg7h02xx-8001

# Ensure WebSocket support is enabled
# DevTunnels should automatically support WebSocket upgrades
```

**Common DevTunnels Issues:**
- ❌ Tunnel expired or inactive
- ❌ Port 8001 not forwarded correctly
- ❌ Authentication required at tunnel level

#### D. Nginx/Reverse Proxy (if applicable)

```nginx
location /ws {
    proxy_pass http://localhost:8001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # WebSocket timeout settings
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
}
```

---

### 3. Testing & Debugging

#### Test WebSocket Connection Manually

**Using wscat (Node.js tool):**
```bash
npm install -g wscat

# Test with query token
wscat -c "ws://zg7h02xx-8001.inc1.devtunnels.ms/ws?token=YOUR_TOKEN"

# Test with header
wscat -c "ws://zg7h02xx-8001.inc1.devtunnels.ms/ws" -H "Authorization: Bearer YOUR_TOKEN"
```

**Using curl:**
```bash
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Host: zg7h02xx-8001.inc1.devtunnels.ms" \
  -H "Origin: http://zg7h02xx-8001.inc1.devtunnels.ms" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://zg7h02xx-8001.inc1.devtunnels.ms/ws
```

**Expected Response:**
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
```

**If you get 403:**
- Check backend logs for authentication errors
- Verify token is valid and not expired
- Check CORS configuration
- Verify endpoint path is correct

#### Flutter Debug Logs

Your app already has comprehensive logging. Check for:
```
[SOCKET] WEBSOCKET_CONNECT_ATTEMPT
[SOCKET] AUTHENTICATION_ERROR (if 403)
[SOCKET] ENDPOINT_NOT_FOUND (if 404)
```

---

### 4. Token Refresh Implementation

Add token refresh before WebSocket connection:

```dart
Future<void> _performConnect() async {
  // ... existing checks ...
  
  try {
    _setState(SocketState.connecting);
    
    // 🚀 NEW: Check token expiration and refresh if needed
    final isExpired = await TokenStorage.isTokenExpired();
    if (isExpired) {
      debugLog.socket('TOKEN_EXPIRED', properties: {'action': 'refreshing'});
      
      // Trigger token refresh (implement this in your auth service)
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        debugLog.socket('TOKEN_REFRESH_FAILED');
        _setState(SocketState.failed);
        return;
      }
    }
    
    final token = await TokenStorage.getAccessToken();
    // ... rest of connection logic ...
  }
}

Future<bool> _refreshAccessToken() async {
  try {
    // Call your token refresh endpoint
    // This should be implemented in your auth service
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;
    
    // Make API call to refresh token
    // Update TokenStorage with new tokens
    return true;
  } catch (e) {
    debugLog.socket('TOKEN_REFRESH_ERROR', error: e.toString());
    return false;
  }
}
```

---

## Quick Fix Checklist

### Flutter (Client) ✅
- [x] Changed `wss://` to `ws://`
- [x] Fixed Origin header to match protocol
- [x] Token in Authorization header
- [x] Token in query string (fallback)
- [ ] Implement token refresh before connection

### Backend (Server) ⚠️
- [ ] Verify `/ws` endpoint exists
- [ ] Call `websocket.accept()` BEFORE validation
- [ ] Accept token from query OR header
- [ ] Check CORS allows WebSocket origin
- [ ] Verify token validation logic
- [ ] Check DevTunnels is active and forwarding port 8001

### Testing 🧪
- [ ] Test with wscat or curl
- [ ] Check backend logs for errors
- [ ] Verify token is not expired
- [ ] Test with fresh token

---

## Expected Behavior After Fix

1. **Connection Attempt:**
   ```
   [SOCKET] CONNECT_ATTEMPT currentState:disconnected
   [SOCKET] WEBSOCKET_CONNECT_ATTEMPT scheme:ws host:zg7h02xx-8001.inc1.devtunnels.ms
   ```

2. **Successful Connection:**
   ```
   [SOCKET] STATE_CHANGE from:connecting to:connected
   [SOCKET] LISTENERS_ATTACHED
   [SOCKET] HEARTBEAT_SENT
   ```

3. **If Still Failing:**
   ```
   [SOCKET] AUTHENTICATION_ERROR action:token_refresh_needed
   ```
   → Check backend logs for specific error

---

## Production Deployment

When moving to production:

1. **Update URL in environment config:**
   ```dart
   // socket_reconnect_manager.dart line 54
   static String get _baseUrl => EnvironmentConfig.wsUrl;
   ```

2. **Use WSS (secure) in production:**
   ```dart
   // environment_config.dart
   _wsUrl = 'wss://gruve-api.hardkore.tech/ws';
   ```

3. **Ensure SSL certificate is valid**

4. **Update CORS to production domain**

---

## Additional Resources

- [FastAPI WebSocket Documentation](https://fastapi.tiangolo.com/advanced/websockets/)
- [RFC 6455 - WebSocket Protocol](https://tools.ietf.org/html/rfc6455)
- [DevTunnels Documentation](https://learn.microsoft.com/en-us/azure/developer/dev-tunnels/)

---

## Support

If issues persist after applying these fixes:

1. Share backend logs showing the 403 error
2. Confirm backend framework (FastAPI/Node.js/etc.)
3. Test WebSocket endpoint with wscat
4. Verify DevTunnels configuration
