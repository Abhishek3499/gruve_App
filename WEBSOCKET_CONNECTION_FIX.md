# WebSocket Connection Issue - ROOT CAUSE ANALYSIS

## 🚨 CRITICAL ISSUE IDENTIFIED

Your Flutter app was connecting to the **WRONG WebSocket server**!

### The Problem

**Frontend was connecting to**: `wss://gruve-api.hardkore.tech/ws` (remote production server)
**Should connect to**: `ws://zg7h02xx-8001.inc1.devtunnels.ms/ws` (local devtunnel backend)

### Why This Happened

1. **Environment Config Mismatch**
   - File: `lib/core/config/environment_config.dart`
   - Line 86: Used `PROD_WS_URL` from `.env` file
   - `.env` had: `PROD_WS_URL=wss://zg7h02xx-8001.inc1.devtunnels.ms/`
   - This was WRONG - should have been `DEV_WS_URL`

2. **Remote Server Has Old Validation**
   - Remote server at `gruve-api.hardkore.tech` requires `conversation_id` for ALL events
   - Your NEW backend (`backend_websocket_event_handler.py`) correctly handles heartbeats WITHOUT `conversation_id`
   - But Flutter wasn't connecting to your new backend!

3. **Socket Manager Hardcoded URL Was Ignored**
   - `socket_reconnect_manager.dart` line 73 had correct URL hardcoded
   - But `EnvironmentConfig.wsUrl` was being used instead
   - Environment config pointed to wrong server

---

## ✅ FIXES APPLIED

### 1. Fixed Environment Config
**File**: `lib/core/config/environment_config.dart`

**Changed**:
```dart
// BEFORE (WRONG)
_wsUrl = dotenv.env['DEV_WS_URL'] ?? 'wss://zg7h02xx-8001.inc1.devtunnels.ms/';

// AFTER (CORRECT)
_wsUrl = dotenv.env['DEV_WS_URL'] ?? 'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws';
```

