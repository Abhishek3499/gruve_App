import 'dart:async';

/// Utility for debouncing rapid actions
/// Prevents excessive API calls or rebuilds
class Debounce {
  Timer? _timer;
  final Duration duration;

  Debounce(this.duration);

  /// Execute action after delay, canceling previous calls
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if action is pending
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Utility for throttling actions
/// Limits execution to once per duration
class Throttle {
  Timer? _timer;
  final Duration duration;
  bool _isThrottled = false;

  Throttle(this.duration);

  /// Execute action immediately, then throttle subsequent calls
  void run(VoidCallback action) {
    if (_isThrottled) return;

    action();
    _isThrottled = true;

    _timer?.cancel();
    _timer = Timer(duration, () {
      _isThrottled = false;
    });
  }

  /// Cancel throttle
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isThrottled = false;
  }

  /// Check if currently throttled
  bool get isThrottled => _isThrottled;

  /// Dispose timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isThrottled = false;
  }
}

/// Factory for common debounce durations
class DebounceDurations {
  static const Duration search = Duration(milliseconds: 300);
  static const Duration button = Duration(milliseconds: 500);
  static const Duration scroll = Duration(milliseconds: 100);
  static const Duration api = Duration(milliseconds: 200);
  static const Duration navigation = Duration(milliseconds: 300);
}

/// Factory for common throttle durations
class ThrottleDurations {
  static const Duration scroll = Duration(milliseconds: 16); // 60fps
  static const Duration resize = Duration(milliseconds: 100);
  static const Duration animation = Duration(milliseconds: 16); // 60fps
}
