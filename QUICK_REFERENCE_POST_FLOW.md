# Quick Reference: Post Share/Upload Flow

## 🎯 Key Components

### 1. Share Button (share_post_screen.dart)
```dart
// State
bool _isSharing = false;

// Handler
void _handleShare() async {
  if (_isSharing) return; // Duplicate prevention
  setState(() => _isSharing = true);
  
  // Navigate back
  Navigator.of(context).pop();
  
  // Schedule upload
  PostShareFlowBridge.scheduleShareUploadAfterReturningHome(
    caption: caption,
    mediaPath: mediaPath,
  );
}

// UI
GestureDetector(
  onTap: _isSharing ? null : _handleShare,
  child: _isSharing 
    ? CircularProgressIndicator() 
    : Text("Share"),
)
```

### 2. Bridge Callbacks (post_share_flow_bridge.dart)
```dart
// Registered by HomeScreen
static Function(bool isVideo)? onShareStartProcessing;
static Function()? onShareUploadError;
static Function(bool isVideo)? onShowSuccessSnackbar;

// Called by bridge
notifyShareStartProcessing(isVideo);  // Shows processing dialog
notifyPostCreated(isVideo: isVideo);  // Refreshes feed + snackbar
```

### 3. Home Screen Setup (home_screen.dart)
```dart
// In initState()
PostShareFlowBridge.onShareStartProcessing = (isVideo) {
  _startVideoProcessing(isVideo);
};

PostShareFlowBridge.onShowSuccessSnackbar = (isVideo) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isVideo ? 'Video posted successfully' : 'Photo posted successfully',
      ),
      backgroundColor: Colors.green,
    ),
  );
};

PostShareFlowBridge.onShareUploadError = () {
  // Cleanup and show error
};
```

### 4. Processing Dialog (processing_dialog.dart)
```dart
ProcessingDialog(
  progress: progress,
  isVideo: isVideo,  // true for video, false for image
  onCancel: () { /* cleanup */ },
)
```

## 🔄 Complete Flow

```
1. User taps Share
   → _handleShare() called
   → _isSharing = true (prevents duplicates)
   → Button shows loading spinner

2. Navigate back to Home
   → PostShareFlowBridge.scheduleShareUploadAfterReturningHome()

3. Next frame on Home
   → onShareStartProcessing(isVideo) called
   → _startVideoProcessing(isVideo)
   → ProcessingDialog appears

4. Upload starts
   → PostService.createPost()
   → Progress: 0% → 100%

5. Upload completes
   → notifyPostCreated(isVideo: isVideo)
   → VideoFeedController.initVideos(refresh: true)
   → Feed refreshes with new post

6. Success feedback
   → onShowSuccessSnackbar(isVideo)
   → Shows "Video/Photo posted successfully"
   → ProcessingDialog closes

7. Done
   → New post visible at top of feed
   → No manual refresh needed
```

## 🎨 Snackbar Messages

| Event | Message | Color | Duration |
|-------|---------|-------|----------|
| Video Success | "Video posted successfully" | Green | 2s |
| Image Success | "Photo posted successfully" | Green | 2s |
| Upload Error | "Upload failed. Check your connection or try again." | Red | 3s |

## 🛡️ Error Handling

```dart
try {
  await PostService().createPost(...);
  await notifyPostCreated(isVideo: isVideo);
} catch (e) {
  onShareUploadError?.call();
  // Shows error snackbar
  // Cleans up processing dialog
}
```

## 📱 Media Type Detection

```dart
static bool _isVideoPath(String path) {
  return path.toLowerCase().endsWith('.mp4') ||
      path.toLowerCase().endsWith('.mov') ||
      path.toLowerCase().endsWith('.avi');
}
```

## ⚡ Performance Tips

1. **Minimal Rebuilds**: Only Share button rebuilds during loading
2. **Smooth Animations**: 150ms delay for visual feedback
3. **Efficient Feed Updates**: Uses ValueNotifier pattern
4. **Memory Safe**: Proper cleanup on errors and disposal

## 🧪 Testing Commands

```dart
// Test duplicate prevention
debugPrint("🔥 SHARE CLICKED");
if (_isSharing) return; // Should prevent

// Test media type detection
final isVideo = _isVideoPath(mediaPath);
debugPrint("🎥 Media type: ${isVideo ? 'VIDEO' : 'IMAGE'}");

// Test feed refresh
await _videoControllerRef!.initVideos(refresh: true);
debugPrint("✅ Feed refreshed");
```

## 🔍 Debug Logs

Key logs to watch:
```
🔥 SHARE CLICKED
🚀 [Bridge] Upload start: 🎥 VIDEO / 🖼️ IMAGE
📁 [Bridge] Path: /path/to/media
✅ [Bridge] Video/Photo upload completed
🔔 [Bridge] Post created notification finished
🔄 [Bridge] Refreshing feed to show new post...
✅ [Bridge] Feed refreshed - new post should be visible
```

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `share_post_screen.dart` | Share button with duplicate prevention |
| `post_share_flow_bridge.dart` | Coordinates upload flow |
| `home_screen.dart` | Registers callbacks, shows dialogs |
| `processing_dialog.dart` | Universal upload progress UI |
| `video_feed_controller.dart` | Manages feed refresh |
| `post_service.dart` | API calls for upload |

## 💡 Common Issues

**Issue**: Share button can be tapped multiple times  
**Fix**: Check `if (_isSharing) return;` at start of handler

**Issue**: No snackbar after image upload  
**Fix**: Ensure `onShowSuccessSnackbar` callback is registered

**Issue**: Feed doesn't update  
**Fix**: Verify `VideoFeedController.initVideos(refresh: true)` is called

**Issue**: Wrong processing message  
**Fix**: Check `isVideo` flag is passed correctly through chain

## 🚀 Quick Start

To add a new upload type:
1. Update `_isVideoPath()` to detect new extension
2. Add new message to `onShowSuccessSnackbar`
3. Update `ProcessingDialog` title/message if needed

That's it! The flow handles the rest automatically.
