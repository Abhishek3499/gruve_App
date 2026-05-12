# CONVERSATION-BASED WEBSOCKET MIGRATION GUIDE

## 🎯 Architecture Change

### OLD: Heartbeat-Only Architecture
```python
# ❌ OLD: Heartbeat without conversation_id
{
  "type": "heartbeat",
  "action": "ping",
  "timestamp": 1778588282849
}
```

### NEW: Unified Conversation-Based Architecture
```python
# ✅ NEW: ALL events require conversation_id
{
  "type": "heartbeat",
  "action": "ping",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1778588282849
}
```

---

## 📋 Files Changed

### ✅ Created
- `backend_unified_websocket.py` - New unified backend
- `CONVERSATION_WEBSOCKET_MIGRATION.md` - This guide

### ✅ Updated
- `lib/core/socket/socket_reconnect_manager.dart` - Added conversation context
- `lib/features/message/screen/chat_screen.dart` - Set/clear conversation context

### ❌ Deleted
- `lib/core/socket/heartbeat_test.dart` - Old heartbeat-only test
- `backend_websocket_event_handler.py` - Old event handler
- `backend_production_websocket.py` - Old production backend

---

## 🚀 Implementation Details

### 1. Backend: Unified Event Schema

All events now inherit from `BaseEvent` with required `conversation_id`:

```python
class BaseEvent(BaseModel):
    """Base event with required conversation_id"""
    conversation_id: str
    timestamp: Optional[int] = None
    
    @field_validator('conversation_id')
    @classmethod
    def validate_conversation_id(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('conversation_id is required and cannot be empty')
        try:
            uuid.UUID(v)
        except ValueError:
            raise ValueError('conversation_id must be a valid UUID string')
        return v
```

### 2. Frontend: Conversation Context Injection

Socket manager now tracks current conversation:

```dart
class SocketReconnectManager {
  String? _currentConversationId;
  
  /// Set conversation context (called when entering chat)
  void setConversationContext(String? conversationId) {
    _currentConversationId = conversationId;
  }
  
  /// Clear conversation context (called when leaving chat)
  void clearConversationContext() {
    _currentConversationId = null;
  }
  
  void _sendHeartbeat() {
    // Skip heartbeat if no conversation context
    if (_currentConversationId == null) return;
    
    final heartbeatData = {
      'type': 'heartbeat',
      'action': 'ping',
      'conversation_id': _currentConversationId!, // ✅ Auto-injected
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    sendMessage(heartbeatData);
  }
}
```

### 3. Chat Screen Integration

```dart
class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    
    // ✅ Set conversation context when entering chat
    final socketManager = SocketReconnectManager();
    socketManager.setConversationContext(_conversationId);
  }
  
  @override
  void dispose() {
    // ✅ Clear conversation context when leaving chat
    final socketManager = SocketReconnectManager();
    socketManager.clearConversationContext();
    
    super.dispose();
  }
}
```

---

## 📊 Event Types

### 1. Heartbeat
```json
{
  "type": "heartbeat",
  "action": "ping",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1778588282849
}
```

**Response:**
```json
{
  "type": "pong",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1778588282850,
  "response_time": 15
}
```

### 2. Send Message
```json
{
  "type": "send_message",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Hello!",
  "sender_id": "user123",
  "timestamp": 1778588282849
}
```

**Response:**
```json
{
  "type": "message_received",
  "message_id": "abc-123-def-456",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": "user123",
  "content": "Hello!",
  "timestamp": 1778588282850,
  "status": "delivered"
}
```

### 3. Typing Indicator
```json
{
  "type": "typing",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "is_typing": true
}
```

**Response:**
```json
{
  "type": "typing_ack",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "is_typing": true,
  "timestamp": 1778588282850
}
```

### 4. Read Receipt
```json
{
  "type": "read_receipt",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "message_id": "abc-123-def-456"
}
```

**Response:**
```json
{
  "type": "read_ack",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "message_id": "abc-123-def-456",
  "timestamp": 1778588282850
}
```

---

## 🔧 Error Handling

### Missing conversation_id
```json
{
  "type": "error",
  "error": "missing_conversation_id",
  "detail": "conversation_id is required and must be UUID string.",
  "details": {
    "event_type": "heartbeat"
  },
  "timestamp": 1778588282850
}
```

### Invalid UUID
```json
{
  "type": "error",
  "error": "validation_error",
  "detail": "conversation_id must be a valid UUID string",
  "timestamp": 1778588282850
}
```

### Unknown Event Type
```json
{
  "type": "error",
  "error": "unknown_event",
  "detail": "Unknown type: invalid_type",
  "timestamp": 1778588282850
}
```

---

## 🧪 Testing

### Test 1: Heartbeat with conversation_id
```python
import asyncio
import websockets
import json

async def test_heartbeat():
    async with websockets.connect("ws://localhost:8001/ws?token=test") as ws:
        # Wait for connection
        await ws.recv()
        
        # Send heartbeat WITH conversation_id
        await ws.send(json.dumps({
            "type": "heartbeat",
            "action": "ping",
            "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
            "timestamp": 1778588282849
        }))
        
        # Receive pong
        response = json.loads(await ws.recv())
        assert response["type"] == "pong"
        assert response["conversation_id"] == "550e8400-e29b-41d4-a716-446655440000"
        print("✅ Heartbeat test passed")

asyncio.run(test_heartbeat())
```

### Test 2: Heartbeat without conversation_id (should fail)
```python
async def test_heartbeat_no_conv():
    async with websockets.connect("ws://localhost:8001/ws?token=test") as ws:
        await ws.recv()
        
        # Send heartbeat WITHOUT conversation_id
        await ws.send(json.dumps({
            "type": "heartbeat",
            "action": "ping",
            "timestamp": 1778588282849
        }))
        
        # Receive error
        response = json.loads(await ws.recv())
        assert response["type"] == "error"
        assert response["error"] == "missing_conversation_id"
        print("✅ Error handling test passed")

asyncio.run(test_heartbeat_no_conv())
```

