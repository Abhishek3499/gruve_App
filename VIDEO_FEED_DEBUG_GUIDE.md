# Video Feed Debug Quick Reference

## 🎥 Video Upload Debug Flow

### Step 1: Upload Initiated

```
🚀 [Bridge] Upload start: 🎥 VIDEO
📁 [Bridge] Path: /path/to/video.mp4
```

**What to check:** Verify the file path is correct and file exists

### Step 2: API Upload

```
🎥 [PostService] Type: VIDEO
📏 [PostService] Upload file size: 5120KB
🌐 [PostService] POST posts/create-post/
```

**What to check:** File size is reasonable, API endpoint is correct

### Step 3: Upload Success

```
✅ [PostService] Status: 200
📥 [PostService] Response: {success: true, ...}
🏁 [PostService] ===== VIDEO POST SUCCESS =====
```

**What to check:** Status is 200, response indicates success

### Step 4: Feed Refresh

```
🔄 [Bridge] Refreshing feed to show new post...
🔄 Refresh API Hit
📡 [PostService] Raw API response: {...}
```

**What to check:** Refresh is triggered, API is called

### Step 5: Video Detection

```
🎥 [Post.fromJson] id=123 mediaType=video url=https://...
📊 [PostService] Parsed: 1 videos, 0 images
```

**What to check:** mediaType is "video", URL is valid

### Step 6: Feed Updated

```
✅ [Bridge] Feed refreshed - new post should be visible
🎥 [VideoFeed] After filter: 1 videos, 0 images
✅ [VideoFeed] Total Posts: 1
```

**What to check:** Video count increased, total posts updated

### Step 7: Video Rendering

```
🎥 [VideoFeed] Rendering video at index 0: post_123
🔄 [VideoFeed] Initializing video at index 0
✅ [VideoFeed] Video initialized at index 0
✅ [VideoFeed] Video rendering: https://...
```

**What to check:** Video initializes successfully, renders on screen

---

## 📡 API Response Debug

### Expected Structure:

```json
{
  "data": {
    "posts": [
      {
        "id": "123",
        "media_url": "video",  // ← MUST BE PRESENT
        "media_url": "https://...",
        "caption": "...",
        "user": {...}
      }
    ]
  }
}
```

### Common Issues:

#### ❌ Missing media_url

```
🎥 [Post.fromJson] id=123 mediaType=image url=https://...video.mp4
```

**Fix:** API should return `media_url: "video"` field

#### ❌ Wrong media_url value

```
🎥 [Post.fromJson] id=123 mediaType=mp4 url=https://...
```

**Fix:** media_url should be "video" not "mp4"

#### ❌ Invalid URL

```
❌ [VideoFeed] Unsupported URL at 0: /media/video.mp4
```

**Fix:** URL must be full HTTPS URL, not relative path

---

## 🔍 Common Problems & Solutions

### Problem: Videos not appearing in feed

#### Check 1: API Response

```bash
# Look for this log:
📡 [PostService] Raw API response: {...}
```

**Action:** Verify response contains posts with `media_url: "video"`

#### Check 2: Parsing

```bash
# Look for this log:
🎥 [Post.fromJson] id=123 mediaType=video
```

**Action:** If mediaType is "image", API is not returning correct type

#### Check 3: Filtering

```bash
# Look for this log:
📊 [PostService] Parsed: 5 videos, 3 images
🎥 [VideoFeed] After filter: 5 videos, 3 images
```

**Action:** If counts don't match, videos are being filtered out

#### Check 4: Rendering

```bash
# Look for this log:
🎥 [VideoFeed] Rendering video at index 0
```

**Action:** If missing, videos aren't reaching the UI layer

---

### Problem: Feed not refreshing after upload

#### Check 1: Bridge Callback

```bash
# Look for this log:
🔄 [Bridge] Refreshing feed to show new post...
```

**Action:** If missing, PostShareFlowBridge callbacks not set

#### Check 2: Controller Reference

```bash
# Look for this log:
🔔 Bridge: Video controller reference set
```

**Action:** If missing, controller wasn't registered with bridge

#### Check 3: Refresh Execution

```bash
# Look for this log:
✅ [Bridge] Feed refreshed - new post should be visible
```

**Action:** If missing, refresh failed or was cancelled

