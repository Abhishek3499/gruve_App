# SendMessage Flow - Debugging Guide

## 🔍 Quick Log Reference

### Normal Successful Flow (WebSocket)
```
[ChatScreen] 📤 SEND FLOW START
[ChatScreen] 📝 Step 1: Local message appended
[ChatScreen] 🌐 Step 2: Starting backend send
[ChatScreen] 🔄 Backend send: Trying WebSocket first
[ChatScreen] 📡 WebSocket send attempt start
[SocketService] 🚀 Attempting to send via WebSocket
[SocketService] ✅ MESSAGE QUEUED FOR DELIVERY
[ChatScreen] ✅ WebSocket send SUCCESS
[ChatScreen] ✅ Step 3: Backend send SUCCESS
[ChatScreen] 🏁 SEND FLOW COMPLETE
```

### WebSocket Timeout → REST Fallback
```
[ChatScreen] 📤 SEND FLOW START
[ChatScreen] 📝 Step 1: Local message appended
[ChatScreen] 🌐 Step 2: Starting backend send
[ChatScreen] ⏱️ WebSocket send TIMEOUT after 3s
[ChatScreen] 🔄 WebSocket failed, using REST fallback
[ChatScreen] 🌐 REST API send start
[MessageController] 🚀 REST send START
[MessageController] 🔑 Fetching current user ID
[MessageController] 🌐 Calling MessageService.sendMessage
[MessageService] 📤 POST /conversations/{id}/messages/
[MessageService] 📊 Send message response status=201
[MessageController] ✅ REST send SUCCESS
[ChatScreen] ✅ Step 3: Backend send SUCCESS
[ChatScreen] 🏁 SEND FLOW COMPLETE
```

### Complete Failure
```
[ChatScreen] 📤 SEND FLOW START
[ChatScreen] 📝 Step 1: Local message appended
[ChatScreen] 🌐 Step 2: Starting backend send
[ChatScreen] ⏱️ WebSocket send TIMEOUT after 3s
[ChatScreen] 🔄 WebSocket failed, using REST fallback
[MessageController] ❌ REST send FAILED: [error]
[ChatScreen] ❌ Step 3: Backend send FAILED
[ChatScreen] 🏁 SEND FLOW COMPLETE
```

## 🚨 Troubleshooting

### Issue: "Logs stop after Step 1"
**Problem**: Backend send not executing
**Check**: 
- Is `_sendToBackend()` being called?
- Any exceptions in try/catch?
- Check for early returns

### Issue: "WebSocket always times out"
**Problem**: WebSocket not connected
**Check**:
- `[SocketService] ⚠️ WEBSOCKET NOT CONNECTED`
- Socket connection state
- Token authentication
- Network connectivity

### Issue: "REST fallback not triggering"
**Problem**: WebSocket send not returning false
**Check**:
- WebSocket timeout logs
- Return value from `_tryWebSocketSend()`
- Exception handling

### Issue: "Messages disappear on reload"
**Problem**: Backend persistence failing
**Check**:
- REST API response status
- `[MessageController] ✅ REST send SUCCESS` log
- Database persistence
- Message ID (should change from local-* to server ID)

## 📊 Log Emoji Legend

- 📤 = Send flow start
- 📝 = Local operation
- 🌐 = Network operation
- 🔄 = Retry/fallback
- 📡 = WebSocket operation
- 🚀 = Starting operation
- ✅ = Success
- ❌ = Failure
- ⚠️ = Warning
- ⏱️ = Timeout
- 🏁 = Flow complete
- 🔑 = Authentication
- 👤 = User data
- 💾 = Data persistence

## 🎯 Key Checkpoints

### Checkpoint 1: Local Append
```
[ChatScreen] 📝 Step 1: Local message appended id=local-XXXXX
```
✅ Message should appear in UI immediately

### Checkpoint 2: Backend Send Start
```
[ChatScreen] 🌐 Step 2: Starting backend send...
```
✅ Backend send initiated

### Checkpoint 3: WebSocket Attempt
```
[ChatScreen] 📡 WebSocket send attempt start
[SocketService] 🚀 Attempting to send via WebSocket...
```
✅ WebSocket send attempted

### Checkpoint 4: WebSocket Result
```
[ChatScreen] ✅ WebSocket send SUCCESS
OR
[ChatScreen] ⏱️ WebSocket send TIMEOUT after 3s
```
✅ WebSocket result determined

### Checkpoint 5: REST Fallback (if needed)
```
[ChatScreen] 🔄 WebSocket failed, using REST fallback...
[MessageController] 🚀 REST send START
```
✅ REST fallback triggered

### Checkpoint 6: Backend Persistence
```
[MessageController] ✅ REST send SUCCESS: message ID=msg-XXXXX
```
✅ Message persisted to backend

### Checkpoint 7: Flow Complete
```
[ChatScreen] 🏁 SEND FLOW COMPLETE
```
✅ Send flow finished

## 🔧 Debug Commands

### Check if logs are present
```bash
# Search for send flow start
grep "SEND FLOW START" logs.txt

# Check for completion
grep "SEND FLOW COMPLETE" logs.txt

# Find failures
grep "FAILED" logs.txt

# Check WebSocket status
grep "WebSocket" logs.txt

# Check REST fallback
grep "REST fallback" logs.txt
```

## 📈 Performance Metrics

### Normal WebSocket Send
- Local append: < 10ms
- WebSocket send: < 100ms
- Total: < 200ms

### REST Fallback
- Local append: < 10ms
- WebSocket timeout: 3000ms
- REST API call: 200-1000ms
- Total: 3200-4000ms

### Timeout Limits
- WebSocket timeout: 3 seconds
- Overall send timeout: 5 seconds
- Maximum execution time: 5 seconds

## ✅ Success Indicators

1. ✅ Local message appears instantly
2. ✅ "SEND FLOW COMPLETE" log present
3. ✅ Either WebSocket SUCCESS or REST SUCCESS
4. ✅ Message persists after app restart
5. ✅ No error shown to user

## ❌ Failure Indicators

1. ❌ Logs stop after Step 1
2. ❌ No "SEND FLOW COMPLETE" log
3. ❌ Both WebSocket and REST fail
4. ❌ Message disappears on reload
5. ❌ Error snackbar shown to user

## 🎓 Understanding the Flow

### Why Optimistic Updates?
- Instant UI feedback
- Better user experience
- Perceived performance

### Why WebSocket First?
- Faster delivery
- Realtime updates
- Lower latency

### Why REST Fallback?
- Guaranteed persistence
- Works when WebSocket down
- Authenticated endpoint

### Why Timeouts?
- Prevent infinite hangs
- Fail fast
- Better error handling

## 📞 Support

If issues persist:
1. Collect full logs from send flow
2. Check network connectivity
3. Verify backend API status
4. Test WebSocket connection
5. Review error messages