---

## 📈 Migration Steps

### Step 1: Stop Old Backend
```bash
# Windows
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *websocket*"

# Linux/Mac
pkill -f "python.*websocket"
```

### Step 2: Start New Unified Backend
```bash
python backend_unified_websocket.py
```

**Expected output:**
```
======================================================================
🚀 Gruve WebSocket - UNIFIED ARCHITECTURE
======================================================================
📍 Endpoint: ws://localhost:8001/ws
🔐 ALL events require conversation_id (UUID)

📝 Event Types:
  • heartbeat: {'type': 'heartbeat', 'action': 'ping', 'conversation_id': 'UUID'}
  • send_message: {'type': 'send_message', 'conversation_id': 'UUID', 'content': '...'}
  • typing: {'type': 'typing', 'conversation_id': 'UUID', 'is_typing': true}
  • read_receipt: {'type': 'read_receipt', 'conversation_id': 'UUID', 'message_id': 'UUID'}
======================================================================
```

### Step 3: Test Flutter App
1. Open app
2. Navigate to any chat screen
3. Verify logs show:
   ```
   [ChatScreen] 🔌 WebSocket conversation context set: 550e8400-...
   [SOCKET] HEARTBEAT_SENT: sent=true conversationId=550e8400-...
   [SOCKET] HEARTBEAT_RECEIVED: responseTime=15ms
   ```
4. Leave chat screen
5. Verify logs show:
   ```
   [ChatScreen] 🔌 WebSocket conversation context cleared
   [SOCKET] HEARTBEAT_SKIPPED: reason=no_conversation_context
   ```

### Step 4: Verify Backend Logs
```
[INFO] [ROUTE] type=heartbeat user=user123 conv=550e8400-...
[INFO] [HEARTBEAT] user=user123 conv=550e8400-... rt=15ms
[INFO] [ROUTE] type=send_message user=user123 conv=550e8400-...
[INFO] [MESSAGE] user=user123 conv=550e8400-... msg=abc-123-...
```

---

## ✅ Benefits

### 1. Unified Schema
- All events use same validation logic
- Consistent error handling
- Easier to maintain

### 2. Conversation Context
- Heartbeat tied to active conversation
- No unnecessary heartbeats when not in chat
- Better resource management

### 3. Clean Architecture
- Single source of truth for conversation_id
- Automatic injection via context
- No manual conversation_id passing

### 4. Better Error Messages
- Clear validation errors
- Specific error codes
- Detailed error context

---

## 🔍 Troubleshooting

### Issue: "conversation_id is required" error

**Cause**: Heartbeat sent without conversation context

**Fix**: Ensure chat screen sets conversation context:
```dart
@override
void initState() {
  super.initState();
  SocketReconnectManager().setConversationContext(_conversationId);
}
```

### Issue: Heartbeat not sent

**Cause**: No conversation context set

**Check**:
```dart
// Should see this log when entering chat:
[ChatScreen] 🔌 WebSocket conversation context set: 550e8400-...

// Should see this log when heartbeat sent:
[SOCKET] HEARTBEAT_SENT: sent=true conversationId=550e8400-...
```

**Fix**: Verify `setConversationContext()` is called in `initState()`

### Issue: Invalid UUID error

**Cause**: conversation_id is not valid UUID format

**Fix**: Ensure conversation_id is valid UUID:
```dart
// ✅ Valid UUID
"550e8400-e29b-41d4-a716-446655440000"

// ❌ Invalid UUID
"invalid-id"
"123"
""
```

---

## 📚 Code Examples

### Example 1: Send Message with Auto-Injected conversation_id
```dart
// In chat screen - conversation context already set
final socketService = SocketService();
socketService.sendMessage(
  conversationId: _conversationId, // Explicit for messages
  message: "Hello!",
);

// Heartbeat automatically uses same conversation_id
// No need to pass it manually!
```

### Example 2: Multiple Conversations
```dart
// User switches between chats
class ChatScreen1 extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    SocketReconnectManager().setConversationContext("conv-1");
    // Heartbeat now uses "conv-1"
  }
}

class ChatScreen2 extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    SocketReconnectManager().setConversationContext("conv-2");
    // Heartbeat now uses "conv-2"
  }
}
```

### Example 3: Leave Chat (Stop Heartbeat)
```dart
@override
void dispose() {
  SocketReconnectManager().clearConversationContext();
  // Heartbeat stops automatically
  super.dispose();
}
```

---

## 🎓 Key Learnings

1. **Unified validation** prevents inconsistent behavior
2. **Context injection** reduces boilerplate code
3. **Conversation-scoped heartbeat** improves resource efficiency
4. **Clear error messages** speed up debugging
5. **Single backend** simplifies deployment

---

## 📞 Support

If you encounter issues:

1. Check backend logs: `python backend_unified_websocket.py`
2. Check Flutter logs: Look for `[SOCKET]` and `[ChatScreen]` tags
3. Verify conversation_id is valid UUID
4. Ensure conversation context is set/cleared properly
5. Test with provided test scripts

---

## ✨ Summary

**Before:**
- Heartbeat: No conversation_id ❌
- Messages: Requires conversation_id ✅
- Inconsistent validation ❌

**After:**
- Heartbeat: Requires conversation_id ✅
- Messages: Requires conversation_id ✅
- Unified validation ✅
- Auto-injection via context ✅
- Clean architecture ✅

**Migration complete! 🎉**