---

### Problem: Scroll lag / jank

#### Check 1: Controller Count

```bash
# Look for this log:
✅ [VideoFeed] Video ready at 0 (total: 3)
```

**Action:** If total > 3, memory leak - controllers not being disposed

#### Check 2: Disposal

```bash
# Look for this log:
🗑️ [VideoFeed] Disposed video at index 5
```

**Action:** Should see disposal logs when scrolling away from videos

#### Check 3: Memory Warning

```bash
# Look for this log:
⚠️ [VideoFeed] Too many controllers (8)
```

**Action:** Critical - memory leak detected, restart app

---

### Problem: Videos fail to load

#### Check 1: Initialization

```bash
# Look for this log:
🔄 [VideoFeed] Initializing video at index 0
```

**Action:** If missing, video URL is invalid or unsupported

#### Check 2: Timeout

```bash
# Look for this log:
❌ [VideoFeed] Video init failed at 0: TimeoutException
```

**Action:** Network too slow or video file too large

#### Check 3: URL Validation

```bash
# Look for this log:
❌ [VideoFeed] Unsupported URL at 0: /media/video.mp4
```

**Action:** URL must be full HTTPS URL

---

## 🛠️ Debug Commands

### Enable Verbose Logging

Already enabled in debug mode - all logs use `debugPrint()`

### Check Current State

Look for these key logs on app start:

```
🏠 Home Screen initState called
🏗️ [FeedProvider] Provider initialized
📡 Initial Load API Hit
```

### Monitor Video Controllers

```
✅ [VideoFeed] Video ready at X (total: Y)
```

**Healthy:** total should be ≤ 3
**Unhealthy:** total > 3 indicates memory leak

### Track Feed Updates

```
🔄 [VideoFeed] Total Posts: X
```

**After upload:** Should increase by 1
**After refresh:** May stay same or increase

---

## 📊 Performance Metrics

### Target Metrics:

- **FPS:** 55-60 fps during scroll
- **Memory:** < 100MB for video controllers
- **Controller Count:** ≤ 3 active controllers
- **Load Time:** < 2s for video initialization

### Warning Signs:

- ⚠️ FPS drops below 30
- ⚠️ Controller count > 3
- ⚠️ Video init takes > 10s
- ⚠️ Memory usage > 200MB

---

## 🎯 Quick Test Scenarios

### Test 1: Upload Video

1. Record/select video
2. Add caption
3. Share
4. **Expected:** Video appears at top of feed within 3 seconds

### Test 2: Scroll Performance

1. Scroll through 10+ posts
2. **Expected:** Smooth 60fps, no jank
3. **Check logs:** Controller count stays ≤ 3

### Test 3: Feed Refresh

1. Pull to refresh
2. **Expected:** New posts appear at top
3. **Check logs:** "✅ Feed refreshed" appears

### Test 4: Mixed Content

1. Upload image
2. Upload video
3. **Expected:** Both appear in feed
4. **Check logs:** Correct video/image counts

---

## 🚨 Emergency Fixes

### Videos not showing after upload

```dart
// Force refresh manually
PostShareFlowBridge.notifyPostCreated();
```

### Feed stuck loading

```dart
// Reset feed state
_videoController?.initVideos(refresh: true);
```

### Memory leak (too many controllers)

```dart
// Restart app - disposal issue needs code fix
```

### Video won't play

```dart
// Check URL format
debugPrint('URL: ${post.media}');
// Should be: https://domain.com/video.mp4
// Not: /media/video.mp4
```

---

## 📝 Log Filtering

### Show only video-related logs:

Search for: `🎥`

### Show only errors:

Search for: `❌`

### Show only API calls:

Search for: `📡`

### Show only refresh events:

Search for: `🔄`

### Show only success events:

Search for: `✅`

---

## 🔗 Related Files

- **Post Model:** `lib/features/story_preview/api/create_post_api/model/post_model.dart`
- **Post Service:** `lib/features/story_preview/api/create_post_api/post_service.dart`
- **Feed Controller:** `lib/features/home/controllers/video_feed_controller.dart`
- **Feed Widget:** `lib/features/home/widgets/video_feed.dart`
- **Bridge:** `lib/features/home/post_share_flow_bridge.dart`
