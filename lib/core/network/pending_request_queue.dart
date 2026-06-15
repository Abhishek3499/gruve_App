      import 'dart:async';
import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/token_refresh_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Manages pending requests during token refresh to prevent race conditions
class PendingRequestQueue {
  final TokenRefreshService _refreshService;
  final List<_QueuedRequest> _queue = [];

  PendingRequestQueue(this._refreshService);

  /// Executes a request, queuing it if refresh is in progress
  Future<Response<T>> execute<T>(
    Future<Response<T>> Function() requestFunction,
    RequestOptions options,
  ) async {
    // If refresh is in progress, queue the request
    if (_refreshService.isRefreshing) {
      AppLogger.d('⏳ [PendingQueue] Refresh in progress, queuing request: ${options.path}');
      return _queueRequest(requestFunction, options);
    }

    // Execute immediately if no refresh in progress
    return requestFunction();
  }

  /// Queues a request and waits for refresh completion
  Future<Response<T>> _queueRequest<T>(
    Future<Response<T>> Function() requestFunction,
    RequestOptions options,
  ) async {
    final completer = Completer<Response<T>>();
    final queuedRequest = _QueuedRequest<T>(
      requestFunction: requestFunction,
      completer: completer,
      options: options,
    );

    _queue.add(queuedRequest);

    try {
      // Wait for refresh to complete
      await _refreshService.queueRequestUntilRefresh();

      // Execute the queued request
      AppLogger.d('▶️ [PendingQueue] Executing queued request: ${options.path}');
      final response = await requestFunction();
      completer.complete(response);

    } catch (e) {
      AppLogger.d('❌ [PendingQueue] Queued request failed: ${options.path}, error: $e');
      completer.completeError(e);
    } finally {
      // Remove from queue
      _queue.remove(queuedRequest);
    }

    return completer.future;
  }

  /// Cancels all pending requests (useful during logout)
  void cancelAll([String? reason]) {
    AppLogger.d('🛑 [PendingQueue] Cancelling all pending requests. Reason: $reason');
    for (final queued in _queue) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(
          DioException(
            requestOptions: queued.options,
            type: DioExceptionType.cancel,
            message: reason ?? 'Request cancelled due to logout',
          ),
        );
      }
    }
    _queue.clear();
  }

  /// Gets the current queue size
  int get queueSize => _queue.length;

  /// Checks if there are pending requests
  bool get hasPendingRequests => _queue.isNotEmpty;
}

/// Represents a queued request
class _QueuedRequest<T> {
  final Future<Response<T>> Function() requestFunction;
  final Completer<Response<T>> completer;
  final RequestOptions options;

  _QueuedRequest({
    required this.requestFunction,
    required this.completer,
    required this.options,
  });
}