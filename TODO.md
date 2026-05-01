# Performance & Loader Fix Plan

## Phase 1: Theme & Color System (Priority: HIGH)

- [x] 1.1 Create centralized loader colors in theme/constants
- [x] 1.2 Update DynamicLoader to accept custom color
- [x] 1.3 Fix LoadingButton to use dynamic loader color
- [x] 1.4 Add loader color to main theme

## Phase 2: Shimmer Loading (Priority: HIGH)

- [x] 2.1 Check & add shimmer package to pubspec.yaml
- [x] 2.2 Create ShimmerLoadingWidget (reusable skeleton)
- [x] 2.3 Update ProfileSkeleton to use shimmer
- [x] 2.4 Add shimmer to other loading screens

## Phase 3: Performance Optimizations (Priority: MEDIUM)

- [x] 3.1 Add image preloading for profile images
- [x] 3.2 Optimize CachedNetworkImage parameters
- [x] 3.3 Add lazy loading for lists
- [x] 3.4 Implement proper pagination

## Phase 4: Smooth Flow Improvements (Priority: LOW)

- [x] 4.1 Add smooth page transitions
- [x] 4.2 Implement cache-first data loading
- [x] 4.3 Add pull-to-refresh optimizations

## Phase 5: Additional Shimmer Enhancements (COMPLETED)

- [x] 5.1 Refactor DynamicLoader with optional color & size parameters
- [x] 5.2 Create AppLoaderColors for centralized loader theme
- [x] 5.3 Create ProfileShimmer widget (safe approach)
- [x] 5.4 Create PostGridShimmer widget (safe approach)
- [x] 5.5 Create StoryListShimmer widget (safe approach)

## Phase 6: Flutter Analyzer Fixes (IN PROGRESS)

### TASK 1: Production Issues - print() statements

- [x] 6.1.1 Fixed dynamic_loader.dart
- [x] 6.1.2 Partially fixed video_options_sheet.dart (removed excessive logs)
- [ ] 6.1.3 Fix blocked_screen.dart print statements
- [ ] 6.1.4 Fix highlight_create_controller.dart print statements
- [ ] 6.1.5 Fix story_service.dart print statements

### TASK 2: Deprecated Code - .withOpacity()

- [x] 6.2.1 Fixed dynamic_loader.dart (.withOpacity → .withValues)
- [ ] 6.2.2 Fix remaining files with .withOpacity()

### TASK 3: VideoPlayerController.network deprecated

- [x] 6.3.1 Fixed profile_post_detail_screen.dart
- [ ] 6.3.2 Fix other files using VideoPlayerController.network

### TASK 4: Async Context Bugs (mounted checks)

- [ ] 6.4.1 Add mounted checks after async operations
