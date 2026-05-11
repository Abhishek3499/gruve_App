/// Loading state enumeration for proper UI state management
enum LoadState {
  /// Initial load - show skeleton, no content yet
  firstLoad,
  
  /// Refreshing existing content - show subtle indicator
  refreshing,
  
  /// Loading more data (pagination) - show bottom shimmer
  paginating,
  
  /// Button action in progress - show button spinner
  buttonLoading,
  
  /// Background refresh - no UI change, silent update
  backgroundLoad,
  
  /// All done - show content
  idle,
  
  /// Error state - show error UI
  error,
}

/// Extension for easier state checking
extension LoadStateExtension on LoadState {
  /// Check if currently loading (any form)
  bool get isLoading => [
    LoadState.firstLoad,
    LoadState.refreshing,
    LoadState.paginating,
    LoadState.buttonLoading,
  ].contains(this);

  /// Check if should show loading indicator
  bool get showLoader => [
    LoadState.firstLoad,
    LoadState.refreshing,
    LoadState.paginating,
    LoadState.buttonLoading,
  ].contains(this);

  /// Check if should show skeleton
  bool get showSkeleton => this == LoadState.firstLoad;

  /// Check if should show content
  bool get showContent => this == LoadState.idle;

  /// Check if should show error
  bool get showError => this == LoadState.error;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case LoadState.firstLoad:
        return 'Loading content...';
      case LoadState.refreshing:
        return 'Refreshing...';
      case LoadState.paginating:
        return 'Loading more...';
      case LoadState.buttonLoading:
        return 'Processing...';
      case LoadState.backgroundLoad:
        return 'Updating...';
      case LoadState.idle:
        return 'Ready';
      case LoadState.error:
        return 'Error occurred';
    }
  }
}
