import 'package:flutter/material.dart';

/// Guards near-end scroll pagination: threshold check + debounce so one fling
/// does not fire dozens of load-more calls.
class PaginationScrollTrigger {
  PaginationScrollTrigger({
    this.threshold = 200,
    this.debounce = const Duration(milliseconds: 250),
  });

  final double threshold;
  final Duration debounce;

  DateTime? _lastTriggerAt;

  void reset() {
    _lastTriggerAt = null;
  }

  bool shouldLoadMore(
    ScrollController controller, {
    required bool isLoading,
    required bool hasMore,
  }) {
    if (isLoading || !hasMore) return false;
    if (!controller.hasClients) return false;

    final position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) return false;
    if (position.pixels < position.maxScrollExtent - threshold) return false;

    final now = DateTime.now();
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < debounce) {
      return false;
    }

    _lastTriggerAt = now;
    return true;
  }

  bool shouldLoadMoreFromMetrics(
    ScrollMetrics metrics, {
    required bool isLoading,
    required bool hasMore,
  }) {
    if (isLoading || !hasMore) return false;
    if (!metrics.hasPixels || !metrics.hasContentDimensions) return false;
    if (metrics.pixels < metrics.maxScrollExtent - threshold) return false;

    final now = DateTime.now();
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < debounce) {
      return false;
    }

    _lastTriggerAt = now;
    return true;
  }
}
