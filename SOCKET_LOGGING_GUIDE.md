# 🔌 Socket Logging & Debugging Guide

## 🚀 Quick Start

### 1. Enable Socket Logging
```dart
import 'package:gruve_app/core/socket/socket_logger.dart';

// Start logging
SocketLogger.startCapture();

// Stop logging and save to file
await SocketLogger.stopCapture();
```

### 2. Run Comprehensive Socket Test
```dart
import 'package:gruve_app/core/socket/socket_test_utility.dart';

// Run full test suite
await SocketTestUtility.startTest();
```

### 3. View Logs in UI
```dart
import 'package:gruve_app/core/socket/socket_log_viewer.dart';

// Show quick log viewer
SocketLogUtils.showQuickViewer(context);

// Show full log viewer
SocketLogUtils.showFullViewer(context);
```

## 📊 What's Fixed

### 1. Heartbeat Protocol Issue
**BEFORE (WRONG):**
```dart
sendMessage({
  'type': 'ping',  // ❌ Backend doesn't recognize this
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

**AFTER (CORRECT):**
```dart
sendMessage({
  'type': 'heartbeat',  // ✅ Backend expects this
  'action': 'ping',     // ✅ Backend expects this
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'connectionId': _connectionId,
});
```

### 2. Enhanced Message Logging
**All outgoing messages now log:**
- Message content (JSON)
- Connection state
- Send result (success/failure)
- Message size
- Timestamp

**All incoming messages now log:**
- Raw message
- Decoded message
- Message type
- Processing result
- Error details (if any)

### 3. Connection State Tracking
- State changes (disconnected → connecting → connected)
- Reconnection attempts
- Connection duration
- Error reasons

## 🔍 Debugging Your Issues

### Issue: Messages disappear after reopening chat
**Check these logs:**
```
🔌 [SOCKET DEBUG] Raw message received: {...}
📊 [SOCKET DEBUG] Decoded message: {...}
🏷️ [SOCKET DEBUG] Message type: message
✅ [SOCKET DEBUG] Message processed and forwarded to listeners
```

**What to look for:**
- Are messages being received by the socket?
- Are messages being forwarded to listeners?
- Is the message type correct?

### Issue: Heartbeat gets error response
**Check these logs:**
```
🔌 [SOCKET DEBUG] Heartbeat sent: {"type":"heartbeat","action":"ping",...}
✅ [SOCKET DEBUG] Heartbeat PONG received successfully (Response time: 45ms)
```

**What to look for:**
- Is heartbeat being sent with correct format?
- Is PONG response being received?
- What's the response time?

### Issue: RenderBox layout crashes
**Check these logs:**
```
🔄 [SOCKET DEBUG] State changed: connecting → connected
📊 [SOCKET DEBUG] Reconnect attempts: 0
🔗 [SOCKET DEBUG] Connection ID: 1234567890
```

**What to look for:**
- Are there rapid state changes?
- Are multiple reconnection attempts happening?
- Is the connection stable?

## 📱 Using the Log Viewer

### Quick Viewer (Dialog)
```dart
SocketLogUtils.showQuickViewer(context);
```
- Shows recent logs in a popup
- Quick summary and clear options
- Good for quick debugging

### Full Viewer (Screen)
```dart
SocketLogUtils.showFullViewer(context);
```
- Full-screen log viewer
- Real-time updates
- Export and test capabilities
- Auto-scroll toggle

### Log Colors
- 🔴 **Red**: Errors, failures
- 🟠 **Orange**: Warnings, unknown actions
- 🟢 **Green**: Success, connection established
- 🔵 **Blue**: Debug info
- 🟣 **Purple**: Heartbeat events
- 🟦 **Teal**: Outgoing messages
- 🟪 **Indigo**: Incoming messages

## 🧪 Running Socket Tests

### Automated Test Suite
```dart
await SocketTestUtility.startTest();
```

**Tests include:**
1. **Connection Test** - Can we connect?
2. **Heartbeat Test** - Is heartbeat working?
3. **Message Send Test** - Can we send messages?
4. **Message Receive Test** - Can we receive messages?
5. **Error Handling Test** - How are errors handled?
6. **Reconnection Test** - Does reconnection work?

### Test Results
After running tests, you'll get:
- `socket_test_report_[timestamp].json` - Full report
- Console summary with pass/fail counts
- Detailed logs for each test

## 📁 Log Files

### Socket Logs
- `socket_logs_[timestamp].txt` - All socket events
- Captured automatically when logging starts
- Includes timestamps, event types, and data

### Test Reports
- `socket_test_report_[timestamp].json` - Test results
- Includes test summary and detailed results
- Contains all logs from test session

## 🔧 Manual Debugging

### 1. Check Connection State
```dart
final manager = SocketReconnectManager();
print('State: ${manager.state.name}');
print('Connected: ${manager.isConnected}');
print('Reconnect attempts: ${manager.reconnectAttempts}');
```

### 2. Send Test Message
```dart
final success = manager.sendMessage({
  'type': 'send_message',
  'conversation_id': 'test-conversation',
  'content': 'Test message',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
print('Send result: $success');
```

### 3. Listen for Messages
```dart
manager.messages.listen((message) {
  print('Received: ${message.toString()}');
});
```

### 4. Test Heartbeat
```dart
final success = manager.sendMessage({
  'type': 'heartbeat',
  'action': 'ping',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
print('Heartbeat sent: $success');
```

## 🚨 Common Issues & Solutions

### Issue: "MESSAGE_RECEIVED type:error"
**Cause**: Backend doesn't understand message format
**Solution**: Check message structure in logs
```dart
// Check if your message format matches backend expectations
final message = {
  'type': 'send_message',  // Correct type
  'conversation_id': '123', // Required field
  'content': 'Hello',     // Required field
  'timestamp': 1234567890,  // Required field
};
```

### Issue: "Heartbeat gets error response"
**Cause**: Wrong heartbeat format (FIXED)
**Solution**: Use new heartbeat format
```dart
// New format (already implemented)
{
  'type': 'heartbeat',
  'action': 'ping',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'connectionId': _connectionId,
}
```

### Issue: "RenderBox was not laid out"
**Cause**: UI rebuilds during socket operations
**Solution**: Check for excessive setState calls
```dart
// Look for logs showing rapid state changes
🔄 [SOCKET DEBUG] State changed: connected → connecting
🔄 [SOCKET DEBUG] State changed: connecting → connected
// This indicates connection instability
```

## 📊 Performance Monitoring

### Key Metrics to Watch
1. **Heartbeat Response Time** - Should be < 1000ms
2. **Message Send Time** - Should be < 500ms
3. **Connection Stability** - Minimal state changes
4. **Error Rate** - Should be < 5%

### Monitoring Commands
```dart
// Get test statistics
final stats = SocketTestUtility.getTestStats();
print('Messages sent: ${stats['messagesSent']}');
print('Messages received: ${stats['messagesReceived']}');
print('Errors: ${stats['errorsCount']}');

// Get log summary
SocketLogger.printSummary();
```

## 🎯 Next Steps

1. **Run the test suite** to identify current issues
2. **Check heartbeat logs** to confirm the fix
3. **Monitor message flow** to see if messages are being received
4. **Export logs** for detailed analysis
5. **Fix any remaining issues** based on log findings

## 📞 Getting Help

If you're still having issues:
1. Run `SocketTestUtility.startTest()`
2. Export the test report
3. Share the logs and report
4. Describe the specific issue you're seeing

The logs will show exactly what's happening with your WebSocket connection!