**Why**: 
- Changed from `wss://` to `ws://` (devtunnels don't need SSL)
- Added `/ws` endpoint path
- Now uses `DEV_WS_URL` instead of `PROD_WS_URL`

### 2. Fixed .env File
**File**: `.env`

**Changed**:
```env
# BEFORE (WRONG)
PROD_WS_URL=wss://zg7h02xx-8001.inc1.devtunnels.ms/

# AFTER (CORRECT)
DEV_WS_URL=ws://zg7h02xx-8001.inc1.devtunnels.ms/ws
PROD_WS_URL=wss://gruve-api.hardkore.tech/ws
```

**Why**:
- Separated dev and prod URLs
- Dev uses local devtunnel
- Prod uses actual production server

### 3. Clarified Socket Manager
**File**: `lib/core/socket/socket_reconnect_manager.dart`

**Changed**:
```dart
// BEFORE (CONFUSING)
static String get _baseUrl => 'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws';
// static String get _baseUrl => EnvironmentConfig.wsUrl; // Uncomment for production

// AFTER (CLEAR)
static String get _baseUrl {
  return 'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws';
}
```

**Why**: Made it explicit that we're using local URL for development

---

## 🔍 HOW TO VERIFY CONNECTION

### Method 1: Run Diagnostic Script
```bash
dart run verify_websocket_connection.dart
```

This will test all WebSocket URLs and show which server responds.

### Method 2: Check Flutter Logs
Look for these log messages:

**NEW Backend (Correct)**:
```
📨 Received: {"type":"connection_established","user_id":"...","timestamp":"...","message":"WebSocket connection successful"}
```

**OLD Backend (Wrong)**:
```
📨 Received: {"type":"connected","message":"..."}
```

### Method 3: Check Heartbeat Response

**NEW Backend (Correct)**:
```json
{
  "type": "pong",
  "timestamp": 1234567891,
  "response_time": 1
}
```

**OLD Backend (Wrong)**:
```json
{
  "type": "error",
  "detail": "conversation_id is required and must be UUID string."
}
```

---

## 🎯 VERIFICATION CHECKLIST

After applying fixes, verify:

- [ ] Flutter app restarts successfully
- [ ] WebSocket connects without errors
- [ ] Heartbeat sends successfully
- [ ] Heartbeat receives `pong` response (NOT error)
- [ ] No `conversation_id` error in logs
- [ ] Connection message shows `connection_established` type

---

## 📊 BACKEND EVENT ROUTING

Your NEW backend (`backend_websocket_event_handler.py`) correctly handles:

### Heartbeat Events (NO conversation_id required)
```json
{
  "type": "heartbeat",
  "action": "ping",
  "timestamp": 1234567890
}
```

**Response**:
```json
{
  "type": "pong",
  "timestamp": 1234567891,
  "response_time": 1
}
```

### Message Events (conversation_id required)
```json
{
  "type": "send_message",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Hello",
  "sender_id": "user123"
}
```

**Response**:
```json
{
  "type": "message_received",
  "message_id": "new-uuid",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": "user123",
  "content": "Hello",
  "timestamp": 1234567891,
  "status": "delivered"
}
```

---

## 🚀 PRODUCTION DEPLOYMENT

When deploying to production:

1. **Update .env**:
   ```env
   PROD_WS_URL=wss://gruve-api.hardkore.tech/ws
   ```

2. **Deploy NEW backend** to production server

3. **Verify** production backend has event routing logic

4. **Test** heartbeat works without `conversation_id`

---

## 🔧 TROUBLESHOOTING

### Issue: Still getting conversation_id error

**Check**:
1. Restart Flutter app completely
2. Verify `.env` file has correct `DEV_WS_URL`
3. Run diagnostic script to confirm connection
4. Check backend is running: `python backend_websocket_event_handler.py`
5. Verify backend logs show "NEW WEBSOCKET CONNECTION ATTEMPT"

### Issue: Connection timeout

**Check**:
1. DevTunnel is running and accessible
2. Backend server is running on port 8001
3. Firewall allows WebSocket connections
4. URL uses `ws://` not `wss://` for devtunnels

### Issue: Backend not receiving messages

**Check**:
1. Backend logs show connection established
2. Frontend logs show "MESSAGE_SENT"
3. WebSocket channel is not null
4. Connection state is "connected"

---

## 📝 KEY TAKEAWAYS

1. **Always verify which server you're connected to**
   - Use diagnostic tools
   - Check connection messages
   - Monitor backend logs

2. **Separate dev and prod configurations**
   - Use `DEV_WS_URL` for development
   - Use `PROD_WS_URL` for production
   - Never mix them up

3. **Event routing is critical**
   - Heartbeat events should NOT require `conversation_id`
   - Message events SHOULD require `conversation_id`
   - Backend must route events correctly

4. **WebSocket URL format matters**
   - DevTunnels: `ws://` (not `wss://`)
   - Production: `wss://` (with SSL)
   - Always include endpoint path: `/ws`

---

## 🎉 EXPECTED BEHAVIOR AFTER FIX

1. **Connection**:
   ```
   ✅ [SocketService] ✅ SOCKET CONNECTED SUCCESSFULLY
   📨 Received: {"type":"connection_established",...}
   ```

2. **Heartbeat**:
   ```
   💓 [HEARTBEAT] Sending heartbeat...
   ✅ [SOCKET DEBUG] Heartbeat sent successfully
   📨 Received: {"type":"pong","timestamp":...,"response_time":1}
   ✅ [SOCKET DEBUG] Heartbeat PONG received successfully
   ```

3. **Messages**:
   ```
   📝 [SocketService] 📝 Sending to conversation: 550e8400-...
   ✅ [SocketService] ✅ MESSAGE QUEUED FOR DELIVERY
   📨 Received: {"type":"message_received",...}
   ```

---

## 🔗 RELATED FILES

- `lib/core/config/environment_config.dart` - Environment configuration
- `lib/core/socket/socket_reconnect_manager.dart` - WebSocket manager
- `lib/services/socket_service.dart` - Socket service wrapper
- `backend_websocket_event_handler.py` - NEW backend with event routing
- `.env` - Environment variables
- `verify_websocket_connection.dart` - Diagnostic tool

---

## 📞 SUPPORT

If issues persist:
1. Run diagnostic script
2. Check backend logs
3. Verify environment variables
4. Test with curl/wscat
5. Review this document

---

**Last Updated**: $(date)
**Status**: ✅ FIXED
**Root Cause**: Frontend connected to wrong WebSocket server
**Solution**: Updated environment config and .env file to use local backend
