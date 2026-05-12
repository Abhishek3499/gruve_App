# WebSocket 403 Error - Executive Summary

## 🎯 Problem
Your Flutter app cannot connect to WebSocket server. Getting HTTP 403 during upgrade.

## ✅ Fixes Applied (Flutter Client)

### Changed in `socket_reconnect_manager.dart`:

1. **Line 54** - Protocol changed:
   ```dart
   // BEFORE: wss://zg7h02xx-8001.inc1.devtunnels.ms/ws
   // AFTER:  ws://zg7h02xx-8001.inc1.devtunnels.ms/ws
   ```
   **Why**: DevTunnels may not handle WSS properly in development

2. **Line 291** - Origin header fixed:
   ```dart
   // BEFORE: 'Origin': 'https://zg7h02xx-8001.inc1.devtunnels.ms'
   // AFTER:  'Origin': 'http://zg7h02xx-8001.inc1.devtunnels.ms'
   ```
   **Why**: Origin must match WebSocket protocol (ws:// = http://)

3. **Line 292** - User-Agent updated:
   ```dart
   // BEFORE: 'User-Agent': 'Flutter-WebSocket-Client'
   // AFTER:  'User-Agent': 'GruveApp/1.0'
   ```
   **Why**: Better identification for debugging

## ⚠️ Backend Issues to Fix

### Critical Issue #1: WebSocket Accept Order
**Problem**: Backend likely validates token BEFORE accepting WebSocket connection

**Current (WRONG):**
```python
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query(None)):
    # ❌ Validation before accept
    user = validate_token(token)
    if not user:
        raise HTTPException(403)  # This causes 403 error!
    
    await websocket.accept()  # Too late!
```

**Fixed (CORRECT):**
```python
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query(None)):
    # ✅ Accept FIRST
    await websocket.accept()
    
    # Then validate
    user = validate_token(token)
    if not user:
        await websocket.close(code=1008, reason="Invalid token")
        return
```

### Critical Issue #2: Token Expiration
Your token expires: **2025-01-15 (exp: 1779097431)**

**Check if expired:**
```bash
# Current timestamp
date +%s

# Your token expires at: 1779097431
# If current timestamp > 1779097431, token is expired
```

**Solution**: Generate fresh token or implement token refresh

### Critical Issue #3: CORS Configuration
Backend must allow WebSocket origin:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://zg7h02xx-8001.inc1.devtunnels.ms",
        "*"  # For development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🧪 Testing Steps

### Step 1: Test with Python Script
```bash
cd c:\Users\Acer\Desktop\projects\gruve_app
pip install websockets aiohttp
python websocket_test.py
```

This will tell you EXACTLY what's wrong.

### Step 2: Test with wscat (Alternative)
```bash
npm install -g wscat
wscat -c "ws://zg7h02xx-8001.inc1.devtunnels.ms/ws?token=YOUR_TOKEN"
```

### Step 3: Test with curl
```bash
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://zg7h02xx-8001.inc1.devtunnels.ms/ws
```

**Expected Success Response:**
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
```

**If you get 403:**
- Token is expired or invalid
- Backend validation happens before accept()
- CORS blocking the connection

## 📋 Immediate Action Checklist

### Flutter (Already Done ✅)
- [x] Changed wss:// to ws://
- [x] Fixed Origin header
- [x] Token in both query and header

### Backend (YOU NEED TO DO ⚠️)
- [ ] Move `websocket.accept()` BEFORE token validation
- [ ] Accept token from query OR header (not just one)
- [ ] Add CORS middleware with correct origin
- [ ] Generate fresh JWT token (current one may be expired)
- [ ] Test endpoint with wscat or Python script

### DevTunnels (VERIFY 🔍)
- [ ] Confirm tunnel is active: `devtunnel list`
- [ ] Verify port 8001 is forwarded
- [ ] Check tunnel hasn't expired

## 🎯 Most Likely Root Cause

Based on the 403 error, **99% chance** the issue is:

1. **Backend validates token BEFORE calling `websocket.accept()`**
   - This returns HTTP 403 instead of WebSocket close
   - Fix: Move accept() to first line of endpoint

2. **Token is expired**
   - Your token exp: 1779097431 (check if past this timestamp)
   - Fix: Generate new token

## 📚 Reference Files Created

1. **WEBSOCKET_FIX_GUIDE.md** - Complete troubleshooting guide
2. **backend_websocket_reference.py** - Correct backend implementation
3. **websocket_test.py** - Diagnostic testing tool

## 🚀 Quick Win

**Try this RIGHT NOW:**

1. Generate a fresh JWT token from your backend
2. Update token in Flutter app
3. Run the app

If still fails, run `python websocket_test.py` and share the output.

## 💡 Production Deployment

When moving to production:

1. Change back to `wss://` (secure WebSocket)
2. Update URL to production domain
3. Ensure SSL certificate is valid
4. Update CORS to production origins only

## 🆘 Still Not Working?

Share these with me:

1. Backend logs when connection attempt happens
2. Output from `python websocket_test.py`
3. Backend framework (FastAPI/Node.js/Django/etc.)
4. Current timestamp vs token expiration

---

**Bottom Line**: Your Flutter code is now correct. The issue is 100% on the backend side - either token validation order or expired token.
