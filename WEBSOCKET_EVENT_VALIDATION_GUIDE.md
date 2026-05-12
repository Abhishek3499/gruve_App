# 🔌 WebSocket Event Validation Guide

## 🚨 **PROBLEM SOLVED**

### **Before (BROKEN):**
```
❌ Backend Error: "conversation_id is required and must be UUID string"
❌ Heartbeat events were being validated as chat messages
❌ All events required conversation_id (even heartbeat)
❌ No proper event routing architecture
```

### **After (FIXED):**
```
✅ Heartbeat events: {"type":"heartbeat","action":"ping"} → {"type":"pong"}
✅ Message events: {"type":"send_message","conversation_id":"UUID","content":"text","sender_id":"user"}
✅ Proper event routing with validation
✅ Production-level error handling
```

## 🏗️ **Architecture Overview**

### **Event Types Supported:**
1. **Heartbeat Events** - Connection health monitoring
2. **Message Events** - Chat message sending
3. **Error Events** - Error responses
4. **Legacy Events** - Backward compatibility

### **Event Routing Flow:**
```
WebSocket Message → Event Router → Handler → Response
     ↓
   Type Detection → Validation → Processing → Response
```

## 📋 **Event Specifications**

### **1. Heartbeat Event**
**Purpose:** Keep connection alive, check latency

**Request:**
```json
{
  "type": "heartbeat",
  "action": "ping",
  "timestamp": 1234567890
}
```

**Response:**
```json
{
  "type": "pong",
  "timestamp": 1234567891,
  "response_time": 45
}
```

**Validation Rules:**
- ✅ NO conversation_id required
- ✅ NO sender_id required
- ✅ Only type and action are required
- ✅ timestamp is optional

### **2. Send Message Event**
**Purpose:** Send chat messages

**Request:**
```json
{
  "type": "send_message",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Hello, world!",
  "sender_id": "user123",
  "timestamp": 1234567890
}
```

**Response:**
```json
{
  "type": "message_received",
  "message_id": "new-uuid-generated",
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": "user123",
  "content": "Hello, world!",
  "timestamp": 1234567891,
  "status": "delivered"
}
```

**Validation Rules:**
- ✅ conversation_id required (must be valid UUID)
- ✅ content required (cannot be empty)
- ✅ sender_id required
- ✅ timestamp optional

### **3. Error Event**
**Purpose:** Error responses from backend

**Response:**
```json
{
  "type": "error",
  "error": "validation_error",
  "code": "validation_error",
  "message": "conversation_id must be a valid UUID string",
  "timestamp": 1234567891,
  "details": {
    "field": "conversation_id",
    "expected": "UUID string"
  }
}
```

## 🔧 **Backend Implementation**

### **Event Handler Structure:**
```python
class WebSocketEventRouter:
    def __init__(self):
        self.event_handlers = {
            "heartbeat": self.handle_heartbeat,
            "send_message": self.handle_send_message,
            "ping": self.handle_legacy_ping,  # Legacy support
            "message": self.handle_legacy_message,  # Legacy support
        }
    
    async def route_event(self, websocket, user_id, event_data):
        event_type = event_data.get("type")
        
        if event_type not in self.event_handlers:
            return self.create_error_response(
                "unknown_event_type",
                f"Unknown event type: {event_type}"
            )
        
        handler = self.event_handlers[event_type]
        return await handler(websocket, user_id, event_data)
```

### **Heartbeat Handler:**
```python
async def handle_heartbeat(self, websocket, user_id, event_data):
    # NO conversation_id validation for heartbeat!
    heartbeat = HeartbeatEvent(**event_data)
    
    # Calculate response time
    response_time = None
    if heartbeat.timestamp:
        current_time = int(datetime.utcnow().timestamp() * 1000)
        response_time = current_time - heartbeat.timestamp
    
    # Send pong response
    return PongResponse(
        timestamp=current_time,
        response_time=response_time
    ).dict()
```

### **Message Handler:**
```python
async def handle_send_message(self, websocket, user_id, event_data):
    # STRICT validation for message events
    message = MessageEvent(**event_data)
    
    # Validate conversation_id is UUID
    try:
        uuid.UUID(message.conversation_id)
    except ValueError:
        raise ValidationError("conversation_id must be a valid UUID string")
    
    # Validate content is not empty
    if not message.content or not message.content.strip():
        raise ValidationError("content is required and cannot be empty")
    
    # Process message...
    return MessageResponse(...).dict()
```

## 📱 **Frontend Implementation**

