import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/loading/load_state.dart';

/// Generic loading state manager for consistent UI states
/// Replaces scattered CircularProgressIndicator usage
class LoadingStateManager<T> {
  LoadState _state = LoadState.firstLoad;
  T? _data;
  String? _error;
  final DateTime _createdAt = DateTime.now();

  // Getters
  LoadState get state => _state;
  T? get data => _data;
  String? get error => _error;
  DateTime get createdAt => _createdAt;

  // Convenience getters
  bool get isLoading => _state.isLoading;
  bool get isIdle => _state == LoadState.idle;
  bool get isFirstLoad => _state == LoadState.firstLoad;
  bool get isRefreshing => _state == LoadState.refreshing;
  bool get isPaginating => _state == LoadState.paginating;
  bool get isButtonLoading => _state == LoadState.buttonLoading;
  bool get isBackgroundLoading => _state == LoadState.backgroundLoad;
  bool get hasError => _state == LoadState.error;
  bool get hasData => _data != null;

  /// Set loading state
  void setLoading(LoadState state, {T? data, String? error}) {
    if (_state != state) {
      _state = state;
      if (data != null) _data = data;
      if (error != null) _error = error;
      debugPrint('⏳ [LoadingState] State changed: ${state.description}');
    }
  }

  /// Set first load state
  void setFirstLoad() => setLoading(LoadState.firstLoad);

  /// Set idle state with data
  void setIdle(T data) => setLoading(LoadState.idle, data: data);

  /// Set refreshing state
  void setRefreshing() => setLoading(LoadState.refreshing);

  /// Set paginating state
  void setPaginating() => setLoading(LoadState.paginating);

  /// Set button loading state
  void setButtonLoading() => setLoading(LoadState.buttonLoading);

  /// Set background loading state
  void setBackgroundLoading() => setLoading(LoadState.backgroundLoad);

  /// Set error state
  void setError(String error) => setLoading(LoadState.error, error: error);

  /// Reset state
  void reset() {
    _state = LoadState.firstLoad;
    _data = null;
    _error = null;
    debugPrint('🔄 [LoadingState] State reset');
  }

  /// Add data during pagination
  void addData(List<T> newData) {
    if (_data is List<T>) {
      final currentList = _data as List<T>;
      _data = [...currentList, ...newData] as T;
      debugPrint('➕ [LoadingState] Added ${newData.length} items to existing data');
    }
  }

  /// Update data during background refresh
  void updateData(T newData) {
    _data = newData;
    debugPrint('🔄 [LoadingState] Updated data in background');
  }

  /// Get state duration
  Duration get stateDuration => DateTime.now().difference(_createdAt);

  @override
  String toString() => 'LoadingStateManager(state: $_state, hasData: $hasData, hasError: $hasError)';
}

/// Extension for easy state checking in widgets
extension LoadingStateWidgetExtension on LoadingStateManager {
  /// Returns appropriate widget based on state
  Widget buildWidget({
    required Widget Function() firstLoadWidget,
    required Widget Function() contentWidget,
    Widget Function()? refreshingWidget,
    Widget Function()? paginatingWidget,
    Widget Function()? buttonLoadingWidget,
    Widget Function()? errorWidget,
  }) {
    switch (state) {
      case LoadState.firstLoad:
        return firstLoadWidget();
      case LoadState.idle:
        return contentWidget();
      case LoadState.refreshing:
        return refreshingWidget?.call() ?? contentWidget();
      case LoadState.paginating:
        return paginatingWidget?.call() ?? contentWidget();
      case LoadState.buttonLoading:
        return buttonLoadingWidget?.call() ?? contentWidget();
      case LoadState.backgroundLoad:
        return contentWidget(); // Silent background update
      case LoadState.error:
        return errorWidget?.call() ?? _DefaultErrorWidget(error: error);
    }
  }
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final String? error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'Something went wrong',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
