import 'dart:async';
import 'package:dio/dio.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';

/// Production-grade request deduplication manager
/// Prevents duplicate in-flight requests and reduces backend stress
class RequestDeduplicationManager {
  static final RequestDeduplicationManager _instance = RequestDeduplicationManager._internal();
  factory RequestDeduplicationManager() => _instance;
  RequestDeduplicationManager._internal();

  /// Map of ongoing requests by their unique key
  final Map<String, _InFlightRequest> _inFlightRequests = {};

  /// Lock for thread-safe operations
  final Completer<void> _lock = Completer<void>()..complete();

  /// Generates a unique request key based on method, path, and parameters
  String _generateRequestKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write('${options.method}:${options.path}');
    
    // Add query parameters to key
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map<String, dynamic>.fromEntries(
        options.queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?${sortedParams.toString()}');
    }
    
    // Add request data for POST/PUT requests (only if it's simple data)
    if (options.data != null && 
        (options.method == 'POST' || options.method == 'PUT') &&
        options.data is Map) {
      final sortedData = Map<String, dynamic>.fromEntries(
        (options.data as Map<String, dynamic>).entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('#${sortedData.toString()}');
    }
    
    final key = buffer.toString();
    debugLog.network('KEYGEN', options.path, duration: Duration.zero, properties: {'key': key});
    return key;
  }

  /// Executes a request with deduplication
  /// 
  /// [requestFunction] - The actual API call function
  /// [options] - Request options for generating the unique key
  /// Returns response from the first successful request
  Future<Response<T>> execute<T>(
    Future<Response<T>> Function() requestFunction,
    RequestOptions options,
  ) async {
    final requestKey = _generateRequestKey(options);
    
    debugLog.network('EXECUTE', options.path, properties: {'key': requestKey, 'inFlightCount': _inFlightRequests.length});
    
    // Wait for any ongoing operations to complete
    await _lock.future;
    
    // Check if request is already in flight
    final existingRequest = _inFlightRequests[requestKey];
    if (existingRequest != null && !existingRequest.completer.isCompleted) {
      debugLog.network('DUPLICATE_FOUND', options.path, isDuplicate: true, properties: {'key': requestKey});
      
      try {
        // Wait for existing request to complete
        final response = await existingRequest.completer.future as Response<T>;
        debugLog.network('DUPLICATE_REUSE', options.path, fromCache: true, properties: {'key': requestKey});
        return response;
      } catch (e) {
        debugLog.network('DUPLICATE_FAILED', options.path, error: e.toString(), properties: {'key': requestKey});
        // Remove failed request and continue with new request
        _inFlightRequests.remove(requestKey);
      }
    }
    
    // Create new in-flight request
    final completer = Completer<Response<T>>();
    // If this request has no duplicate waiter, completeError below can be
    // reported by Dart as an unhandled async error. The original caller still
    // receives the thrown error from requestFunction; this listener only keeps
    // the shared duplicate future quiet when nobody else is awaiting it.
    completer.future.catchError((_) {});
    final inFlightRequest = _InFlightRequest<T>(completer, options);
    _inFlightRequests[requestKey] = inFlightRequest;
    
    debugLog.network('NEW_REQUEST', options.path, properties: {'key': requestKey, 'totalInFlight': _inFlightRequests.length});
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await requestFunction();
      final duration = stopwatch.elapsed;
      completer.complete(response);
      debugLog.network('REQUEST_SUCCESS', options.path, statusCode: response.statusCode ?? 0, duration: duration, properties: {'key': requestKey});
      return response;
    } catch (e) {
      final duration = stopwatch.elapsed;
      completer.completeError(e);
      debugLog.network('REQUEST_FAILED', options.path, error: e.toString(), duration: duration, properties: {'key': requestKey});
      rethrow;
    } finally {
      // Clean up completed request
      _inFlightRequests.remove(requestKey);
      debugLog.network('CLEANUP', options.path, properties: {'key': requestKey, 'remainingInFlight': _inFlightRequests.length});
    }
  }

  /// Gets the count of currently in-flight requests
  int get inFlightCount => _inFlightRequests.length;

  /// Gets all in-flight request paths (for debugging)
  List<String> get inFlightPaths => 
      _inFlightRequests.values.map((req) => req.options.path).toList();

  /// Cancels all in-flight requests (useful for logout)
  Future<void> cancelAll([String? reason]) async {
    debugLog.network('CANCEL_ALL', 'all_requests', properties: {
      'reason': reason ?? 'Deduplication cleanup',
      'inFlightCount': _inFlightRequests.length,
    });
    
    for (final entry in _inFlightRequests.entries) {
      final request = entry.value;
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          DioException(
            requestOptions: request.options,
            type: DioExceptionType.cancel,
            message: reason ?? 'Request cancelled by deduplication manager',
          ),
        );
      }
    }
    
    _inFlightRequests.clear();
    debugLog.network('CANCELLED_ALL', 'all_requests', properties: {'remainingCount': 0});
  }

  /// Clears completed requests (maintenance)
  void cleanup() {
    final beforeCount = _inFlightRequests.length;
    final completedKeys = <String>[];
    
    _inFlightRequests.removeWhere((key, request) {
      if (request.completer.isCompleted) {
        completedKeys.add(key);
        return true;
      }
      return false;
    });
    
    final afterCount = _inFlightRequests.length;
    final cleanedCount = beforeCount - afterCount;
    
    if (cleanedCount > 0) {
      debugLog.cache('CLEANUP', 'completed_requests', 
        source: 'RequestDeduplicationManager',
        size: completedKeys.length);
    }
  }
}

/// Represents an in-flight request
class _InFlightRequest<T> {
  final Completer<Response<T>> completer;
  final RequestOptions options;
  final DateTime createdAt;

  _InFlightRequest(this.completer, this.options) : createdAt = DateTime.now();
}

/// Dio interceptor for request deduplication
class RequestDeduplicationInterceptor extends Interceptor {
  final RequestDeduplicationManager _manager = RequestDeduplicationManager();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip deduplication for certain endpoints
    if (_shouldSkipDeduplication(options)) {
      handler.next(options);
      return;
    }

    try {
      final response = await _manager.execute(
        () => _performRequest(options),
        options,
      );
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.reject(e);
      } else {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: e,
            message: e.toString(),
          ),
        );
      }
    }
  }

  /// Performs the actual request using a fresh Dio instance
  Future<Response> _performRequest(RequestOptions options) async {
    final dio = Dio(BaseOptions(
      baseUrl: options.baseUrl,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      sendTimeout: options.sendTimeout,
      headers: options.headers,
    ));

    return dio.fetch(options);
  }

  /// Determines if a request should skip deduplication
  bool _shouldSkipDeduplication(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') {
      return true;
    }

    final skipPaths = {
      '/auth/refresh',
      '/auth/login',
      '/auth/signup',
      '/ws',
      '/socket.io/',
    };
    
    return skipPaths.any((path) => options.path.contains(path)) ||
           options.extra['skipDeduplication'] == true;
  }
}