### **Heartbeat Sending:**
```dart
void _sendHeartbeat() {
  // 🚨 PRODUCTION FIX: NO conversation_id for heartbeat!
  final heartbeatData = {
    'type': 'heartbeat',
    'action': 'ping',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  
  final sent = sendMessage(heartbeatData);
  // Handle response...
}
```

### **Message Sending:**
```dart
bool sendMessage({
  required String conversationId,
  required String message,
  String? senderId,
}) {
  // 🚨 PRODUCTION FIX: All required fields included
  final messageData = {
    'type': 'send_message',
    'conversation_id': conversationId,  // Required: UUID
    'content': message,                 // Required: non-empty
    'sender_id': senderId ?? 'current_user',  // Required
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  
  return _reconnectManager.sendMessage(messageData);
}
```

### **Response Handling:**
```dart
void _onMessageReceived(dynamic message) {
  final data = jsonDecode(message);
  
  // Handle pong response
  if (data['type'] == 'pong') {
    final responseTime = data['response_time'];
    print('✅ Heartbeat response time: ${responseTime}ms');
    return;
  }
  
  // Handle message received
  if (data['type'] == 'message_received') {
    final messageId = data['message_id'];
    final conversationId = data['conversation_id'];
    print('✅ Message delivered: ${messageId}');
    return;
  }
  
  // Handle errors
  if (data['type'] == 'error') {
    final errorCode = data['error'];
    final errorMessage = data['message'];
    print('❌ Backend error: ${errorCode} - ${errorMessage}');
    return;
  }
}
```

## 🧪 **Testing Examples**

### **Test Heartbeat:**
```bash
# Send heartbeat
wscat -c "ws://localhost:8001/ws?token=YOUR_TOKEN"
> {"type":"heartbeat","action":"ping","timestamp":1234567890}

# Expected response
< {"type":"pong","timestamp":1234567891,"response_time":45}
```

### **Test Message:**
```bash
# Send message
> {"type":"send_message","conversation_id":"550e8400-e29b-41d4-a716-446655440000","content":"Hello","sender_id":"user123"}

# Expected response
< {"type":"message_received","message_id":"new-uuid","conversation_id":"550e8400-e29b-41d4-a716-446655440000","sender_id":"user123","content":"Hello","timestamp":1234567891,"status":"delivered"}
```

### **Test Error:**
```bash
# Send invalid message (missing conversation_id)
> {"type":"send_message","content":"Hello"}

# Expected error response
< {"type":"error","error":"validation_error","code":"validation_error","message":"conversation_id is required","timestamp":1234567891}
```

## 🔄 **Legacy Support**

### **Legacy Ping → Heartbeat:**
```bash
# Legacy format (still supported)
> {"type":"ping","timestamp":1234567890}

# Automatically converted to heartbeat and handled
< {"type":"pong","timestamp":1234567891,"response_time":45}
```

### **Legacy Message → Send Message:**
```bash
# Legacy format (still supported)
> {"type":"message","conversation_id":"550e8400-e29b-41d4-a716-446655440000","content":"Hello"}

# Automatically converted to send_message and handled
< {"type":"message_received","message_id":"new-uuid","conversation_id":"550e8400-e29b-41d4-a716-446655440000","content":"Hello","timestamp":1234567891,"status":"delivered"}
```

## 🚀 **Production Benefits**

### **1. Proper Event Separation**
- Heartbeat events don't require conversation_id
- Message events have strict validation
- Clear event type boundaries

### **2. Better Error Handling**
- Structured error responses
- Detailed validation messages
- Proper error codes

### **3. Performance Optimization**
- No unnecessary validation for heartbeat
- Fast heartbeat processing
- Efficient message routing

### **4. Maintainability**
- Clear event handler structure
- Easy to add new event types
- Comprehensive logging

### **5. Backward Compatibility**
- Legacy event formats still work
- Automatic conversion to new formats
- Smooth migration path

## 🎯 **Key Fixes Applied**

1. **✅ Heartbeat Validation Fixed** - No more conversation_id requirement
2. **✅ Event Routing Implemented** - Proper handler separation
3. **✅ Validation Rules Applied** - Strict validation for messages only
4. **✅ Error Responses Standardized** - Structured error format
5. **✅ Legacy Support Added** - Backward compatibility maintained
6. **✅ Frontend Updated** - Correct event formats used
7. **✅ Production Logging** - Comprehensive debug information

## 📊 **Expected Results**

- **Heartbeat Success**: `{"type":"pong","response_time":45}`
- **Message Success**: `{"type":"message_received","status":"delivered"}`
- **Error Response**: `{"type":"error","error":"validation_error"}`
- **No More**: `"conversation_id is required"` errors for heartbeat

The WebSocket backend now properly handles heartbeat events separately from message events, eliminating the validation error you were experiencing!
